import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kfc/theme/mau_sac.dart';
import 'package:kfc/models/san_pham.dart';
import 'package:kfc/providers/yeu_thich_provider.dart';

class FavoriteButton extends StatefulWidget {
  final SanPham sanPham;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const FavoriteButton({
    Key? key,
    required this.sanPham,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
  }) : super(key: key);

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleFavorite() {
    final yeuThichProvider = Provider.of<YeuThichProvider>(context, listen: false);
    final isCurrentlyFavorite = yeuThichProvider.kiemTraYeuThich(widget.sanPham.id);

    // Animation
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    if (isCurrentlyFavorite) {
      yeuThichProvider.xoaKhoiYeuThich(widget.sanPham.id);
      _showSnackBar('Đã xóa khỏi yêu thích', Icons.heart_broken, MauSac.xam);
    } else {
      yeuThichProvider.themVaoYeuThich(widget.sanPham);
      _showSnackBar('Đã thêm vào yêu thích', Icons.favorite, MauSac.kfcRed);
    }
  }

  void _showSnackBar(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<YeuThichProvider>(
      builder: (context, yeuThichProvider, child) {
        final isYeuThich = yeuThichProvider.kiemTraYeuThich(widget.sanPham.id);
        
        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: GestureDetector(
                onTap: _toggleFavorite,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isYeuThich ? Icons.favorite : Icons.favorite_border,
                    size: widget.size,
                    color: isYeuThich 
                        ? (widget.activeColor ?? MauSac.kfcRed)
                        : (widget.inactiveColor ?? MauSac.xam),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

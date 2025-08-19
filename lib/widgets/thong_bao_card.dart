import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/thong_bao.dart';
import '../providers/notification_provider.dart';
import '../theme/mau_sac.dart';
import 'package:timeago/timeago.dart' as timeago;

class ThongBaoCard extends StatefulWidget {
  final ThongBao thongBao;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool showDeleteButton;
  final EdgeInsetsGeometry? margin;

  const ThongBaoCard({
    Key? key,
    required this.thongBao,
    this.onTap,
    this.onDelete,
    this.showDeleteButton = true,
    this.margin,
  }) : super(key: key);

  @override
  State<ThongBaoCard> createState() => _ThongBaoCardState();
}

class _ThongBaoCardState extends State<ThongBaoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Start entrance animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: widget.margin ?? const EdgeInsets.only(bottom: 12),
            child: _buildCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: _getCardBackgroundColor(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getBorderColor(),
          width: _getBorderWidth(),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          if (!widget.thongBao.daDoc)
            BoxShadow(
              color: MauSac.kfcRed.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 0),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _handleTap,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            transform: Matrix4.identity()
              ..scale(_isPressed ? 0.98 : 1.0),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildCardContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notification Icon
        _buildNotificationIcon(),
        
        const SizedBox(width: 12),
        
        // Content
        Expanded(
          child: _buildContentSection(),
        ),
        
        // Actions
        if (widget.showDeleteButton)
          _buildActionButtons(),
      ],
    );
  }

  Widget _buildNotificationIcon() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _getNotificationColor().withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getNotificationColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Icon(
        _getNotificationIcon(),
        color: _getNotificationColor(),
        size: 24,
      ),
    );
  }

  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and unread indicator
        Row(
          children: [
            Expanded(
              child: Text(
                widget.thongBao.tieuDe,
                style: TextStyle(
                  color: MauSac.trang,
                  fontSize: 16,
                  fontWeight: widget.thongBao.daDoc 
                      ? FontWeight.w500 
                      : FontWeight.bold,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!widget.thongBao.daDoc) ...[
              const SizedBox(width: 8),
              _buildUnreadIndicator(),
            ],
          ],
        ),
        
        const SizedBox(height: 6),
        
        // Content
        Text(
          widget.thongBao.noiDung,
          style: TextStyle(
            color: MauSac.xam.withOpacity(0.85),
            fontSize: 14,
            height: 1.4,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 10),
        
        // Footer
        _buildFooter(),
      ],
    );
  }

  Widget _buildUnreadIndicator() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: MauSac.kfcRed,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: MauSac.kfcRed.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(0, 0),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Time and category
        Expanded(
          child: Row(
            children: [
              Icon(
                Icons.access_time,
                size: 12,
                color: MauSac.xam.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                timeago.format(widget.thongBao.thoiGian, locale: 'vi'),
                style: TextStyle(
                  color: MauSac.xam.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              _buildCategoryChip(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getNotificationColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getNotificationColor().withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        _getCategoryText(),
        style: TextStyle(
          color: _getNotificationColor(),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Mark as read/unread button
        _buildActionButton(
          icon: widget.thongBao.daDoc 
              ? Icons.mark_email_unread_outlined
              : Icons.mark_email_read_outlined,
          onTap: _toggleReadStatus,
          tooltip: widget.thongBao.daDoc ? 'Đánh dấu chưa đọc' : 'Đánh dấu đã đọc',
        ),
        
        const SizedBox(height: 8),
        
        // Delete button
        _buildActionButton(
          icon: Icons.delete_outline,
          onTap: _handleDelete,
          tooltip: 'Xóa thông báo',
          color: MauSac.kfcRed.withOpacity(0.7),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: (color ?? MauSac.xam).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color ?? MauSac.xam.withOpacity(0.7),
            size: 16,
          ),
        ),
      ),
    );
  }

  // Helper methods
  Color _getCardBackgroundColor() {
    if (!widget.thongBao.daDoc) {
      return MauSac.denNhat.withOpacity(0.95);
    }
    return MauSac.denNhat.withOpacity(0.7);
  }

  Color _getBorderColor() {
    if (!widget.thongBao.daDoc) {
      return MauSac.kfcRed.withOpacity(0.3);
    }
    return MauSac.xam.withOpacity(0.2);
  }

  double _getBorderWidth() {
    return widget.thongBao.daDoc ? 1 : 1.5;
  }

  IconData _getNotificationIcon() {
    switch (widget.thongBao.loai) {
      case 'don_hang':
        return Icons.shopping_bag_outlined;
      case 'khuyen_mai':
        return Icons.local_offer_outlined;
      case 'san_pham':
        return Icons.fastfood_outlined;
      case 'he_thong':
        return Icons.info_outline;
      case 'thanh_toan':
        return Icons.payment_outlined;
      case 'giao_hang':
        return Icons.local_shipping_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotificationColor() {
    switch (widget.thongBao.loai) {
      case 'don_hang':
        return MauSac.xanhLa;
      case 'khuyen_mai':
        return MauSac.vang;
      case 'san_pham':
        return MauSac.cam;
      case 'thanh_toan':
        return MauSac.xanhDuong;
      case 'giao_hang':
        return MauSac.tim;
      case 'he_thong':
      default:
        return MauSac.kfcRed;
    }
  }

  String _getCategoryText() {
    switch (widget.thongBao.loai) {
      case 'don_hang':
        return 'Đơn hàng';
      case 'khuyen_mai':
        return 'Khuyến mãi';
      case 'san_pham':
        return 'Sản phẩm';
      case 'thanh_toan':
        return 'Thanh toán';
      case 'giao_hang':
        return 'Giao hàng';
      case 'he_thong':
        return 'Hệ thống';
      default:
        return 'Thông báo';
    }
  }

  void _setPressed(bool pressed) {
    setState(() {
      _isPressed = pressed;
    });
  }

  void _handleTap() {
    // Mark as read if not read
    if (!widget.thongBao.daDoc) {
      _toggleReadStatus();
    }
    
    // Call custom onTap if provided
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      _handleDefaultTap();
    }
  }

  void _handleDefaultTap() {
    // Default navigation logic based on notification type
    switch (widget.thongBao.loai) {
      case 'don_hang':
        Navigator.pushNamed(context, '/don-hang');
        break;
      case 'san_pham':
        if (widget.thongBao.duLieuThem?['sanPhamId'] != null) {
          Navigator.pushNamed(
            context, 
            '/product-detail',
            arguments: {'sanPhamId': widget.thongBao.duLieuThem!['sanPhamId']},
          );
        }
        break;
      case 'khuyen_mai':
        Navigator.pushNamed(context, '/home');
        break;
      case 'thanh_toan':
        Navigator.pushNamed(context, '/don-hang');
        break;
      case 'giao_hang':
        Navigator.pushNamed(context, '/don-hang');
        break;
      default:
        break;
    }
  }

  void _toggleReadStatus() {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    if (widget.thongBao.daDoc) {
      // Mark as unread (if needed in future)
      // provider.danhDauChuaDoc(widget.thongBao.id);
    } else {
      provider.danhDauDaDoc(widget.thongBao.id);
    }
  }

  void _handleDelete() {
    if (widget.onDelete != null) {
      widget.onDelete!();
    } else {
      _showDeleteDialog();
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MauSac.denNhat,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.delete_outline,
              color: MauSac.kfcRed,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Xóa thông báo',
              style: TextStyle(
                color: MauSac.trang,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa thông báo "${widget.thongBao.tieuDe}"?',
          style: const TextStyle(
            color: MauSac.xam,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Hủy',
              style: TextStyle(color: MauSac.xam),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final provider = Provider.of<NotificationProvider>(context, listen: false);
              provider.xoaThongBao(widget.thongBao.id);
              Navigator.pop(context);
              
              // Show snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Đã xóa thông báo'),
                  backgroundColor: MauSac.xanhLa,
                  duration: const Duration(seconds: 2),
                  action: SnackBarAction(
                    label: 'Hoàn tác',
                    textColor: MauSac.trang,
                    onPressed: () {
                      // Implement undo functionality if needed
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MauSac.kfcRed,
              foregroundColor: MauSac.trang,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

// Compact version for smaller spaces
class ThongBaoCardCompact extends StatelessWidget {
  final ThongBao thongBao;
  final VoidCallback? onTap;

  const ThongBaoCardCompact({
    Key? key,
    required this.thongBao,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: thongBao.daDoc 
            ? MauSac.denNhat.withOpacity(0.5)
            : MauSac.denNhat.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: thongBao.daDoc 
              ? MauSac.xam.withOpacity(0.2)
              : MauSac.kfcRed.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _getNotificationColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getNotificationIcon(),
                    color: _getNotificationColor(),
                    size: 16,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        thongBao.tieuDe,
                        style: TextStyle(
                          color: MauSac.trang,
                          fontSize: 14,
                          fontWeight: thongBao.daDoc 
                              ? FontWeight.w400 
                              : FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeago.format(thongBao.thoiGian, locale: 'vi'),
                        style: TextStyle(
                          color: MauSac.xam.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Unread indicator
                if (!thongBao.daDoc)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: MauSac.kfcRed,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon() {
    switch (thongBao.loai) {
      case 'don_hang':
        return Icons.shopping_bag_outlined;
      case 'khuyen_mai':
        return Icons.local_offer_outlined;
      case 'san_pham':
        return Icons.fastfood_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotificationColor() {
    switch (thongBao.loai) {
      case 'don_hang':
        return MauSac.xanhLa;
      case 'khuyen_mai':
        return MauSac.vang;
      case 'san_pham':
        return MauSac.cam;
      default:
        return MauSac.kfcRed;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:kfc/theme/mau_sac.dart';

class HinhAnhDanhMuc extends StatelessWidget {
  final String hinhAnh;
  final double size;

  const HinhAnhDanhMuc({
    Key? key,
    required this.hinhAnh,
    this.size = 32,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String imagePath = _getImagePath(hinhAnh);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: MauSac.denNhat,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          imagePath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              _getDefaultIcon(hinhAnh),
              color: MauSac.kfcRed,
              size: size * 0.6,
            );
          },
        ),
      ),
    );
  }

  String _getImagePath(String hinhAnh) {
    if (hinhAnh.startsWith('assets/')) {
      return hinhAnh;
    }
    
    if (hinhAnh.isNotEmpty) {
      return 'assets/images/categories/$hinhAnh';
    }
    
    return 'assets/images/categories/default_category.png';
  }

  IconData _getDefaultIcon(String hinhAnh) {
    // Trả về icon phù hợp dựa trên tên danh mục
    String fileName = hinhAnh.toLowerCase();
    
    if (fileName.contains('chicken') || fileName.contains('ga')) {
      return Icons.set_meal;
    } else if (fileName.contains('burger')) {
      return Icons.lunch_dining;
    } else if (fileName.contains('drink') || fileName.contains('nuoc')) {
      return Icons.local_drink;
    } else if (fileName.contains('dessert') || fileName.contains('trang_mieng')) {
      return Icons.cake;
    } else if (fileName.contains('combo')) {
      return Icons.restaurant_menu;
    }
    
    return Icons.fastfood;
  }
}
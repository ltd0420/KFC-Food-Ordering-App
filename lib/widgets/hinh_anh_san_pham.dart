import 'package:flutter/material.dart';
import 'package:kfc/theme/mau_sac.dart';

class HinhAnhSanPham extends StatelessWidget {
  final String hinhAnh;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const HinhAnhSanPham({
    Key? key,
    required this.hinhAnh,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Xử lý đường dẫn hình ảnh
    String imagePath = _getImagePath(hinhAnh);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: MauSac.denNhat,
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Image.asset(
          imagePath,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            // Hiển thị icon mặc định khi không tìm thấy hình
            return Container(
              width: width,
              height: height,
              color: MauSac.denNhat,
              child: const Icon(
                Icons.fastfood,
                color: MauSac.kfcRed,
                size: 48,
              ),
            );
          },
        ),
      ),
    );
  }

  String _getImagePath(String hinhAnh) {
    // Nếu đã có đường dẫn đầy đủ
    if (hinhAnh.startsWith('assets/')) {
      return hinhAnh;
    }
    
    // Nếu chỉ có tên file
    if (hinhAnh.isNotEmpty) {
      return 'assets/images/$hinhAnh';
    }
    
    // Mặc định
    return 'assets/images/default_food.png';
  }
}
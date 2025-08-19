import 'package:flutter/material.dart';
import 'package:kfc/models/danh_muc.dart';
import 'package:kfc/theme/mau_sac.dart';
import 'package:kfc/widgets/hinh_anh_danh_muc.dart';

class DanhMucCard extends StatelessWidget {
  final DanhMuc danhMuc;
  final VoidCallback? onTap;

  const DanhMucCard({
    Key? key,
    required this.danhMuc,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MauSac.denNhat,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: MauSac.kfcRed.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HinhAnhDanhMuc(
              hinhAnh: danhMuc.hinhAnh,
              size: 40,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: Text(
                danhMuc.ten,
                style: const TextStyle(
                  color: MauSac.trang,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DanhMucCardVertical extends StatelessWidget {
  final DanhMuc danhMuc;
  final VoidCallback? onTap;

  const DanhMucCardVertical({
    Key? key,
    required this.danhMuc,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MauSac.denNhat,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: MauSac.kfcRed.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: MauSac.denNhat,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: MauSac.kfcRed.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: HinhAnhDanhMuc(
                  hinhAnh: danhMuc.hinhAnh,
                  size: 35,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    danhMuc.ten,
                    style: const TextStyle(
                      color: MauSac.trang,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    danhMuc.moTa,
                    style: TextStyle(
                      color: MauSac.trang.withOpacity(0.8),
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DanhMucCardHorizontal extends StatelessWidget {
  final DanhMuc danhMuc;
  final VoidCallback? onTap;

  const DanhMucCardHorizontal({
    Key? key,
    required this.danhMuc,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Container hình ảnh
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: MauSac.denNhat,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: MauSac.kfcRed.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: HinhAnhDanhMuc(
                  hinhAnh: danhMuc.hinhAnh,
                  size: 30,
                ),
              ),
            ),
            
            const SizedBox(height: 6),
            
            // Tên danh mục
            SizedBox(
              height: 32, // Chiều cao cố định
              child: Text(
                danhMuc.ten,
                style: const TextStyle(
                  color: MauSac.trang,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

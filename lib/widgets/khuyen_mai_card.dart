import 'package:flutter/material.dart';
import 'package:kfc/models/san_pham.dart';
import 'package:kfc/theme/mau_sac.dart';
import 'package:kfc/screens/man_hinh_chi_tiet_san_pham.dart';
import 'package:provider/provider.dart';
import 'package:kfc/providers/gio_hang_provider.dart';
import 'package:kfc/models/san_pham_gio_hang.dart';

class KhuyenMaiCard extends StatelessWidget {
  final SanPham sanPham;
  final VoidCallback? onTap;

  const KhuyenMaiCard({
    Key? key,
    required this.sanPham,
    this.onTap,
  }) : super(key: key);

  String _getImagePath(String hinhAnh) {
    if (hinhAnh.isEmpty) return '';
    if (hinhAnh.startsWith('assets/')) return hinhAnh;
    return 'assets/images/$hinhAnh';
  }

  @override
  Widget build(BuildContext context) {
    final giaGoc = sanPham.gia;
    final giaSauGiam = sanPham.khuyenMai == true && sanPham.giamGia != null && sanPham.giamGia! > 0
        ? (giaGoc * (100 - sanPham.giamGia!) / 100).round()
        : giaGoc;

    return GestureDetector(
      onTap: onTap ?? () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ManHinhChiTietSanPham(
              sanPhamId: sanPham.id,
              sanPhamBanDau: sanPham,
            ),
          ),
        );
      },
      child: Container(
        width: 280,
        height: 280, // Chiều cao cố định cho toàn bộ card
        margin: const EdgeInsets.only(right: 16),
        child: Card(
          color: MauSac.denNhat,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Hình ảnh với badge khuyến mãi
              Expanded(
                flex: 3, // 60% chiều cao cho hình ảnh
                child: Stack(
                  children: [
                    // Hình ảnh chính
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        child: _getImagePath(sanPham.hinhAnh).isNotEmpty
                            ? Image.asset(
                                _getImagePath(sanPham.hinhAnh),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: MauSac.kfcRed.withOpacity(0.8),
                                    child: const Center(
                                      child: Icon(
                                        Icons.fastfood,
                                        color: Colors.white,
                                        size: 50,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: MauSac.kfcRed.withOpacity(0.8),
                                child: const Center(
                                  child: Icon(
                                    Icons.fastfood,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                ),
                              ),
                    ),
                  ),
                  
                  // Badge khuyến mãi
                  if (sanPham.khuyenMai == true && sanPham.giamGia != null && sanPham.giamGia! > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: MauSac.kfcRed,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'GIẢM ${sanPham.giamGia}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  
                  // Label "HOT DEAL"
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: MauSac.kfcRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'HOT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Thông tin sản phẩm
            Expanded(
              flex: 2, // 40% chiều cao cho thông tin
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên sản phẩm
                    Expanded(
                      flex: 2,
                      child: Text(
                        sanPham.ten,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: MauSac.trang,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // Mô tả ngắn
                    if (sanPham.moTa.isNotEmpty)
                      Expanded(
                        flex: 1,
                        child: Text(
                          sanPham.moTa,
                          style: TextStyle(
                            fontSize: 10,
                            color: MauSac.xam.withOpacity(0.8),
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    
                    // Giá và nút
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Thông tin giá
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Giá sau giảm
                              Text(
                                '${giaSauGiam.toStringAsFixed(0)} ₫',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: MauSac.kfcRed,
                                ),
                              ),
                              
                              // Giá gốc (nếu có khuyến mãi)
                              if (sanPham.khuyenMai == true && sanPham.giamGia != null && sanPham.giamGia! > 0)
                                Text(
                                  '${giaGoc.toStringAsFixed(0)} ₫',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: MauSac.xam.withOpacity(0.7),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        // Nút đặt hàng
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: MauSac.kfcRed,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              final gioHangProvider = Provider.of<GioHangProvider>(context, listen: false);
                              final sanPhamGioHang = SanPhamGioHang(
                                sanPham: sanPham,
                                soLuong: 1,
                              );
                              gioHangProvider.themSanPham(sanPhamGioHang);
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text('Đã thêm ${sanPham.ten} vào giỏ hàng'),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: MauSac.xanhLa,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  margin: const EdgeInsets.all(16),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_shopping_cart,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Đặt',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
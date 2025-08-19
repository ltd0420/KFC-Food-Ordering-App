import 'package:flutter/material.dart';
import 'package:kfc/models/san_pham.dart';
import 'package:kfc/screens/man_hinh_chi_tiet_san_pham.dart';
import 'package:kfc/theme/mau_sac.dart';
import 'package:provider/provider.dart';
import 'package:kfc/providers/gio_hang_provider.dart';
import 'package:kfc/models/san_pham_gio_hang.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SanPhamCard extends StatelessWidget {
  final SanPham sanPham;
  final VoidCallback? onTap;
  final bool showDiscount;
  final double? width;
  final double? height;

  const SanPhamCard({
    Key? key,
    required this.sanPham,
    this.onTap,
    this.showDiscount = true,
    this.width,
    this.height,
  }) : super(key: key);

  // Widget hiển thị hình ảnh
  Widget _buildProductImage() {
    if (sanPham.hinhAnh.isEmpty) {
      return _buildPlaceholder();
    }

    if (sanPham.hinhAnh.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: sanPham.hinhAnh,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(color: MauSac.kfcRed),
        ),
        errorWidget: (context, url, error) {
          print('Lỗi tải hình ảnh từ Firebase: $error, URL: $url');
          return _buildPlaceholder();
        },
      );
    }

    return Image.asset(
      sanPham.hinhAnh,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        print('Lỗi tải tài nguyên assets: $error, Path: ${sanPham.hinhAnh}');
        return _buildPlaceholder();
      },
    );
  }

  // Widget placeholder khi hình ảnh không tải được
  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: MauSac.kfcRed.withOpacity(0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fastfood,
              size: 40,
              color: Colors.white,
            ),
            SizedBox(height: 4),
            Text(
              'KFC',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget hiển thị thông tin giá
  Widget _buildPriceInfo() {
    if (sanPham.khuyenMai == true && sanPham.giamGia != null && sanPham.giamGia! > 0) {
      final giaGoc = sanPham.gia;
      final giaSauGiam = (giaGoc * (100 - sanPham.giamGia!) / 100).round();
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          // Giá gốc (gạch ngang)
          Text(
            '${giaGoc.toStringAsFixed(0)} ₫',
            style: TextStyle(
              fontSize: 12,
              color: MauSac.xam.withOpacity(0.7),
              decoration: TextDecoration.lineThrough,
              decorationColor: MauSac.xam.withOpacity(0.7),
            ),
          ),
        ],
      );
    } else {
      return Text(
        '${sanPham.gia.toStringAsFixed(0)} ₫',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: MauSac.kfcRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        width: width,
        height: height,
        child: Card(
          color: MauSac.denNhat,
          elevation: 6,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hình ảnh sản phẩm
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildProductImage(),
                      // Overlay gradient
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Badge khuyến mãi
                      if (showDiscount && sanPham.khuyenMai == true && sanPham.giamGia != null && sanPham.giamGia! > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: MauSac.kfcRed,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '-${sanPham.giamGia}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Thông tin sản phẩm
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tên sản phẩm
                      Expanded(
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
                      
                      const SizedBox(height: 8),
                      
                      // Thông tin giá và khuyến mãi
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Giá sản phẩm
                          Expanded(
                            child: _buildPriceInfo(),
                          ),
                          
                          // Nút thêm vào giỏ hàng
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: MauSac.kfcRed,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: MauSac.kfcRed.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  // Thêm sản phẩm vào giỏ hàng
                                  final gioHangProvider = Provider.of<GioHangProvider>(context, listen: false);
                                  final sanPhamGioHang = SanPhamGioHang(
                                    sanPham: sanPham,
                                    soLuong: 1,
                                  );
                                  gioHangProvider.themSanPham(sanPhamGioHang);
                                  
                                  // Hiển thị snackbar khi thêm vào giỏ hàng
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Đã thêm ${sanPham.ten} vào giỏ hàng'),
                                      duration: const Duration(seconds: 1),
                                      backgroundColor: MauSac.xanhLa,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                },
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 20,
                                ),
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

// Widget mở rộng cho danh sách sản phẩm ngang
class SanPhamCardHorizontal extends StatelessWidget {
  final SanPham sanPham;
  final VoidCallback? onTap;

  const SanPhamCardHorizontal({
    Key? key,
    required this.sanPham,
    this.onTap,
  }) : super(key: key);

  Widget _buildProductImage() {
    if (sanPham.hinhAnh.isEmpty) {
      return _buildPlaceholder();
    }

    if (sanPham.hinhAnh.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: sanPham.hinhAnh,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(color: MauSac.kfcRed),
        ),
        errorWidget: (context, url, error) {
          print('Lỗi tải hình ảnh từ Firebase: $error, URL: $url');
          return _buildPlaceholder();
        },
      );
    }

    return Image.asset(
      sanPham.hinhAnh,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        print('Lỗi tải tài nguyên assets: $error, Path: ${sanPham.hinhAnh}');
        return _buildPlaceholder();
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: MauSac.kfcRed.withOpacity(0.8),
      child: const Center(
        child: Icon(
          Icons.fastfood,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Card(
          color: MauSac.denNhat,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Hình ảnh
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 80,
                    height: 80,
                    child: _buildProductImage(),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Thông tin sản phẩm
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tên sản phẩm
                      Text(
                        sanPham.ten,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: MauSac.trang,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Mô tả ngắn
                      if (sanPham.moTa.isNotEmpty)
                        Text(
                          sanPham.moTa,
                          style: TextStyle(
                            fontSize: 12,
                            color: MauSac.xam.withOpacity(0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      
                      const SizedBox(height: 8),
                      
                      // Giá và khuyến mãi
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Giá
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (sanPham.khuyenMai == true && sanPham.giamGia != null && sanPham.giamGia! > 0) ...[
                                Text(
                                  '${((sanPham.gia * (100 - sanPham.giamGia!) / 100)).round().toStringAsFixed(0)} ₫',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: MauSac.kfcRed,
                                  ),
                                ),
                                Text(
                                  '${sanPham.gia.toStringAsFixed(0)} ₫',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: MauSac.xam.withOpacity(0.7),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ] else
                                Text(
                                  '${sanPham.gia.toStringAsFixed(0)} ₫',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: MauSac.kfcRed,
                                  ),
                                ),
                            ],
                          ),
                          
                          // Badge khuyến mãi
                          if (sanPham.khuyenMai == true && sanPham.giamGia != null && sanPham.giamGia! > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: MauSac.kfcRed,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '-${sanPham.giamGia}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget cho sản phẩm nhỏ (trong danh sách ngang)
class SanPhamCardSmall extends StatelessWidget {
  final SanPham sanPham;
  final VoidCallback? onTap;

  const SanPhamCardSmall({
    Key? key,
    required this.sanPham,
    this.onTap,
  }) : super(key: key);

  Widget _buildProductImage() {
    if (sanPham.hinhAnh.isEmpty) {
      return _buildPlaceholder();
    }

    if (sanPham.hinhAnh.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: sanPham.hinhAnh,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(color: MauSac.kfcRed),
        ),
        errorWidget: (context, url, error) {
          print('Lỗi tải hình ảnh từ Firebase: $error, URL: $url');
          return _buildPlaceholder();
        },
      );
    }

    return Image.asset(
      sanPham.hinhAnh,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        print('Lỗi tải tài nguyên assets: $error, Path: ${sanPham.hinhAnh}');
        return _buildPlaceholder();
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: MauSac.kfcRed.withOpacity(0.8),
      child: const Center(
        child: Icon(
          Icons.fastfood,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Card(
          color: MauSac.denNhat,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hình ảnh
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Container(
                    width: double.infinity,
                    child: _buildProductImage(),
                  ),
                ),
              ),
              
              // Thông tin
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        sanPham.ten,
                        style: const TextStyle(
                          color: MauSac.trang,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${sanPham.gia.toStringAsFixed(0)} ₫',
                        style: const TextStyle(
                          color: MauSac.kfcRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
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
import 'package:kfc/models/san_pham.dart';

class SanPhamGioHang {
  final SanPham sanPham;
  final int soLuong;

  SanPhamGioHang({
    required this.sanPham,
    required this.soLuong,
  });

  // Tính tổng giá của sản phẩm trong giỏ hàng
  double get tongGia {
    final giaSanPham = sanPham.coKhuyenMai ? sanPham.giaGiam : sanPham.gia;
    return (giaSanPham * soLuong).toDouble();
  }

  // Chuyển đổi từ Map sang SanPhamGioHang
  factory SanPhamGioHang.fromJson(Map<String, dynamic> map) {
    return SanPhamGioHang(
      sanPham: SanPham.fromJson(map['sanPham']),
      soLuong: map['soLuong'] ?? 1,
    );
  }

  // Chuyển đổi từ SanPhamGioHang sang Map
  Map<String, dynamic> toJson() {
    return {
      'sanPham': sanPham.toJson(),
      'soLuong': soLuong,
    };
  }

  // Tạo bản sao với số lượng mới
  SanPhamGioHang copyWith({int? soLuong}) {
    return SanPhamGioHang(
      sanPham: sanPham,
      soLuong: soLuong ?? this.soLuong,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SanPhamGioHang &&
        other.sanPham.id == sanPham.id &&
        other.soLuong == soLuong;
  }

  @override
  int get hashCode => sanPham.id.hashCode ^ soLuong.hashCode;

  @override
  String toString() {
    return 'SanPhamGioHang(sanPham: ${sanPham.ten}, soLuong: $soLuong)';
  }
}

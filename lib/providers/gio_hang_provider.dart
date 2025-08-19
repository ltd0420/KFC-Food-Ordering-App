import 'package:flutter/material.dart';
import 'package:kfc/models/san_pham_gio_hang.dart';

class GioHangProvider extends ChangeNotifier {
  List<SanPhamGioHang> _danhSachSanPham = [];

  List<SanPhamGioHang> get danhSachSanPham => _danhSachSanPham;

  int get tongSoLuong {
    return _danhSachSanPham.fold(0, (sum, item) => sum + item.soLuong);
  }

  double get tongTien {
    return _danhSachSanPham.fold(0.0, (sum, item) => sum + item.tongGia);
  }

  void themSanPham(SanPhamGioHang sanPhamGioHang) {
    final index = _danhSachSanPham.indexWhere(
      (item) => item.sanPham.id == sanPhamGioHang.sanPham.id,
    );

    if (index >= 0) {
      _danhSachSanPham[index] = _danhSachSanPham[index].copyWith(
        soLuong: _danhSachSanPham[index].soLuong + sanPhamGioHang.soLuong,
      );
    } else {
      _danhSachSanPham.add(sanPhamGioHang);
    }
    notifyListeners();
  }

  void tangSoLuong(String sanPhamId) {
    final index = _danhSachSanPham.indexWhere(
      (item) => item.sanPham.id == sanPhamId,
    );

    if (index >= 0) {
      _danhSachSanPham[index] = _danhSachSanPham[index].copyWith(
        soLuong: _danhSachSanPham[index].soLuong + 1,
      );
      notifyListeners();
    }
  }

  void giamSoLuong(String sanPhamId) {
    final index = _danhSachSanPham.indexWhere(
      (item) => item.sanPham.id == sanPhamId,
    );

    if (index >= 0 && _danhSachSanPham[index].soLuong > 1) {
      _danhSachSanPham[index] = _danhSachSanPham[index].copyWith(
        soLuong: _danhSachSanPham[index].soLuong - 1,
      );
      notifyListeners();
    }
  }

  void xoaSanPham(String sanPhamId) {
    _danhSachSanPham.removeWhere((item) => item.sanPham.id == sanPhamId);
    notifyListeners();
  }

  void xoaGioHang() {
    _danhSachSanPham.clear();
    notifyListeners();
  }

  bool kiemTraSanPhamTrongGio(String sanPhamId) {
    return _danhSachSanPham.any((item) => item.sanPham.id == sanPhamId);
  }

  int laySoLuongSanPham(String sanPhamId) {
    final index = _danhSachSanPham.indexWhere(
      (item) => item.sanPham.id == sanPhamId,
    );
    return index >= 0 ? _danhSachSanPham[index].soLuong : 0;
  }
}

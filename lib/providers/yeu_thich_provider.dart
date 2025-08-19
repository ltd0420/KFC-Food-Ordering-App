import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kfc/models/san_pham.dart';

class YeuThichProvider with ChangeNotifier {
  List<SanPham> _danhSachYeuThich = [];
  final String _keyLuuTru = 'danh_sach_yeu_thich';

  List<SanPham> get danhSachYeuThich => _danhSachYeuThich;

  YeuThichProvider() {
    _khoiTao();
  }

  Future<void> _khoiTao() async {
    await _layDanhSachYeuThich();
  }

  Future<void> _layDanhSachYeuThich() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final danhSachJson = prefs.getStringList(_keyLuuTru) ?? [];
      
      _danhSachYeuThich = danhSachJson.map((json) {
        final Map<String, dynamic> data = jsonDecode(json);
        return SanPham(
          id: data['id'],
          ten: data['ten'],
          gia: data['gia'],
          hinhAnh: data['hinhAnh'],
          moTa: data['moTa'],
          danhMucId: data['danhMucId'],
          khuyenMai: data['khuyenMai'],
          giamGia: data['giamGia'],
        );
      }).toList();
      
      notifyListeners();
    } catch (e) {
      print('Lỗi khi lấy danh sách yêu thích: $e');
    }
  }

  Future<void> _luuDanhSachYeuThich() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final danhSachJson = _danhSachYeuThich.map((sanPham) {
        return jsonEncode({
          'id': sanPham.id,
          'ten': sanPham.ten,
          'gia': sanPham.gia,
          'hinhAnh': sanPham.hinhAnh,
          'moTa': sanPham.moTa,
          'danhMucId': sanPham.danhMucId,
          'khuyenMai': sanPham.khuyenMai,
          'giamGia': sanPham.giamGia,
        });
      }).toList();
      
      await prefs.setStringList(_keyLuuTru, danhSachJson);
    } catch (e) {
      print('Lỗi khi lưu danh sách yêu thích: $e');
    }
  }

  bool kiemTraYeuThich(String sanPhamId) {
    return _danhSachYeuThich.any((item) => item.id == sanPhamId);
  }

  Future<void> themVaoYeuThich(SanPham sanPham) async {
    if (!kiemTraYeuThich(sanPham.id)) {
      _danhSachYeuThich.add(sanPham);
      await _luuDanhSachYeuThich();
      notifyListeners();
    }
  }

  Future<void> xoaKhoiYeuThich(String sanPhamId) async {
    _danhSachYeuThich.removeWhere((item) => item.id == sanPhamId);
    await _luuDanhSachYeuThich();
    notifyListeners();
  }

  Future<void> toggleYeuThich(SanPham sanPham) async {
    if (kiemTraYeuThich(sanPham.id)) {
      await xoaKhoiYeuThich(sanPham.id);
    } else {
      await themVaoYeuThich(sanPham);
    }
  }

  Future<void> xoaTatCa() async {
    _danhSachYeuThich.clear();
    await _luuDanhSachYeuThich();
    notifyListeners();
  }
}

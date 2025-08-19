import 'package:flutter/material.dart';
import 'package:kfc/models/danh_muc.dart';
import 'package:kfc/services/firebase_service.dart';

class DanhMucProvider extends ChangeNotifier {
  List<DanhMuc> _danhSachDanhMuc = [];
  bool _dangTaiDuLieu = false;
  String? _loi;

  // Getters
  List<DanhMuc> get danhSachDanhMuc => _danhSachDanhMuc;
  bool get dangTaiDuLieu => _dangTaiDuLieu;
  String? get loi => _loi;

  // Constructor - tự động tải dữ liệu
  DanhMucProvider() {
    layDanhSachDanhMuc();
  }

  // Lấy danh mục từ Firebase
  Future<void> layDanhSachDanhMuc({bool forceRefresh = false}) async {
    _dangTaiDuLieu = true;
    _loi = null;
    notifyListeners();

    try {
      _danhSachDanhMuc = await FirebaseService.layDanhSachDanhMuc(forceRefresh: forceRefresh);
      _loi = null;
    } catch (e) {
      _loi = 'Không thể tải danh mục: $e';
      _danhSachDanhMuc = [];
    } finally {
      _dangTaiDuLieu = false;
      notifyListeners();
    }
  }

  // Tìm danh mục theo ID
  DanhMuc? timDanhMucTheoId(String id) {
    try {
      return _danhSachDanhMuc.firstWhere((danhMuc) => danhMuc.id == id);
    } catch (e) {
      return null;
    }
  }

  // Làm mới dữ liệu (force refresh)
  Future<void> lamMoi() async {
    await layDanhSachDanhMuc(forceRefresh: true);
  }
}
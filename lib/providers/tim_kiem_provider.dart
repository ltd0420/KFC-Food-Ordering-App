import 'package:flutter/material.dart';
import 'package:kfc/models/san_pham.dart';
import 'package:kfc/services/firebase_service.dart';

class TimKiemProvider extends ChangeNotifier {
  String _tuKhoa = '';
  String _danhMucId = '';
  String _sapXepTheo = 'mac_dinh';
  bool _chiHienKhuyenMai = false;
  List<SanPham> _ketQuaTimKiem = [];
  bool _dangTimKiem = false;

  String get tuKhoa => _tuKhoa;
  String get danhMucId => _danhMucId;
  String get sapXepTheo => _sapXepTheo;
  bool get chiHienKhuyenMai => _chiHienKhuyenMai;
  List<SanPham> get ketQuaTimKiem => _ketQuaTimKiem;
  bool get dangTimKiem => _dangTimKiem;

  // Đặt từ khóa tìm kiếm
  void datTuKhoa(String tuKhoa) {
    _tuKhoa = tuKhoa;
    _timKiem();
    notifyListeners();
  }

  // Đặt danh mục lọc
  void datDanhMuc(String danhMucId) {
    _danhMucId = danhMucId;
    _timKiem();
    notifyListeners();
  }

  // Đặt cách sắp xếp
  void datSapXep(String sapXepTheo) {
    _sapXepTheo = sapXepTheo;
    _timKiem();
    notifyListeners();
  }

  // Đặt chỉ hiện khuyến mãi
  void datChiHienKhuyenMai(bool chiHienKhuyenMai) {
    _chiHienKhuyenMai = chiHienKhuyenMai;
    _timKiem();
    notifyListeners();
  }

  // Xóa bộ lọc
  void xoaBoLoc() {
    _danhMucId = '';
    _sapXepTheo = 'mac_dinh';
    _chiHienKhuyenMai = false;
    _timKiem();
    notifyListeners();
  }

  // Thực hiện tìm kiếm (SỬA LẠI)
  Future<void> _timKiem() async {
    if (_tuKhoa.isEmpty && _danhMucId.isEmpty && !_chiHienKhuyenMai) {
      _ketQuaTimKiem = [];
      return;
    }

    _dangTimKiem = true;
    notifyListeners();

    try {
      List<SanPham> ketQua = [];

      if (_tuKhoa.isNotEmpty) {
        // Tìm kiếm theo từ khóa - SỬA LẠI
        ketQua = await FirebaseService.timKiemSanPham(_tuKhoa);
      } else if (_danhMucId.isNotEmpty) {
        // Lọc theo danh mục
        ketQua = await FirebaseService.layDanhSachSanPhamTheoDanhMuc(_danhMucId);
      } else {
        // Lấy tất cả sản phẩm
        ketQua = await FirebaseService.layDanhSachSanPham();
      }

      // Áp dụng bộ lọc
      if (_danhMucId.isNotEmpty && _tuKhoa.isNotEmpty) {
        ketQua = ketQua.where((sp) => sp.danhMucId == _danhMucId).toList();
      }

      if (_chiHienKhuyenMai) {
        ketQua = ketQua.where((sp) => sp.khuyenMai == true).toList();
      }

      // Sắp xếp
      switch (_sapXepTheo) {
        case 'gia_tang':
          ketQua.sort((a, b) => a.gia.compareTo(b.gia));
          break;
        case 'gia_giam':
          ketQua.sort((a, b) => b.gia.compareTo(a.gia));
          break;
        default:
          // Giữ thứ tự mặc định
          break;
      }

      _ketQuaTimKiem = ketQua;
    } catch (e) {
      print('Lỗi khi tìm kiếm: $e');
      _ketQuaTimKiem = [];
    } finally {
      _dangTimKiem = false;
      notifyListeners();
    }
  }

  // Lọc thông báo theo loại
  List<SanPham> locThongBaoTheoLoai(String loai) {
    switch (loai) {
      case 'khuyen_mai':
        return _ketQuaTimKiem.where((sp) => sp.khuyenMai == true).toList();
      default:
        return _ketQuaTimKiem;
    }
  }
}
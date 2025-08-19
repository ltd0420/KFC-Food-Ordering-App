import 'package:flutter/foundation.dart';
import 'package:kfc/models/nguoi_dung.dart';

class NguoiDungProvider with ChangeNotifier {
  NguoiDung? _nguoiDung;

  NguoiDung? get nguoiDung => _nguoiDung;

  // Getter để tương thích với code khác
  NguoiDung? get currentUser => _nguoiDung;

  bool get daDangNhap => _nguoiDung != null;

  // Kiểm tra có phải admin không
  bool get isAdmin => _nguoiDung?.isAdmin ?? false;

  // Kiểm tra có phải user không
  bool get isUser => _nguoiDung?.isUser ?? true;

  // Lấy quyền hiện tại
  String get currentRole => _nguoiDung?.rule ?? 'user';

  void dangNhap(NguoiDung nguoiDung) {
    _nguoiDung = nguoiDung;
    notifyListeners();
  }

  void dangXuat() {
    _nguoiDung = null;
    notifyListeners();
  }

  void capNhatThongTin({
    String? ten,
    String? soDienThoai,
    String? rule,
  }) {
    if (_nguoiDung != null) {
      _nguoiDung = NguoiDung(
        id: _nguoiDung!.id,
        ten: ten ?? _nguoiDung!.ten,
        email: _nguoiDung!.email,
        soDienThoai: soDienThoai ?? _nguoiDung!.soDienThoai,
        rule: rule ?? _nguoiDung!.rule,
      );
      notifyListeners();
    }
  }

  // Cập nhật quyền (chỉ dành cho admin hoặc hệ thống)
  void capNhatQuyen(String newRule) {
    if (_nguoiDung != null) {
      _nguoiDung = NguoiDung(
        id: _nguoiDung!.id,
        ten: _nguoiDung!.ten,
        email: _nguoiDung!.email,
        soDienThoai: _nguoiDung!.soDienThoai,
        rule: newRule,
      );
      notifyListeners();
    }
  }

  // Kiểm tra quyền truy cập
  bool hasPermission(String requiredRole) {
    if (_nguoiDung == null) return false;
    
    switch (requiredRole) {
      case 'admin':
        return _nguoiDung!.rule == 'admin';
      case 'user':
        return _nguoiDung!.rule == 'user' || _nguoiDung!.rule == 'admin';
      default:
        return false;
    }
  }

  // Reset về trạng thái ban đầu
  void reset() {
    _nguoiDung = null;
    notifyListeners();
  }
}
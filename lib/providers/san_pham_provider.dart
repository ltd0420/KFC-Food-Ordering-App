import 'package:flutter/material.dart';
import 'package:kfc/models/san_pham.dart';
import 'package:kfc/services/firebase_service.dart';

class SanPhamProvider extends ChangeNotifier {
  List<SanPham> _danhSachSanPham = [];
  List<SanPham> _sanPhamKhuyenMai = [];
  List<SanPham> _sanPhamNoiBat = [];
  
  bool _dangTaiDuLieu = false;
  bool _dangTaiKhuyenMai = false;
  bool _dangTaiNoiBat = false;
  
  String? _loi;
  String? _loiKhuyenMai;
  String? _loiNoiBat;

  // Getters
  List<SanPham> get danhSachSanPham => _danhSachSanPham;
  List<SanPham> get sanPhamKhuyenMai => _sanPhamKhuyenMai;
  List<SanPham> get sanPhamNoiBat => _sanPhamNoiBat;
  
  bool get dangTaiDuLieu => _dangTaiDuLieu;
  bool get dangTaiKhuyenMai => _dangTaiKhuyenMai;
  bool get dangTaiNoiBat => _dangTaiNoiBat;
  
  String? get loi => _loi;
  String? get loiKhuyenMai => _loiKhuyenMai;
  String? get loiNoiBat => _loiNoiBat;

  // Constructor - tự động tải dữ liệu
  SanPhamProvider() {
    layDanhSachSanPham();
    layDanhSachSanPhamKhuyenMai();
    layDanhSachSanPhamNoiBat();
  }

  // Lấy tất cả sản phẩm
  Future<void> layDanhSachSanPham({bool forceRefresh = false}) async {
    _dangTaiDuLieu = true;
    _loi = null;
    notifyListeners();

    try {
      _danhSachSanPham = await FirebaseService.layDanhSachSanPham(forceRefresh: forceRefresh);
      _loi = null;
    } catch (e) {
      _loi = 'Không thể tải sản phẩm: $e';
      _danhSachSanPham = [];
    } finally {
      _dangTaiDuLieu = false;
      notifyListeners();
    }
  }

  // Lấy sản phẩm khuyến mãi
  Future<void> layDanhSachSanPhamKhuyenMai() async {
    _dangTaiKhuyenMai = true;
    _loiKhuyenMai = null;
    notifyListeners();

    try {
      _sanPhamKhuyenMai = await FirebaseService.layDanhSachSanPhamKhuyenMai();
      _loiKhuyenMai = null;
    } catch (e) {
      _loiKhuyenMai = 'Không thể tải sản phẩm khuyến mãi: $e';
      _sanPhamKhuyenMai = [];
    } finally {
      _dangTaiKhuyenMai = false;
      notifyListeners();
    }
  }

  // Lấy sản phẩm nổi bật
  Future<void> layDanhSachSanPhamNoiBat() async {
    _dangTaiNoiBat = true;
    _loiNoiBat = null;
    notifyListeners();

    try {
      _sanPhamNoiBat = await FirebaseService.layDanhSachSanPhamNoiBat();
      _loiNoiBat = null;
    } catch (e) {
      _loiNoiBat = 'Không thể tải sản phẩm nổi bật: $e';
      _sanPhamNoiBat = [];
    } finally {
      _dangTaiNoiBat = false;
      notifyListeners();
    }
  }

  // Lấy sản phẩm theo danh mục
  Future<List<SanPham>> layDanhSachSanPhamTheoDanhMuc(String danhMucId) async {
    try {
      return await FirebaseService.layDanhSachSanPhamTheoDanhMuc(danhMucId);
    } catch (e) {
      print('Lỗi khi lấy sản phẩm theo danh mục: $e');
      return [];
    }
  }

  // Lắng nghe thay đổi real-time
  void batDauLangNghe() {
    FirebaseService.streamSanPham().listen(
      (danhSachMoi) {
        _danhSachSanPham = danhSachMoi;
        _sanPhamKhuyenMai = danhSachMoi.where((sp) => sp.khuyenMai == true).toList();
        _loi = null;
        _loiKhuyenMai = null;
        notifyListeners();
      },
      onError: (error) {
        _loi = 'Lỗi kết nối: $error';
        notifyListeners();
      },
    );
  }

  // Tìm sản phẩm theo ID
  SanPham? timSanPhamTheoId(String id) {
    try {
      return _danhSachSanPham.firstWhere((sanPham) => sanPham.id == id);
    } catch (e) {
      return null;
    }
  }

  // Làm mới dữ liệu (force refresh)
  Future<void> lamMoi() async {
    // Xóa cache trước khi làm mới
    FirebaseService.xoaCache();
    
    await Future.wait([
      layDanhSachSanPham(forceRefresh: true),
      layDanhSachSanPhamKhuyenMai(),
      layDanhSachSanPhamNoiBat(),
    ]);
  }
}
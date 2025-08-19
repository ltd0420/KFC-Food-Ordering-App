import 'package:flutter/material.dart';
import 'package:kfc/models/don_hang.dart';
import 'package:kfc/models/san_pham_gio_hang.dart';
import 'package:kfc/services/don_hang_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

class DonHangProvider with ChangeNotifier {
  final DonHangService _donHangService = DonHangService();
  Map<String, int> _orderStatuses = {};
  Map<String, int> _paymentStatuses = {};
  
  List<DonHang> _donHangList = [];
  DonHang? _currentDonHang;
  bool _isLoading = false;
  String? _error;
  bool _disposed = false;

  List<DonHang> get donHangList => _donHangList;
  DonHang? get currentDonHang => _currentDonHang;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _notifyListeners() {
    if (!_disposed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) {
          notifyListeners();
        }
      });
    }
  }

  Future<String?> createDonHang({
    required String nguoiDungId,
    required String tenNguoiNhan,
    required String soDienThoai,
    required String diaChi,
    required List<SanPhamGioHang> danhSachSanPham,
    required double tongTien,
    required double phiGiaoHang,
    String? ghiChu,
    String? phuongThucThanhToan,
  }) async {
    if (_disposed) return null;
    
    _isLoading = true;
    _error = null;
    _notifyListeners();

    try {
      final donHang = DonHang(
        id: '',
        nguoiDungId: nguoiDungId,
        tenNguoiNhan: tenNguoiNhan,
        soDienThoai: soDienThoai,
        diaChi: diaChi,
        danhSachSanPham: danhSachSanPham,
        tongTien: tongTien,
        phiGiaoHang: phiGiaoHang,
        tongCong: tongTien + phiGiaoHang,
        trangThai: TrangThaiDonHang.dangXuLy,
        thoiGianDat: DateTime.now(),
        ghiChu: ghiChu,
        phuongThucThanhToan: phuongThucThanhToan,
      );

      final id = await _donHangService.createDonHang(donHang);
      
      if (_disposed) return null;
      
      _currentDonHang = DonHang(
        id: id,
        nguoiDungId: nguoiDungId,
        tenNguoiNhan: tenNguoiNhan,
        soDienThoai: soDienThoai,
        diaChi: diaChi,
        danhSachSanPham: danhSachSanPham,
        tongTien: tongTien,
        phiGiaoHang: phiGiaoHang,
        tongCong: tongTien + phiGiaoHang,
        trangThai: TrangThaiDonHang.dangXuLy,
        thoiGianDat: DateTime.now(),
        ghiChu: ghiChu,
        phuongThucThanhToan: phuongThucThanhToan,
      );
      
      _isLoading = false;
      _notifyListeners();
      return id;
    } catch (e) {
      if (!_disposed) {
        _error = 'Đã xảy ra lỗi khi tạo đơn hàng: $e';
        _isLoading = false;
        _notifyListeners();
      }
      return null;
    }
  }

  Future<void> updateOrderStatus(String orderId, int status) async {
    try {
     print('Mock: Updating order status for OrderID=$orderId to Status=$status');
      _orderStatuses[orderId] = status; // Lưu trạng thái trong bộ nhớ
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updatePaymentStatus(String orderId, int status) async {
    try {
      print('Mock: Updating payment status for OrderID=$orderId to PaymentStatus=$status');
      _paymentStatuses[orderId] = status; // Lưu trạng thái trong bộ nhớ
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchDonHangByUser(String userId) async {
    if (_disposed) return;
    
    _isLoading = true;
    _error = null;
    _notifyListeners();

    try {
      final orders = await _donHangService.getDonHangByUser(userId);
      
      if (!_disposed) {
        _donHangList = orders;
        _isLoading = false;
        _notifyListeners();
      }
    } catch (e) {
      if (!_disposed) {
        _error = 'Đã xảy ra lỗi khi lấy danh sách đơn hàng: $e';
        _isLoading = false;
        _notifyListeners();
      }
    }
  }

  Future<void> fetchDonHangById(String id) async {
    if (_disposed) return;
    
    _isLoading = true;
    _error = null;
    _notifyListeners();

    try {
      final order = await _donHangService.getDonHangById(id);
      
      if (!_disposed) {
        _currentDonHang = order;
        _isLoading = false;
        _notifyListeners();
      }
    } catch (e) {
      if (!_disposed) {
        _error = 'Đã xảy ra lỗi khi lấy chi tiết đơn hàng: $e';
        _isLoading = false;
        _notifyListeners();
      }
    }
  }

  Future<bool> updateTrangThaiDonHang(String id, TrangThaiDonHang trangThai) async {
    if (_disposed) return false;
    
    _isLoading = true;
    _error = null;
    _notifyListeners();

    try {
      await _donHangService.updateTrangThaiDonHang(id, trangThai);
      
      if (_disposed) return false;
      
      if (_currentDonHang != null && _currentDonHang!.id == id) {
        _currentDonHang = _currentDonHang!.copyWith(trangThai: trangThai);
      }
      
      _donHangList = _donHangList.map((donHang) {
        if (donHang.id == id) {
          return donHang.copyWith(trangThai: trangThai);
        }
        return donHang;
      }).toList();
      
      _isLoading = false;
      _notifyListeners();
      return true;
    } catch (e) {
      if (!_disposed) {
        _error = 'Đã xảy ra lỗi khi cập nhật trạng thái đơn hàng: $e';
        _isLoading = false;
        _notifyListeners();
      }
      return false;
    }
  }

  Future<void> fetchAllDonHang() async {
    if (_disposed) return;
    
    _isLoading = true;
    _error = null;
    _notifyListeners();

    try {
      final orders = await _donHangService.getAllDonHang();
      
      if (!_disposed) {
        _donHangList = orders;
        _isLoading = false;
        _notifyListeners();
      }
    } catch (e) {
      if (!_disposed) {
        _error = 'Đã xảy ra lỗi khi lấy tất cả đơn hàng: $e';
        _isLoading = false;
        _notifyListeners();
      }
    }
  }

  Future<void> fetchDonHangByTrangThai(TrangThaiDonHang trangThai) async {
    if (_disposed) return;
    
    _isLoading = true;
    _error = null;
    _notifyListeners();

    try {
      final orders = await _donHangService.getDonHangByTrangThai(trangThai);
      
      if (!_disposed) {
        _donHangList = orders;
        _isLoading = false;
        _notifyListeners();
      }
    } catch (e) {
      if (!_disposed) {
        _error = 'Đã xảy ra lỗi khi lấy đơn hàng theo trạng thái: $e';
        _isLoading = false;
        _notifyListeners();
      }
    }
  }

  Future<void> fetchDonHangByUserAndTrangThai(String userId, TrangThaiDonHang trangThai) async {
    if (_disposed) return;
    
    _isLoading = true;
    _error = null;
    _notifyListeners();

    try {
      final allUserOrders = await _donHangService.getDonHangByUser(userId);
      
      if (!_disposed) {
        _donHangList = allUserOrders.where((donHang) => donHang.trangThai == trangThai).toList();
        _isLoading = false;
        _notifyListeners();
      }
    } catch (e) {
      if (!_disposed) {
        _error = 'Đã xảy ra lỗi khi lấy đơn hàng theo trạng thái: $e';
        _isLoading = false;
        _notifyListeners();
      }
    }
  }

  List<DonHang> getDonHangByTrangThaiFromList(TrangThaiDonHang trangThai) {
    return _donHangList.where((donHang) => donHang.trangThai == trangThai).toList();
  }

  int getCountByTrangThai(TrangThaiDonHang trangThai) {
    return _donHangList.where((donHang) => donHang.trangThai == trangThai).length;
  }

  double getTongDoanhThu() {
    return _donHangList
        .where((donHang) => donHang.trangThai == TrangThaiDonHang.daGiao)
        .fold(0.0, (sum, donHang) => sum + donHang.tongCong);
  }

  void reset() {
    if (_disposed) return;
    
    _donHangList = [];
    _currentDonHang = null;
    _isLoading = false;
    _error = null;
    _notifyListeners();
  }

  void clearError() {
    if (_disposed) return;
    
    _error = null;
    _notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
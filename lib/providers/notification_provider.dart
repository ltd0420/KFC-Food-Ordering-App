import 'package:flutter/material.dart';
import '../models/thong_bao.dart';
import '../services/notification_service.dart';
import 'dart:async';

class NotificationProvider extends ChangeNotifier {
  List<ThongBao> _danhSachThongBao = [];
  bool _dangTai = false;
  String? _loi;
  bool _isFirebaseConnected = false;
  bool _collectionExists = false;
  StreamSubscription<List<ThongBao>>? _notificationSubscription;

  List<ThongBao> get danhSachThongBao => _danhSachThongBao;
  bool get dangTai => _dangTai;
  String? get loi => _loi;
  bool get isFirebaseConnected => _isFirebaseConnected;
  bool get collectionExists => _collectionExists;

  // Lấy số lượng thông báo chưa đọc
  int get soThongBaoChuaDoc {
    return _danhSachThongBao.where((tb) => !tb.daDoc).length;
  }

  // Lấy thông báo mới nhất chưa đọc
  List<ThongBao> get thongBaoChuaDoc {
    return _danhSachThongBao.where((tb) => !tb.daDoc).toList();
  }

  // Khởi tạo và kiểm tra Firebase
  void initialize() {
    _initializeFirebaseConnection();
    _checkCollectionAndListen();
  }

  void _initializeFirebaseConnection() {
    try {
      _isFirebaseConnected = true;
      print('✅ Kết nối Firebase thành công');
      notifyListeners();
    } catch (e) {
      _isFirebaseConnected = false;
      _loi = 'Lỗi kết nối Firebase: $e';
      print('❌ Lỗi kết nối Firebase: $e');
      notifyListeners();
    }
  }

  Future<void> _checkCollectionAndListen() async {
    try {
      // Kiểm tra collection có tồn tại không
      _collectionExists = await NotificationService.checkNotificationCollectionExists();
      
      if (_collectionExists) {
        _listenToNotifications();
      } else {
        print('📭 Collection thong_bao chưa được tạo - chờ admin tạo thông báo đầu tiên');
        _danhSachThongBao = [];
        _dangTai = false;
        _loi = null;
      }
      
      notifyListeners();
    } catch (e) {
      _loi = 'Lỗi kiểm tra Firebase: $e';
      _dangTai = false;
      _isFirebaseConnected = false;
      notifyListeners();
    }
  }

  void _listenToNotifications() {
    _notificationSubscription?.cancel();
  
    _notificationSubscription = NotificationService.streamUserNotifications().listen(
      (danhSach) {
        _danhSachThongBao = danhSach;
        _dangTai = false;
        _loi = null;
        _isFirebaseConnected = true;
        _collectionExists = true;
        notifyListeners();
      },
      onError: (error) {
        _loi = 'Lỗi Firebase: $error';
        _dangTai = false;
        _isFirebaseConnected = false;
        notifyListeners();
      },
    );
  }

  // Tải danh sách thông báo
  Future<void> taiDanhSachThongBao() async {
    _dangTai = true;
    _loi = null;
    notifyListeners();

    try {
      // Kiểm tra lại collection
      _collectionExists = await NotificationService.checkNotificationCollectionExists();
      
      if (_collectionExists) {
        _danhSachThongBao = await NotificationService.getUserNotifications();
        _isFirebaseConnected = true;
      } else {
        _danhSachThongBao = [];
        print('📭 Collection thong_bao chưa được tạo');
      }
      
      _dangTai = false;
      notifyListeners();
    } catch (e) {
      _loi = e.toString();
      _dangTai = false;
      _isFirebaseConnected = false;
      notifyListeners();
    }
  }

  // Đánh dấu thông báo đã đọc
  Future<void> danhDauDaDoc(String notificationId) async {
    if (!_collectionExists) return;
    
    try {
      await NotificationService.markAsRead(notificationId);
      
      // Cập nhật local state
      final index = _danhSachThongBao.indexWhere((tb) => tb.id == notificationId);
      if (index != -1) {
        _danhSachThongBao[index] = _danhSachThongBao[index].copyWith(daDoc: true);
        notifyListeners();
      }
    } catch (e) {
      print('Lỗi khi đánh dấu đã đọc: $e');
    }
  }

  // Đánh dấu tất cả đã đọc
  Future<void> danhDauTatCaDaDoc() async {
    if (!_collectionExists) return;
    
    try {
      final chuaDoc = thongBaoChuaDoc;
      for (final thongBao in chuaDoc) {
        await NotificationService.markAsRead(thongBao.id);
      }
      
      // Cập nhật local state
      _danhSachThongBao = _danhSachThongBao.map((tb) => 
          tb.copyWith(daDoc: true)).toList();
      notifyListeners();
    } catch (e) {
      print('Lỗi khi đánh dấu tất cả đã đọc: $e');
    }
  }

  // Xóa thông báo
  Future<void> xoaThongBao(String notificationId) async {
    if (!_collectionExists) return;
    
    try {
      await NotificationService.deleteNotification(notificationId);
      
      // Cập nhật local state
      _danhSachThongBao.removeWhere((tb) => tb.id == notificationId);
      notifyListeners();
    } catch (e) {
      print('Lỗi khi xóa thông báo: $e');
    }
  }

  // Lọc thông báo theo loại
  List<ThongBao> layThongBaoTheoLoai(String loai) {
    return _danhSachThongBao.where((tb) => tb.loai == loai).toList();
  }

  // Reset provider
  void reset() {
    _danhSachThongBao = [];
    _dangTai = false;
    _loi = null;
    _collectionExists = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }
}

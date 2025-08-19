import 'package:cloud_firestore/cloud_firestore.dart';

enum VaiTroAdmin {
  superAdmin,
  quanLyDonHang,
  quanLySanPham,
  quanLyKhuyenMai,
}

class AdminUser {
  final String id;
  final String email;
  final String ten;
  final String? avatar;
  final List<VaiTroAdmin> vaiTro;
  final bool trangThaiHoatDong;
  final DateTime ngayTao;
  final DateTime? lanDangNhapCuoi;

  AdminUser({
    required this.id,
    required this.email,
    required this.ten,
    this.avatar,
    required this.vaiTro,
    required this.trangThaiHoatDong,
    required this.ngayTao,
    this.lanDangNhapCuoi,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json, String id) {
    return AdminUser(
      id: id,
      email: json['email'] ?? '',
      ten: json['ten'] ?? '',
      avatar: json['avatar'],
      vaiTro: (json['vaiTro'] as List<dynamic>?)
          ?.map((e) => _parseVaiTro(e.toString()))
          .toList() ?? [],
      trangThaiHoatDong: json['trangThaiHoatDong'] ?? false,
      ngayTao: _parseDateTime(json['ngayTao']),
      lanDangNhapCuoi: json['lanDangNhapCuoi'] != null 
          ? _parseDateTime(json['lanDangNhapCuoi']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'ten': ten,
      'avatar': avatar,
      'vaiTro': vaiTro.map((e) => e.toString().split('.').last).toList(),
      'trangThaiHoatDong': trangThaiHoatDong,
      'ngayTao': Timestamp.fromDate(ngayTao),
      'lanDangNhapCuoi': lanDangNhapCuoi != null 
          ? Timestamp.fromDate(lanDangNhapCuoi!) 
          : null,
    };
  }

  static VaiTroAdmin _parseVaiTro(String value) {
    switch (value) {
      case 'superAdmin':
        return VaiTroAdmin.superAdmin;
      case 'quanLyDonHang':
        return VaiTroAdmin.quanLyDonHang;
      case 'quanLySanPham':
        return VaiTroAdmin.quanLySanPham;
      case 'quanLyKhuyenMai':
        return VaiTroAdmin.quanLyKhuyenMai;
      default:
        return VaiTroAdmin.quanLyDonHang;
    }
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  bool coQuyenQuanLyDonHang() {
    return vaiTro.contains(VaiTroAdmin.superAdmin) || 
           vaiTro.contains(VaiTroAdmin.quanLyDonHang);
  }
}
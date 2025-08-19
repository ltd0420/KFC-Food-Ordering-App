import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kfc/models/san_pham_gio_hang.dart';

enum TrangThaiDonHang {
  dangXuLy,
  dangGiao,
  daGiao,
  daHuy,
}

class DonHang {
  final String id;
  final String nguoiDungId;
  final String tenNguoiNhan;
  final String soDienThoai;
  final String diaChi;
  final List<SanPhamGioHang> danhSachSanPham;
  final double tongTien;
  final double phiGiaoHang;
  final double tongCong;
  final TrangThaiDonHang trangThai;
  final DateTime thoiGianDat;
  final String? ghiChu;
  final String? phuongThucThanhToan;

  DonHang({
    required this.id,
    required this.nguoiDungId,
    required this.tenNguoiNhan,
    required this.soDienThoai,
    required this.diaChi,
    required this.danhSachSanPham,
    required this.tongTien,
    required this.phiGiaoHang,
    required this.tongCong,
    required this.trangThai,
    required this.thoiGianDat,
    this.ghiChu,
    this.phuongThucThanhToan,
  });

  factory DonHang.fromJson(Map<String, dynamic> json, String id) {
    return DonHang(
      id: id,
      nguoiDungId: json['nguoiDungId']?.toString() ?? '',
      tenNguoiNhan: json['tenNguoiNhan']?.toString() ?? '',
      soDienThoai: json['soDienThoai']?.toString() ?? '',
      diaChi: json['diaChi']?.toString() ?? '',
      danhSachSanPham: _parseDanhSachSanPham(json['danhSachSanPham']),
      tongTien: _parseToDouble(json['tongTien']),
      phiGiaoHang: _parseToDouble(json['phiGiaoHang']),
      tongCong: _parseToDouble(json['tongCong']),
      trangThai: _parseTrangThai(json['trangThai']),
      thoiGianDat: _parseDateTime(json['thoiGianDat']),
      ghiChu: json['ghiChu']?.toString(),
      phuongThucThanhToan: json['phuongThucThanhToan']?.toString(),
    );
  }

  static List<SanPhamGioHang> _parseDanhSachSanPham(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((item) => SanPhamGioHang.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  static double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static TrangThaiDonHang _parseTrangThai(dynamic value) {
    if (value == null) return TrangThaiDonHang.dangXuLy;
    final trangThaiStr = value.toString();
    switch (trangThaiStr) {
      case 'dangXuLy':
        return TrangThaiDonHang.dangXuLy;
      case 'dangGiao':
        return TrangThaiDonHang.dangGiao;
      case 'daGiao':
        return TrangThaiDonHang.daGiao;
      case 'daHuy':
        return TrangThaiDonHang.daHuy;
      default:
        return TrangThaiDonHang.dangXuLy;
    }
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'nguoiDungId': nguoiDungId,
      'tenNguoiNhan': tenNguoiNhan,
      'soDienThoai': soDienThoai,
      'diaChi': diaChi,
      'danhSachSanPham': danhSachSanPham.map((item) => item.toJson()).toList(),
      'tongTien': tongTien,
      'phiGiaoHang': phiGiaoHang,
      'tongCong': tongCong,
      'trangThai': _trangThaiToString(trangThai),
      'thoiGianDat': Timestamp.fromDate(thoiGianDat),
      'ghiChu': ghiChu,
      'phuongThucThanhToan': phuongThucThanhToan,
    };
  }

  String _trangThaiToString(TrangThaiDonHang trangThai) {
    switch (trangThai) {
      case TrangThaiDonHang.dangXuLy:
        return 'dangXuLy';
      case TrangThaiDonHang.dangGiao:
        return 'dangGiao';
      case TrangThaiDonHang.daGiao:
        return 'daGiao';
      case TrangThaiDonHang.daHuy:
        return 'daHuy';
    }
  }

  String get trangThaiText {
    switch (trangThai) {
      case TrangThaiDonHang.dangXuLy:
        return 'Đang xử lý';
      case TrangThaiDonHang.dangGiao:
        return 'Đang giao';
      case TrangThaiDonHang.daGiao:
        return 'Đã giao';
      case TrangThaiDonHang.daHuy:
        return 'Đã hủy';
    }
  }

  String get ngayDatHang {
    return '${thoiGianDat.day.toString().padLeft(2, '0')}/${thoiGianDat.month.toString().padLeft(2, '0')}/${thoiGianDat.year}';
  }

  String get gioDatHang {
    return '${thoiGianDat.hour.toString().padLeft(2, '0')}:${thoiGianDat.minute.toString().padLeft(2, '0')}';
  }

  DonHang copyWith({
    String? id,
    String? nguoiDungId,
    String? tenNguoiNhan,
    String? soDienThoai,
    String? diaChi,
    List<SanPhamGioHang>? danhSachSanPham,
    double? tongTien,
    double? phiGiaoHang,
    double? tongCong,
    TrangThaiDonHang? trangThai,
    DateTime? thoiGianDat,
    String? ghiChu,
    String? phuongThucThanhToan,
  }) {
    return DonHang(
      id: id ?? this.id,
      nguoiDungId: nguoiDungId ?? this.nguoiDungId,
      tenNguoiNhan: tenNguoiNhan ?? this.tenNguoiNhan,
      soDienThoai: soDienThoai ?? this.soDienThoai,
      diaChi: diaChi ?? this.diaChi,
      danhSachSanPham: danhSachSanPham ?? this.danhSachSanPham,
      tongTien: tongTien ?? this.tongTien,
      phiGiaoHang: phiGiaoHang ?? this.phiGiaoHang,
      tongCong: tongCong ?? this.tongCong,
      trangThai: trangThai ?? this.trangThai,
      thoiGianDat: thoiGianDat ?? this.thoiGianDat,
      ghiChu: ghiChu ?? this.ghiChu,
      phuongThucThanhToan: phuongThucThanhToan ?? this.phuongThucThanhToan,
    );
  }

  @override
  String toString() {
    return 'DonHang(id: $id, tenNguoiNhan: $tenNguoiNhan, tongCong: $tongCong, phuongThucThanhToan: $phuongThucThanhToan)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DonHang && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
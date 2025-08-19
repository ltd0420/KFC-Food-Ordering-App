class DanhGia {
  final String id;
  final String sanPhamId;
  final String nguoiDungId;
  final String tenNguoiDung;
  final int soSao; // 1-5 sao
  final String binhLuan;
  final String ngayTao; // Đổi thành String để dễ xử lý
  final List<String>? hinhAnh; // Hình ảnh đính kèm (optional)

  DanhGia({
    required this.id,
    required this.sanPhamId,
    required this.nguoiDungId,
    required this.tenNguoiDung,
    required this.soSao,
    required this.binhLuan,
    required this.ngayTao,
    this.hinhAnh,
  });

  factory DanhGia.fromJson(Map<String, dynamic> json) {
    print('🔍 Parsing DanhGia từ JSON: $json');
  
    final danhGia = DanhGia(
      id: json['id']?.toString() ?? '',
      sanPhamId: json['sanPhamId']?.toString() ?? '',
      nguoiDungId: json['nguoiDungId']?.toString() ?? '',
      tenNguoiDung: json['tenNguoiDung']?.toString() ?? 'Người dùng ẩn danh',
      soSao: _parseToInt(json['soSao'], defaultValue: 5),
      binhLuan: json['binhLuan']?.toString() ?? '',
      ngayTao: _parseToString(json['ngayTao']),
      hinhAnh: json['hinhAnh'] != null 
          ? List<String>.from(json['hinhAnh']) 
          : null,
    );
    
    print('✅ Parsed thành công: ${danhGia.tenNguoiDung}, ${danhGia.soSao} sao');
    return danhGia;
  }

  Map<String, dynamic> toJson() {
    return {
      'sanPhamId': sanPhamId,
      'nguoiDungId': nguoiDungId,
      'tenNguoiDung': tenNguoiDung,
      'soSao': soSao,
      'binhLuan': binhLuan,
      'ngayTao': ngayTao,
      'hinhAnh': hinhAnh,
    };
  }

  static int _parseToInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  static String _parseToString(dynamic value) {
    if (value == null) return DateTime.now().toIso8601String();
    if (value is String) return value;
    if (value is DateTime) return value.toIso8601String();
    // Firestore Timestamp
    if (value.runtimeType.toString() == 'Timestamp') {
      return value.toDate().toIso8601String();
    }
    return DateTime.now().toIso8601String();
  }

  // Helper methods
  String get ngayTaoFormatted {
    try {
      final dateTime = DateTime.parse(ngayTao);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} ngày trước';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} giờ trước';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} phút trước';
      } else {
        return 'Vừa xong';
      }
    } catch (e) {
      return 'Không xác định';
    }
  }

  DateTime get ngayTaoDateTime {
    try {
      return DateTime.parse(ngayTao);
    } catch (e) {
      return DateTime.now();
    }
  }

  @override
  String toString() {
    return 'DanhGia(id: $id, sanPhamId: $sanPhamId, soSao: $soSao)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DanhGia && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Model cho thống kê đánh giá
class ThongKeDanhGia {
  final double diemTrungBinh;
  final int tongSoDanhGia;
  final Map<int, int> phanBoSao; // {1: 5, 2: 10, 3: 20, 4: 30, 5: 35}

  ThongKeDanhGia({
    required this.diemTrungBinh,
    required this.tongSoDanhGia,
    required this.phanBoSao,
  });

  factory ThongKeDanhGia.fromDanhSachDanhGia(List<DanhGia> danhSachDanhGia) {
    if (danhSachDanhGia.isEmpty) {
      return ThongKeDanhGia(
        diemTrungBinh: 0.0,
        tongSoDanhGia: 0,
        phanBoSao: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      );
    }

    // Tính tổng số sao
    int tongSao = danhSachDanhGia.fold(0, (sum, danhGia) => sum + danhGia.soSao);
    double diemTrungBinh = tongSao / danhSachDanhGia.length;

    // Phân bố sao
    Map<int, int> phanBoSao = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (var danhGia in danhSachDanhGia) {
      phanBoSao[danhGia.soSao] = (phanBoSao[danhGia.soSao] ?? 0) + 1;
    }

    return ThongKeDanhGia(
      diemTrungBinh: diemTrungBinh,
      tongSoDanhGia: danhSachDanhGia.length,
      phanBoSao: phanBoSao,
    );
  }

  String get diemTrungBinhFormatted => diemTrungBinh.toStringAsFixed(1);
  
  String get tongSoDanhGiaFormatted {
    if (tongSoDanhGia >= 1000) {
      return '${(tongSoDanhGia / 1000).toStringAsFixed(1)}k';
    }
    return tongSoDanhGia.toString();
  }
}

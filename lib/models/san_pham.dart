class SanPham {
  final String id;
  final String ten;
  final int gia;
  final String hinhAnh;
  final String moTa;
  final String danhMucId;
  final bool? khuyenMai; // nullable
  final int? giamGia; // nullable

  SanPham({
    required this.id,
    required this.ten,
    required this.gia,
    required this.hinhAnh,
    required this.moTa,
    required this.danhMucId,
    this.khuyenMai,
    this.giamGia,
  });

  factory SanPham.fromJson(Map<String, dynamic> json) {
    return SanPham(
      id: json['id']?.toString() ?? '',
      ten: json['ten']?.toString() ?? '',
      gia: _parseToInt(json['gia']),
      hinhAnh: json['hinhAnh']?.toString() ?? '',
      moTa: json['moTa']?.toString() ?? '',
      // Ưu tiên danhMucID trước, sau đó mới đến danhMucId
      danhMucId: json['danhMucID']?.toString() ?? 
               json['danhMucId']?.toString() ?? 
               json['danhmucid']?.toString() ?? '',
      khuyenMai: _parseToBool(json['khuyenMai']),
      giamGia: _parseToIntNullable(json['giamGia']),
    );
  }

  // Helper method để parse an toàn sang int
  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  // Helper method để parse an toàn sang int nullable
  static int? _parseToIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  // Helper method để parse an toàn sang bool
  static bool? _parseToBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    if (value is int) {
      return value == 1;
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'ten': ten,
      'gia': gia,
      'hinhAnh': hinhAnh,
      'moTa': moTa,
      // Lưu cả hai format để đảm bảo tương thích
      'danhMucID': danhMucId, // Format chính
      'danhMucId': danhMucId, // Format backup
      'khuyenMai': khuyenMai,
      'giamGia': giamGia,
    };
  }

  // Helper methods
  bool get coKhuyenMai => khuyenMai == true;
  int get phanTramGiamGia => giamGia ?? 0;
  int get giaGiam => coKhuyenMai ? (gia * (100 - phanTramGiamGia) / 100).round() : gia;

  @override
  String toString() {
    return 'SanPham(id: $id, ten: $ten, gia: $gia)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SanPham && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

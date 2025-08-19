class DanhMuc {
  final String id;
  final String ten;
  final String hinhAnh;
  final String moTa;

  DanhMuc({
    required this.id,
    required this.ten,
    required this.hinhAnh,
    required this.moTa,
  });

  factory DanhMuc.fromJson(Map<String, dynamic> json) {
    return DanhMuc(
      id: json['id']?.toString() ?? '',
      ten: json['ten']?.toString() ?? '',
      hinhAnh: json['hinhAnh']?.toString() ?? '',
      moTa: json['moTa']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ten': ten,
      'hinhAnh': hinhAnh,
      'moTa': moTa,
    };
  }

  @override
  String toString() {
    return 'DanhMuc(id: $id, ten: $ten)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DanhMuc && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

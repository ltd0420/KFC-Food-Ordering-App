class NguoiDung {
  final String id;
  final String ten;
  final String email;
  final String soDienThoai;
  final String rule; // Thêm trường rule

  NguoiDung({
    required this.id,
    required this.ten,
    required this.email,
    required this.soDienThoai,
    this.rule = 'user', // Mặc định là user
  });

  // Chuyển đổi từ Map sang NguoiDung
  factory NguoiDung.fromMap(Map<String, dynamic> map) {
    return NguoiDung(
      id: map['id'] ?? '',
      ten: map['ten'] ?? '',
      email: map['email'] ?? '',
      soDienThoai: map['soDienThoai'] ?? '',
      rule: map['rule'] ?? 'user',
    );
  }

  // Chuyển đổi từ NguoiDung sang Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ten': ten,
      'email': email,
      'soDienThoai': soDienThoai,
      'rule': rule,
    };
  }

  // Kiểm tra có phải admin không
  bool get isAdmin => rule == 'admin';
  
  // Kiểm tra có phải user không
  bool get isUser => rule == 'user';
}

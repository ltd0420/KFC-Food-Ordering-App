class ThongBao {
  final String id;
  final String tieuDe;
  final String noiDung;
  final String loai; // 'don_hang', 'khuyen_mai', 'he_thong'
  final DateTime thoiGian;
  final bool daDoc;
  final String? hinhAnh;
  final Map<String, dynamic>? duLieuThem;

  ThongBao({
    required this.id,
    required this.tieuDe,
    required this.noiDung,
    required this.loai,
    required this.thoiGian,
    this.daDoc = false,
    this.hinhAnh,
    this.duLieuThem,
  });

  factory ThongBao.fromJson(Map<String, dynamic> json) {
    return ThongBao(
      id: json['id'] ?? '',
      tieuDe: json['tieuDe'] ?? '',
      noiDung: json['noiDung'] ?? '',
      loai: json['loai'] ?? 'he_thong',
      thoiGian: json['thoiGian'] != null 
          ? DateTime.parse(json['thoiGian'])
          : DateTime.now(),
      daDoc: json['daDoc'] ?? false,
      hinhAnh: json['hinhAnh'],
      duLieuThem: json['duLieuThem'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tieuDe': tieuDe,
      'noiDung': noiDung,
      'loai': loai,
      'thoiGian': thoiGian.toIso8601String(),
      'daDoc': daDoc,
      'hinhAnh': hinhAnh,
      'duLieuThem': duLieuThem,
    };
  }

  ThongBao copyWith({
    String? id,
    String? tieuDe,
    String? noiDung,
    String? loai,
    DateTime? thoiGian,
    bool? daDoc,
    String? hinhAnh,
    Map<String, dynamic>? duLieuThem,
  }) {
    return ThongBao(
      id: id ?? this.id,
      tieuDe: tieuDe ?? this.tieuDe,
      noiDung: noiDung ?? this.noiDung,
      loai: loai ?? this.loai,
      thoiGian: thoiGian ?? this.thoiGian,
      daDoc: daDoc ?? this.daDoc,
      hinhAnh: hinhAnh ?? this.hinhAnh,
      duLieuThem: duLieuThem ?? this.duLieuThem,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/san_pham.dart';
import '../models/danh_muc.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache để tránh gọi Firebase liên tục
  static List<DanhMuc>? _cachedDanhMuc;
  static List<SanPham>? _cachedSanPham;
  static DateTime? _lastCacheTime;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // Kiểm tra cache còn hiệu lực không
  static bool _isCacheValid() {
    if (_lastCacheTime == null) return false;
    return DateTime.now().difference(_lastCacheTime!) < _cacheExpiry;
  }

  // Helper method để parse giá trị int an toàn
  static int _parseToInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  static int? _parseToIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static bool _parseToBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    if (value is num) {
      return value != 0;
    }
    return defaultValue;
  }

  // Hàm xử lý dữ liệu sản phẩm để đảm bảo tính nhất quán
  static Map<String, dynamic> _processProductData(Map<String, dynamic> data) {
    final processedData = Map<String, dynamic>.from(data);
    
    // Xử lý trường giá
    processedData['gia'] = _parseToInt(data['gia']);
    
    // Xử lý trường khuyến mãi
    final hasPromotion = _parseToBool(data['khuyenMai']);
    processedData['khuyenMai'] = hasPromotion;
    
    // Xử lý trường giảm giá
    if (hasPromotion) {
      processedData['giamGia'] = _parseToIntNullable(data['giamGia']) ?? 0;
    } else {
      processedData['giamGia'] = null;
    }
    
    // Xử lý trường danh mục ID - ưu tiên danhMucID
    if (data.containsKey('danhMucID')) {
      processedData['danhMucId'] = data['danhMucID'];
    } else if (data.containsKey('danhMucId')) {
      processedData['danhMucId'] = data['danhMucId'];
    } else {
      processedData['danhMucId'] = '';
    }
    
    // Đảm bảo các trường khác có giá trị mặc định nếu null
    processedData['ten'] = data['ten'] ?? 'Sản phẩm không tên';
    processedData['moTa'] = data['moTa'] ?? '';
    processedData['hinhAnh'] = data['hinhAnh'] ?? '';
    
    return processedData;
  }

  // Lấy danh sách danh mục từ Firebase
  static Future<List<DanhMuc>> layDanhSachDanhMuc({bool forceRefresh = false}) async {
    // Sử dụng cache nếu còn hiệu lực và không bắt buộc refresh
    if (!forceRefresh && _isCacheValid() && _cachedDanhMuc != null) {
      print('📦 Sử dụng cache cho danh mục');
      return _cachedDanhMuc!;
    }

    try {
      print('🔄 Đang lấy danh mục từ Firebase...');
      
      QuerySnapshot snapshot = await _firestore
          .collection('danh_muc')
          .orderBy('ten')
          .get()
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout khi lấy danh mục');
            },
          );
      
      List<DanhMuc> danhSachDanhMuc = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return DanhMuc.fromJson(data);
      }).toList();

      // Cập nhật cache
      _cachedDanhMuc = danhSachDanhMuc;
      _lastCacheTime = DateTime.now();

      print('✅ Lấy thành công ${danhSachDanhMuc.length} danh mục từ Firebase');
      return danhSachDanhMuc;
    } catch (e) {
      print('❌ Lỗi khi lấy danh mục từ Firebase: $e');
      
      // Nếu có cache cũ, trả về cache
      if (_cachedDanhMuc != null) {
        print('📦 Sử dụng cache cũ do lỗi kết nối');
        return _cachedDanhMuc!;
      }
      
      rethrow;
    }
  }

  // Lấy danh sách sản phẩm từ Firebase
  static Future<List<SanPham>> layDanhSachSanPham({bool forceRefresh = false}) async {
    // Sử dụng cache nếu còn hiệu lực và không bắt buộc refresh
    if (!forceRefresh && _isCacheValid() && _cachedSanPham != null) {
      print('📦 Sử dụng cache cho sản phẩm');
      return _cachedSanPham!;
    }

    try {
      print('🔄 Đang lấy sản phẩm từ Firebase...');
      
      QuerySnapshot snapshot = await _firestore
          .collection('san_pham')
          .orderBy('ten')
          .get()
          .timeout(
            Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Timeout khi lấy sản phẩm');
            },
          );
      
      List<SanPham> danhSachSanPham = [];
      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          
          // Xử lý dữ liệu trước khi tạo đối tượng SanPham
          final processedData = _processProductData(data);
          danhSachSanPham.add(SanPham.fromJson(processedData));
        } catch (e) {
          print('⚠️ Lỗi khi parse sản phẩm ${doc.id}: $e');
          // Bỏ qua sản phẩm lỗi
        }
      }

      // Cập nhật cache
      _cachedSanPham = danhSachSanPham;
      _lastCacheTime = DateTime.now();

      print('✅ Lấy thành công ${danhSachSanPham.length} sản phẩm từ Firebase');
      return danhSachSanPham;
    } catch (e) {
      print('❌ Lỗi khi lấy sản phẩm từ Firebase: $e');
      
      // Nếu có cache cũ, trả về cache
      if (_cachedSanPham != null) {
        print('📦 Sử dụng cache cũ do lỗi kết nối');
        return _cachedSanPham!;
      }
      
      rethrow;
    }
  }

  // Lấy sản phẩm theo danh mục
  static Future<List<SanPham>> layDanhSachSanPhamTheoDanhMuc(String danhMucId) async {
    try {
      // Nếu có cache sản phẩm, lọc từ cache
      if (_isCacheValid() && _cachedSanPham != null) {
        print('📦 Lọc sản phẩm theo danh mục từ cache');
        return _cachedSanPham!.where((sp) => sp.danhMucId == danhMucId).toList();
      }

      print('🔄 Đang lấy sản phẩm theo danh mục: $danhMucId');
      
      QuerySnapshot snapshot = await _firestore
          .collection('san_pham')
          .where('danhMucID', isEqualTo: danhMucId)
          .get()
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout khi lấy sản phẩm theo danh mục');
            },
          );
      
      List<SanPham> danhSachSanPham = [];
      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          final processedData = _processProductData(data);
          danhSachSanPham.add(SanPham.fromJson(processedData));
        } catch (e) {
          print('⚠️ Lỗi khi parse sản phẩm theo danh mục ${doc.id}: $e');
        }
      }

      print('✅ Lấy thành công ${danhSachSanPham.length} sản phẩm cho danh mục $danhMucId');
      return danhSachSanPham;
    } catch (e) {
      print('❌ Lỗi khi lấy sản phẩm theo danh mục: $e');
      rethrow;
    }
  }

  // Lấy sản phẩm khuyến mãi
  static Future<List<SanPham>> layDanhSachSanPhamKhuyenMai() async {
    try {
      // Nếu có cache sản phẩm, lọc từ cache
      if (_isCacheValid() && _cachedSanPham != null) {
        print('📦 Lọc sản phẩm khuyến mãi từ cache');
        return _cachedSanPham!.where((sp) => sp.coKhuyenMai).toList();
      }

      print('🔄 Đang lấy sản phẩm khuyến mãi...');
      
      QuerySnapshot snapshot = await _firestore
          .collection('san_pham')
          .where('khuyenMai', isEqualTo: true)
          .get()
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout khi lấy sản phẩm khuyến mãi');
            },
          );
      
      List<SanPham> danhSachSanPham = [];
      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          final processedData = _processProductData(data);
          danhSachSanPham.add(SanPham.fromJson(processedData));
        } catch (e) {
          print('⚠️ Lỗi khi parse sản phẩm khuyến mãi ${doc.id}: $e');
        }
      }

      print('✅ Lấy thành công ${danhSachSanPham.length} sản phẩm khuyến mãi');
      return danhSachSanPham;
    } catch (e) {
      print('❌ Lỗi khi lấy sản phẩm khuyến mãi: $e');
      rethrow;
    }
  }

  // Lấy sản phẩm nổi bật
  static Future<List<SanPham>> layDanhSachSanPhamNoiBat() async {
    try {
      // Nếu có cache sản phẩm, lấy sản phẩm nổi bật theo logic
      if (_isCacheValid() && _cachedSanPham != null) {
        print('📦 Lọc sản phẩm nổi bật từ cache');
        return _cachedSanPham!
            .where((sp) => sp.coKhuyenMai || sp.gia >= 50000)
            .take(10)
            .toList();
      }

      print('🔄 Đang lấy sản phẩm nổi bật...');
      
      // Thử tìm sản phẩm có field 'noiBat'
      QuerySnapshot snapshot = await _firestore
          .collection('san_pham')
          .where('noiBat', isEqualTo: true)
          .get()
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout khi lấy sản phẩm nổi bật');
            },
          );
      
      List<SanPham> danhSachSanPham = [];
      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          final processedData = _processProductData(data);
          danhSachSanPham.add(SanPham.fromJson(processedData));
        } catch (e) {
          print('⚠️ Lỗi khi parse sản phẩm nổi bật ${doc.id}: $e');
        }
      }

      // Nếu không có sản phẩm nổi bật, lấy sản phẩm khuyến mãi
      if (danhSachSanPham.isEmpty) {
        print('🔄 Không có sản phẩm nổi bật, lấy sản phẩm khuyến mãi...');
        return await layDanhSachSanPhamKhuyenMai();
      }

      print('✅ Lấy thành công ${danhSachSanPham.length} sản phẩm nổi bật');
      return danhSachSanPham;
    } catch (e) {
      print('❌ Lỗi khi lấy sản phẩm nổi bật: $e');
      
      // Fallback: Lấy sản phẩm khuyến mãi
      try {
        return await layDanhSachSanPhamKhuyenMai();
      } catch (e2) {
        rethrow;
      }
    }
  }

  // Tìm kiếm sản phẩm
  static Future<List<SanPham>> timKiemSanPham(String tuKhoa) async {
    try {
      print('🔍 Đang tìm kiếm sản phẩm với từ khóa: $tuKhoa');
      
      if (_isCacheValid() && _cachedSanPham != null) {
        print('📦 Tìm kiếm từ cache');
        List<SanPham> ketQua = _cachedSanPham!.where((sanPham) {
          return sanPham.ten.toLowerCase().contains(tuKhoa.toLowerCase()) ||
                 sanPham.moTa.toLowerCase().contains(tuKhoa.toLowerCase());
        }).toList();
        
        if (ketQua.isNotEmpty) {
          print('✅ Tìm thấy ${ketQua.length} sản phẩm từ cache');
          return ketQua;
        }
      }
      
      QuerySnapshot snapshot = await _firestore
          .collection('san_pham')
          .get()
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout khi tìm kiếm sản phẩm');
            },
          );
      
      List<SanPham> tatCaSanPham = [];
      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          final processedData = _processProductData(data);
          tatCaSanPham.add(SanPham.fromJson(processedData));
        } catch (e) {
          print('⚠️ Lỗi khi parse sản phẩm tìm kiếm ${doc.id}: $e');
        }
      }

      _cachedSanPham = tatCaSanPham;
      _lastCacheTime = DateTime.now();

      List<SanPham> ketQua = tatCaSanPham.where((sanPham) {
        return sanPham.ten.toLowerCase().contains(tuKhoa.toLowerCase()) ||
               sanPham.moTa.toLowerCase().contains(tuKhoa.toLowerCase());
      }).toList();

      print('✅ Tìm thấy ${ketQua.length} sản phẩm');
      return ketQua;
    } catch (e) {
      print('❌ Lỗi khi tìm kiếm sản phẩm: $e');
      rethrow;
    }
  }

  // Lấy sản phẩm liên quan
  static Future<List<SanPham>> laySanPhamLienQuan(SanPham sanPham) async {
    try {
      print('🔄 Đang lấy sản phẩm liên quan cho: ${sanPham.ten}');
      
      if (_isCacheValid() && _cachedSanPham != null) {
        print('📦 Lọc sản phẩm liên quan từ cache');
        return _cachedSanPham!
            .where((sp) => sp.danhMucId == sanPham.danhMucId && sp.id != sanPham.id)
            .take(3)
            .toList();
      }
      
      QuerySnapshot snapshot = await _firestore
          .collection('san_pham')
          .where('danhMucID', isEqualTo: sanPham.danhMucId)
          .limit(4)
          .get()
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout khi lấy sản phẩm liên quan');
            },
          );
      
      List<SanPham> danhSachSanPham = [];
      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          final processedData = _processProductData(data);
          final sp = SanPham.fromJson(processedData);
          if (sp.id != sanPham.id) {
            danhSachSanPham.add(sp);
          }
        } catch (e) {
          print('⚠️ Lỗi khi parse sản phẩm liên quan ${doc.id}: $e');
        }
      }

      print('✅ Lấy thành công ${danhSachSanPham.length} sản phẩm liên quan');
      return danhSachSanPham.take(3).toList();
    } catch (e) {
      print('❌ Lỗi khi lấy sản phẩm liên quan: $e');
      rethrow;
    }
  }

  // Lấy sản phẩm theo ID
  static Future<SanPham?> laySanPhamTheoId(String sanPhamId) async {
    try {
      print('🔍 Đang lấy sản phẩm ID: $sanPhamId từ Firebase...');
      
      // Lấy trực tiếp từ Firebase
      final docSnapshot = await _firestore
          .collection('san_pham')
          .doc(sanPhamId)
          .get()
          .timeout(
            Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Timeout khi lấy sản phẩm theo ID');
            },
          );
      
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        data['id'] = sanPhamId;
        
        final processedData = _processProductData(data);
        final sanPham = SanPham.fromJson(processedData);
        
        print('✅ Đã lấy sản phẩm từ Firebase: ${sanPham.ten}');
        return sanPham;
      } else {
        print('❌ Không tìm thấy document với ID: $sanPhamId');
        
        // Thử tìm bằng query nếu không tìm thấy bằng document ID
        print('🔍 Thử tìm bằng query...');
        final querySnapshot = await _firestore
            .collection('san_pham')
            .where('id', isEqualTo: sanPhamId)
            .limit(1)
            .get();
        
        if (querySnapshot.docs.isNotEmpty) {
          final doc = querySnapshot.docs.first;
          final data = doc.data();
          data['id'] = doc.id;
          
          final processedData = _processProductData(data);
          final sanPham = SanPham.fromJson(processedData);
          
          print('✅ Đã tìm thấy sản phẩm bằng query: ${sanPham.ten}');
          return sanPham;
        }
        
        return null;
      }
    } catch (e) {
      print('❌ Lỗi khi lấy sản phẩm theo ID: $e');
      return null;
    }
  }

  // Xóa cache
  static void xoaCache() {
    _cachedDanhMuc = null;
    _cachedSanPham = null;
    _lastCacheTime = null;
    print('🗑️ Đã xóa cache');
  }

  // Stream danh mục
  static Stream<List<DanhMuc>> streamDanhMuc() {
    try {
      return _firestore
          .collection('danh_muc')
          .orderBy('ten')
          .snapshots()
          .map((snapshot) {
        List<DanhMuc> danhSach = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return DanhMuc.fromJson(data);
        }).toList();
        
        _cachedDanhMuc = danhSach;
        _lastCacheTime = DateTime.now();
        
        return danhSach;
      });
    } catch (e) {
      print('❌ Lỗi stream danh mục: $e');
      throw e;
    }
  }

  // Stream sản phẩm
  static Stream<List<SanPham>> streamSanPham() {
    try {
      return _firestore
          .collection('san_pham')
          .orderBy('ten')
          .snapshots()
          .map((snapshot) {
        List<SanPham> danhSach = [];
        for (var doc in snapshot.docs) {
          try {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            final processedData = _processProductData(data);
            danhSach.add(SanPham.fromJson(processedData));
          } catch (e) {
            print('⚠️ Lỗi khi parse sản phẩm stream ${doc.id}: $e');
          }
        }
        
        _cachedSanPham = danhSach;
        _lastCacheTime = DateTime.now();
        
        return danhSach;
      });
    } catch (e) {
      print('❌ Lỗi stream sản phẩm: $e');
      throw e;
    }
  }
}

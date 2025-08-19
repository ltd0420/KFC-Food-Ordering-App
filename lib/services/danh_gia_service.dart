import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/danh_gia.dart';

class DanhGiaService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'danh_gia';

  // Thêm đánh giá mới
  static Future<bool> themDanhGia(DanhGia danhGia) async {
    try {
      print('🔄 Đang thêm đánh giá cho sản phẩm: ${danhGia.sanPhamId}');
      print('📝 Thông tin đánh giá: ${danhGia.toJson()}');
      
      final docRef = await _firestore.collection(_collection).add(danhGia.toJson());
      print('✅ Thêm đánh giá thành công với ID: ${docRef.id}');
      
      return true;
    } catch (e) {
      print('❌ Lỗi khi thêm đánh giá: $e');
      return false;
    }
  }

  // Lấy danh sách đánh giá theo sản phẩm (không dùng orderBy để tránh cần index)
  static Future<List<DanhGia>> layDanhGiaTheoSanPham(String sanPhamId) async {
    try {
      print('🔄 Đang lấy đánh giá cho sản phẩm: $sanPhamId');
      
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('sanPhamId', isEqualTo: sanPhamId)
          .get()
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout khi lấy đánh giá');
            },
          );
    
      List<DanhGia> danhSachDanhGia = [];
      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          
          print('📄 Raw data từ Firestore: $data');
          
          final danhGia = DanhGia.fromJson(data);
          print('✅ Parsed đánh giá: ${danhGia.tenNguoiDung}, ${danhGia.soSao} sao, ${danhGia.binhLuan}');
          
          danhSachDanhGia.add(danhGia);
        } catch (e) {
          print('⚠️ Lỗi khi parse đánh giá ${doc.id}: $e');
          print('📄 Data gây lỗi: ${doc.data()}');
        }
      }

      // Sắp xếp theo thời gian trong code thay vì query
      danhSachDanhGia.sort((a, b) {
        try {
          final dateA = DateTime.parse(a.ngayTao);
          final dateB = DateTime.parse(b.ngayTao);
          return dateB.compareTo(dateA); // Mới nhất trước
        } catch (e) {
          return 0;
        }
      });

      print('✅ Lấy thành công ${danhSachDanhGia.length} đánh giá');
      return danhSachDanhGia;
    } catch (e) {
      print('❌ Lỗi khi lấy đánh giá: $e');
      return [];
    }
  }

  // Lấy thống kê đánh giá theo sản phẩm
  static Future<ThongKeDanhGia> layThongKeDanhGia(String sanPhamId) async {
    try {
      final danhSachDanhGia = await layDanhGiaTheoSanPham(sanPhamId);
      return ThongKeDanhGia.fromDanhSachDanhGia(danhSachDanhGia);
    } catch (e) {
      print('❌ Lỗi khi lấy thống kê đánh giá: $e');
      return ThongKeDanhGia(
        diemTrungBinh: 0.0,
        tongSoDanhGia: 0,
        phanBoSao: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      );
    }
  }

  // Kiểm tra người dùng đã đánh giá sản phẩm chưa
  static Future<bool> kiemTraDaDanhGia(String sanPhamId, String nguoiDungId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('sanPhamId', isEqualTo: sanPhamId)
          .where('nguoiDungId', isEqualTo: nguoiDungId)
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Lỗi khi kiểm tra đánh giá: $e');
      return false;
    }
  }

  // Cập nhật đánh giá
  static Future<bool> capNhatDanhGia(String danhGiaId, int soSao, String binhLuan) async {
    try {
      await _firestore.collection(_collection).doc(danhGiaId).update({
        'soSao': soSao,
        'binhLuan': binhLuan,
        'ngayCapNhat': DateTime.now().toIso8601String(),
      });
      
      print('✅ Cập nhật đánh giá thành công');
      return true;
    } catch (e) {
      print('❌ Lỗi khi cập nhật đánh giá: $e');
      return false;
    }
  }

  // Xóa đánh giá
  static Future<bool> xoaDanhGia(String danhGiaId) async {
    try {
      await _firestore.collection(_collection).doc(danhGiaId).delete();
      
      print('✅ Xóa đánh giá thành công');
      return true;
    } catch (e) {
      print('❌ Lỗi khi xóa đánh giá: $e');
      return false;
    }
  }

  // Lấy đánh giá của người dùng cho sản phẩm
  static Future<DanhGia?> layDanhGiaCuaNguoiDung(String sanPhamId, String nguoiDungId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('sanPhamId', isEqualTo: sanPhamId)
          .where('nguoiDungId', isEqualTo: nguoiDungId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        Map<String, dynamic> data = snapshot.docs.first.data() as Map<String, dynamic>;
        data['id'] = snapshot.docs.first.id;
        return DanhGia.fromJson(data);
      }
      
      return null;
    } catch (e) {
      print('❌ Lỗi khi lấy đánh giá của người dùng: $e');
      return null;
    }
  }

  // Stream đánh giá theo sản phẩm (realtime) - không dùng orderBy
  static Stream<List<DanhGia>> streamDanhGiaTheoSanPham(String sanPhamId) {
    try {
      return _firestore
          .collection(_collection)
          .where('sanPhamId', isEqualTo: sanPhamId)
          .snapshots()
          .map((snapshot) {
        List<DanhGia> danhSach = [];
        for (var doc in snapshot.docs) {
          try {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            danhSach.add(DanhGia.fromJson(data));
          } catch (e) {
            print('⚠️ Lỗi khi parse đánh giá stream ${doc.id}: $e');
          }
        }
        
        // Sắp xếp trong code
        danhSach.sort((a, b) {
          try {
            final dateA = DateTime.parse(a.ngayTao);
            final dateB = DateTime.parse(b.ngayTao);
            return dateB.compareTo(dateA);
          } catch (e) {
            return 0;
          }
        });
        
        return danhSach;
      });
    } catch (e) {
      print('❌ Lỗi stream đánh giá: $e');
      return Stream.value([]);
    }
  }

  // Lấy top đánh giá tích cực (đơn giản hóa query)
  static Future<List<DanhGia>> layTopDanhGiaTichCuc({int limit = 10}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('soSao', isGreaterThanOrEqualTo: 4)
          .limit(limit)
          .get();
      
      List<DanhGia> danhSach = [];
      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          danhSach.add(DanhGia.fromJson(data));
        } catch (e) {
          print('⚠️ Lỗi khi parse top đánh giá ${doc.id}: $e');
        }
      }

      // Sắp xếp trong code
      danhSach.sort((a, b) {
        if (a.soSao != b.soSao) {
          return b.soSao.compareTo(a.soSao);
        }
        try {
          final dateA = DateTime.parse(a.ngayTao);
          final dateB = DateTime.parse(b.ngayTao);
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });

      return danhSach.take(limit).toList();
    } catch (e) {
      print('❌ Lỗi khi lấy top đánh giá: $e');
      return [];
    }
  }

  // Tạo index đơn giản cho Firestore (chỉ cần chạy 1 lần)
  static Future<void> taoIndexDonGian() async {
    try {
      // Tạo một document mẫu để Firestore tự tạo index cơ bản
      await _firestore.collection(_collection).add({
        'sanPhamId': 'sample',
        'nguoiDungId': 'sample',
        'soSao': 5,
        'binhLuan': 'Sample review',
        'tenNguoiDung': 'Sample User',
        'ngayTao': DateTime.now().toIso8601String(),
      });
      
      print('✅ Tạo index mẫu thành công');
    } catch (e) {
      print('❌ Lỗi khi tạo index: $e');
    }
  }
}

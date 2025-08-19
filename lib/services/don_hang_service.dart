import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kfc/models/don_hang.dart';
import 'package:kfc/models/san_pham_gio_hang.dart';

class DonHangService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'donHang';

  // Tạo đơn hàng mới
  Future<String> createDonHang(DonHang donHang) async {
    try {
      final docRef = await _firestore.collection(_collection).add(donHang.toJson());
      return docRef.id;
    } catch (e) {
      print('Lỗi khi tạo đơn hàng: $e');
      throw e;
    }
  }

  // Lấy danh sách đơn hàng của người dùng (đơn giản hóa query)
  Future<List<DonHang>> getDonHangByUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('nguoiDungId', isEqualTo: userId)
          .get();

      List<DonHang> donHangList = snapshot.docs
          .map((doc) => DonHang.fromJson(doc.data(), doc.id))
          .toList();

      // Sắp xếp theo thời gian đặt hàng (mới nhất trước)
      donHangList.sort((a, b) => b.thoiGianDat.compareTo(a.thoiGianDat));

      return donHangList;
    } catch (e) {
      print('Lỗi khi lấy danh sách đơn hàng: $e');
      throw e;
    }
  }

  // Lấy chi tiết đơn hàng
  Future<DonHang?> getDonHangById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return DonHang.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Lỗi khi lấy chi tiết đơn hàng: $e');
      throw e;
    }
  }

  // Cập nhật trạng thái đơn hàng
  Future<void> updateTrangThaiDonHang(String id, TrangThaiDonHang trangThai) async {
    try {
      String trangThaiStr;
      switch (trangThai) {
        case TrangThaiDonHang.dangXuLy:
          trangThaiStr = 'dangXuLy';
          break;
        case TrangThaiDonHang.dangGiao:
          trangThaiStr = 'dangGiao';
          break;
        case TrangThaiDonHang.daGiao:
          trangThaiStr = 'daGiao';
          break;
        case TrangThaiDonHang.daHuy:
          trangThaiStr = 'daHuy';
          break;
      }

      await _firestore.collection(_collection).doc(id).update({
        'trangThai': trangThaiStr,
        'capNhatLuc': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Lỗi khi cập nhật trạng thái đơn hàng: $e');
      throw e;
    }
  }

  // Lấy tất cả đơn hàng (cho admin) - đơn giản hóa
  Future<List<DonHang>> getAllDonHang() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .get();

      List<DonHang> donHangList = snapshot.docs
          .map((doc) => DonHang.fromJson(doc.data(), doc.id))
          .toList();

      // Sắp xếp theo thời gian đặt hàng (mới nhất trước)
      donHangList.sort((a, b) => b.thoiGianDat.compareTo(a.thoiGianDat));

      return donHangList;
    } catch (e) {
      print('Lỗi khi lấy tất cả đơn hàng: $e');
      throw e;
    }
  }

  // Lấy đơn hàng theo trạng thái - đơn giản hóa
  Future<List<DonHang>> getDonHangByTrangThai(TrangThaiDonHang trangThai) async {
    try {
      String trangThaiStr;
      switch (trangThai) {
        case TrangThaiDonHang.dangXuLy:
          trangThaiStr = 'dangXuLy';
          break;
        case TrangThaiDonHang.dangGiao:
          trangThaiStr = 'dangGiao';
          break;
        case TrangThaiDonHang.daGiao:
          trangThaiStr = 'daGiao';
          break;
        case TrangThaiDonHang.daHuy:
          trangThaiStr = 'daHuy';
          break;
      }

      final snapshot = await _firestore
          .collection(_collection)
          .where('trangThai', isEqualTo: trangThaiStr)
          .get();

      List<DonHang> donHangList = snapshot.docs
          .map((doc) => DonHang.fromJson(doc.data(), doc.id))
          .toList();

      // Sắp xếp theo thời gian đặt hàng (mới nhất trước)
      donHangList.sort((a, b) => b.thoiGianDat.compareTo(a.thoiGianDat));

      return donHangList;
    } catch (e) {
      print('Lỗi khi lấy đơn hàng theo trạng thái: $e');
      throw e;
    }
  }

  // Lấy đơn hàng trong khoảng thời gian (cho báo cáo)
  Future<List<DonHang>> getDonHangByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('thoiGianDat', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('thoiGianDat', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      List<DonHang> donHangList = snapshot.docs
          .map((doc) => DonHang.fromJson(doc.data(), doc.id))
          .toList();

      // Sắp xếp theo thời gian đặt hàng (mới nhất trước)
      donHangList.sort((a, b) => b.thoiGianDat.compareTo(a.thoiGianDat));

      return donHangList;
    } catch (e) {
      print('Lỗi khi lấy đơn hàng theo khoảng thời gian: $e');
      throw e;
    }
  }

  // Stream để theo dõi đơn hàng real-time (cho admin)
  Stream<List<DonHang>> streamAllDonHang() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) {
      List<DonHang> donHangList = snapshot.docs
          .map((doc) => DonHang.fromJson(doc.data(), doc.id))
          .toList();

      // Sắp xếp theo thời gian đặt hàng (mới nhất trước)
      donHangList.sort((a, b) => b.thoiGianDat.compareTo(a.thoiGianDat));

      return donHangList;
    });
  }

  // Stream để theo dõi đơn hàng của user real-time
  Stream<List<DonHang>> streamDonHangByUser(String userId) {
    return _firestore
        .collection(_collection)
        .where('nguoiDungId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      List<DonHang> donHangList = snapshot.docs
          .map((doc) => DonHang.fromJson(doc.data(), doc.id))
          .toList();

      // Sắp xếp theo thời gian đặt hàng (mới nhất trước)
      donHangList.sort((a, b) => b.thoiGianDat.compareTo(a.thoiGianDat));

      return donHangList;
    });
  }
}

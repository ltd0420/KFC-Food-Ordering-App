import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kfc/models/nguoi_dung.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy thông tin người dùng từ Firestore
  static Future<NguoiDung?> getUserData(String uid) async {
    try {
      print('Đang lấy thông tin user từ Firestore: $uid');
      
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout khi lấy dữ liệu từ Firestore');
            },
          );
      
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print('Dữ liệu user từ Firestore: $data');
        
        return NguoiDung.fromMap(data);
      } else {
        print('Không tìm thấy document user trong Firestore');
        return null;
      }
    } catch (e) {
      print('Lỗi khi lấy thông tin người dùng từ Firestore: $e');
      return null;
    }
  }

  // Kiểm tra quyền và điều hướng
  static String getNavigationRoute(String? rule) {
    print('Xác định route dựa trên quyền: $rule');
    
    switch (rule?.toLowerCase()) {
      case 'admin':
        print('Điều hướng đến trang admin');
        return '/admin';
      case 'user':
      default:
        print('Điều hướng đến trang home');
        return '/home';
    }
  }

  // Cập nhật thông tin người dùng trong Firestore
  static Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        ...data,
        'capNhatLuc': FieldValue.serverTimestamp(),
      });
      print('Cập nhật thông tin user thành công');
    } catch (e) {
      print('Lỗi khi cập nhật thông tin người dùng: $e');
      throw Exception('Không thể cập nhật thông tin người dùng');
    }
  }

  // Tạo thông tin người dùng mới trong Firestore
  static Future<void> createUserData(String uid, NguoiDung nguoiDung) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        ...nguoiDung.toMap(),
        'taoLuc': FieldValue.serverTimestamp(),
        'capNhatLuc': FieldValue.serverTimestamp(),
      });
      print('Tạo thông tin user mới thành công');
    } catch (e) {
      print('Lỗi khi tạo thông tin người dùng: $e');
      throw Exception('Không thể tạo thông tin người dùng');
    }
  }

  // Đăng xuất
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('Đăng xuất thành công');
    } catch (e) {
      print('Lỗi khi đăng xuất: $e');
      throw Exception('Không thể đăng xuất');
    }
  }

  // Lấy user hiện tại
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Kiểm tra trạng thái đăng nhập
  static bool isLoggedIn() {
    return _auth.currentUser != null;
  }
}

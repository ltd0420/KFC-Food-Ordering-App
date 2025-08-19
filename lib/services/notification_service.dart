import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/thong_bao.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Khởi tạo notification service
  static Future<void> initialize() async {
    // Khởi tạo local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Khởi tạo Firebase Messaging
    await _initializeFirebaseMessaging();
  }

  static Future<void> _initializeFirebaseMessaging() async {
    try {
      // Yêu cầu quyền thông báo
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Đã cấp quyền thông báo');
        
        // Lấy FCM token
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          await _saveTokenToFirestore(token);
        }

        // Lắng nghe token refresh
        _firebaseMessaging.onTokenRefresh.listen(_saveTokenToFirestore);

        // Xử lý thông báo khi app đang chạy
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Xử lý thông báo khi app được mở từ background
        FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

        // Xử lý thông báo khi app được mở từ terminated state
        RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
        if (initialMessage != null) {
          _handleBackgroundMessage(initialMessage);
        }
      }
    } catch (e) {
      print('❌ Lỗi khởi tạo Firebase Messaging: $e');
    }
  }

  static Future<void> _saveTokenToFirestore(String token) async {
    try {
      // Lưu token vào collection users (đã tồn tại)
      await _firestore.collection('users').doc('current_user_id').set({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('✅ Đã lưu FCM token vào users collection');
    } catch (e) {
      print('❌ Lỗi khi lưu FCM token: $e');
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    print('📱 Nhận thông báo khi app đang chạy: ${message.notification?.title}');
    
    // Hiển thị local notification
    _showLocalNotification(
      title: message.notification?.title ?? 'KFC Vietnam',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  static void _handleBackgroundMessage(RemoteMessage message) {
    print('📱 Mở app từ thông báo: ${message.notification?.title}');
    _handleNotificationAction(message.data);
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'kfc_channel',
      'KFC Notifications',
      channelDescription: 'Thông báo từ KFC Vietnam',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFD00808),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  static void _onNotificationTapped(NotificationResponse response) {
    print('📱 Người dùng tap vào thông báo: ${response.payload}');
  }

  static void _handleNotificationAction(Map<String, dynamic> data) {
    final type = data['type'];
    final id = data['id'];
    
    if (type == 'don_hang') {
      // Navigate to order detail
    }
  }

  // Gửi thông báo local
  static Future<void> sendLocalNotification({
    required String title,
    required String body,
    String? imageUrl,
  }) async {
    await _showLocalNotification(
      title: title,
      body: body,
    );
  }

  // Kiểm tra xem collection thong_bao có tồn tại không
  static Future<bool> checkNotificationCollectionExists() async {
    try {
      final snapshot = await _firestore
          .collection('thong_bao')
          .limit(1)
          .get();
      
      print('📋 Collection thong_bao exists: ${snapshot.docs.isNotEmpty}');
      return true; // Collection tồn tại
    } catch (e) {
      print('📭 Collection thong_bao không tồn tại: $e');
      return false; // Collection không tồn tại
    }
  }

  // Lấy thông báo từ Firebase (KHÔNG SỬ DỤNG ORDERBY để tránh lỗi index)
  static Future<List<ThongBao>> getUserNotifications() async {
    try {
      // Kiểm tra collection có tồn tại không
      bool collectionExists = await checkNotificationCollectionExists();
      if (!collectionExists) {
        print('📭 Collection thong_bao chưa được tạo');
        return [];
      }

      // Lấy tất cả thông báo của user (không orderBy để tránh lỗi index)
      final snapshot = await _firestore
          .collection('thong_bao')
          .where('duLieuBoSung.nguoiDungId', isEqualTo: 'current_user_id')
          .limit(50)
          .get();

      if (snapshot.docs.isEmpty) {
        print('📭 Chưa có thông báo nào cho user này');
        return [];
      }

      List<ThongBao> notifications = snapshot.docs.map((doc) {
        final data = doc.data();
        return _convertFirebaseToThongBao(doc.id, data);
      }).toList();

      // Sắp xếp theo thời gian trong code (thay vì Firebase)
      notifications.sort((a, b) => b.thoiGian.compareTo(a.thoiGian));

      print('✅ Đã lấy ${notifications.length} thông báo từ Firebase');
      return notifications;
    } catch (e) {
      print('❌ Lỗi khi lấy thông báo từ Firebase: $e');
      return [];
    }
  }

  // Stream thông báo từ Firebase (KHÔNG SỬ DỤNG ORDERBY để tránh lỗi index)
  static Stream<List<ThongBao>> streamUserNotifications() {
    return Stream.fromFuture(checkNotificationCollectionExists())
        .asyncExpand((collectionExists) {
      if (!collectionExists) {
        print('📭 Stream: Collection thong_bao chưa được tạo');
        return Stream.value(<ThongBao>[]);
      }

      return _firestore
          .collection('thong_bao')
          .where('duLieuBoSung.nguoiDungId', isEqualTo: 'current_user_id')
          .limit(50)
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isEmpty) {
          print('📭 Stream: Chưa có thông báo nào cho user này');
          return <ThongBao>[];
        }

        List<ThongBao> notifications = snapshot.docs.map((doc) {
          final data = doc.data();
          return _convertFirebaseToThongBao(doc.id, data);
        }).toList();

        // Sắp xếp theo thời gian trong code (thay vì Firebase)
        notifications.sort((a, b) => b.thoiGian.compareTo(a.thoiGian));

        print('✅ Stream: Đã nhận ${notifications.length} thông báo từ Firebase');
        return notifications;
      });
    }).handleError((error) {
      print('❌ Lỗi stream thông báo: $error');
      return <ThongBao>[];
    });
  }

  // Convert Firebase document to ThongBao model
  static ThongBao _convertFirebaseToThongBao(String docId, Map<String, dynamic> data) {
    DateTime thoiGian = DateTime.now();
    if (data['thoiGianTao'] != null) {
      if (data['thoiGianTao'] is Timestamp) {
        thoiGian = (data['thoiGianTao'] as Timestamp).toDate();
      } else if (data['thoiGianTao'] is String) {
        try {
          thoiGian = DateTime.parse(data['thoiGianTao']);
        } catch (e) {
          print('Lỗi parse thời gian: $e');
        }
      }
    }

    Map<String, dynamic> duLieuBoSung = {};
    if (data['duLieuBoSung'] != null) {
      duLieuBoSung = Map<String, dynamic>.from(data['duLieuBoSung']);
    }

    String loai = duLieuBoSung['loai'] ?? 'don_hang';
    String? status = duLieuBoSung['trangThai'];

    return ThongBao(
      id: docId,
      tieuDe: data['tieuDe'] ?? '',
      noiDung: data['noiDung'] ?? '',
      loai: loai,
      thoiGian: thoiGian,
      daDoc: data['daDoc'] ?? false,
      duLieuThem: {
        'donHangId': duLieuBoSung['donHangId'],
        'status': status,
        'trangThai': status,
        'nguoiDungId': duLieuBoSung['nguoiDungId'],
        'timestamp': thoiGian.toIso8601String(),
        ...duLieuBoSung,
      },
    );
  }

  // Đánh dấu thông báo đã đọc (nếu collection tồn tại)
  static Future<void> markAsRead(String notificationId) async {
    try {
      bool collectionExists = await checkNotificationCollectionExists();
      if (!collectionExists) {
        print('📭 Không thể đánh dấu đã đọc: Collection thong_bao chưa tồn tại');
        return;
      }

      await _firestore
          .collection('thong_bao')
          .doc(notificationId)
          .update({
        'daDoc': true,
        'readAt': FieldValue.serverTimestamp(),
      });
      print('✅ Đã đánh dấu thông báo đã đọc: $notificationId');
    } catch (e) {
      print('❌ Lỗi khi đánh dấu đã đọc: $e');
    }
  }

  // Xóa thông báo (nếu collection tồn tại)
  static Future<void> deleteNotification(String notificationId) async {
    try {
      bool collectionExists = await checkNotificationCollectionExists();
      if (!collectionExists) {
        print('📭 Không thể xóa: Collection thong_bao chưa tồn tại');
        return;
      }

      await _firestore
          .collection('thong_bao')
          .doc(notificationId)
          .delete();
      print('✅ Đã xóa thông báo: $notificationId');
    } catch (e) {
      print('❌ Lỗi khi xóa thông báo: $e');
    }
  }

  // Tạo thông báo mới trong Firebase (cho admin gửi đến user)
  static Future<void> createFirebaseNotificationForUser({
    required String userId,
    required String orderId,
    required String status,
    String? customTitle,
    String? customMessage,
  }) async {
    try {
      String tieuDe = '';
      String noiDung = '';
      
      // Tạo nội dung thông báo dựa trên trạng thái
      switch (status) {
        case 'shipping':
          tieuDe = customTitle ?? '🚚 Đơn hàng đang được giao';
          noiDung = customMessage ?? 'Đơn hàng #${orderId.substring(0, 8)} của bạn đang trên đường giao đến. Vui lòng chuẩn bị nhận hàng!';
          break;
        case 'delivered':
          tieuDe = customTitle ?? '✅ Đơn hàng đã giao thành công';
          noiDung = customMessage ?? 'Đơn hàng #${orderId.substring(0, 8)} đã được giao thành công. Cảm ơn bạn đã tin tưởng KFC!';
          break;
        case 'cancelled':
          tieuDe = customTitle ?? '❌ Đơn hàng đã bị hủy';
          noiDung = customMessage ?? 'Đơn hàng #${orderId.substring(0, 8)} đã bị hủy. Nếu có thắc mắc, vui lòng liên hệ hotline.';
          break;
        case 'confirmed':
          tieuDe = customTitle ?? '✅ Đơn hàng đã được xác nhận';
          noiDung = customMessage ?? 'Đơn hàng #${orderId.substring(0, 8)} đã được xác nhận và đang được chuẩn bị.';
          break;
        default:
          tieuDe = customTitle ?? '📋 Cập nhật đơn hàng';
          noiDung = customMessage ?? 'Đơn hàng #${orderId.substring(0, 8)} đã được cập nhật trạng thái.';
      }

      // Tạo document trong Firebase
      final notificationData = {
        'tieuDe': tieuDe,
        'noiDung': noiDung,
        'loai': 'don_hang',
        'thoiGianTao': FieldValue.serverTimestamp(),
        'daDoc': false,
        'duLieuBoSung': {
          'nguoiDungId': userId,
          'donHangId': orderId,
          'trangThai': status,
          'loai': 'don_hang',
          'timestamp': DateTime.now().toIso8601String(),
        },
      };

      // Lưu vào Firebase
      final docRef = await _firestore.collection('thong_bao').add(notificationData);
      
      print('✅ Đã tạo thông báo Firebase: ${docRef.id}');
      print('📋 Tiêu đề: $tieuDe');
      print('📝 Nội dung: $noiDung');

      // Gửi local notification
      await _showLocalNotification(
        title: tieuDe,
        body: noiDung,
        payload: '{"type": "don_hang", "orderId": "$orderId", "notificationId": "${docRef.id}"}',
      );

      return;
    } catch (e) {
      print('❌ Lỗi khi tạo thông báo Firebase: $e');
      
      // Fallback: chỉ gửi local notification nếu Firebase fail
      await _showLocalNotification(
        title: customTitle ?? '📋 Cập nhật đơn hàng',
        body: customMessage ?? 'Đơn hàng của bạn đã được cập nhật.',
      );
    }
  }

// Tạo thông báo Firebase với nội dung tùy chỉnh
static Future<void> createCustomFirebaseNotification({
  required String userId,
  required String title,
  required String message,
  String loai = 'thong_bao',
  Map<String, dynamic>? extraData,
}) async {
  try {
    final notificationData = {
      'tieuDe': title,
      'noiDung': message,
      'loai': loai,
      'thoiGianTao': FieldValue.serverTimestamp(),
      'daDoc': false,
      'duLieuBoSung': {
        'nguoiDungId': userId,
        'loai': loai,
        'timestamp': DateTime.now().toIso8601String(),
        ...?extraData,
      },
    };

    final docRef = await _firestore.collection('thong_bao').add(notificationData);
    
    print('✅ Đã tạo thông báo tùy chỉnh: ${docRef.id}');

    // Gửi local notification
    await _showLocalNotification(
      title: title,
      body: message,
      payload: '{"type": "$loai", "notificationId": "${docRef.id}"}',
    );
  } catch (e) {
    print('❌ Lỗi khi tạo thông báo tùy chỉnh: $e');
  }
}
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Tạo phòng chat mới (đơn giản hóa)
  Future<String> createChatRoom(String customerName) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');

    // Kiểm tra xem người dùng đã có phòng chat đang hoạt động chưa
    final existingRooms = await _firestore
        .collection('chat_rooms')
        .where('customerId', isEqualTo: user.uid)
        .where('isActive', isEqualTo: true)
        .get();

    // Nếu đã có phòng chat đang hoạt động, trả về ID phòng đó
    if (existingRooms.docs.isNotEmpty) {
      return existingRooms.docs.first.id;
    }

    // Tạo phòng chat mới
    final chatRoom = ChatRoom(
      id: '',
      customerId: user.uid,
      customerName: customerName,
      createdAt: DateTime.now(),
      lastMessageTime: DateTime.now(),
      lastMessage: 'Khách hàng đã bắt đầu cuộc trò chuyện',
    );

    final docRef = await _firestore.collection('chat_rooms').add(chatRoom.toMap());
    
    // Gửi tin nhắn hệ thống đầu tiên
    await _firestore.collection('chat_rooms').doc(docRef.id).collection('messages').add(
      ChatMessage(
        id: '',
        senderId: 'system',
        senderName: 'Hệ thống KFC',
        message: 'Chào mừng bạn đến với hỗ trợ KFC! Admin sẽ phản hồi sớm nhất có thể.',
        timestamp: DateTime.now(),
      ).toMap(),
    );

    return docRef.id;
  }

  // Gửi tin nhắn
  Future<void> sendMessage(String roomId, String message, {String? imageUrl}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');

    // Lấy thông tin người dùng từ Firestore
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() as Map<String, dynamic>;
    final displayName = userData['displayName'] ?? 'Người dùng';
    final userRole = userData['rule'] ?? 'user';

    // Tạo tin nhắn mới
    final chatMessage = ChatMessage(
      id: '',
      senderId: user.uid,
      senderName: userRole == 'admin' ? 'Admin KFC' : displayName,
      message: message,
      timestamp: DateTime.now(),
      imageUrl: imageUrl,
    );

    // Lưu tin nhắn vào collection messages của phòng chat
    await _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .add(chatMessage.toMap());

    // Cập nhật thông tin phòng chat
    await _firestore.collection('chat_rooms').doc(roomId).update({
      'lastMessage': message,
      'lastMessageTime': Timestamp.fromDate(DateTime.now()),
      // Chỉ tăng unreadCount nếu không phải admin gửi
      if (userRole != 'admin') 'unreadCount': FieldValue.increment(1),
    });
  }

  // Lấy danh sách tin nhắn của một phòng chat
  Stream<List<ChatMessage>> getMessages(String roomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatMessage.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Lấy thông tin phòng chat
  Stream<ChatRoom?> getChatRoom(String roomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return ChatRoom.fromMap(snapshot.data()!, snapshot.id);
      } else {
        return null;
      }
    });
  }

  // Đánh dấu tin nhắn đã đọc (đơn giản hóa)
  Future<void> markMessagesAsRead(String roomId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Lấy thông tin người dùng
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() as Map<String, dynamic>;
    final userRole = userData['rule'] ?? 'user';

    // Nếu là admin, reset unreadCount về 0
    if (userRole == 'admin') {
      await _firestore.collection('chat_rooms').doc(roomId).update({
        'unreadCount': 0,
      });
    }
  }

  // Lấy danh sách phòng chat cho admin
  Stream<List<ChatRoom>> getStaffChatRooms() {
    return _firestore
        .collection('chat_rooms')
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatRoom.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Lấy phòng chat của khách hàng hiện tại
  Stream<List<ChatRoom>> getCustomerChatRooms() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('chat_rooms')
        .where('customerId', isEqualTo: user.uid)
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatRoom.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Admin tự động được gán vào phòng chat
  Future<void> assignStaffToRoom(String roomId, String adminId, String adminName) async {
    await _firestore.collection('chat_rooms').doc(roomId).update({
      'staffId': adminId,
      'staffName': adminName,
    });

    // Gửi tin nhắn thông báo
    await _firestore.collection('chat_rooms').doc(roomId).collection('messages').add(
      ChatMessage(
        id: '',
        senderId: 'system',
        senderName: 'Hệ thống KFC',
        message: 'Admin đã tham gia cuộc trò chuyện và sẵn sàng hỗ trợ bạn!',
        timestamp: DateTime.now(),
      ).toMap(),
    );
  }

  // Đóng phòng chat
  Future<void> closeChatRoom(String roomId) async {
    await _firestore.collection('chat_rooms').doc(roomId).update({
      'isActive': false,
    });

    // Gửi tin nhắn thông báo
    await _firestore.collection('chat_rooms').doc(roomId).collection('messages').add(
      ChatMessage(
        id: '',
        senderId: 'system',
        senderName: 'Hệ thống KFC',
        message: 'Cuộc trò chuyện đã được đóng. Cảm ơn bạn đã sử dụng dịch vụ!',
        timestamp: DateTime.now(),
      ).toMap(),
    );
  }
}

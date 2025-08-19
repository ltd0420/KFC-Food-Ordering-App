import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final String customerId;
  final String customerName;
  final String? staffId;
  final String? staffName;
  final DateTime createdAt;
  final DateTime lastMessageTime;
  final String lastMessage;
  final bool isActive;
  final int unreadCount;

  ChatRoom({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.staffId,
    this.staffName,
    required this.createdAt,
    required this.lastMessageTime,
    required this.lastMessage,
    this.isActive = true,
    this.unreadCount = 0,
  });

  factory ChatRoom.fromMap(Map<String, dynamic> map, String id) {
    return ChatRoom(
      id: id,
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      staffId: map['staffId'],
      staffName: map['staffName'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastMessageTime: map['lastMessageTime'] != null
          ? (map['lastMessageTime'] as Timestamp).toDate()
          : DateTime.now(),
      lastMessage: map['lastMessage'] ?? '',
      isActive: map['isActive'] ?? true,
      unreadCount: map['unreadCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'staffId': staffId,
      'staffName': staffName,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessage': lastMessage,
      'isActive': isActive,
      'unreadCount': unreadCount,
    };
  }
}

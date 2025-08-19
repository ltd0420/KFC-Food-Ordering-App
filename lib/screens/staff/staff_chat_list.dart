import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/chat_room.dart';
import '../../services/chat_service.dart';
import '../chat/chat_screen.dart';

class StaffChatListScreen extends StatefulWidget {
  const StaffChatListScreen({Key? key}) : super(key: key);

  @override
  _StaffChatListScreenState createState() => _StaffChatListScreenState();
}

class _StaffChatListScreenState extends State<StaffChatListScreen> with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  late TabController _tabController;
  String? _staffId;
  String? _staffName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStaffInfo();
  }

  Future<void> _loadStaffInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _staffId = user.uid;
          _staffName = userData['displayName'] ?? 'Nhân viên';
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý hỗ trợ khách hàng'),
        backgroundColor: Colors.red,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Đang chờ'),
            Tab(text: 'Đang hỗ trợ'),
          ],
          indicatorColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab phòng chat đang chờ (chưa có nhân viên)
          _buildChatRoomList(false),
          
          // Tab phòng chat đang hỗ trợ (đã có nhân viên)
          _buildChatRoomList(true),
        ],
      ),
    );
  }

  Widget _buildChatRoomList(bool hasStaff) {
    return StreamBuilder<List<ChatRoom>>(
      stream: _chatService.getStaffChatRooms(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Không có phòng chat nào'));
        }

        // Lọc phòng chat theo trạng thái nhân viên
        final chatRooms = snapshot.data!.where((room) {
          if (!room.isActive) return false;
          return hasStaff ? room.staffId != null : room.staffId == null;
        }).toList();

        if (chatRooms.isEmpty) {
          return Center(
            child: Text(
              hasStaff ? 'Không có phòng chat nào đang được hỗ trợ' : 'Không có phòng chat nào đang chờ',
            ),
          );
        }

        return ListView.builder(
          itemCount: chatRooms.length,
          itemBuilder: (context, index) {
            final room = chatRooms[index];
            return _buildChatRoomItem(room, hasStaff);
          },
        );
      },
    );
  }

  Widget _buildChatRoomItem(ChatRoom room, bool hasStaff) {
    final bool isMyRoom = room.staffId == _staffId;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red,
          child: Text(
            room.customerName.isNotEmpty ? room.customerName[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(room.customerName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              room.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Tạo lúc: ${_formatDateTime(room.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(room.lastMessageTime),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            if (room.unreadCount > 0)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  room.unreadCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
          ],
        ),
        onTap: () => _handleChatRoomTap(room, hasStaff, isMyRoom),
      ),
    );
  }

  void _handleChatRoomTap(ChatRoom room, bool hasStaff, bool isMyRoom) {
    if (!hasStaff) {
      // Phòng chat đang chờ - hiển thị dialog xác nhận tiếp nhận
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tiếp nhận hỗ trợ'),
          content: Text('Bạn muốn tiếp nhận hỗ trợ cho khách hàng ${room.customerName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (_staffId != null && _staffName != null) {
                  await _chatService.assignStaffToRoom(room.id, _staffId!, _staffName!);
                  
                  // Mở màn hình chat
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(roomId: room.id),
                    ),
                  );
                }
              },
              child: const Text('Tiếp nhận'),
            ),
          ],
        ),
      );
    } else if (isMyRoom) {
      // Phòng chat của mình - mở màn hình chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(roomId: room.id),
        ),
      );
    } else {
      // Phòng chat của nhân viên khác - hiển thị thông báo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phòng chat này đang được hỗ trợ bởi ${room.staffName}'),
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

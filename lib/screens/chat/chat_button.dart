import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chat_service.dart';
import 'chat_screen.dart';

class ChatSupportButton extends StatelessWidget {
  final ChatService _chatService = ChatService();
  
  ChatSupportButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _handleChatButtonPressed(context),
      backgroundColor: Colors.red,
      child: const Icon(
        Icons.chat,
        color: Colors.white,
      ),
      tooltip: 'Trò chuyện với nhân viên hỗ trợ',
    );
  }

  Future<void> _handleChatButtonPressed(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập để sử dụng tính năng này')),
        );
        return;
      }

      // Hiển thị dialog loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Lấy thông tin người dùng
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>;
      final displayName = userData['displayName'] ?? 'Người dùng';

      // Tạo hoặc lấy phòng chat hiện có
      final roomId = await _chatService.createChatRoom(displayName);

      // Đóng dialog loading
      Navigator.pop(context);

      // Mở màn hình chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(roomId: roomId),
        ),
      );
    } catch (e) {
      // Đóng dialog loading nếu có lỗi
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra: ${e.toString()}')),
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kfc/theme/mau_sac.dart';
import 'package:kfc/services/chat_service.dart';
import 'package:kfc/screens/chat/chat_screen.dart';

class FloatingChatButton extends StatelessWidget {
  final ChatService _chatService = ChatService();
  
  FloatingChatButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Chỉ hiển thị nút chat khi user đã đăng nhập và không phải admin
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) return const SizedBox.shrink();
            
            final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
            final userRole = userData?['rule'] ?? 'user';
            
            // Không hiển thị nút chat cho admin
            if (userRole == 'admin') return const SizedBox.shrink();
            
            return Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: () => _handleChatButtonPressed(context),
                backgroundColor: MauSac.kfcRed,
                heroTag: "chat_button", // Thêm heroTag để tránh conflict
                child: const Icon(
                  Icons.chat,
                  color: MauSac.trang,
                ),
                tooltip: 'Trò chuyện với hỗ trợ KFC',
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleChatButtonPressed(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng đăng nhập để sử dụng tính năng này'),
            backgroundColor: MauSac.kfcRed,
          ),
        );
        return;
      }

      // Hiển thị dialog loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: MauSac.kfcRed),
        ),
      );

      // Lấy thông tin người dùng
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data() as Map<String, dynamic>;
      final displayName = userData['displayName'] ?? userData['ten'] ?? 'Khách hàng';

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
        SnackBar(
          content: Text('Có lỗi xảy ra: ${e.toString()}'),
          backgroundColor: MauSac.kfcRed,
        ),
      );
    }
  }
}

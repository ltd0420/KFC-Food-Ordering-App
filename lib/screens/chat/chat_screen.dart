import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:kfc/theme/mau_sac.dart';
import '../../models/chat_message.dart';
import '../../models/chat_room.dart';
import '../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;

  const ChatScreen({Key? key, required this.roomId}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _currentUserId;
  bool _isDeletingMessage = false;
  String? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadUserRole();
    // Đánh dấu tin nhắn đã đọc khi mở màn hình
    _chatService.markMessagesAsRead(widget.roomId);
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _currentUserRole = userData['rule'] ?? 'user';
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _chatService.sendMessage(widget.roomId, message);
      _messageController.clear();
      
      // Đảm bảo cuộn xuống tin nhắn mới nhất
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể gửi tin nhắn: ${e.toString()}'),
          backgroundColor: MauSac.kfcRed,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Tải ảnh lên Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      await storageRef.putFile(File(image.path));
      final imageUrl = await storageRef.getDownloadURL();
      
      // Gửi tin nhắn với ảnh
      await _chatService.sendMessage(widget.roomId, 'Đã gửi một hình ảnh', imageUrl: imageUrl);
      
      // Đảm bảo cuộn xuống tin nhắn mới nhất
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể gửi ảnh: ${e.toString()}'),
          backgroundColor: MauSac.kfcRed,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Hàm xóa tin nhắn
  Future<void> _deleteMessage(ChatMessage message) async {
    // Hiển thị dialog xác nhận
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MauSac.denNhat,
        title: const Text(
          'Xóa tin nhắn',
          style: TextStyle(color: MauSac.trang),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn xóa tin nhắn này?',
          style: TextStyle(color: MauSac.trang),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: MauSac.xam),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Xóa',
              style: TextStyle(color: MauSac.kfcRed),
            ),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirm) return;
    
    setState(() {
      _isDeletingMessage = true;
    });
    
    try {
      await _chatService.deleteMessage(widget.roomId, message);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa tin nhắn'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể xóa tin nhắn: ${e.toString()}'),
          backgroundColor: MauSac.kfcRed,
        ),
      );
    } finally {
      setState(() {
        _isDeletingMessage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<ChatRoom?>(
          stream: _chatService.getChatRoom(widget.roomId),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              final chatRoom = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hỗ trợ KFC',
                    style: TextStyle(color: MauSac.trang),
                  ),
                  Text(
                    chatRoom.staffName != null
                        ? 'Nhân viên: ${chatRoom.staffName}'
                        : 'Đang chờ nhân viên...',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: MauSac.trang,
                    ),
                  ),
                ],
              );
            }
            return const Text(
              'Hỗ trợ KFC',
              style: TextStyle(color: MauSac.trang),
            );
          },
        ),
        backgroundColor: MauSac.kfcRed,
        iconTheme: const IconThemeData(color: MauSac.trang),
      ),
      backgroundColor: MauSac.denNen,
      body: Column(
        children: [
          // Danh sách tin nhắn
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getMessages(widget.roomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: MauSac.kfcRed),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'Chưa có tin nhắn nào',
                      style: TextStyle(color: MauSac.xam),
                    ),
                  );
                }

                final messages = snapshot.data!;
                
                // Cuộn xuống tin nhắn mới nhất sau khi danh sách được cập nhật
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUserId;
                    final isSystem = message.senderId == 'system';

                    if (isSystem) {
                      return _buildSystemMessage(message);
                    }

                    // Kiểm tra xem người dùng có quyền xóa tin nhắn này không
                    final canDelete = isMe || _currentUserRole == 'admin';

                    return _buildDismissibleMessage(message, isMe, canDelete);
                  },
                );
              },
            ),
          ),

          // Thanh nhập tin nhắn
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: MauSac.denNhat,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Nút gửi ảnh
                IconButton(
                  icon: const Icon(Icons.photo, color: MauSac.kfcRed),
                  onPressed: _isLoading ? null : _sendImage,
                ),
                // Ô nhập tin nhắn
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: MauSac.trang),
                    decoration: const InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      hintStyle: TextStyle(color: MauSac.xam),
                      border: InputBorder.none,
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                // Nút gửi tin nhắn
                IconButton(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: MauSac.kfcRed,
                          ),
                        )
                      : const Icon(Icons.send, color: MauSac.kfcRed),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: MauSac.denNhat,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Text(
            message.message,
            style: const TextStyle(
              color: MauSac.xam,
              fontSize: 12.0,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDismissibleMessage(ChatMessage message, bool isMe, bool canDelete) {
    // Nếu không thể xóa, trả về tin nhắn bình thường
    if (!canDelete) {
      return _buildMessageBubble(message, isMe);
    }
    
    // Nếu có thể xóa, bọc trong Dismissible để có thể kéo để xóa
    return Dismissible(
      key: Key(message.id),
      direction: DismissDirection.endToStart, // Chỉ cho phép kéo từ phải qua trái
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: MauSac.denNhat,
            title: const Text(
              'Xóa tin nhắn',
              style: TextStyle(color: MauSac.trang),
            ),
            content: const Text(
              'Bạn có chắc chắn muốn xóa tin nhắn này?',
              style: TextStyle(color: MauSac.trang),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Hủy',
                  style: TextStyle(color: MauSac.xam),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Xóa',
                  style: TextStyle(color: MauSac.kfcRed),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _deleteMessage(message);
      },
      child: _buildMessageBubble(message, isMe),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              backgroundColor: MauSac.kfcRed,
              child: const Icon(Icons.support_agent, color: MauSac.trang),
              radius: 16,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, bottom: 2.0),
                    child: Text(
                      message.senderName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: MauSac.xam,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    color: isMe ? MauSac.kfcRed : MauSac.denNhat,
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.imageUrl != null)
                        GestureDetector(
                          onTap: () {
                            // Hiển thị ảnh full màn hình khi nhấn vào
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Scaffold(
                                  appBar: AppBar(
                                    backgroundColor: Colors.black,
                                    iconTheme: const IconThemeData(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.black,
                                  body: Center(
                                    child: InteractiveViewer(
                                      minScale: 0.5,
                                      maxScale: 4.0,
                                      child: Image.network(message.imageUrl!),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              message.imageUrl!,
                              width: 200,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 200,
                                  height: 150,
                                  alignment: Alignment.center,
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: MauSac.kfcRed,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      if (message.message.isNotEmpty)
                        Text(
                          message.message,
                          style: TextStyle(
                            color: isMe ? MauSac.trang : MauSac.trang,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe ? MauSac.trang.withOpacity(0.7) : MauSac.xam,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

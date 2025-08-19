import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kfc/theme/mau_sac.dart';
import 'package:kfc/models/nguoi_dung.dart';

class ManHinhQLND extends StatefulWidget {
  const ManHinhQLND({Key? key}) : super(key: key);

  @override
  State<ManHinhQLND> createState() => _ManHinhQLNDState();
}

class _ManHinhQLNDState extends State<ManHinhQLND> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MauSac.denNhat,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: MauSac.xamDam.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: MauSac.xamDam.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Danh sách người dùng',
                    style: TextStyle(
                      color: MauSac.trang,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MauSac.kfcRed,
                    foregroundColor: MauSac.trang,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Làm mới'),
                ),
              ],
            ),
          ),
          
          // User List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('taoLuc', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: MauSac.kfcRed,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Lỗi: ${snapshot.error}',
                          style: const TextStyle(color: MauSac.trang),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MauSac.kfcRed,
                          ),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: MauSac.kfcRed,
                    ),
                  );
                }

                final users = snapshot.data?.docs ?? [];

                if (users.isEmpty) {
                  return const Center(
                    child: Text(
                      'Không có người dùng nào',
                      style: TextStyle(color: MauSac.xam),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userDoc = users[index];
                    final userData = userDoc.data() as Map<String, dynamic>;
                    final user = NguoiDung.fromMap(userData);
                    
                    return Card(
                      color: MauSac.denNen,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 600) {
                              // Desktop/Tablet layout
                              return Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: user.isAdmin 
                                        ? MauSac.kfcRed.withOpacity(0.1)
                                        : MauSac.xanhLa.withOpacity(0.1),
                                    child: Icon(
                                      user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                                      color: user.isAdmin ? MauSac.kfcRed : MauSac.xanhLa,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.ten,
                                          style: const TextStyle(
                                            color: MauSac.trang,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          user.email,
                                          style: TextStyle(
                                            color: MauSac.xam,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'ID: ${userDoc.id}',
                                          style: TextStyle(
                                            color: MauSac.xam.withOpacity(0.7),
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: user.isAdmin 
                                                ? MauSac.kfcRed.withOpacity(0.1)
                                                : MauSac.xanhLa.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            user.rule.toUpperCase(),
                                            style: TextStyle(
                                              color: user.isAdmin ? MauSac.kfcRed : MauSac.xanhLa,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, color: MauSac.xam),
                                    color: MauSac.denNhat,
                                    onSelected: (value) async {
                                      if (value == 'change_role') {
                                        await _changeUserRole(userDoc.id, user);
                                      } else if (value == 'delete') {
                                        await _deleteUser(userDoc.id, user);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'change_role',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.swap_horiz,
                                              color: MauSac.cam,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Đổi quyền',
                                              style: TextStyle(color: MauSac.trang),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete,
                                              color: MauSac.kfcRed,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Xóa',
                                              style: TextStyle(color: MauSac.trang),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            } else {
                              // Mobile layout
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: user.isAdmin 
                                            ? MauSac.kfcRed.withOpacity(0.1)
                                            : MauSac.xanhLa.withOpacity(0.1),
                                        child: Icon(
                                          user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                                          color: user.isAdmin ? MauSac.kfcRed : MauSac.xanhLa,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user.ten,
                                              style: const TextStyle(
                                                color: MauSac.trang,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              user.email,
                                              style: TextStyle(
                                                color: MauSac.xam,
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'ID: ${userDoc.id}',
                                              style: TextStyle(
                                                color: MauSac.xam.withOpacity(0.7),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, color: MauSac.xam),
                                        color: MauSac.denNhat,
                                        onSelected: (value) async {
                                          if (value == 'change_role') {
                                            await _changeUserRole(userDoc.id, user);
                                          } else if (value == 'delete') {
                                            await _deleteUser(userDoc.id, user);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'change_role',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.swap_horiz,
                                                  color: MauSac.cam,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                const Text(
                                                  'Đổi quyền',
                                                  style: TextStyle(color: MauSac.trang),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.delete,
                                                  color: MauSac.kfcRed,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                const Text(
                                                  'Xóa',
                                                  style: TextStyle(color: MauSac.trang),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: user.isAdmin 
                                            ? MauSac.kfcRed.withOpacity(0.1)
                                            : MauSac.xanhLa.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        user.rule.toUpperCase(),
                                        style: TextStyle(
                                          color: user.isAdmin ? MauSac.kfcRed : MauSac.xanhLa,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeUserRole(String userId, NguoiDung user) async {
    try {
      final newRole = user.isAdmin ? 'user' : 'admin';
      
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: MauSac.denNhat,
          title: const Text(
            'Xác nhận đổi quyền',
            style: TextStyle(color: MauSac.trang),
          ),
          content: Text(
            'Bạn có chắc muốn đổi quyền của ${user.ten} từ ${user.rule.toUpperCase()} thành ${newRole.toUpperCase()}?',
            style: const TextStyle(color: MauSac.xam),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy', style: TextStyle(color: MauSac.xam)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: MauSac.kfcRed,
                foregroundColor: MauSac.trang,
              ),
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Show loading
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đang cập nhật quyền...'),
              backgroundColor: MauSac.cam,
              duration: Duration(seconds: 1),
            ),
          );
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'rule': newRole,
          'capNhatLuc': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Đã đổi quyền của ${user.ten} thành ${newRole.toUpperCase()}'),
              backgroundColor: MauSac.xanhLa,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Lỗi khi đổi quyền: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi khi đổi quyền: $e'),
            backgroundColor: MauSac.kfcRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _deleteUser(String userId, NguoiDung user) async {
    try {
      print('🔍 Attempting to delete user with ID: $userId');
      print('👤 User name: ${user.ten}');
      print('📧 User email: ${user.email}');

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: MauSac.denNhat,
          title: const Text(
            '⚠️ Xác nhận xóa người dùng',
            style: TextStyle(color: MauSac.trang),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn có chắc muốn xóa người dùng sau?',
                style: const TextStyle(color: MauSac.xam),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MauSac.kfcRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: MauSac.kfcRed.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '👤 Tên: ${user.ten}',
                      style: const TextStyle(color: MauSac.trang, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '📧 Email: ${user.email}',
                      style: const TextStyle(color: MauSac.xam),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '🔑 Quyền: ${user.rule.toUpperCase()}',
                      style: TextStyle(
                        color: user.isAdmin ? MauSac.kfcRed : MauSac.xanhLa,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '🆔 ID: $userId',
                      style: TextStyle(
                        color: MauSac.xam.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '⚠️ Hành động này không thể hoàn tác!',
                style: TextStyle(
                  color: MauSac.kfcRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('❌ Hủy', style: TextStyle(color: MauSac.xam)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: MauSac.kfcRed,
                foregroundColor: MauSac.trang,
              ),
              child: const Text('🗑️ Xóa'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Show loading
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔄 Đang xóa người dùng...'),
              backgroundColor: MauSac.cam,
              duration: Duration(seconds: 2),
            ),
          );
        }

        print('🔥 Starting Firebase delete operation...');
        
        // Check if document exists first
        final docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
            
        if (!docSnapshot.exists) {
          print('❌ Document does not exist!');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Người dùng không tồn tại trong cơ sở dữ liệu'),
                backgroundColor: MauSac.kfcRed,
              ),
            );
          }
          return;
        }

        print('✅ Document exists, proceeding with delete...');

        // Delete the document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .delete();

        print('✅ Delete operation completed successfully');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Đã xóa người dùng "${user.ten}" thành công'),
              backgroundColor: MauSac.xanhLa,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error during delete operation: $e');
      print('❌ Error type: ${e.runtimeType}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '❌ Lỗi khi xóa người dùng',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('Chi tiết: $e'),
              ],
            ),
            backgroundColor: MauSac.kfcRed,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: MauSac.trang,
              onPressed: () => _deleteUser(userId, user),
            ),
          ),
        );
      }
    }
  }
}

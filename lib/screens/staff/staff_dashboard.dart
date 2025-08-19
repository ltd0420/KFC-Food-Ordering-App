import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'staff_chat_list.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({Key? key}) : super(key: key);

  @override
  _StaffDashboardState createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  int _pendingChats = 0;
  int _activeChats = 0;
  String _staffName = '';

  @override
  void initState() {
    super.initState();
    _loadStaffInfo();
    _loadChatStats();
  }

  Future<void> _loadStaffInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _staffName = userData['displayName'] ?? 'Nhân viên';
        });
      }
    }
  }

  Future<void> _loadChatStats() async {
    // Đếm số phòng chat đang chờ (chưa có nhân viên)
    final pendingChatsQuery = await FirebaseFirestore.instance
        .collection('chat_rooms')
        .where('staffId', isNull: true)
        .where('isActive', isEqualTo: true)
        .get();
    
    // Đếm số phòng chat đang hỗ trợ (đã có nhân viên)
    final activeChatsQuery = await FirebaseFirestore.instance
        .collection('chat_rooms')
        .where('staffId', isNotEqualTo: null)
        .where('isActive', isEqualTo: true)
        .get();
    
    setState(() {
      _pendingChats = pendingChatsQuery.docs.length;
      _activeChats = activeChatsQuery.docs.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng điều khiển nhân viên'),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin nhân viên
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.red,
                      radius: 30,
                      child: Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xin chào, $_staffName',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('Nhân viên hỗ trợ khách hàng'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Thống kê chat
            const Text(
              'Thống kê hỗ trợ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                // Phòng chat đang chờ
                Expanded(
                  child: _buildStatCard(
                    'Đang chờ',
                    _pendingChats.toString(),
                    Colors.orange,
                    Icons.hourglass_empty,
                  ),
                ),
                const SizedBox(width: 16),
                // Phòng chat đang hỗ trợ
                Expanded(
                  child: _buildStatCard(
                    'Đang hỗ trợ',
                    _activeChats.toString(),
                    Colors.green,
                    Icons.chat_bubble,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Nút quản lý chat
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StaffChatListScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.support_agent),
                label: const Text('Quản lý hỗ trợ khách hàng'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Nút làm mới thống kê
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loadChatStats,
                icon: const Icon(Icons.refresh),
                label: const Text('Làm mới thống kê'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:kfc/theme/mau_sac.dart';
import 'package:kfc/providers/nguoi_dung_provider.dart';
import 'package:kfc/screens/admin/man_hinh_dashboard.dart';
import 'package:kfc/screens/admin/man_hinh_qlnd.dart';
import 'package:kfc/screens/admin/man_hinh_qlsp.dart';
import 'package:kfc/screens/admin/man_hinh_qldh.dart';
import 'package:kfc/screens/admin/admin_chat_dashboard.dart'; // Thêm import này

class ManHinhAdmin extends StatefulWidget {
  const ManHinhAdmin({Key? key}) : super(key: key);

  @override
  State<ManHinhAdmin> createState() => _ManHinhAdminState();
}

class _ManHinhAdminState extends State<ManHinhAdmin> {
  int _selectedIndex = 0;
  bool _isLoading = false;

  // Cập nhật danh sách menu - thêm "Hỗ trợ khách hàng"
  final List<String> _menuItems = [
    'Dashboard',
    'Quản lý người dùng',
    'Quản lý sản phẩm',
    'Quản lý đơn hàng',
    'Hỗ trợ khách hàng', // Thêm mục này
    'Cài đặt',
  ];

  // Cập nhật danh sách icon - thêm icon chat
  final List<IconData> _menuIcons = [
    Icons.dashboard,
    Icons.people,
    Icons.restaurant_menu,
    Icons.shopping_cart,
    Icons.support_agent, // Thêm icon này
    Icons.settings,
  ];

  Future<void> _dangXuat() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await FirebaseAuth.instance.signOut();
      
      if (mounted) {
        final nguoiDungProvider = Provider.of<NguoiDungProvider>(context, listen: false);
        nguoiDungProvider.dangXuat();
        
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      print('Lỗi khi đăng xuất: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi đăng xuất: $e'),
            backgroundColor: MauSac.kfcRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MauSac.denNen,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive design
            final isDesktop = constraints.maxWidth > 1024;
            final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1024;
            
            if (isDesktop) {
              return Row(
                children: [
                  _buildSidebar(280),
                  Expanded(child: _buildMainContent()),
                ],
              );
            } else if (isTablet) {
              return Row(
                children: [
                  _buildSidebar(240),
                  Expanded(child: _buildMainContent()),
                ],
              );
            } else {
              // Mobile layout
              return _selectedIndex == -1 
                  ? _buildSidebar(double.infinity)
                  : Column(
                      children: [
                        _buildMobileHeader(),
                        Expanded(child: _buildMainContent()),
                      ],
                    );
            }
          },
        ),
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MauSac.denNhat,
        border: Border(
          bottom: BorderSide(
            color: MauSac.xamDam.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _selectedIndex = -1;
              });
            },
            icon: const Icon(Icons.menu, color: MauSac.trang),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _selectedIndex >= 0 ? _menuItems[_selectedIndex] : 'Menu',
              style: const TextStyle(
                color: MauSac.trang,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: _dangXuat,
            icon: const Icon(Icons.logout, color: MauSac.kfcRed),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(double width) {
    return Container(
      width: width == double.infinity ? null : width,
      decoration: BoxDecoration(
        color: MauSac.denNhat,
        border: width != double.infinity ? Border(
          right: BorderSide(
            color: MauSac.xamDam.withOpacity(0.2),
            width: 1,
          ),
        ) : null,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  MauSac.kfcRed,
                  MauSac.kfcRed.withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: MauSac.trang,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    size: 30,
                    color: MauSac.kfcRed,
                  ),
                ),
                const SizedBox(height: 12),
                Consumer<NguoiDungProvider>(
                  builder: (context, provider, child) {
                    return Column(
                      children: [
                        Text(
                          provider.nguoiDung?.ten ?? 'Admin',
                          style: const TextStyle(
                            color: MauSac.trang,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: MauSac.trang.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            provider.nguoiDung?.rule.toUpperCase() ?? 'ADMIN',
                            style: const TextStyle(
                              color: MauSac.trang,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Menu Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedIndex == index;
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? MauSac.kfcRed.withOpacity(0.1) : null,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: MauSac.kfcRed.withOpacity(0.3))
                        : null,
                  ),
                  child: ListTile(
                    leading: Icon(
                      _menuIcons[index],
                      color: isSelected ? MauSac.kfcRed : MauSac.xam,
                    ),
                    title: Text(
                      _menuItems[index],
                      style: TextStyle(
                        color: isSelected ? MauSac.kfcRed : MauSac.trang,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          
          // Logout Button
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _dangXuat,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MauSac.kfcRed,
                  foregroundColor: MauSac.trang,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: MauSac.trang,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.logout),
                label: Text(_isLoading ? 'Đang đăng xuất...' : 'Đăng xuất'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Only show on desktop/tablet
          if (MediaQuery.of(context).size.width > 768) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedIndex >= 0 ? _menuItems[_selectedIndex] : 'Dashboard',
                    style: const TextStyle(
                      color: MauSac.trang,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: MauSac.kfcRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: MauSac.kfcRed.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: MauSac.kfcRed,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Online',
                        style: TextStyle(
                          color: MauSac.kfcRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          
          // Content
          Expanded(
            child: _buildContentForIndex(_selectedIndex >= 0 ? _selectedIndex : 0),
          ),
        ],
      ),
    );
  }

  // Cập nhật hàm này để thêm case cho chat support
  Widget _buildContentForIndex(int index) {
    switch (index) {
      case 0:
        return const ManHinhDashboard();
      case 1:
        return const ManHinhQLND();
      case 2:
        return const ManHinhQLSP();
      case 3:
        return const ManHinhQLDH();
      case 4:
        return const AdminChatDashboard(); // Thêm case này
      case 5: // Cài đặt chuyển thành case 5
        return _buildSettings();
      default:
        return const ManHinhDashboard();
    }
  }

  Widget _buildSettings() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.settings,
            size: 64,
            color: MauSac.xam,
          ),
          const SizedBox(height: 16),
          const Text(
            'Cài đặt',
            style: TextStyle(
              color: MauSac.trang,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chức năng đang được phát triển',
            style: TextStyle(
              color: MauSac.xam,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

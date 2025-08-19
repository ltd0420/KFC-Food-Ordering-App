import 'package:flutter/material.dart';
import 'package:kfc/screens/man_hinh_dang_ky.dart';
import 'package:kfc/screens/man_hinh_dang_nhap.dart';
import 'package:kfc/screens/man_hinh_don_hang.dart';
import 'package:kfc/theme/mau_sac.dart';
import 'package:kfc/models/nguoi_dung.dart';
import 'package:kfc/providers/nguoi_dung_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'dart:io';

class ManHinhTaiKhoan extends StatefulWidget {
  const ManHinhTaiKhoan({Key? key}) : super(key: key);

  @override
  State<ManHinhTaiKhoan> createState() => _ManHinhTaiKhoanState();
}

class _ManHinhTaiKhoanState extends State<ManHinhTaiKhoan>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _headerAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.elasticOut,
    ));

    _headerAnimationController.forward();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MauSac.denNen,
      body: SafeArea(
        child: StreamBuilder<User?>(
          stream: _auth.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingView();
            }
            
            if (snapshot.hasData && snapshot.data != null) {
              return _buildLoggedInView(snapshot.data!);
            } else {
              return _buildLoggedOutView();
            }
          },
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(
        color: MauSac.kfcRed,
        strokeWidth: 3,
      ),
    );
  }

  Widget _buildLoggedInView(User user) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(user.uid).snapshots(),
      builder: (context, userSnapshot) {
        Map<String, dynamic>? userData;
        
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          if (userData != null && context.read<NguoiDungProvider>().nguoiDung == null) {
            final nguoiDung = NguoiDung.fromMap({
              'id': user.uid,
              'ten': userData['displayName'] ?? '',
              'email': userData['email'] ?? '',
              'soDienThoai': userData['soDienThoai'] ?? '',
              'rule': userData['rule'] ?? 'user',
            });
            context.read<NguoiDungProvider>().dangNhap(nguoiDung);
          }
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildUserHeader(user, userData),
              const SizedBox(height: 20),
              _buildMenuOptions(user),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoggedOutView() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          MauSac.kfcRed.withOpacity(0.1),
                          MauSac.kfcRed.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(70),
                      border: Border.all(
                        color: MauSac.kfcRed.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      size: 70,
                      color: MauSac.kfcRed,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Chào mừng đến với KFC!',
              style: TextStyle(
                color: MauSac.trang,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Đăng nhập để đặt hàng và nhận những\nưu đãi đặc biệt từ KFC',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MauSac.xam.withOpacity(0.8),
                fontSize: 16,
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 40),
            _buildAuthButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(User user, Map<String, dynamic>? userData) {
    final displayName = userData?['displayName'] ?? user.displayName ?? 'Người dùng KFC';
    final email = user.email ?? '';
    final soDienThoai = userData?['soDienThoai'] ?? '';
    final photoURL = userData?['photoURL'] ?? user.photoURL;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.all(20),
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
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: MauSac.kfcRed.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
              ),
              child: photoURL != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        photoURL,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white,
                    ),
            ),
            
            const SizedBox(width: 20),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (email.isNotEmpty)
                    Text(
                      email,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (soDienThoai.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      soDienThoai,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Khách hàng mới😊',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                onPressed: () => _showEditProfileDialog(user, userData),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOptions(User user) {
    final menuItems = [
      {
        'icon': Icons.receipt_long,
        'title': 'Đơn hàng của tôi',
        'subtitle': 'Xem lịch sử và trạng thái đơn hàng',
        'onTap': () => _navigateToOrders(),
      },
      {
        'icon': Icons.person_outline,
        'title': 'Thông tin cá nhân',
        'subtitle': 'Xem thông tin tài khoản',
        'onTap': () => _showPersonalInfoDialog(user),
      },
      {
        'icon': Icons.security,
        'title': 'Bảo mật',
        'subtitle': 'Đổi mật khẩu và bảo mật tài khoản',
        'onTap': () => _showSecurityDialog(),
      },
      {
        'icon': Icons.info_outline,
        'title': 'Về KFC',
        'subtitle': 'Thông tin ứng dụng và điều khoản',
        'onTap': () => _showAboutDialog(),
      },
      {
        'icon': Icons.logout,
        'title': 'Đăng xuất',
        'subtitle': 'Thoát khỏi tài khoản hiện tại',
        'onTap': () => _showLogoutDialog(),
      },
    ];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: MauSac.denNhat,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: MauSac.kfcRed.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: menuItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == menuItems.length - 1;
            
            return Column(
              children: [
                _buildMenuItem(
                  item['icon'] as IconData,
                  item['title'] as String,
                  item['subtitle'] as String,
                  item['onTap'] as VoidCallback,
                ),
                if (!isLast)
                  Divider(
                    color: MauSac.xam.withOpacity(0.2),
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: MauSac.kfcRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: MauSac.kfcRed,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: MauSac.trang,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: MauSac.xam.withOpacity(0.8),
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: MauSac.xam.withOpacity(0.5),
        size: 16,
      ),
    );
  }

  Widget _buildAuthButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () => _navigateToLogin(),
            icon: const Icon(Icons.login, size: 20),
            label: const Text(
              'Đăng nhập',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: MauSac.kfcRed,
              foregroundColor: MauSac.trang,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () => _navigateToRegister(),
            icon: const Icon(Icons.person_add, size: 20),
            label: const Text(
              'Đăng ký',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: MauSac.kfcRed,
              side: const BorderSide(color: MauSac.kfcRed, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ManHinhDangNhap(),
      ),
    );
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ManHinhDangKy(),
      ),
    );
  }

  void _navigateToOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ManHinhDonHang(),
      ),
    );
  }

  void _showEditProfileDialog(User user, Map<String, dynamic>? userData) {
    final TextEditingController nameController = TextEditingController(
      text: userData?['displayName'] ?? user.displayName ?? '',
    );
    final TextEditingController soDienThoaiController = TextEditingController(
      text: userData?['soDienThoai'] ?? user.phoneNumber ?? '',
    );
    XFile? selectedImage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final AnimationController imageAnimationController = AnimationController(
            duration: const Duration(milliseconds: 600),
            vsync: Navigator.of(context),
          );
          final AnimationController fieldsAnimationController = AnimationController(
            duration: const Duration(milliseconds: 800),
            vsync: Navigator.of(context),
          );

          final Animation<double> imageFadeAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: imageAnimationController,
            curve: Curves.easeOut,
          ));

          final Animation<double> imageScaleAnimation = Tween<double>(
            begin: 0.5,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: imageAnimationController,
            curve: Curves.elasticOut,
          ));

          final Animation<Offset> fieldsSlideAnimation = Tween<Offset>(
            begin: const Offset(0, 0.5),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: fieldsAnimationController,
            curve: Curves.easeOutBack,
          ));

          imageAnimationController.forward();
          fieldsAnimationController.forward();

          return AlertDialog(
            backgroundColor: MauSac.denNhat,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MauSac.kfcRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit, color: MauSac.kfcRed, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Chỉnh sửa thông tin',
                  style: TextStyle(
                    color: MauSac.trang,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        setState(() {
                          selectedImage = image;
                          imageAnimationController.reset();
                          imageAnimationController.forward();
                        });
                      }
                    },
                    child: FadeTransition(
                      opacity: imageFadeAnimation,
                      child: ScaleTransition(
                        scale: imageScaleAnimation,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: MauSac.xam.withOpacity(0.2),
                            border: Border.all(
                              color: MauSac.kfcRed.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: selectedImage != null
                              ? ClipOval(
                                  child: Image.file(
                                    File(selectedImage!.path),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.broken_image,
                                      color: MauSac.kfcRed,
                                      size: 60,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  color: MauSac.kfcRed,
                                  size: 60,
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedImage != null ? 'Đã chọn ảnh' : 'Chạm để chọn ảnh',
                    style: TextStyle(
                      color: MauSac.xam.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  SlideTransition(
                    position: fieldsSlideAnimation,
                    child: Column(
                      children: [
                        TextField(
                          controller: nameController,
                          style: const TextStyle(color: MauSac.trang),
                          decoration: InputDecoration(
                            labelText: 'Họ và tên',
                            labelStyle: TextStyle(color: MauSac.xam.withOpacity(0.8)),
                            filled: true,
                            fillColor: MauSac.xam.withOpacity(0.1),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: MauSac.xam.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: MauSac.kfcRed),
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: soDienThoaiController,
                          style: const TextStyle(color: MauSac.trang),
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Số điện thoại',
                            labelStyle: TextStyle(color: MauSac.xam.withOpacity(0.8)),
                            filled: true,
                            fillColor: MauSac.xam.withOpacity(0.1),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: MauSac.xam.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: MauSac.kfcRed),
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  imageAnimationController.dispose();
                  fieldsAnimationController.dispose();
                  Navigator.pop(context);
                },
                child: const Text(
                  'Hủy',
                  style: TextStyle(
                    color: MauSac.xam,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _updateUserProfile(user, nameController.text, soDienThoaiController.text, selectedImage);
                  imageAnimationController.dispose();
                  fieldsAnimationController.dispose();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MauSac.kfcRed,
                  foregroundColor: MauSac.trang,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Lưu'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPersonalInfoDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              content: Center(child: CircularProgressIndicator(color: MauSac.kfcRed)),
            );
          }

          Map<String, dynamic>? userData;
          if (snapshot.hasData && snapshot.data!.exists) {
            userData = snapshot.data!.data() as Map<String, dynamic>?;
          }

          print('userData in PersonalInfoDialog: $userData');
          print('user.phoneNumber: ${user.phoneNumber}');
          final displayName = userData?['displayName'] ?? user.displayName ?? 'Chưa cung cấp';
          final email = user.email ?? 'Chưa cung cấp';
          final soDienThoai = userData?['soDienThoai']  ?? 'Chưa cung cấp số điện thoại';
          final photoURL = userData?['photoURL'] ?? user.photoURL;

          final AnimationController imageAnimationController = AnimationController(
            duration: const Duration(milliseconds: 600),
            vsync: Navigator.of(context),
          );
          final AnimationController fieldsAnimationController = AnimationController(
            duration: const Duration(milliseconds: 800),
            vsync: Navigator.of(context),
          );

          final Animation<double> imageFadeAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: imageAnimationController,
            curve: Curves.easeOut,
          ));

          final Animation<double> imageScaleAnimation = Tween<double>(
            begin: 0.5,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: imageAnimationController,
            curve: Curves.elasticOut,
          ));

          final Animation<Offset> fieldsSlideAnimation = Tween<Offset>(
            begin: const Offset(0, 0.5),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: fieldsAnimationController,
            curve: Curves.easeOutBack,
          ));

          imageAnimationController.forward();
          fieldsAnimationController.forward();

          return AlertDialog(
            backgroundColor: MauSac.denNhat,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: MauSac.kfcRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person, color: MauSac.kfcRed, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Thông tin cá nhân',
                      style: TextStyle(
                        color: MauSac.trang,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: MauSac.kfcRed.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: MauSac.kfcRed, size: 20),
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditProfileDialog(user, userData);
                    },
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: imageFadeAnimation,
                    child: ScaleTransition(
                      scale: imageScaleAnimation,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: MauSac.xam.withOpacity(0.2),
                          border: Border.all(
                            color: MauSac.kfcRed.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: photoURL != null
                            ? ClipOval(
                                child: Image.network(
                                  photoURL,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.person,
                                    color: MauSac.kfcRed,
                                    size: 60,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                color: MauSac.kfcRed,
                                size: 60,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SlideTransition(
                    position: fieldsSlideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoField('Họ và tên', displayName),
                        const SizedBox(height: 16),
                        _buildInfoField('Email', email),
                        const SizedBox(height: 16),
                        _buildInfoField('Số điện thoại', soDienThoai),
                        const SizedBox(height: 16),
                        _buildInfoField('Mật khẩu', '******'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  imageAnimationController.dispose();
                  fieldsAnimationController.dispose();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MauSac.kfcRed,
                  foregroundColor: MauSac.trang,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Đóng'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: MauSac.xam.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: MauSac.xam.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: MauSac.xam.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: MauSac.trang,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateUserProfile(User user, String displayName, String soDienThoai, XFile? image) async {
  try {
    String? photoURL;

    if (image != null) {
      final storageRef = _storage.ref().child('user_photos/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = await storageRef.putFile(File(image.path));
      photoURL = await uploadTask.ref.getDownloadURL();
    }

    await user.updateDisplayName(displayName);
    if (photoURL != null) {
      await user.updatePhotoURL(photoURL);
    }
    await _firestore.collection('users').doc(user.uid).update({
  'phoneNumber': FieldValue.delete(), // Xóa trường phoneNumber
});
    final userDoc = {
      'displayName': displayName,
      'soDienThoai': soDienThoai.isNotEmpty ? soDienThoai : null,
      'email': user.email,
      'photoURL': photoURL ?? user.photoURL,
      'rule': context.read<NguoiDungProvider>().currentRole,
      'updatedAt': FieldValue.serverTimestamp(),
      // Loại bỏ phoneNumber nếu không cần thiết
    };
    print('Saving to Firestore: $userDoc');
    await _firestore.collection('users').doc(user.uid).set(userDoc, SetOptions(merge: true));
    print('Firestore updated successfully');

    context.read<NguoiDungProvider>().capNhatThongTin(
      ten: displayName,
      soDienThoai: soDienThoai,
    );

    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('Cập nhật thông tin thành công'),
          ],
        ),
        backgroundColor: MauSac.xanhLa,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );

    setState(() {});
  } catch (e) {
    print('Error updating profile: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text('Lỗi: ${e.toString()}'),
          ],
        ),
        backgroundColor: MauSac.kfcRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

  void _showSecurityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MauSac.denNhat,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: MauSac.kfcRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.security, color: MauSac.kfcRed, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Bảo mật tài khoản',
              style: TextStyle(
                color: MauSac.trang,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.lock_outline, color: MauSac.kfcRed),
              title: const Text(
                'Đổi mật khẩu',
                style: TextStyle(color: MauSac.trang),
              ),
              onTap: () {
                Navigator.pop(context);
                _resetPassword();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: MauSac.kfcRed),
              title: const Text(
                'Xóa tài khoản',
                style: TextStyle(color: MauSac.trang),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteAccountDialog();
              },
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: MauSac.kfcRed,
              foregroundColor: MauSac.trang,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPassword() async {
    final user = _auth.currentUser;
    if (user?.email != null) {
      try {
        await _auth.sendPasswordResetEmail(email: user!.email!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.email, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Email đặt lại mật khẩu đã được gửi'),
              ],
            ),
            backgroundColor: MauSac.xanhLa,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text('Lỗi: ${e.toString()}'),
              ],
            ),
            backgroundColor: MauSac.kfcRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MauSac.denNhat,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: MauSac.kfcRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning, color: MauSac.kfcRed, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Xóa tài khoản',
              style: TextStyle(
                color: MauSac.trang,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn xóa tài khoản? Hành động này không thể hoàn tác và tất cả dữ liệu sẽ bị mất.',
          style: TextStyle(
            color: MauSac.trang,
            fontSize: 16,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Hủy',
              style: TextStyle(
                color: MauSac.xam,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => _deleteAccount(),
            style: ElevatedButton.styleFrom(
              backgroundColor: MauSac.kfcRed,
              foregroundColor: MauSac.trang,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Xóa tài khoản'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).delete();
        
        try {
          await _storage.ref().child('user_photos/${user.uid}').listAll().then((value) {
            for (var item in value.items) {
              item.delete();
            }
          });
        } catch (_) {}
        
        await user.delete();
        
        context.read<NguoiDungProvider>().dangXuat();
        
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Tài khoản đã được xóa'),
              ],
            ),
            backgroundColor: MauSac.xanhLa,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text('Lỗi: ${e.toString()}'),
            ],
          ),
          backgroundColor: MauSac.kfcRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final AnimationController contentAnimationController = AnimationController(
          duration: const Duration(milliseconds: 800),
          vsync: Navigator.of(context),
        );
        final Animation<double> fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: contentAnimationController,
          curve: Curves.easeOut,
        ));
        final Animation<Offset> slideAnimation = Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: contentAnimationController,
          curve: Curves.easeOutBack,
        ));

        contentAnimationController.forward();

        return AlertDialog(
          backgroundColor: MauSac.denNhat,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MauSac.kfcRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.info, color: MauSac.kfcRed, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Về KFC Việt Nam',
                style: TextStyle(
                  color: MauSac.trang,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo or Icon
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: MauSac.kfcRed.withOpacity(0.1),
                          border: Border.all(
                            color: MauSac.kfcRed.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.fastfood,
                          color: MauSac.kfcRed,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // App Info
                    const Text(
                      'KFC Vietnam App',
                      style: TextStyle(
                        color: MauSac.trang,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Phiên bản: 1.0.0',
                      style: TextStyle(
                        color: MauSac.xam.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Ngày phát hành: 09/06/2025',
                      style: TextStyle(
                        color: MauSac.xam.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // About KFC
                    const Text(
                      'Giới thiệu về KFC',
                      style: TextStyle(
                        color: MauSac.trang,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'KFC (Kentucky Fried Chicken) là thương hiệu gà rán nổi tiếng toàn cầu, được thành lập bởi Đại tá Harland Sanders vào năm 1930 tại Kentucky, Hoa Kỳ. KFC Việt Nam bắt đầu hoạt động từ năm 1997 và hiện có hơn 140 nhà hàng trên toàn quốc.',
                      style: TextStyle(
                        color: MauSac.trang,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mission
                    const Text(
                      'Sứ mệnh',
                      style: TextStyle(
                        color: MauSac.trang,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mang đến những bữa ăn ngon, chất lượng cao với công thức 11 loại thảo mộc và gia vị bí mật, cùng dịch vụ thân thiện và nhanh chóng.',
                      style: TextStyle(
                        color: MauSac.trang,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Contact Info
                    const Text(
                      'Liên hệ',
                      style: TextStyle(
                        color: MauSac.trang,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hotline: 1900 6886\nEmail: support@kfcvietnam.com.vn\nWebsite: www.kfcvietnam.com.vn',
                      style: TextStyle(
                        color: MauSac.trang,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                contentAnimationController.dispose();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: MauSac.kfcRed,
                foregroundColor: MauSac.trang,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MauSac.denNhat,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: MauSac.kfcRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.logout, color: MauSac.kfcRed, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Đăng xuất',
              style: TextStyle(
                color: MauSac.trang,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?',
          style: TextStyle(
            color: MauSac.trang,
            fontSize: 16,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Hủy',
              style: TextStyle(
                color: MauSac.xam,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _auth.signOut();
              context.read<NguoiDungProvider>().dangXuat();
              Navigator.pop(context);
              
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManHinhDangNhap(),
                ),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MauSac.kfcRed,
              foregroundColor: MauSac.trang,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:kfc/theme/mau_sac.dart';
import 'package:kfc/models/nguoi_dung.dart';
import 'package:provider/provider.dart';
import 'package:kfc/providers/nguoi_dung_provider.dart';
import 'package:kfc/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class ManHinhDangKy extends StatefulWidget {
  const ManHinhDangKy({Key? key}) : super(key: key);

  @override
  State<ManHinhDangKy> createState() => _ManHinhDangKyState();
}

class _ManHinhDangKyState extends State<ManHinhDangKy>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _tenController = TextEditingController();
  final _emailController = TextEditingController();
  final _soDienThoaiController = TextEditingController();
  final _matKhauController = TextEditingController();
  final _xacNhanMatKhauController = TextEditingController();
  final _rule = "user"; // Mặc định là user
  bool _hienMatKhau = false;
  bool _dangXuLy = false;

  late AnimationController _animationController;
  late AnimationController _headerAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<Offset> _headerSlideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutBack,
    ));

    _headerAnimationController.forward();
    _animationController.forward();
  }

  @override
  void dispose() {
    _tenController.dispose();
    _emailController.dispose();
    _soDienThoaiController.dispose();
    _matKhauController.dispose();
    _xacNhanMatKhauController.dispose();
    _animationController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  // Kiểm tra kết nối internet
  Future<bool> _kiemTraKetNoiInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> _dangKy() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          _dangXuLy = true;
        });

        // Kiểm tra kết nối internet trước
        bool coInternet = await _kiemTraKetNoiInternet();
        if (!coInternet) {
          throw Exception('Không có kết nối internet');
        }

        print('Bắt đầu đăng ký với email: ${_emailController.text.trim()}');
        
        // Tạo tài khoản với Firebase Authentication
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _matKhauController.text,
        ).timeout(
          Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Timeout - Kết nối quá chậm');
          },
        );

        print('Đăng ký thành công! UID: ${userCredential.user?.uid}');

        // Cập nhật thông tin hiển thị của người dùng
        await userCredential.user?.updateDisplayName(_tenController.text.trim());
        print('Cập nhật tên hiển thị thành công');

        // Tạo đối tượng NguoiDung
        final nguoiDung = NguoiDung(
          id: userCredential.user!.uid,
          ten: _tenController.text.trim(),
          email: _emailController.text.trim(),
          soDienThoai: _soDienThoaiController.text.trim(),
          rule: _rule,
        );

        // Lưu thông tin vào Firestore Database
        await AuthService.createUserData(userCredential.user!.uid, nguoiDung);

        // Cập nhật Provider với thông tin từ Firebase
        final nguoiDungProvider = Provider.of<NguoiDungProvider>(context, listen: false);
        nguoiDungProvider.dangNhap(nguoiDung);

        // Hiển thị thông báo thành công
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Đăng ký thành công!'),
                ],
              ),
              backgroundColor: MauSac.xanhLa,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );

          // Điều hướng dựa trên quyền
          String route = AuthService.getNavigationRoute(nguoiDung.rule);
          
          // Quay về màn hình chính và xóa tất cả màn hình trước đó
          Navigator.pushNamedAndRemoveUntil(
            context,
            route,
            (route) => false,
          );
        }
      } on FirebaseAuthException catch (e) {
        print('FirebaseAuthException: ${e.code} - ${e.message}');
        
        String thongBaoLoi = 'Đã xảy ra lỗi khi đăng ký.';
        
        switch (e.code) {
          case 'weak-password':
            thongBaoLoi = 'Mật khẩu quá yếu.';
            break;
          case 'email-already-in-use':
            thongBaoLoi = 'Email này đã được sử dụng.';
            break;
          case 'invalid-email':
            thongBaoLoi = 'Email không hợp lệ.';
            break;
          case 'operation-not-allowed':
            thongBaoLoi = 'Đăng ký bằng email/password chưa được bật trong Firebase.';
            break;
          case 'network-request-failed':
            thongBaoLoi = 'Lỗi kết nối mạng. Vui lòng kiểm tra internet.';
            break;
          default:
            thongBaoLoi = 'Lỗi: ${e.message ?? e.code}';
        }
        
        _hienThiLoi(thongBaoLoi);
      } on FirebaseException catch (e) {
        print('FirebaseException: ${e.code} - ${e.message}');
        _hienThiLoi('Lỗi khi lưu thông tin: ${e.message}');
      } on SocketException catch (e) {
        print('SocketException: $e');
        _hienThiLoi('Lỗi kết nối mạng. Vui lòng kiểm tra internet.');
      } catch (e) {
        print('Lỗi khác: $e');
        if (e.toString().contains('Timeout') || e.toString().contains('timeout')) {
          _hienThiLoi('Kết nối quá chậm. Vui lòng thử lại.');
        } else if (e.toString().contains('internet') || e.toString().contains('network')) {
          _hienThiLoi('Lỗi kết nối mạng. Vui lòng kiểm tra internet.');
        } else {
          _hienThiLoi('Lỗi không xác định: ${e.toString()}');
        }
      } finally {
        if (mounted) {
          setState(() {
            _dangXuLy = false;
          });
        }
      }
    }
  }

  void _hienThiLoi(String thongBao) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(thongBao)),
            ],
          ),
          backgroundColor: MauSac.kfcRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Thử lại',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MauSac.denNen,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Header
                  _buildHeader(),
                  
                  const SizedBox(height: 32),
                  
                  // Form đăng ký
                  _buildSignUpForm(),
                  
                  const SizedBox(height: 32),
                  
                  // Nút đăng ký
                  _buildSignUpButton(),
                  
                  const SizedBox(height: 24),
                  
                  // Đăng nhập
                  _buildLoginSection(),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SlideTransition(
      position: _headerSlideAnimation,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: MauSac.denNhat,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MauSac.kfcRed.withOpacity(0.2)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: MauSac.trang),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Spacer(),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      MauSac.kfcRed,
                      MauSac.kfcRed.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: MauSac.kfcRed.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_add,
                  size: 30,
                  color: MauSac.trang,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 48), // Balance the back button
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Tạo tài khoản mới',
            style: TextStyle(
              color: MauSac.trang,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Điền thông tin để bắt đầu hành trình ẩm thực',
            style: TextStyle(
              color: MauSac.xam.withOpacity(0.8),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpForm() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Column(
              children: [
                _buildTextField(
                  controller: _tenController,
                  label: 'Họ và tên',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập họ và tên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _soDienThoaiController,
                  label: 'Số điện thoại',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập số điện thoại';
                    }
                    if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                      return 'Số điện thoại không hợp lệ (10 số)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildPasswordField(
                  controller: _matKhauController,
                  label: 'Mật khẩu',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    if (value.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildPasswordField(
                  controller: _xacNhanMatKhauController,
                  label: 'Xác nhận mật khẩu',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng xác nhận mật khẩu';
                    }
                    if (value != _matKhauController.text) {
                      return 'Mật khẩu không khớp';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: MauSac.trang, fontSize: 16),
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: MauSac.xam.withOpacity(0.8)),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MauSac.kfcRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: MauSac.kfcRed, size: 20),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: MauSac.xamDam.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(16),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: MauSac.kfcRed, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: MauSac.kfcRed),
            borderRadius: BorderRadius.circular(16),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: MauSac.kfcRed, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          filled: true,
          fillColor: MauSac.denNhat,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: MauSac.trang, fontSize: 16),
        obscureText: !_hienMatKhau,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: MauSac.xam.withOpacity(0.8)),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MauSac.kfcRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.lock_outline, color: MauSac.kfcRed, size: 20),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _hienMatKhau ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: MauSac.xam,
            ),
            onPressed: () {
              setState(() {
                _hienMatKhau = !_hienMatKhau;
              });
            },
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: MauSac.xamDam.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(16),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: MauSac.kfcRed, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: MauSac.kfcRed),
            borderRadius: BorderRadius.circular(16),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: MauSac.kfcRed, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          filled: true,
          fillColor: MauSac.denNhat,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildSignUpButton() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: MauSac.kfcRed.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _dangXuLy ? null : _dangKy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MauSac.kfcRed,
                  foregroundColor: MauSac.trang,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: MauSac.kfcRed.withOpacity(0.5),
                ),
                child: _dangXuLy
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: MauSac.trang,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Tạo tài khoản',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginSection() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: MauSac.denNhat,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: MauSac.kfcRed.withOpacity(0.1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Đã có tài khoản? ',
                    style: TextStyle(
                      color: MauSac.xam.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                  TextButton(
                    onPressed: _dangXuLy ? null : () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Đăng nhập',
                      style: TextStyle(
                        color: MauSac.kfcRed,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kfc/providers/nguoi_dung_provider.dart';
import 'package:kfc/providers/gio_hang_provider.dart';
import 'package:kfc/providers/danh_muc_provider.dart';
import 'package:kfc/providers/san_pham_provider.dart';
import 'package:kfc/providers/tim_kiem_provider.dart';
import 'package:kfc/providers/yeu_thich_provider.dart';
import 'package:kfc/providers/don_hang_provider.dart';
import 'package:kfc/providers/notification_provider.dart';
import 'package:kfc/screens/splash_wrapper.dart';
import 'package:kfc/screens/man_hinh_trang_chu.dart';
import 'package:kfc/screens/admin/man_hinh_admin.dart';
import 'package:kfc/screens/man_hinh_dang_nhap.dart';
import 'package:kfc/screens/man_hinh_dang_ky.dart';
import 'package:kfc/screens/man_hinh_chi_tiet_san_pham.dart';
import 'package:kfc/screens/man_hinh_tim_kiem.dart';
import 'package:kfc/screens/man_hinh_yeu_thich.dart';
import 'package:kfc/screens/man_hinh_gio_hang.dart';
import 'package:kfc/screens/man_hinh_tai_khoan.dart';
import 'package:kfc/screens/man_hinh_danh_muc.dart';
import 'package:kfc/screens/man_hinh_thong_bao.dart';
import 'package:kfc/screens/navigation_wrapper.dart';
import 'package:kfc/services/auth_service.dart';
import 'package:kfc/services/notification_service.dart';
import 'package:kfc/theme/mau_sac.dart';
import 'package:kfc/screens/man_hinh_don_hang.dart';
import '../firebase_options.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Cố định hướng màn hình là dọc
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Thiết lập màu cho status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: MauSac.denNhat,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Khởi tạo Notification Service
  await NotificationService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NguoiDungProvider()),
        ChangeNotifierProvider(create: (_) => DanhMucProvider()),
        ChangeNotifierProvider(create: (_) => SanPhamProvider()),
        ChangeNotifierProvider(create: (_) => TimKiemProvider()),
        ChangeNotifierProvider(create: (_) => GioHangProvider()),
        ChangeNotifierProvider(create: (_) => YeuThichProvider()),
        ChangeNotifierProvider(create: (_) => DonHangProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'KFC Vietnam',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.red,
          scaffoldBackgroundColor: MauSac.denNen,
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            backgroundColor: MauSac.denNen,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: MauSac.trang,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            iconTheme: IconThemeData(
              color: MauSac.trang,
            ),
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: MauSac.trang),
            bodyMedium: TextStyle(color: MauSac.trang),
            bodySmall: TextStyle(color: MauSac.xam),
            titleLarge: TextStyle(color: MauSac.trang, fontWeight: FontWeight.bold),
            titleMedium: TextStyle(color: MauSac.trang, fontWeight: FontWeight.bold),
            titleSmall: TextStyle(color: MauSac.trang, fontWeight: FontWeight.bold),
          ),
          colorScheme: ColorScheme.fromSwatch().copyWith(
            primary: MauSac.kfcRed,
            secondary: MauSac.vang,
            background: MauSac.denNen,
            surface: MauSac.denNhat,
          ),
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const ManHinhDangNhap(),
          '/register': (context) => const ManHinhDangKy(),
          '/home': (context) => const NavigationWrapper(),
          '/admin': (context) => const ManHinhAdmin(),
          '/search': (context) => const ManHinhTimKiem(),
          '/favorites': (context) => const ManHinhYeuThich(),
          '/cart': (context) => const ManHinhGioHang(),
          '/account': (context) => const ManHinhTaiKhoan(),
          '/don-hang': (context) => const ManHinhDonHang(),
          '/notifications': (context) => const ManHinhThongBao(),
        },
        onGenerateRoute: (settings) {
          // Xử lý route cho chi tiết sản phẩm
          if (settings.name == '/product-detail') {
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => ManHinhChiTietSanPham(
                sanPhamId: args?['sanPhamId'] ?? '',
                sanPhamBanDau: args?['sanPham'],
              ),
            );
          }
          
          // Xử lý route cho danh mục
          if (settings.name == '/category') {
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => ManHinhDanhMuc(
                danhMuc: args?['danhMuc'],
              ),
            );
          }
          
          return null;
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      // Lắng nghe thay đổi trạng thái authentication
      FirebaseAuth.instance.authStateChanges().listen((User? user) async {
        if (mounted) {
          if (user != null) {
            await _handleUserLogin(user);
          } else {
            await _handleUserLogout();
          }
        }
      });
    } catch (e) {
      print('Lỗi khi kiểm tra trạng thái auth: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi kết nối. Vui lòng thử lại.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleUserLogin(User user) async {
    try {
      print('User đã đăng nhập: ${user.uid}');
      
      // Lấy thông tin người dùng từ Firestore
      final userData = await AuthService.getUserData(user.uid);
      
      if (userData != null) {
        // Cập nhật Provider
        final nguoiDungProvider = Provider.of<NguoiDungProvider>(context, listen: false);
        nguoiDungProvider.dangNhap(userData);
        
        // Khởi tạo NotificationProvider
        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
        notificationProvider.initialize();
        
        // Điều hướng dựa trên quyền
        String route = AuthService.getNavigationRoute(userData.rule);
        
        print('Điều hướng đến: $route với quyền: ${userData.rule}');
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          // Điều hướng đến trang phù hợp
          Navigator.pushReplacementNamed(context, route);
        }
      } else {
        // Không tìm thấy thông tin user trong Firestore
        print('Không tìm thấy thông tin user trong Firestore');
        await _handleUserLogout();
      }
    } catch (e) {
      print('Lỗi khi xử lý đăng nhập: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi khi tải thông tin người dùng.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleUserLogout() async {
    try {
      // Cập nhật Provider
      final nguoiDungProvider = Provider.of<NguoiDungProvider>(context, listen: false);
      nguoiDungProvider.dangXuat();
      
      // Reset NotificationProvider
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      notificationProvider.reset();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Điều hướng đến màn hình đăng nhập
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('Lỗi khi xử lý đăng xuất: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi khi đăng xuất.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SplashWrapper();
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: MauSac.denNen,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: MauSac.kfcRed,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: MauSac.trang,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _isLoading = true;
                  });
                  _checkAuthState();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MauSac.kfcRed,
                  foregroundColor: MauSac.trang,
                ),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return const ManHinhDangNhap();
  }
}
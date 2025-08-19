import 'package:flutter/material.dart';
import 'package:kfc/theme/mau_sac.dart';
import 'package:kfc/models/san_pham.dart';
import 'package:kfc/models/san_pham_gio_hang.dart';
import 'package:kfc/providers/gio_hang_provider.dart';
import 'package:kfc/screens/man_hinh_chi_tiet_san_pham.dart';
import 'package:provider/provider.dart';
import 'package:kfc/providers/nguoi_dung_provider.dart';
import 'package:kfc/providers/don_hang_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ManHinhGioHang extends StatefulWidget {
  const ManHinhGioHang({Key? key}) : super(key: key);

  @override
  State<ManHinhGioHang> createState() => _ManHinhGioHangState();
}

class _ManHinhGioHangState extends State<ManHinhGioHang> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _headerAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _tenController = TextEditingController();
  final _sdtController = TextEditingController();
  final _diaChiController = TextEditingController();
  final _ghiChuController = TextEditingController();
  String? _phuongThucThanhToan = 'Khi nhận hàng';
  bool _isLoading = false;

  // VNPay Configuration (from Config.java)
  static const String vnpPayUrl = "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html";
  static const String vnpReturnUrl = "myapp://success-vnpay"; // Use a custom scheme
  static const String vnpTmnCode = "U5GZCPNQ";
  static const String secretKey = "PZLKWTG6AB8N3OP1GBCV1398AYRE3207";
  static const String vnpApiUrl = "https://sandbox.vnpayment.vn/merchant_webapi/api/transaction";

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
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
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nguoiDungProvider = Provider.of<NguoiDungProvider>(context, listen: false);
      if (nguoiDungProvider.currentUser != null) {
        _tenController.text = nguoiDungProvider.currentUser!.ten;
        _sdtController.text = nguoiDungProvider.currentUser!.soDienThoai ?? '';
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _headerAnimationController.dispose();
    _tenController.dispose();
    _sdtController.dispose();
    _diaChiController.dispose();
    _ghiChuController.dispose();
    super.dispose();
  }

  String _getImagePath(String hinhAnh) {
    if (hinhAnh.isEmpty) return '';
    if (hinhAnh.startsWith('assets/')) return hinhAnh;
    return 'assets/images/$hinhAnh';
  }

  String _formatCurrency(int amount) {
    return '${amount.toString()} ₫';
  }

  Widget _buildImageFromAssets(String imagePath, {double? height, BoxFit? fit}) {
    final fullPath = _getImagePath(imagePath);
    
    if (fullPath.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MauSac.kfcRed.withOpacity(0.8),
              MauSac.kfcRed.withOpacity(0.6),
            ],
          ),
        ),
        child: const Center(
          child: Icon(Icons.fastfood, size: 30, color: Colors.white),
        ),
      );
    }

    return Image.asset(
      fullPath,
      height: height,
      width: double.infinity,
      fit: fit ?? BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                MauSac.kfcRed.withOpacity(0.8),
                MauSac.kfcRed.withOpacity(0.6),
              ],
            ),
          ),
          child: const Center(
            child: Icon(Icons.image_not_supported, size: 30, color: Colors.white),
          ),
        );
      },
    );
  }

  // VNPay Utility Functions (from Config.java)
  String hmacSHA512(String key, String data) {
    try {
      final keyBytes = utf8.encode(key);
      final dataBytes = utf8.encode(data);
      final hmacSha512 = Hmac(sha512, keyBytes);
      final digest = hmacSha512.convert(dataBytes);
      return digest.toString();
    } catch (e) {
      return "";
    }
  }

  String generatePaymentUrl({
    required String orderId,
    required double amount,
    required String ipAddress,
    String bankCode = "",
    String locale = "vn",
  }) {
    final vnpParams = <String, String>{
      "vnp_Version": "2.1.0",
      "vnp_Command": "pay",
      "vnp_TmnCode": vnpTmnCode,
      "vnp_Amount": ((amount * 100).toInt()).toString(),
      "vnp_CurrCode": "VND",
      "vnp_TxnRef": orderId,
      "vnp_OrderInfo": "Thanh toan don hang: $orderId",
      "vnp_OrderType": "other",
      "vnp_Locale": locale,
      "vnp_ReturnUrl": vnpReturnUrl,
      "vnp_IpAddr": ipAddress,
      "vnp_CreateDate": DateFormat('yyyyMMddHHmmss').format(DateTime.now().toUtc().add(Duration(hours: 7))),
      "vnp_ExpireDate": DateFormat('yyyyMMddHHmmss').format(DateTime.now().toUtc().add(Duration(hours: 7, minutes: 15))),
    };

    if (bankCode.isNotEmpty) {
      vnpParams["vnp_BankCode"] = bankCode;
    }

    final sortedKeys = vnpParams.keys.toList()..sort();
    final hashData = StringBuffer();
    final query = StringBuffer();
    for (var key in sortedKeys) {
      final value = vnpParams[key];
      if (value != null && value.isNotEmpty) {
        hashData.write('$key=${Uri.encodeQueryComponent(value)}');
        query.write('${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value)}');
        if (key != sortedKeys.last) {
          hashData.write('&');
          query.write('&');
        }
      }
    }

    final vnpSecureHash = hmacSHA512(secretKey, hashData.toString());
    query.write('&vnp_SecureHash=$vnpSecureHash');

    return "$vnpPayUrl?$query";
  }

  Future<String> getIpAddress() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org'));
      if (response.statusCode == 200) {
        return response.body;
      }
      return "127.0.0.1";
    } catch (e) {
      return "127.0.0.1";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MauSac.denNen,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: MauSac.denNhat,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildHeaderTitle()),
                _buildClearAllButton(),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatsRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Giỏ hàng',
          style: TextStyle(
            color: MauSac.trang,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Kiểm tra và đặt hàng',
          style: TextStyle(
            color: MauSac.xam.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildClearAllButton() {
    return Consumer<GioHangProvider>(
      builder: (context, gioHangProvider, child) {
        if (gioHangProvider.danhSachSanPham.isEmpty) {
          return const SizedBox.shrink();
        }
        return Container(
          decoration: BoxDecoration(
            color: MauSac.kfcRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MauSac.kfcRed.withOpacity(0.3)),
          ),
          child: IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: MauSac.kfcRed, size: 22),
            onPressed: () => _showClearAllDialog(),
            padding: const EdgeInsets.all(12),
            tooltip: 'Xóa tất cả',
          ),
        );
      },
    );
  }

  Widget _buildStatsRow() {
    return Consumer<GioHangProvider>(
      builder: (context, gioHangProvider, child) {
        final tongSoLuong = gioHangProvider.tongSoLuong;
        final tongTien = gioHangProvider.tongTien;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: MauSac.denNen,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MauSac.kfcRed.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MauSac.kfcRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shopping_cart,
                  color: MauSac.kfcRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$tongSoLuong món ăn',
                      style: const TextStyle(
                        color: MauSac.trang,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      tongSoLuong > 0 ? 'Tổng: ${_formatCurrency(tongTien.round())}' : 'Giỏ hàng trống',
                      style: TextStyle(
                        color: MauSac.xam.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (tongSoLuong > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: MauSac.kfcRed,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$tongSoLuong',
                    style: const TextStyle(
                      color: MauSac.trang,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    return Consumer<GioHangProvider>(
      builder: (context, gioHangProvider, child) {
        final danhSachSanPham = gioHangProvider.danhSachSanPham;

        if (danhSachSanPham.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildCartList(gioHangProvider),
              ),
            ),
            _buildBottomSection(gioHangProvider),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
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
                      Icons.shopping_cart_outlined,
                      size: 70,
                      color: MauSac.kfcRed,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Giỏ hàng trống',
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
              'Hãy thêm những món ăn yêu thích\nvào giỏ hàng để bắt đầu đặt hàng',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MauSac.xam.withOpacity(0.8),
                fontSize: 16,
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartList(GioHangProvider gioHangProvider) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: gioHangProvider.danhSachSanPham.length,
      itemBuilder: (context, index) {
        final sanPhamGioHang = gioHangProvider.danhSachSanPham[index];
        
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: _buildCartItem(sanPhamGioHang, gioHangProvider, index),
        );
      },
    );
  }

  Widget _buildCartItem(SanPhamGioHang sanPhamGioHang, GioHangProvider gioHangProvider, int index) {
    final sanPham = sanPhamGioHang.sanPham;
    final soLuong = sanPhamGioHang.soLuong;
    final giaGoc = sanPham.gia;
    final giaSauGiam = sanPham.khuyenMai == true && 
        sanPham.giamGia != null && 
        sanPham.giamGia! > 0
        ? (giaGoc * (100 - sanPham.giamGia!) / 100)
        : giaGoc;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: MauSac.denNhat,
        borderRadius: BorderRadius.circular(20),
        border: Border.fromBorderSide(
          BorderSide(color: MauSac.kfcRed.withOpacity(0.3)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManHinhChiTietSanPham(
                      sanPhamId: sanPham.id,
                      sanPhamBanDau: sanPham,
                    ),
                  ),
                );
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: MauSac.kfcRed.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _buildImageFromAssets(sanPham.hinhAnh, height: 80),
                    ),
                    if (sanPham.khuyenMai == true && 
                        sanPham.giamGia != null && 
                        sanPham.giamGia! > 0)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: MauSac.kfcRed,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-${sanPham.giamGia}%',
                            style: const TextStyle(
                              color: MauSac.trang,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sanPham.ten,
                    style: const TextStyle(
                      color: MauSac.trang,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Text(
                        _formatCurrency(giaSauGiam.round()),
                        style: const TextStyle(
                          color: MauSac.kfcRed,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (sanPham.khuyenMai == true && 
                          sanPham.giamGia != null && 
                          sanPham.giamGia! > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          _formatCurrency(giaGoc.round()),
                          style: TextStyle(
                            color: MauSac.xam.withOpacity(0.7),
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: MauSac.denNen,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: MauSac.kfcRed.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, color: MauSac.kfcRed, size: 18),
                              onPressed: () {
                                if (soLuong > 1) {
                                  gioHangProvider.giamSoLuong(sanPham.id);
                                } else {
                                  _showRemoveItemDialog(sanPham, gioHangProvider);
                                }
                              },
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '$soLuong',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: MauSac.trang,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, color: MauSac.kfcRed, size: 18),
                              onPressed: () => gioHangProvider.tangSoLuong(sanPham.id),
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                          ],
                        ),
                      ),
                      
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: MauSac.kfcRed, size: 20),
                        onPressed: () => _showRemoveItemDialog(sanPham, gioHangProvider),
                        padding: const EdgeInsets.all(8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection(GioHangProvider gioHangProvider) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: MauSac.denNhat,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildOrderSummary(gioHangProvider),
              
              const SizedBox(height: 20),
              
              _buildCheckoutButton(gioHangProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(GioHangProvider gioHangProvider) {
    final tongTien = gioHangProvider.tongTien.round();
    final phiGiaoHang = 15000;
    final tongCong = tongTien + phiGiaoHang;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MauSac.denNen,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MauSac.kfcRed.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MauSac.kfcRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt_long, color: MauSac.kfcRed, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tóm tắt đơn hàng',
                style: TextStyle(
                  color: MauSac.trang,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildSummaryRow('Tạm tính', _formatCurrency(tongTien)),
          const SizedBox(height: 8),
          _buildSummaryRow('Phí giao hàng', _formatCurrency(phiGiaoHang)),
          
          const SizedBox(height: 12),
          Container(height: 1, color: MauSac.xam.withOpacity(0.3)),
          const SizedBox(height: 12),
          
          _buildSummaryRow(
            'Tổng cộng', 
            _formatCurrency(tongCong),
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? MauSac.trang : MauSac.xam.withOpacity(0.8),
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? MauSac.kfcRed : MauSac.trang,
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutButton(GioHangProvider gioHangProvider) {
    final tongCong = gioHangProvider.tongTien.round() + 15000;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () => _datHang(gioHangProvider),
        icon: const Icon(Icons.payment, size: 20),
        label: Text(
          'Đặt hàng (${_formatCurrency(tongCong)})',
          style: const TextStyle(
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
    );
  }

  void _showRemoveItemDialog(SanPham sanPham, GioHangProvider gioHangProvider) {
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
              child: const Icon(Icons.delete_outline, color: MauSac.kfcRed, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Xóa sản phẩm',
                style: TextStyle(
                  color: MauSac.trang,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa "${sanPham.ten}" khỏi giỏ hàng?',
          style: const TextStyle(
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
            onPressed: () {
              gioHangProvider.xoaSanPham(sanPham.id);
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('Đã xóa ${sanPham.ten} khỏi giỏ hàng'),
                      ),
                    ],
                  ),
                  backgroundColor: MauSac.xanhLa,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MauSac.kfcRed,
              foregroundColor: MauSac.trang,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Xóa',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog() {
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
              child: const Icon(Icons.warning_amber, color: MauSac.kfcRed, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Xóa tất cả',
                style: TextStyle(
                  color: MauSac.trang,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn xóa tất cả sản phẩm khỏi giỏ hàng?',
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
            onPressed: () {
              final gioHangProvider = Provider.of<GioHangProvider>(context, listen: false);
              gioHangProvider.xoaGioHang();
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.delete_sweep, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Text('Đã xóa tất cả sản phẩm khỏi giỏ hàng'),
                    ],
                  ),
                  backgroundColor: MauSac.kfcRed,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MauSac.kfcRed,
              foregroundColor: MauSac.trang,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Xóa tất cả',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _datHang(GioHangProvider gioHangProvider) {
    final nguoiDungProvider = Provider.of<NguoiDungProvider>(context, listen: false);
    
    if (nguoiDungProvider.currentUser == null) {
      _showLoginDialog();
      return;
    }
    
    if (gioHangProvider.danhSachSanPham.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giỏ hàng của bạn đang trống'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    _showCheckoutBottomSheet(gioHangProvider);
  }
  
  void _showLoginDialog() {
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
              child: const Icon(Icons.login, color: MauSac.kfcRed, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Yêu cầu đăng nhập',
                style: TextStyle(
                  color: MauSac.trang,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Bạn cần đăng nhập để có thể đặt hàng.',
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
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/dang-nhap');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MauSac.kfcRed,
              foregroundColor: MauSac.trang,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Đăng nhập',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showCheckoutBottomSheet(GioHangProvider gioHangProvider) {
    final nguoiDungProvider = Provider.of<NguoiDungProvider>(context, listen: false);
    
    if (nguoiDungProvider.currentUser != null) {
      _tenController.text = nguoiDungProvider.currentUser!.ten;
      _sdtController.text = nguoiDungProvider.currentUser!.soDienThoai ?? '';
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: MauSac.denNhat,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: MauSac.denNhat,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: MauSac.xam.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: MauSac.kfcRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delivery_dining, color: MauSac.kfcRed, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Thông tin giao hàng',
                            style: TextStyle(
                              color: MauSac.trang,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _tenController,
                          label: 'Họ tên người nhận',
                          icon: Icons.person,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập họ tên';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _sdtController,
                          label: 'Số điện thoại',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập số điện thoại';
                            }
                            if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                              return 'Số điện thoại không hợp lệ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _diaChiController,
                          label: 'Địa chỉ giao hàng',
                          icon: Icons.location_on,
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập địa chỉ giao hàng';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _ghiChuController,
                          label: 'Ghi chú (tùy chọn)',
                          icon: Icons.note,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _phuongThucThanhToan,
                          decoration: InputDecoration(
                            labelText: 'Phương thức thanh toán',
                            labelStyle: TextStyle(color: MauSac.xam.withOpacity(0.8)),
                            prefixIcon: const Icon(Icons.payment, color: MauSac.kfcRed),
                            filled: true,
                            fillColor: MauSac.denNen,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: MauSac.xam.withOpacity(0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: MauSac.xam.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: MauSac.kfcRed),
                            ),
                          ),
                          dropdownColor: MauSac.denNhat,
                          style: const TextStyle(color: MauSac.trang),
                          items: const [
                            DropdownMenuItem(value: 'Khi nhận hàng', child: Text('Khi nhận hàng')),
                            DropdownMenuItem(value: 'Trực tuyến', child: Text('Trực tuyến (VNPay)')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _phuongThucThanhToan = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng chọn phương thức thanh toán';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        if (_phuongThucThanhToan == 'Khi nhận hàng')
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: MauSac.xanhLa.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: MauSac.xanhLa.withOpacity(0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle, color: MauSac.xanhLa, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Đã chọn thanh toán khi nhận hàng',
                                    style: TextStyle(color: MauSac.trang, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_phuongThucThanhToan == 'Trực tuyến')
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: MauSac.denNen,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: MauSac.kfcRed.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Thanh toán qua VNPay',
                                  style: TextStyle(
                                    color: MauSac.trang,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Bạn sẽ được chuyển đến cổng thanh toán VNPay để hoàn tất giao dịch.',
                                  style: TextStyle(
                                    color: MauSac.xam,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),
                        
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: MauSac.denNen,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: MauSac.kfcRed.withOpacity(0.2)),
                          ),
                          child: Column(
                            children: [
                              _buildSummaryRow('Tạm tính', _formatCurrency(gioHangProvider.tongTien.round())),
                              const SizedBox(height: 8),
                              _buildSummaryRow('Phí giao hàng', _formatCurrency(15000)),
                              const SizedBox(height: 12),
                              Container(height: 1, color: MauSac.xam.withOpacity(0.3)),
                              const SizedBox(height: 12),
                              _buildSummaryRow(
                                'Tổng cộng', 
                                _formatCurrency(gioHangProvider.tongTien.round() + 15000),
                                isTotal: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: MauSac.denNhat,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MauSac.xam.withOpacity(0.2),
                          foregroundColor: MauSac.trang,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          'Hủy',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _processOrder(gioHangProvider, setState),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MauSac.kfcRed,
                          foregroundColor: MauSac.trang,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Xác nhận đặt hàng',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: MauSac.trang),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: MauSac.xam.withOpacity(0.8)),
        prefixIcon: Icon(icon, color: MauSac.kfcRed),
        filled: true,
        fillColor: MauSac.denNen,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MauSac.xam.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MauSac.xam.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MauSac.kfcRed),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
  
 Future<void> _processOrder(GioHangProvider gioHangProvider, StateSetter setState) async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    final nguoiDungProvider = Provider.of<NguoiDungProvider>(context, listen: false);
    final donHangProvider = Provider.of<DonHangProvider>(context, listen: false);

    print('Processing order: Starting createDonHang');
    final orderId = await donHangProvider.createDonHang(
      nguoiDungId: nguoiDungProvider.currentUser!.id,
      tenNguoiNhan: _tenController.text,
      soDienThoai: _sdtController.text,
      diaChi: _diaChiController.text,
      danhSachSanPham: gioHangProvider.danhSachSanPham,
      tongTien: gioHangProvider.tongTien,
      phiGiaoHang: 15000.0,
      ghiChu: _ghiChuController.text.isNotEmpty ? _ghiChuController.text : null,
      phuongThucThanhToan: _phuongThucThanhToan,
    );

    print('Processing order: Order ID = $orderId');

    if (orderId == null) {
      throw Exception(donHangProvider.error ?? 'Đã xảy ra lỗi khi tạo đơn hàng');
    }

    if (_phuongThucThanhToan == 'Trực tuyến') {
      final ipAddress = await getIpAddress();
      final paymentUrl = generatePaymentUrl(
        orderId: orderId,
        amount: gioHangProvider.tongTien + 15000,
        ipAddress: ipAddress,
      );

      print('Payment URL: $paymentUrl');

      final paymentSuccess = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VNPayWebView(
            paymentUrl: paymentUrl,
            orderId: orderId,
          ),
        ),
      );

      print('Payment result: $paymentSuccess');

      if (paymentSuccess == true && mounted) {
        print('Payment successful, showing success dialog');
        gioHangProvider.xoaGioHang();
        Navigator.pop(context); // Đóng bottom sheet
        _showSuccessDialog(orderId);
      } else {
        print('Payment failed or cancelled');
        throw Exception('Thanh toán không thành công hoặc bị hủy');
      }
    } else {
      gioHangProvider.xoaGioHang();
      Navigator.pop(context); // Đóng bottom sheet
      _showSuccessDialog(orderId);
    }
  } catch (e, stackTrace) {
    print('Error processing order: $e\n$stackTrace');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xảy ra lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
  
  void _showSuccessDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: MauSac.denNhat,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: MauSac.xanhLa.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check_circle, color: MauSac.xanhLa, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Đặt hàng thành công!',
                style: TextStyle(
                  color: MauSac.trang,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mã đơn hàng: $orderId',
              style: const TextStyle(
                color: MauSac.kfcRed,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cảm ơn bạn đã đặt hàng! Chúng tôi sẽ liên hệ với bạn sớm nhất có thể.',
              style: TextStyle(
                color: MauSac.trang,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: const Text(
              'Tiếp tục mua sắm',
              style: TextStyle(
                color: MauSac.xam,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/don-hang');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MauSac.kfcRed,
              foregroundColor: MauSac.trang,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Xem đơn hàng',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class VNPayWebView extends StatefulWidget {
  final String paymentUrl;
  final String orderId;

  const VNPayWebView({Key? key, required this.paymentUrl, required this.orderId}) : super(key: key);

  @override
  _VNPayWebViewState createState() => _VNPayWebViewState();
}

class _VNPayWebViewState extends State<VNPayWebView> {
  late WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('WebView: Page started - $url');
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            print('WebView: Page finished - $url');
            setState(() => _isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            print('WebView: Navigation request - ${request.url}');
            if (request.url.startsWith(_ManHinhGioHangState.vnpReturnUrl)) {
              _handlePaymentResponse(request.url);
              return NavigationDecision.prevent;
            }
            if (request.url.contains('vnpay.vn') || request.url.contains('sandbox.vnpayment.vn')) {
              return NavigationDecision.navigate;
            }
            if (request.url.startsWith('myapp://')) {
              _handlePaymentResponse(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView: Error - ${error.description}');
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi tải trang VNPay: ${error.description}'),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _handlePaymentResponse(String url) async {
  print('Handling payment response: $url');
  try {
    final uri = Uri.parse(url);
    final params = uri.queryParameters;

    if (!params.containsKey('vnp_SecureHash') || !params.containsKey('vnp_ResponseCode')) {
      throw Exception('Thiếu tham số vnp_SecureHash hoặc vnp_ResponseCode');
    }

    final vnpSecureHash = params['vnp_SecureHash']!;
    final responseCode = params['vnp_ResponseCode']!;
    final paramsForHash = Map<String, String>.from(params)
      ..remove('vnp_SecureHash')
      ..remove('vnp_SecureHashType');

    final sortedKeys = paramsForHash.keys.toList()..sort();
    final hashData = sortedKeys.map((key) => '$key=${Uri.encodeQueryComponent(paramsForHash[key]!)}').join('&');
    final calculatedHash = _ManHinhGioHangState().hmacSHA512(_ManHinhGioHangState.secretKey, hashData);

    print('Hash data: $hashData');
    print('Calculated hash: $calculatedHash');
    print('Received hash: $vnpSecureHash');
    print('Response code: $responseCode');

    final donHangProvider = Provider.of<DonHangProvider>(context, listen: false);

    if (calculatedHash == vnpSecureHash) {
      if (responseCode == '00') {
        print('Payment successful, updating order status');
        await donHangProvider.updateOrderStatus(widget.orderId, 2); // Success
        await donHangProvider.updatePaymentStatus(widget.orderId, 1); // Paid
        if (mounted) {
          print('Navigating back with success');
          Navigator.pop(context, true); // Thoát VNPayWebView
        }
      } else {
        print('Payment failed with response code: $responseCode');
        await donHangProvider.updateOrderStatus(widget.orderId, 1); // Pending/Failed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Thanh toán thất bại: Mã lỗi $responseCode'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context, false);
        }
      }
    } else {
      print('Hash validation failed: Calculated=$calculatedHash, Received=$vnpSecureHash');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi xác thực thanh toán: Hash không khớp'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context, false);
      }
    }
  } catch (e, stackTrace) {
    print('Error handling payment response: $e\n$stackTrace');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xử lý thanh toán: $e'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context, false);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán VNPay'),
        backgroundColor: MauSac.kfcRed,
        foregroundColor: MauSac.trang,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context, false);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
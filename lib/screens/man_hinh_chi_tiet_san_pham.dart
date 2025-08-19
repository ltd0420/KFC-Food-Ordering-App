import 'package:flutter/material.dart';
import 'package:kfc/models/san_pham.dart';
import 'package:kfc/services/firebase_service.dart';
import 'package:kfc/theme/mau_sac.dart';
import 'package:kfc/providers/yeu_thich_provider.dart';
import 'package:kfc/providers/gio_hang_provider.dart';
import 'package:kfc/widgets/favorite_button.dart';
import 'package:provider/provider.dart';
import 'package:kfc/models/san_pham_gio_hang.dart';
import 'package:kfc/models/danh_gia.dart';
import 'package:kfc/services/danh_gia_service.dart';
import 'package:kfc/widgets/danh_gia_widget.dart';
import 'package:kfc/screens/man_hinh_viet_danh_gia.dart';
import 'package:kfc/screens/man_hinh_xem_danh_gia.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ManHinhChiTietSanPham extends StatefulWidget {
  final String? sanPhamId;
  final SanPham? sanPhamBanDau;
  final SanPham? sanPham;

  const ManHinhChiTietSanPham({
    Key? key,
    this.sanPhamId,
    this.sanPhamBanDau,
    this.sanPham,
  }) : assert(sanPhamId != null || sanPham != null || sanPhamBanDau != null, 
         'Phải cung cấp ít nhất một trong các tham số: sanPhamId, sanPham hoặc sanPhamBanDau'),
       super(key: key);

  @override
  State<ManHinhChiTietSanPham> createState() => _ManHinhChiTietSanPhamState();
}

class _ManHinhChiTietSanPhamState extends State<ManHinhChiTietSanPham> {
  int _soLuong = 1;
  SanPham? _sanPham;
  bool _dangTai = true;
  String? _loi;
  List<SanPham> _sanPhamLienQuan = [];
  late String _sanPhamId;

  ThongKeDanhGia? _thongKeDanhGia;
  List<DanhGia> _danhGiaGanNhat = [];
  bool _dangTaiDanhGia = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    
    if (widget.sanPham != null) {
      _sanPhamId = widget.sanPham!.id;
    } else if (widget.sanPhamBanDau != null) {
      _sanPhamId = widget.sanPhamBanDau!.id;
    } else {
      _sanPhamId = widget.sanPhamId!;
    }
    
    _taiDuLieuSanPham();
  }

  Future<void> _taiDuLieuDanhGia() async {
    if (_sanPham == null) return;
    
    setState(() {
      _dangTaiDanhGia = true;
    });

    try {
      final thongKe = await DanhGiaService.layThongKeDanhGia(_sanPham!.id);
      final danhSachDanhGia = await DanhGiaService.layDanhGiaTheoSanPham(_sanPham!.id);
      final danhGiaGanNhat = danhSachDanhGia.take(3).toList();

      if (mounted) {
        setState(() {
          _thongKeDanhGia = thongKe;
          _danhGiaGanNhat = danhGiaGanNhat;
          _dangTaiDanhGia = false;
        });
      }
    } catch (e) {
      print('Lỗi khi tải đánh giá: $e');
      if (mounted) {
        setState(() {
          _dangTaiDanhGia = false;
        });
      }
    }
  }

  Future<void> _taiDuLieuSanPham() async {
    setState(() {
      _dangTai = true;
      _loi = null;
      _sanPham = null;
    });

    try {
      final sanPham = await FirebaseService.laySanPhamTheoId(_sanPhamId);
      
      if (mounted) {
        setState(() {
          _sanPham = sanPham;
          _dangTai = false;
          if (sanPham == null) {
            _loi = 'Không tìm thấy sản phẩm';
          } else {
            _taiSanPhamLienQuan(sanPham);
            _taiDuLieuDanhGia();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dangTai = false;
          _loi = 'Lỗi khi tải dữ liệu: $e';
        });
      }
    }
  }

  Future<void> _taiSanPhamLienQuan(SanPham sanPham) async {
    try {
      final danhSachLienQuan = await FirebaseService.laySanPhamLienQuan(sanPham);
      if (mounted) {
        setState(() {
          _sanPhamLienQuan = danhSachLienQuan;
        });
      }
    } catch (e) {
      print('Lỗi khi tải sản phẩm liên quan: $e');
    }
  }

  String _getImagePath(String hinhAnh) {
    if (hinhAnh.isEmpty) return '';
    if (hinhAnh.startsWith('assets/')) return hinhAnh;
    if (hinhAnh.startsWith('http')) return hinhAnh; // URL hình ảnh
    return 'assets/images/$hinhAnh';
  }

// Hàm để xây dựng hình ảnh từ assets hoặc URL
  Widget _buildImageFromNetwork(String imageUrl, {double? height, BoxFit? fit}) {
    if (imageUrl.isEmpty) {
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fastfood, size: 60, color: Colors.white),
              SizedBox(height: 8),
              Text('Chưa có hình ảnh', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      height: height,
      width: double.infinity,
      fit: fit ?? BoxFit.cover,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(color: MauSac.kfcRed),
      ),
      errorWidget: (context, url, error) => Container(
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 60, color: Colors.white),
              SizedBox(height: 8),
              Text('Không thể tải hình ảnh', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
  
  // Hàm để xây dựng hình ảnh từ assets hoặc URL
  Widget _buildImageFromAssets(String imagePath, {double? height, BoxFit? fit}) {
    if (imagePath.startsWith('http')) {
      return _buildImageFromNetwork(imagePath, height: height, fit: fit);
    }
    return Image.asset(
      imagePath,
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_not_supported, size: 60, color: Colors.white),
                SizedBox(height: 8),
                Text('Không thể tải hình ảnh', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _tangSoLuong() {
    setState(() {
      _soLuong++;
    });
  }

  void _giamSoLuong() {
    if (_soLuong > 1) {
      setState(() {
        _soLuong--;
      });
    }
  }

  void _themVaoGioHang() {
    if (_sanPham == null) return;
  
    final gioHangProvider = Provider.of<GioHangProvider>(context, listen: false);
    final sanPhamGioHang = SanPhamGioHang(
      sanPham: _sanPham!,
      soLuong: _soLuong,
    );
    gioHangProvider.themSanPham(sanPhamGioHang);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Đã thêm ${_sanPham!.ten} (x$_soLuong) vào giỏ hàng'),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: MauSac.xanhLa,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildBody() {
    if (_dangTai) {
      return _buildLoadingState();
    }

    if (_loi != null) {
      return _buildErrorState();
    }

    if (_sanPham == null) {
      return _buildNotFoundState();
    }

    return _buildProductDetail();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: MauSac.kfcRed),
          SizedBox(height: 16),
          Text(
            'Đang tải dữ liệu...',
            style: TextStyle(color: MauSac.xam, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: MauSac.denNhat,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: MauSac.kfcRed.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: MauSac.kfcRed),
              const SizedBox(height: 16),
              const Text(
                'Oops! Có lỗi xảy ra',
                style: TextStyle(
                  color: MauSac.trang,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _loi!,
                style: const TextStyle(color: MauSac.xam, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Quay lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MauSac.xam,
                      foregroundColor: MauSac.trang,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _taiDuLieuSanPham,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MauSac.kfcRed,
                      foregroundColor: MauSac.trang,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: MauSac.denNhat,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: MauSac.kfcRed.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 64, color: MauSac.xam),
              const SizedBox(height: 16),
              const Text(
                'Không tìm thấy sản phẩm',
                style: TextStyle(
                  color: MauSac.trang,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sản phẩm bạn đang tìm có thể đã bị xóa hoặc không tồn tại.',
                style: TextStyle(color: MauSac.xam, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Quay lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MauSac.kfcRed,
                  foregroundColor: MauSac.trang,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductDetail() {
    final giaGoc = _sanPham!.gia;
    final giaSauGiam = _sanPham!.khuyenMai == true && _sanPham!.giamGia != null && _sanPham!.giamGia! > 0
        ? (giaGoc * (100 - _sanPham!.giamGia!) / 100).round()
        : giaGoc;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: MauSac.denNen,
          foregroundColor: MauSac.trang,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          actions: [
            if (_sanPham != null)
              Container(
                margin: const EdgeInsets.all(8),
                child: FavoriteButton(
                  sanPham: _sanPham!,
                  size: 24,
                  activeColor: MauSac.kfcRed,
                  inactiveColor: Colors.white,
                ),
              ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                _buildImageFromAssets(_sanPham!.hinhAnh),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
                if (_sanPham!.khuyenMai == true && _sanPham!.giamGia != null && _sanPham!.giamGia! > 0)
                  Positioned(
                    top: 100,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: MauSac.kfcRed,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.white, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            'GIẢM ${_sanPham!.giamGia}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildProductInfo(giaGoc, giaSauGiam),
              _buildDescription(),
              _buildReviewSection(),
              if (_sanPhamLienQuan.isNotEmpty) _buildRelatedProducts(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductInfo(int giaGoc, int giaSauGiam) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MauSac.denNhat,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _sanPham!.ten,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: MauSac.trang,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${giaSauGiam.toStringAsFixed(0)} ₫',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: MauSac.kfcRed,
                ),
              ),
              if (_sanPham!.khuyenMai == true && _sanPham!.giamGia != null && _sanPham!.giamGia! > 0) ...[
                const SizedBox(width: 12),
                Text(
                  '${giaGoc.toStringAsFixed(0)} ₫',
                  style: TextStyle(
                    fontSize: 18,
                    color: MauSac.xam.withOpacity(0.7),
                    decoration: TextDecoration.lineThrough,
                    decorationColor: MauSac.xam.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _xemTatCaDanhGia(),
                child: Row(
                  children: [
                    if (_thongKeDanhGia != null) ...[
                      RatingStars(
                        rating: _thongKeDanhGia!.diemTrungBinh,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_thongKeDanhGia!.diemTrungBinhFormatted} (${_thongKeDanhGia!.tongSoDanhGiaFormatted} đánh giá)',
                        style: const TextStyle(color: MauSac.xam, fontSize: 14),
                      ),
                    ] else if (_dangTaiDanhGia) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: MauSac.kfcRed,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Đang tải đánh giá...',
                        style: TextStyle(color: MauSac.xam, fontSize: 14),
                      ),
                    ] else ...[
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            Icons.star_border,
                            color: MauSac.xam.withOpacity(0.3),
                            size: 20,
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Chưa có đánh giá',
                        style: TextStyle(color: MauSac.xam, fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
              Consumer<YeuThichProvider>(
                builder: (context, yeuThichProvider, child) {
                  final isYeuThich = yeuThichProvider.kiemTraYeuThich(_sanPham!.id);
                  return GestureDetector(
                    onTap: () {
                      if (isYeuThich) {
                        yeuThichProvider.xoaKhoiYeuThich(_sanPham!.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.heart_broken, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text('Đã xóa khỏi yêu thích'),
                              ],
                            ),
                            backgroundColor: MauSac.xam,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else {
                        yeuThichProvider.themVaoYeuThich(_sanPham!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.favorite, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text('Đã thêm vào yêu thích'),
                              ],
                            ),
                            backgroundColor: MauSac.kfcRed,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isYeuThich ? MauSac.kfcRed.withOpacity(0.1) : MauSac.denNen,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isYeuThich ? MauSac.kfcRed : MauSac.xam.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isYeuThich ? Icons.favorite : Icons.favorite_border,
                            color: isYeuThich ? MauSac.kfcRed : MauSac.xam,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isYeuThich ? 'Đã thích' : 'Yêu thích',
                            style: TextStyle(
                              color: isYeuThich ? MauSac.kfcRed : MauSac.xam,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MauSac.denNhat,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description, color: MauSac.kfcRed, size: 24),
              SizedBox(width: 8),
              Text(
                'Mô tả sản phẩm',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: MauSac.trang,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _sanPham!.moTa.isNotEmpty 
                ? _sanPham!.moTa 
                : 'Sản phẩm chất lượng cao từ KFC, được chế biến theo công thức bí mật với 11 loại gia vị đặc biệt.',
            style: const TextStyle(
              color: MauSac.xam,
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MauSac.denNhat,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: MauSac.vang, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Đánh giá sản phẩm',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: MauSac.trang,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _xemTatCaDanhGia,
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(
                    color: MauSac.kfcRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_thongKeDanhGia != null) ...[
            ThongKeDanhGiaWidget(
              thongKe: _thongKeDanhGia!,
              showDetails: false,
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _vietDanhGia,
              icon: const Icon(Icons.edit, size: 20),
              label: const Text(
                'Viết đánh giá',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: MauSac.kfcRed,
                side: const BorderSide(color: MauSac.kfcRed),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (_danhGiaGanNhat.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Đánh giá gần nhất',
              style: TextStyle(
                color: MauSac.trang,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(_danhGiaGanNhat.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: DanhGiaCard(danhGia: _danhGiaGanNhat[index]),
              );
            }),
          ] else if (!_dangTaiDanhGia && _thongKeDanhGia?.tongSoDanhGia == 0) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: MauSac.denNen,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MauSac.xam.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 48,
                    color: MauSac.xam.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Chưa có đánh giá nào',
                    style: TextStyle(
                      color: MauSac.xam.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hãy là người đầu tiên đánh giá sản phẩm này!',
                    style: TextStyle(
                      color: MauSac.xam.withOpacity(0.6),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
          if (_dangTaiDanhGia) ...[
            const SizedBox(height: 20),
            const Center(
              child: CircularProgressIndicator(color: MauSac.kfcRed),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRelatedProducts() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MauSac.denNhat,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.recommend, color: MauSac.kfcRed, size: 24),
              SizedBox(width: 8),
              Text(
                'Sản phẩm liên quan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: MauSac.trang,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _sanPhamLienQuan.length,
              itemBuilder: (context, index) {
                final sanPham = _sanPhamLienQuan[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => ManHinhChiTietSanPham(
                          sanPhamId: sanPham.id,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: MauSac.denNen,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: MauSac.kfcRed.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: _buildImageFromAssets(
                            sanPham.hinhAnh,
                            height: 100,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      sanPham.ten,
                                      style: const TextStyle(
                                        color: MauSac.trang,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Consumer<YeuThichProvider>(
                                    builder: (context, yeuThichProvider, child) {
                                      final isYeuThich = yeuThichProvider.kiemTraYeuThich(sanPham.id);
                                      return GestureDetector(
                                        onTap: () {
                                          if (isYeuThich) {
                                            yeuThichProvider.xoaKhoiYeuThich(sanPham.id);
                                          } else {
                                            yeuThichProvider.themVaoYeuThich(sanPham);
                                          }
                                        },
                                        child: Icon(
                                          isYeuThich ? Icons.favorite : Icons.favorite_border,
                                          color: isYeuThich ? MauSac.kfcRed : MauSac.xam,
                                          size: 16,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${sanPham.gia.toStringAsFixed(0)} ₫',
                                style: const TextStyle(
                                  color: MauSac.kfcRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MauSac.denNhat,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
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
                    icon: const Icon(Icons.remove, color: MauSac.kfcRed),
                    onPressed: _giamSoLuong,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '$_soLuong',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: MauSac.trang,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: MauSac.kfcRed),
                    onPressed: _tangSoLuong,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _themVaoGioHang,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MauSac.kfcRed,
                  foregroundColor: MauSac.trang,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_cart_outlined, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'THÊM VÀO GIỎ - ${(_sanPham!.gia * _soLuong).toStringAsFixed(0)} ₫',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _vietDanhGia() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Vui lòng đăng nhập để đánh giá'),
            ],
          ),
          backgroundColor: MauSac.cam,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ManHinhVietDanhGia(sanPham: _sanPham!),
      ),
    );

    if (result == true) {
      _taiDuLieuDanhGia();
    }
  }

  void _xemTatCaDanhGia() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ManHinhXemDanhGia(sanPham: _sanPham!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MauSac.denNen,
      body: _buildBody(),
      bottomNavigationBar: _sanPham != null ? _buildBottomBar() : null,
    );
  }
}

class DanhGiaCard extends StatelessWidget {
  final DanhGia danhGia;

  const DanhGiaCard({Key? key, required this.danhGia}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MauSac.denNen,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MauSac.xam.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  danhGia.tenNguoiDung,
                  style: const TextStyle(
                    color: MauSac.trang,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                danhGia.ngayTaoFormatted,
                style: TextStyle(
                  color: MauSac.xam.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < danhGia.soSao ? Icons.star : Icons.star_border,
                color: MauSac.vang,
                size: 16,
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            danhGia.binhLuan,
            style: const TextStyle(
              color: MauSac.trang,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (danhGia.hinhAnh != null && danhGia.hinhAnh!.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: danhGia.hinhAnh!.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          backgroundColor: Colors.transparent,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  danhGia.hinhAnh![index],
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 200,
                                      height: 200,
                                      color: MauSac.denNhat,
                                      child: const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          color: MauSac.kfcRed,
                                          size: 40,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(),
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
                        ),
                      );
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: MauSac.xam.withOpacity(0.2)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          danhGia.hinhAnh![index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: MauSac.kfcRed,
                                size: 40,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
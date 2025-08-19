import 'package:flutter/material.dart';
import 'package:kfc/theme/mau_sac.dart';
import 'package:kfc/models/san_pham.dart';
import 'package:kfc/providers/yeu_thich_provider.dart';
import 'package:kfc/providers/gio_hang_provider.dart';
import 'package:kfc/screens/man_hinh_chi_tiet_san_pham.dart';
import 'package:provider/provider.dart';
import 'package:kfc/models/san_pham_gio_hang.dart';

class ManHinhYeuThich extends StatefulWidget {
  const ManHinhYeuThich({Key? key}) : super(key: key);

  @override
  State<ManHinhYeuThich> createState() => _ManHinhYeuThichState();
}

class _ManHinhYeuThichState extends State<ManHinhYeuThich>
    with TickerProviderStateMixin {
  bool _dangTaiDuLieu = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _headerAnimationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animation cho fade in
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Animation cho header slide
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutBack,
    ));

    // Bắt đầu animations
    _headerAnimationController.forward();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  Future<void> _lamMoiDuLieu() async {
    setState(() {
      _dangTaiDuLieu = true;
    });

    // Giả lập tải dữ liệu
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() {
        _dangTaiDuLieu = false;
      });
    }
  }

  String _getImagePath(String hinhAnh) {
    if (hinhAnh.isEmpty) return '';
    if (hinhAnh.startsWith('assets/')) return hinhAnh;
    return 'assets/images/$hinhAnh';
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
          child: Icon(Icons.fastfood, size: 40, color: Colors.white),
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
            child: Icon(Icons.image_not_supported, size: 40, color: Colors.white),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MauSac.denNen,
      body: SafeArea(
        child: Column(
          children: [
            _buildAnimatedHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _lamMoiDuLieu,
                color: MauSac.kfcRed,
                backgroundColor: MauSac.denNhat,
                strokeWidth: 3,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return SlideTransition(
      position: _slideAnimation,
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
          'Món ăn yêu thích',
          style: TextStyle(
            color: MauSac.trang,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Những món ăn bạn đã lưu',
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
    return Consumer<YeuThichProvider>(
      builder: (context, yeuThichProvider, child) {
        if (yeuThichProvider.danhSachYeuThich.isEmpty) {
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
    return Consumer<YeuThichProvider>(
      builder: (context, yeuThichProvider, child) {
        final count = yeuThichProvider.danhSachYeuThich.length;
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
                  Icons.favorite,
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
                      '$count món ăn',
                      style: const TextStyle(
                        color: MauSac.trang,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      count > 0 ? 'Trong danh sách yêu thích' : 'Chưa có món nào',
                      style: TextStyle(
                        color: MauSac.xam.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: MauSac.kfcRed,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count',
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
    return Consumer<YeuThichProvider>(
      builder: (context, yeuThichProvider, child) {
        final danhSachYeuThich = yeuThichProvider.danhSachYeuThich;

        if (_dangTaiDuLieu) {
          return _buildLoadingState();
        }

        if (danhSachYeuThich.isEmpty) {
          return _buildEmptyState();
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: _buildFavoritesList(danhSachYeuThich),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: MauSac.denNhat,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const CircularProgressIndicator(
              color: MauSac.kfcRed,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Đang tải danh sách yêu thích...',
            style: TextStyle(
              color: MauSac.xam,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
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
                      Icons.favorite_border,
                      size: 70,
                      color: MauSac.kfcRed,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Chưa có món ăn yêu thích',
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
              'Hãy khám phá menu và thêm những món ăn\nyêu thích vào danh sách để dễ dàng tìm lại',
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

  Widget _buildFavoritesList(List<SanPham> danhSachYeuThich) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: danhSachYeuThich.length,
        itemBuilder: (context, index) {
          return _buildFavoriteCard(danhSachYeuThich[index], index);
        },
      ),
    );
  }

  Widget _buildFavoriteCard(SanPham sanPham, int index) {
    final giaGoc = sanPham.gia;
    final giaSauGiam = sanPham.khuyenMai == true && 
        sanPham.giamGia != null && 
        sanPham.giamGia! > 0
        ? (giaGoc * (100 - sanPham.giamGia!) / 100).round()
        : giaGoc;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
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
      child: GestureDetector(
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
          decoration: BoxDecoration(
            color: MauSac.denNhat,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: MauSac.kfcRed.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hình ảnh sản phẩm
              Expanded(
                flex: 5,
                child: _buildProductImage(sanPham),
              ),
              
              // Thông tin sản phẩm
              Expanded(
                flex: 4,
                child: _buildProductInfo(sanPham, giaGoc, giaSauGiam),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(SanPham sanPham) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: _buildImageFromAssets(sanPham.hinhAnh),
          ),
        ),
        
        // Gradient overlay
        Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.1),
              ],
            ),
          ),
        ),
        
        // Badge khuyến mãi
        if (sanPham.khuyenMai == true && 
            sanPham.giamGia != null && 
            sanPham.giamGia! > 0)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [MauSac.kfcRed, MauSac.kfcRed.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                '-${sanPham.giamGia}%',
                style: const TextStyle(
                  color: MauSac.trang,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        
        // Nút yêu thích
        Positioned(
          top: 12,
          left: 12,
          child: _buildFavoriteButton(sanPham),
        ),
      ],
    );
  }

  Widget _buildFavoriteButton(SanPham sanPham) {
    return Consumer<YeuThichProvider>(
      builder: (context, yeuThichProvider, child) {
        return GestureDetector(
          onTap: () => _removeFavorite(sanPham),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite,
              color: MauSac.kfcRed,
              size: 18,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductInfo(SanPham sanPham, int giaGoc, int giaSauGiam) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tên sản phẩm
          Text(
            sanPham.ten,
            style: const TextStyle(
              color: MauSac.trang,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 4),
          
          // Giá
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${giaSauGiam.toStringAsFixed(0)} ₫',
                style: const TextStyle(
                  color: MauSac.kfcRed,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (sanPham.khuyenMai == true && 
                  sanPham.giamGia != null && 
                  sanPham.giamGia! > 0)
                Text(
                  '${giaGoc.toStringAsFixed(0)} ₫',
                  style: TextStyle(
                    color: MauSac.xam.withOpacity(0.7),
                    fontSize: 10,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 4),
          
          // Nút thêm vào giỏ hàng
          SizedBox(
            width: double.infinity,
            height: 28,
            child: ElevatedButton.icon(
              onPressed: () => _addToCart(sanPham),
              icon: const Icon(Icons.add_shopping_cart, size: 12),
              label: const Text(
                'Thêm vào giỏ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: MauSac.kfcRed,
                foregroundColor: MauSac.trang,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 1,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _removeFavorite(SanPham sanPham) {
    final yeuThichProvider = Provider.of<YeuThichProvider>(context, listen: false);
    yeuThichProvider.xoaKhoiYeuThich(sanPham.id);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.heart_broken, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Đã xóa ${sanPham.ten} khỏi yêu thích',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: MauSac.xam,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'Hoàn tác',
          textColor: MauSac.kfcRed,
          onPressed: () {
            yeuThichProvider.themVaoYeuThich(sanPham);
          },
        ),
      ),
    );
  }

  void _addToCart(SanPham sanPham) {
    final gioHangProvider = Provider.of<GioHangProvider>(context, listen: false);
    final sanPhamGioHang = SanPhamGioHang(
      sanPham: sanPham,
      soLuong: 1,
    );
    gioHangProvider.themSanPham(sanPhamGioHang);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Đã thêm ${sanPham.ten} vào giỏ hàng',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: MauSac.xanhLa,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
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
                'Xóa tất cả yêu thích',
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
          'Bạn có chắc chắn muốn xóa tất cả sản phẩm yêu thích? Hành động này không thể hoàn tác.',
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
              final yeuThichProvider = Provider.of<YeuThichProvider>(context, listen: false);
              yeuThichProvider.xoaTatCa();
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.delete_sweep, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Đã xóa tất cả sản phẩm yêu thích',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
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
}

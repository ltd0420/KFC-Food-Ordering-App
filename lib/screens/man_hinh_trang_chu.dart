import 'package:flutter/material.dart';
import 'package:kfc/theme/mau_sac.dart';
import 'package:provider/provider.dart';
import 'package:kfc/screens/man_hinh_chi_tiet_san_pham.dart';
import 'package:kfc/screens/man_hinh_danh_muc.dart';
import 'package:kfc/providers/danh_muc_provider.dart';
import 'package:kfc/providers/san_pham_provider.dart';
import 'package:kfc/widgets/hinh_anh_san_pham.dart';
import 'package:kfc/widgets/hinh_anh_danh_muc.dart';
import 'package:kfc/widgets/danh_muc_card.dart';
import 'package:kfc/widgets/khuyen_mai_card.dart';
import 'package:kfc/widgets/san_pham_card.dart';
import 'package:kfc/widgets/floating_chat_button.dart';
import 'package:kfc/models/san_pham.dart';
import 'package:kfc/models/danh_muc.dart';
import 'dart:math' as math;

class ManHinhTrangChu extends StatefulWidget {
  const ManHinhTrangChu({Key? key}) : super(key: key);

  @override
  State<ManHinhTrangChu> createState() => _ManHinhTrangChuState();
}

class _ManHinhTrangChuState extends State<ManHinhTrangChu> with SingleTickerProviderStateMixin {
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  late AnimationController _fallingLeavesController;

  final List<Map<String, dynamic>> _danhSachBanner = [
    {
      'hinhAnh': 'assets/images/banner1.png',
      'tieuDe': 'Combo nhóm giảm 25%',
      'moTa': 'Áp dụng cho nhóm từ 3-4 người',
      'nhan': 'HOT',
      'mauNhan': MauSac.kfcRed,
    },
    {
      'hinhAnh': 'assets/images/banner2.png',
      'tieuDe': 'Mua 1 tặng 1',
      'moTa': 'Áp dụng cho burger và gà rán',
      'nhan': 'NEW',
      'mauNhan': MauSac.xanhLa,
    },
    {
      'hinhAnh': 'assets/images/banner3.png',
      'tieuDe': 'Freeship đơn từ 100K',
      'moTa': 'Áp dụng cho tất cả đơn hàng',
      'nhan': 'FREE',
      'mauNhan': MauSac.vang,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Auto scroll banner
    Future.delayed(const Duration(seconds: 3), _autoScrollBanner);

    // Initialize falling leaves animation
    _fallingLeavesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  void _autoScrollBanner() {
    if (mounted && _bannerController.hasClients) {
      setState(() {
        _currentBannerIndex = (_currentBannerIndex + 1) % _danhSachBanner.length;
      });
      _bannerController.animateToPage(
        _currentBannerIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      Future.delayed(const Duration(seconds: 3), _autoScrollBanner);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'KFC Vietnam',
          style: TextStyle(
            color: MauSac.trang,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: MauSac.denNen,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: MauSac.trang, size: 24),
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: MauSac.trang, size: 24),
            onPressed: () {
              Navigator.pushNamed(context, '/favorites');
            },
          ),
        ],
      ),
      backgroundColor: MauSac.denNen,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              final danhMucProvider = Provider.of<DanhMucProvider>(context, listen: false);
              final sanPhamProvider = Provider.of<SanPhamProvider>(context, listen: false);
              
              await Future.wait([
                danhMucProvider.lamMoi(),
                sanPhamProvider.lamMoi(),
              ]);
            },
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner khuyến mãi
                  _buildBannerSection(),
                  
                  // Banner indicators
                  _buildBannerIndicators(),
                  
                  // Danh mục
                  const SizedBox(height: 20),
                  _buildDanhMucSection(),
                  
                  // Khuyến mãi hôm nay
                  const SizedBox(height: 20),
                  _buildKhuyenMaiSection(),
                  
                  // Tất cả món ăn
                  const SizedBox(height: 20),
                  _buildTatCaMonAnSection(),
                  
                  const SizedBox(height: 80), // Giảm khoảng cách vì đã bỏ nút cart
                ],
              ),
            ),
          ),
          // Falling leaves effect
          FallingLeaves(animationController: _fallingLeavesController),
          
          // Chỉ giữ lại nút chat hỗ trợ
          FloatingChatButton(),
        ],
      ),
    );
  }

  Widget _buildBannerSection() {
    return Container(
      height: 180,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: PageView.builder(
        controller: _bannerController,
        onPageChanged: (index) {
          setState(() {
            _currentBannerIndex = index;
          });
        },
        itemCount: _danhSachBanner.length,
        itemBuilder: (context, index) {
          final banner = _danhSachBanner[index];
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image
                  Image.asset(
                    banner['hinhAnh'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              MauSac.kfcRed.withOpacity(0.9),
                              MauSac.kfcRed.withOpacity(0.7),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Dark overlay for better text readability
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
                  
                  // Content overlay
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top section with badge and content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Badge
                              if (banner['nhan'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: banner['mauNhan'] ?? MauSac.kfcRed,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    banner['nhan'],
                                    style: const TextStyle(
                                      color: MauSac.trang,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              
                              const SizedBox(height: 12),
                              
                              // Title with shadow
                              Flexible(
                                child: Text(
                                  banner['tieuDe'],
                                  style: TextStyle(
                                    color: MauSac.trang,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              
                              const SizedBox(height: 6),
                              
                              // Description with shadow
                              Flexible(
                                child: Text(
                                  banner['moTa'],
                                  style: TextStyle(
                                    color: MauSac.trang,
                                    fontSize: 14,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
    );
  }

  Widget _buildBannerIndicators() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _danhSachBanner.length,
          (index) => Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentBannerIndex == index
                  ? MauSac.kfcRed
                  : MauSac.xam.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDanhMucSection() {
    return Consumer<DanhMucProvider>(
      builder: (context, danhMucProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Danh mục',
                style: TextStyle(
                  color: MauSac.trang,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            if (danhMucProvider.dangTaiDuLieu)
              const SizedBox(
                height: 120,
                child: Center(
                  child: CircularProgressIndicator(color: MauSac.kfcRed),
                ),
              )
            else if (danhMucProvider.loi != null)
              _buildErrorWidget(danhMucProvider.loi!, () => danhMucProvider.lamMoi())
            else
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: danhMucProvider.danhSachDanhMuc.length,
                  itemBuilder: (context, index) {
                    final danhMuc = danhMucProvider.danhSachDanhMuc[index];
                    return DanhMucCardHorizontal(
                      danhMuc: danhMuc,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ManHinhDanhMuc(danhMuc: danhMuc),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildKhuyenMaiSection() {
    return Consumer<SanPhamProvider>(
      builder: (context, sanPhamProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: MauSac.kfcRed,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Khuyến mãi hôm nay',
                    style: TextStyle(
                      color: MauSac.trang,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to all promotions
                    },
                    child: const Text(
                      'Hãy nhanh tay!',
                      style: TextStyle(
                        color: MauSac.kfcRed,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            if (sanPhamProvider.dangTaiKhuyenMai)
              const SizedBox(
                height: 280,
                child: Center(
                  child: CircularProgressIndicator(color: MauSac.kfcRed),
                ),
              )
            else if (sanPhamProvider.loiKhuyenMai != null)
              _buildErrorWidget(sanPhamProvider.loiKhuyenMai!, () => sanPhamProvider.layDanhSachSanPhamKhuyenMai())
            else if (sanPhamProvider.sanPhamKhuyenMai.isEmpty)
              const SizedBox(
                height: 280,
                child: Center(
                  child: Text(
                    'Không có sản phẩm khuyến mãi',
                    style: TextStyle(color: MauSac.xam),
                  ),
                ),
              )
            else
              SizedBox(
                height: 280,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: sanPhamProvider.sanPhamKhuyenMai.length,
                  itemBuilder: (context, index) {
                    final sanPham = sanPhamProvider.sanPhamKhuyenMai[index];
                    return KhuyenMaiCard(
                      sanPham: sanPham,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ManHinhChiTietSanPham(
                              sanPhamId: sanPham.id,
                              sanPhamBanDau: sanPham,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTatCaMonAnSection() {
    return Consumer<SanPhamProvider>(
      builder: (context, sanPhamProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tất cả món ăn',
                    style: TextStyle(
                      color: MauSac.trang,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (sanPhamProvider.danhSachSanPham.isNotEmpty)
                    Text(
                      '${sanPhamProvider.danhSachSanPham.length} món',
                      style: const TextStyle(
                        color: MauSac.xam,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            if (sanPhamProvider.dangTaiDuLieu)
              const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(color: MauSac.kfcRed),
                ),
              )
            else if (sanPhamProvider.loi != null)
              _buildErrorWidget(sanPhamProvider.loi!, () => sanPhamProvider.layDanhSachSanPham())
            else if (sanPhamProvider.danhSachSanPham.isEmpty)
              const SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'Không có sản phẩm',
                    style: TextStyle(color: MauSac.xam),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: sanPhamProvider.danhSachSanPham.length,
                  itemBuilder: (context, index) {
                    final sanPham = sanPhamProvider.danhSachSanPham[index];
                    return SanPhamCard(
                      sanPham: sanPham,
                      showDiscount: true,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ManHinhChiTietSanPham(
                              sanPhamId: sanPham.id,
                              sanPhamBanDau: sanPham,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildErrorWidget(String error, VoidCallback onRetry) {
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: MauSac.denNhat,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MauSac.kfcRed.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: MauSac.kfcRed, size: 16),
          const SizedBox(height: 4),
          const Flexible(
            child: Text(
              'Lỗi tải dữ liệu',
              style: TextStyle(color: MauSac.trang, fontSize: 9),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 24,
            child: ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: MauSac.kfcRed,
                minimumSize: const Size(50, 24),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                textStyle: const TextStyle(fontSize: 8),
              ),
              child: const Text(
                'Thử lại',
                style: TextStyle(color: MauSac.trang, fontSize: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _fallingLeavesController.dispose();
    super.dispose();
  }
}

// Custom widget for falling leaves effect
class FallingLeaves extends StatefulWidget {
  final AnimationController animationController;

  const FallingLeaves({required this.animationController, Key? key}) : super(key: key);

  @override
  _FallingLeavesState createState() => _FallingLeavesState();
}

class _FallingLeavesState extends State<FallingLeaves> with SingleTickerProviderStateMixin {
  late List<Leaf> _leaves;

  @override
  void initState() {
    super.initState();
    _leaves = []; // Khởi tạo với danh sách rỗng để tránh lỗi late
    widget.animationController.addListener(_updateLeaves);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_leaves.isEmpty) { // Cập nhật nếu danh sách rỗng
      _leaves = List.generate(10, (index) => Leaf(
        x: math.Random().nextDouble() * MediaQuery.of(context).size.width,
        y: -50 - (math.Random().nextDouble() * 100),
        speed: 1 + math.Random().nextDouble() * 2,
        rotationSpeed: math.Random().nextDouble() * 0.1,
      ));
    }
  }

  void _updateLeaves() {
    if (_leaves.isNotEmpty) { // Kiểm tra để tránh lỗi nếu danh sách rỗng
      setState(() {
        for (var leaf in _leaves) {
          leaf.y += leaf.speed;
          leaf.rotation += leaf.rotationSpeed;
          if (leaf.y > MediaQuery.of(context).size.height + 50) {
            leaf.y = -50;
            leaf.x = math.Random().nextDouble() * MediaQuery.of(context).size.width;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    widget.animationController.removeListener(_updateLeaves);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer( // Thêm IgnorePointer để không chặn sự kiện
      child: CustomPaint(
        painter: LeafPainter(_leaves),
        child: Container(),
      ),
    );
  }
}

class Leaf {
  double x;
  double y;
  double speed;
  double rotation;
  double rotationSpeed;

  Leaf({
    required this.x,
    required this.y,
    required this.speed,
    required this.rotationSpeed,
  }) : rotation = 0.0;
}

class LeafPainter extends CustomPainter {
  final List<Leaf> leaves;

  LeafPainter(this.leaves);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.orange.withOpacity(0.7);
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(10, -10, 20, 0)
      ..lineTo(15, 20)
      ..quadraticBezierTo(10, 10, 0, 0)
      ..close();

    for (var leaf in leaves) {
      canvas.save();
      canvas.translate(leaf.x, leaf.y);
      canvas.rotate(leaf.rotation);
      canvas.drawPath(path, paint..style = PaintingStyle.fill);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
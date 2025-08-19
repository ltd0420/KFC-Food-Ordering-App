import 'package:flutter/material.dart';
import 'package:kfc/models/danh_muc.dart';
import 'package:kfc/models/san_pham.dart';
import 'package:kfc/services/firebase_service.dart';
import 'package:kfc/theme/mau_sac.dart';
import 'package:kfc/widgets/san_pham_card.dart';

class ManHinhDanhMuc extends StatefulWidget {
  final DanhMuc danhMuc;

  const ManHinhDanhMuc({
    Key? key,
    required this.danhMuc,
  }) : super(key: key);

  @override
  State<ManHinhDanhMuc> createState() => _ManHinhDanhMucState();
}

class _ManHinhDanhMucState extends State<ManHinhDanhMuc>
    with TickerProviderStateMixin {
  List<SanPham> _danhSachSanPham = [];
  bool _dangTai = true;
  String? _loi;
  String _sapXepTheo = 'ten'; // ten, gia_tang, gia_giam, moi_nhat

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _taiDanhSachSanPham();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _taiDanhSachSanPham() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });

    try {
      print('🔄 Đang tải sản phẩm cho danh mục: ${widget.danhMuc.id}');
      
      final danhSach = await FirebaseService.layDanhSachSanPhamTheoDanhMuc(widget.danhMuc.id);
      
      if (mounted) {
        setState(() {
          _danhSachSanPham = danhSach;
          _dangTai = false;
          _sapXepDanhSach();
        });
        
        _animationController.forward();
        print('✅ Đã tải ${danhSach.length} sản phẩm cho danh mục ${widget.danhMuc.ten}');
      }
    } catch (e) {
      print('❌ Lỗi khi tải sản phẩm danh mục: $e');
      if (mounted) {
        setState(() {
          _dangTai = false;
          _loi = 'Lỗi khi tải dữ liệu: $e';
        });
      }
    }
  }

  void _sapXepDanhSach() {
    switch (_sapXepTheo) {
      case 'ten':
        _danhSachSanPham.sort((a, b) => a.ten.compareTo(b.ten));
        break;
      case 'gia_tang':
        _danhSachSanPham.sort((a, b) => a.gia.compareTo(b.gia));
        break;
      case 'gia_giam':
        _danhSachSanPham.sort((a, b) => b.gia.compareTo(a.gia));
        break;
      case 'moi_nhat':
        _danhSachSanPham.sort((a, b) => b.id.compareTo(a.id));
        break;
    }
  }

  void _chonSapXep() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: MauSac.denNhat,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: MauSac.xam.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: MauSac.kfcRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.sort, color: MauSac.kfcRed, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Sắp xếp theo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: MauSac.trang,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              _buildSapXepOption('ten', 'Tên A-Z', Icons.sort_by_alpha),
              _buildSapXepOption('gia_tang', 'Giá thấp đến cao', Icons.trending_up),
              _buildSapXepOption('gia_giam', 'Giá cao đến thấp', Icons.trending_down),
              _buildSapXepOption('moi_nhat', 'Mới nhất', Icons.new_releases),
              
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSapXepOption(String value, String title, IconData icon) {
    final isSelected = _sapXepTheo == value;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? MauSac.kfcRed.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? MauSac.kfcRed : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? MauSac.kfcRed : MauSac.xam.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isSelected ? MauSac.trang : MauSac.xam,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? MauSac.kfcRed : MauSac.trang,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 16,
          ),
        ),
        trailing: isSelected 
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: MauSac.kfcRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check, color: MauSac.trang, size: 16),
              )
            : null,
        onTap: () {
          setState(() {
            _sapXepTheo = value;
            _sapXepDanhSach();
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _lamMoi() {
    FirebaseService.xoaCache();
    _animationController.reset();
    _taiDanhSachSanPham();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MauSac.denNen,
      body: SafeArea(
        child: Column(
          children: [
            // Header cố định
            _buildHeader(),
            
            // Nội dung chính
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: MauSac.denNhat, // Đổi từ gradient đỏ sang màu đen
      ),
      child: Column(
        children: [
          // Top navigation bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Back button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: MauSac.denNen,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: MauSac.kfcRed.withOpacity(0.2)),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: MauSac.trang,
                      size: 18,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                  ),
                ),
                
                const Spacer(),
                
                // Sort button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: MauSac.denNen,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: MauSac.kfcRed.withOpacity(0.2)),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.tune,
                      color: MauSac.trang,
                      size: 20,
                    ),
                    onPressed: _chonSapXep,
                    padding: EdgeInsets.zero,
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Refresh button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: MauSac.denNen,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: MauSac.kfcRed.withOpacity(0.2)),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.refresh,
                      color: MauSac.trang,
                      size: 20,
                    ),
                    onPressed: _lamMoi,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          
          // Category info
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: MauSac.kfcRed.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'DANH MỤC',
                    style: TextStyle(
                      color: MauSac.kfcRed,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Category name
                Text(
                  widget.danhMuc.ten,
                  style: const TextStyle(
                    color: MauSac.trang,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Category description
                if (widget.danhMuc.moTa.isNotEmpty)
                  Text(
                    widget.danhMuc.moTa,
                    style: TextStyle(
                      color: MauSac.xam.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_dangTai) {
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
              'Đang tải sản phẩm...',
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

    if (_loi != null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: MauSac.denNhat,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: MauSac.kfcRed.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MauSac.kfcRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: MauSac.kfcRed,
                ),
              ),
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
                style: const TextStyle(
                  color: MauSac.xam,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _lamMoi,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MauSac.kfcRed,
                  foregroundColor: MauSac.trang,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_danhSachSanPham.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: MauSac.denNhat,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: MauSac.kfcRed.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: MauSac.kfcRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 64,
                  color: MauSac.kfcRed,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Chưa có sản phẩm',
                style: TextStyle(
                  color: MauSac.trang,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chưa có sản phẩm nào trong danh mục "${widget.danhMuc.ten}"',
                style: const TextStyle(
                  color: MauSac.xam,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _lamMoi,
                icon: const Icon(Icons.refresh),
                label: const Text('Tải lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MauSac.kfcRed,
                  foregroundColor: MauSac.trang,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Stats info
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: MauSac.denNhat,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MauSac.kfcRed.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MauSac.kfcRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.restaurant_menu,
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
                      '${_danhSachSanPham.length} sản phẩm',
                      style: const TextStyle(
                        color: MauSac.trang,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Sắp xếp: ${_getSapXepText()}',
                      style: TextStyle(
                        color: MauSac.xam.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: MauSac.kfcRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_danhSachSanPham.length}',
                  style: const TextStyle(
                    color: MauSac.trang,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Products grid
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _danhSachSanPham.length,
                      itemBuilder: (context, index) {
                        return TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 300 + (index * 100)),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: Opacity(
                                opacity: value,
                                child: child,
                              ),
                            );
                          },
                          child: SanPhamCard(
                            sanPham: _danhSachSanPham[index],
                            showDiscount: true,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        
        const SizedBox(height: 16),
      ],
    );
  }

  String _getSapXepText() {
    switch (_sapXepTheo) {
      case 'ten':
        return 'Tên A-Z';
      case 'gia_tang':
        return 'Giá thấp đến cao';
      case 'gia_giam':
        return 'Giá cao đến thấp';
      case 'moi_nhat':
        return 'Mới nhất';
      default:
        return 'Tên A-Z';
    }
  }
}
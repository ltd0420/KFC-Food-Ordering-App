import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kfc/models/san_pham.dart';
import 'package:kfc/models/danh_gia.dart';
import 'package:kfc/services/danh_gia_service.dart';
import 'package:kfc/widgets/danh_gia_widget.dart';
import 'package:kfc/screens/man_hinh_viet_danh_gia.dart';
import 'package:kfc/theme/mau_sac.dart';

class ManHinhXemDanhGia extends StatefulWidget {
  final SanPham sanPham;

  const ManHinhXemDanhGia({
    Key? key,
    required this.sanPham,
  }) : super(key: key);

  @override
  State<ManHinhXemDanhGia> createState() => _ManHinhXemDanhGiaState();
}

class _ManHinhXemDanhGiaState extends State<ManHinhXemDanhGia>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<DanhGia> _danhSachDanhGia = [];
  ThongKeDanhGia? _thongKe;
  DanhGia? _danhGiaCuaToi;
  bool _dangTai = true;
  int _filterSao = 0; // 0 = tất cả, 1-5 = filter theo số sao

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
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

    _taiDuLieu();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _taiDuLieu() async {
    setState(() {
      _dangTai = true;
    });

    try {
      // Tải danh sách đánh giá
      final danhSach = await DanhGiaService.layDanhGiaTheoSanPham(widget.sanPham.id);
      
      // Tải thống kê
      final thongKe = await DanhGiaService.layThongKeDanhGia(widget.sanPham.id);
      
      // Kiểm tra đánh giá của người dùng hiện tại
      DanhGia? danhGiaCuaToi;
      final user = _auth.currentUser;
      if (user != null) {
        danhGiaCuaToi = await DanhGiaService.layDanhGiaCuaNguoiDung(
          widget.sanPham.id,
          user.uid,
        );
      }

      if (mounted) {
        setState(() {
          _danhSachDanhGia = danhSach;
          _thongKe = thongKe;
          _danhGiaCuaToi = danhGiaCuaToi;
          _dangTai = false;
        });
      }
    } catch (e) {
      print('Lỗi khi tải đánh giá: $e');
      if (mounted) {
        setState(() {
          _dangTai = false;
        });
      }
    }
  }

  List<DanhGia> get _danhSachDanhGiaFiltered {
    if (_filterSao == 0) {
      return _danhSachDanhGia;
    }
    return _danhSachDanhGia.where((danhGia) => danhGia.soSao == _filterSao).toList();
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip('Tất cả', 0),
          const SizedBox(width: 8),
          ...List.generate(5, (index) {
            final soSao = 5 - index;
            final soLuong = _thongKe?.phanBoSao[soSao] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip('$soSao ⭐ ($soLuong)', soSao),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int value) {
    final isSelected = _filterSao == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? MauSac.trang : MauSac.xam,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterSao = value;
        });
      },
      backgroundColor: MauSac.denNhat,
      selectedColor: MauSac.kfcRed,
      checkmarkColor: MauSac.trang,
      side: BorderSide(
        color: isSelected ? MauSac.kfcRed : MauSac.xam.withOpacity(0.3),
      ),
    );
  }

  Widget _buildMyReviewSection() {
    if (_danhGiaCuaToi == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: MauSac.denNhat,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MauSac.kfcRed.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.rate_review,
              color: MauSac.kfcRed,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'Chia sẻ trải nghiệm của bạn',
              style: TextStyle(
                color: MauSac.trang,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy cho chúng tôi biết bạn cảm thấy thế nào về món ăn này',
              style: TextStyle(
                color: MauSac.xam.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _vietDanhGia(),
                icon: const Icon(Icons.edit, size: 20),
                label: const Text(
                  'Viết đánh giá',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MauSac.kfcRed,
                  foregroundColor: MauSac.trang,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: MauSac.kfcRed, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Đánh giá của bạn',
                style: TextStyle(
                  color: MauSac.trang,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _chinhSuaDanhGia(),
                icon: const Icon(Icons.edit, size: 16, color: MauSac.kfcRed),
                label: const Text(
                  'Chỉnh sửa',
                  style: TextStyle(color: MauSac.kfcRed),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DanhGiaCard(danhGia: _danhGiaCuaToi!),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    final danhSachFiltered = _danhSachDanhGiaFiltered;
    
    if (danhSachFiltered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.comment_outlined,
              size: 64,
              color: MauSac.xam.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _filterSao == 0 
                  ? 'Chưa có đánh giá nào'
                  : 'Không có đánh giá $_filterSao sao',
              style: TextStyle(
                color: MauSac.xam.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: danhSachFiltered.length,
      itemBuilder: (context, index) {
        final danhGia = danhSachFiltered[index];
        
        // Không hiển thị đánh giá của người dùng hiện tại trong danh sách chung
        if (_danhGiaCuaToi != null && danhGia.id == _danhGiaCuaToi!.id) {
          return const SizedBox.shrink();
        }
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: DanhGiaCard(danhGia: danhGia),
        );
      },
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
        builder: (context) => ManHinhVietDanhGia(
          sanPham: widget.sanPham,
        ),
      ),
    );

    if (result == true) {
      _taiDuLieu(); // Tải lại dữ liệu sau khi viết đánh giá
    }
  }

  Future<void> _chinhSuaDanhGia() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ManHinhVietDanhGia(
          sanPham: widget.sanPham,
        ),
      ),
    );

    if (result == true) {
      _taiDuLieu(); // Tải lại dữ liệu sau khi chỉnh sửa
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MauSac.denNen,
      appBar: AppBar(
        backgroundColor: MauSac.denNen,
        foregroundColor: MauSac.trang,
        title: const Text(
          'Đánh giá sản phẩm',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _taiDuLieu,
          ),
        ],
      ),
      body: _dangTai
          ? const Center(
              child: CircularProgressIndicator(color: MauSac.kfcRed),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: _taiDuLieu,
                color: MauSac.kfcRed,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thống kê tổng quan
                      if (_thongKe != null)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: ThongKeDanhGiaWidget(thongKe: _thongKe!),
                        ),

                      // Đánh giá của tôi
                      _buildMyReviewSection(),

                      const SizedBox(height: 8),

                      // Filter chips
                      if (_thongKe != null && _thongKe!.tongSoDanhGia > 0)
                        _buildFilterChips(),

                      const SizedBox(height: 16),

                      // Danh sách đánh giá
                      _buildReviewsList(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: _danhGiaCuaToi == null
          ? FloatingActionButton.extended(
              onPressed: _vietDanhGia,
              backgroundColor: MauSac.kfcRed,
              foregroundColor: MauSac.trang,
              icon: const Icon(Icons.edit),
              label: const Text('Viết đánh giá'),
            )
          : null,
    );
  }
}

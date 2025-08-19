import 'package:flutter/material.dart';
import 'package:kfc/theme/mau_sac.dart';

class BannerKhuyenMai extends StatefulWidget {
  final List<Map<String, dynamic>> danhSachBanner;
  
  const BannerKhuyenMai({
    Key? key,
    required this.danhSachBanner,
  }) : super(key: key);

  @override
  State<BannerKhuyenMai> createState() => _BannerKhuyenMaiState();
}

class _BannerKhuyenMaiState extends State<BannerKhuyenMai> {
  final PageController _pageController = PageController();
  int _trangHienTai = 0;

  @override
  void initState() {
    super.initState();
    // Tự động chuyển trang sau mỗi 5 giây
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _batDauTuDongChuyenTrang();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _batDauTuDongChuyenTrang() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        if (_trangHienTai < widget.danhSachBanner.length - 1) {
          _trangHienTai++;
        } else {
          _trangHienTai = 0;
        }
        
        _pageController.animateToPage(
          _trangHienTai,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        
        _batDauTuDongChuyenTrang();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.danhSachBanner.length,
            onPageChanged: (index) {
              setState(() {
                _trangHienTai = index;
              });
            },
            itemBuilder: (context, index) {
              final banner = widget.danhSachBanner[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: MauSac.denNhat,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // Hình ảnh banner
                      Positioned.fill(
                        child: Image.asset(
                          banner['hinhAnh'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: MauSac.kfcRed.withOpacity(0.3),
                              child: Center(
                                child: Icon(
                                  Icons.fastfood,
                                  size: 60,
                                  color: MauSac.kfcRed,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Lớp phủ tối
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Nội dung banner
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              banner['tieuDe'],
                              style: const TextStyle(
                                color: MauSac.trang,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              banner['moTa'],
                              style: const TextStyle(
                                color: MauSac.trangNhat,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Nhãn khuyến mãi
                      if (banner['nhan'] != null)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: MauSac.kfcRed,
                              borderRadius: BorderRadius.circular(20),
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
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Chỉ báo trang
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.danhSachBanner.length,
            (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _trangHienTai == index
                    ? MauSac.kfcRed
                    : MauSac.xamDam,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:kfc/models/danh_gia.dart';
import 'package:kfc/theme/mau_sac.dart';

// Widget hiển thị rating stars
class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool allowHalfRating;

  const RatingStars({
    Key? key,
    required this.rating,
    this.size = 20,
    this.activeColor,
    this.inactiveColor,
    this.allowHalfRating = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          _getStarIcon(index + 1, rating),
          size: size,
          color: _getStarColor(index + 1, rating),
        );
      }),
    );
  }

  IconData _getStarIcon(int position, double rating) {
    if (allowHalfRating) {
      if (position <= rating) {
        return Icons.star;
      } else if (position - 0.5 <= rating) {
        return Icons.star_half;
      } else {
        return Icons.star_border;
      }
    } else {
      return position <= rating ? Icons.star : Icons.star_border;
    }
  }

  Color _getStarColor(int position, double rating) {
    if (position <= rating || (allowHalfRating && position - 0.5 <= rating)) {
      return activeColor ?? MauSac.vang;
    } else {
      return inactiveColor ?? MauSac.xam.withOpacity(0.3);
    }
  }
}

// Widget hiển thị thống kê đánh giá
class ThongKeDanhGiaWidget extends StatelessWidget {
  final ThongKeDanhGia thongKe;
  final bool showDetails;

  const ThongKeDanhGiaWidget({
    Key? key,
    required this.thongKe,
    this.showDetails = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MauSac.denNhat,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MauSac.kfcRed.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Điểm trung bình và số lượng đánh giá
          Row(
            children: [
              Text(
                thongKe.diemTrungBinhFormatted,
                style: const TextStyle(
                  color: MauSac.trang,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RatingStars(
                    rating: thongKe.diemTrungBinh,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${thongKe.tongSoDanhGiaFormatted} đánh giá',
                    style: TextStyle(
                      color: MauSac.xam.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          if (showDetails && thongKe.tongSoDanhGia > 0) ...[
            const SizedBox(height: 16),
            const Divider(color: MauSac.xam, height: 1),
            const SizedBox(height: 16),
            
            // Phân bố sao
            ...List.generate(5, (index) {
              final soSao = 5 - index;
              final soLuong = thongKe.phanBoSao[soSao] ?? 0;
              final phanTram = thongKe.tongSoDanhGia > 0 
                  ? (soLuong / thongKe.tongSoDanhGia) * 100 
                  : 0.0;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text(
                      '$soSao',
                      style: const TextStyle(
                        color: MauSac.trang,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.star,
                      color: MauSac.vang,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: MauSac.xam.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: phanTram / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              color: MauSac.kfcRed,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '$soLuong',
                        style: TextStyle(
                          color: MauSac.xam.withOpacity(0.8),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// Widget hiển thị một đánh giá
class DanhGiaCard extends StatelessWidget {
  final DanhGia danhGia;
  final bool showProductInfo;
  final VoidCallback? onTap;

  const DanhGiaCard({
    Key? key,
    required this.danhGia,
    this.showProductInfo = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('🎨 Rendering DanhGiaCard: ${danhGia.tenNguoiDung}, ${danhGia.soSao} sao, ${danhGia.binhLuan}');
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MauSac.denNhat,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MauSac.kfcRed.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với tên người dùng và thời gian
            Row(
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: MauSac.kfcRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      danhGia.tenNguoiDung.isNotEmpty 
                          ? danhGia.tenNguoiDung[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: MauSac.kfcRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Tên và thời gian
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        danhGia.tenNguoiDung.isNotEmpty ? danhGia.tenNguoiDung : 'Người dùng ẩn danh',
                        style: const TextStyle(
                          color: MauSac.trang,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        danhGia.ngayTaoFormatted,
                        style: TextStyle(
                          color: MauSac.xam.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Rating
                RatingStars(
                  rating: danhGia.soSao.toDouble(),
                  size: 16,
                  allowHalfRating: false,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Bình luận
            if (danhGia.binhLuan.isNotEmpty)
              Text(
                danhGia.binhLuan,
                style: const TextStyle(
                  color: MauSac.trang,
                  fontSize: 14,
                  height: 1.4,
                ),
              )
            else
              Text(
                'Người dùng chưa để lại bình luận.',
                style: TextStyle(
                  color: MauSac.xam.withOpacity(0.6),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            
            // Debug info (có thể xóa sau khi test xong)
            if (danhGia.binhLuan.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Debug: soSao=${danhGia.soSao}, tenNguoiDung="${danhGia.tenNguoiDung}"',
                  style: TextStyle(
                    color: MauSac.xam.withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
              ),
            
            // Hình ảnh đính kèm (nếu có)
            if (danhGia.hinhAnh != null && danhGia.hinhAnh!.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: danhGia.hinhAnh!.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: MauSac.kfcRed.withOpacity(0.3)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          danhGia.hinhAnh![index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: MauSac.xam.withOpacity(0.2),
                              child: const Icon(
                                Icons.image_not_supported,
                                color: MauSac.xam,
                                size: 30,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Widget cho việc chọn rating
class RatingSelector extends StatefulWidget {
  final int initialRating;
  final ValueChanged<int> onRatingChanged;
  final double size;

  const RatingSelector({
    Key? key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.size = 40,
  }) : super(key: key);

  @override
  State<RatingSelector> createState() => _RatingSelectorState();
}

class _RatingSelectorState extends State<RatingSelector> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        return GestureDetector(
          onTap: () {
            setState(() {
              _currentRating = starNumber;
            });
            widget.onRatingChanged(starNumber);
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            child: Icon(
              starNumber <= _currentRating ? Icons.star : Icons.star_border,
              size: widget.size,
              color: starNumber <= _currentRating 
                  ? MauSac.vang 
                  : MauSac.xam.withOpacity(0.5),
            ),
          ),
        );
      }),
    );
  }
}

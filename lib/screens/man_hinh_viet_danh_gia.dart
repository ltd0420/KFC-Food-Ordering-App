import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kfc/models/san_pham.dart';
import 'package:kfc/theme/mau_sac.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ManHinhVietDanhGia extends StatefulWidget {
  final SanPham sanPham;

  const ManHinhVietDanhGia({
    Key? key,
    required this.sanPham,
  }) : super(key: key);

  @override
  State<ManHinhVietDanhGia> createState() => _ManHinhVietDanhGiaState();
}

class _ManHinhVietDanhGiaState extends State<ManHinhVietDanhGia>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _binhLuanController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  int _soSao = 5;
  bool _dangGui = false;
  List<XFile> _selectedImages = [];
  final int _maxImages = 3; // Giới hạn số ảnh tối đa

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

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _binhLuanController.dispose();
    super.dispose();
  }

  String _getImagePath(String hinhAnh) {
    if (hinhAnh.isEmpty) return '';
    if (hinhAnh.startsWith('assets/')) return hinhAnh;
    return 'assets/images/$hinhAnh';
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && _selectedImages.length < _maxImages) {
      setState(() {
        _selectedImages.add(image);
      });
    } else if (_selectedImages.length >= _maxImages) {
      _showErrorSnackBar('Bạn chỉ có thể chọn tối đa $_maxImages ảnh');
    }
  }

  Widget _buildProductInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MauSac.denNhat,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MauSac.kfcRed.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 80,
              height: 80,
              child: _getImagePath(widget.sanPham.hinhAnh).isNotEmpty
                  ? Image.asset(
                      _getImagePath(widget.sanPham.hinhAnh),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: MauSac.kfcRed.withOpacity(0.8),
                          child: const Icon(
                            Icons.fastfood,
                            color: Colors.white,
                            size: 30,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: MauSac.kfcRed.withOpacity(0.8),
                      child: const Icon(
                        Icons.fastfood,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.sanPham.ten,
                  style: const TextStyle(
                    color: MauSac.trang,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.sanPham.gia.round()} ₫',
                  style: const TextStyle(
                    color: MauSac.kfcRed,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MauSac.denNhat,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MauSac.kfcRed.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.star, color: MauSac.vang, size: 24),
              SizedBox(width: 8),
              Text(
                'Đánh giá của bạn',
                style: TextStyle(
                  color: MauSac.trang,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _soSao = index + 1;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      index < _soSao ? Icons.star : Icons.star_border,
                      color: MauSac.vang,
                      size: 40,
                    ),
                  ),
                );
              }),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Center(
            child: Text(
              _getRatingDescription(_soSao),
              style: TextStyle(
                color: _getRatingColor(_soSao),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingDescription(int rating) {
    switch (rating) {
      case 1:
        return 'Rất không hài lòng';
      case 2:
        return 'Không hài lòng';
      case 3:
        return 'Bình thường';
      case 4:
        return 'Hài lòng';
      case 5:
        return 'Rất hài lòng';
      default:
        return 'Chọn đánh giá';
    }
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
      case 2:
        return MauSac.kfcRed;
      case 3:
        return MauSac.cam;
      case 4:
      case 5:
        return MauSac.xanhLa;
      default:
        return MauSac.xam;
    }
  }

  Widget _buildCommentSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MauSac.denNhat,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MauSac.kfcRed.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.comment, color: MauSac.kfcRed, size: 24),
              SizedBox(width: 8),
              Text(
                'Chia sẻ trải nghiệm',
                style: TextStyle(
                  color: MauSac.trang,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          TextField(
            controller: _binhLuanController,
            maxLines: 5,
            maxLength: 500,
            style: const TextStyle(color: MauSac.trang),
            decoration: InputDecoration(
              hintText: 'Chia sẻ cảm nhận của bạn về món ăn này...',
              hintStyle: TextStyle(color: MauSac.xam.withOpacity(0.6)),
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
              counterStyle: TextStyle(color: MauSac.xam.withOpacity(0.6)),
            ),
          ),

          const SizedBox(height: 16),

          // Image picker section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Đính kèm ảnh',
                style: TextStyle(
                  color: MauSac.trang,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_selectedImages.length}/$_maxImages',
                style: TextStyle(
                  color: MauSac.xam.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length + 1,
              itemBuilder: (context, index) {
                if (index == _selectedImages.length) {
                  return GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: MauSac.denNen,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: MauSac.kfcRed.withOpacity(0.3)),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.add_photo_alternate,
                          color: MauSac.kfcRed,
                          size: 40,
                        ),
                      ),
                    ),
                  );
                }

                return Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: MauSac.kfcRed.withOpacity(0.3)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_selectedImages[index].path),
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
                    Positioned(
                      top: 4,
                      right: 12,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImages.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: MauSac.kfcRed,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _dangGui ? null : _guiDanhGia,
        style: ElevatedButton.styleFrom(
          backgroundColor: MauSac.kfcRed,
          foregroundColor: MauSac.trang,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 5,
        ),
        child: _dangGui
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: MauSac.trang,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Đang gửi...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : const Text(
                'Gửi đánh giá',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _guiDanhGia() async {
    final user = _auth.currentUser;
    if (user == null) {
      _showErrorSnackBar('Vui lòng đăng nhập để đánh giá');
      return;
    }

    if (_binhLuanController.text.trim().isEmpty) {
      _showErrorSnackBar('Vui lòng nhập bình luận');
      return;
    }

    setState(() {
      _dangGui = true;
    });

    try {
      print('Bắt đầu gửi đánh giá...');
      print('User ID: ${user.uid}');
      print('Sản phẩm ID: ${widget.sanPham.id}');
      print('Số sao: $_soSao');
      print('Bình luận: ${_binhLuanController.text.trim()}');
      print('Số ảnh: ${_selectedImages.length}');

      // Lấy thông tin user từ Firestore
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      String tenNguoiDung = 'Người dùng KFC';
      
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        tenNguoiDung = userData['displayName'] ?? user.displayName ?? 'Người dùng KFC';
      } else if (user.displayName != null) {
        tenNguoiDung = user.displayName!;
      }

      print('Tên người dùng: $tenNguoiDung');

      // Tải ảnh lên Firebase Storage
      List<String> imageUrls = [];
      for (var image in _selectedImages) {
        final storageRef = _storage.ref().child('danh_gia_images/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_${image.name}');
        final uploadTask = await storageRef.putFile(File(image.path));
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
        print('Đã tải ảnh lên: $downloadUrl');
      }

      // Tạo dữ liệu đánh giá
      Map<String, dynamic> danhGiaData = {
        'sanPhamId': widget.sanPham.id,
        'nguoiDungId': user.uid,
        'tenNguoiDung': tenNguoiDung,
        'soSao': _soSao,
        'binhLuan': _binhLuanController.text.trim(),
        'ngayTao': FieldValue.serverTimestamp(),
        'ngayCapNhat': FieldValue.serverTimestamp(),
        'hinhAnh': imageUrls.isNotEmpty ? imageUrls : null,
      };

      print('Dữ liệu đánh giá: $danhGiaData');

      // Lưu vào Firestore
      DocumentReference docRef = await _firestore.collection('danh_gia').add(danhGiaData);
      
      print('Đã lưu đánh giá với ID: ${docRef.id}');

      _showSuccessSnackBar('Gửi đánh giá thành công!');
      
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        Navigator.of(context).pop(true);
      }

    } catch (e) {
      print('Lỗi khi gửi đánh giá: $e');
      _showErrorSnackBar('Lỗi: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _dangGui = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: MauSac.xanhLa,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: MauSac.kfcRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MauSac.denNen,
      appBar: AppBar(
        backgroundColor: MauSac.denNen,
        foregroundColor: MauSac.trang,
        title: const Text(
          'Viết đánh giá',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductInfo(),
                const SizedBox(height: 20),
                _buildRatingSection(),
                const SizedBox(height: 20),
                _buildCommentSection(),
                const SizedBox(height: 32),
                _buildSubmitButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
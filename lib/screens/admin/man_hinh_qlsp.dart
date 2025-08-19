import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kfc/theme/mau_sac.dart';
import 'package:kfc/models/san_pham.dart';
import 'package:kfc/models/danh_muc.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

class ManHinhQLSP extends StatefulWidget {
  const ManHinhQLSP({Key? key}) : super(key: key);

  @override
  State<ManHinhQLSP> createState() => _ManHinhQLSPState();
}

class _ManHinhQLSPState extends State<ManHinhQLSP> with SingleTickerProviderStateMixin {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<DanhMuc> _categories = [];
  bool _categoriesLoaded = false;
  bool _isLoading = false;

  // Firebase Storage instance
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadCategories();

    // Khởi tạo animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0.0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Hàm helper để parse int an toàn
  int _parseToInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  // Hàm helper để parse int nullable an toàn
  int? _parseToIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  // Hàm helper để parse bool an toàn
  bool _parseToBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is num) return value != 0;
    return defaultValue;
  }

  // Hàm để hiển thị hình ảnh từ URL hoặc assets
  Widget _buildImage(String imagePath, {double? width, double? height, BoxFit? fit}) {
    if (imagePath.isEmpty) return _buildPlaceholderImage(width: width, height: height);

    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(width: width, height: height),
      );
    }

    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(width: width, height: height),
    );
  }

  Widget _buildPlaceholderImage({double? width, double? height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [MauSac.kfcRed.withOpacity(0.8), MauSac.kfcRed.withOpacity(0.6)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fastfood, size: 32, color: Colors.white),
            SizedBox(height: 4),
            Text(
              'Chưa có hình ảnh',
              style: TextStyle(color: Colors.white, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Hàm upload ảnh lên Firebase Storage
  Future<String?> _uploadImage(File image, String productId) async {
    try {
      final fileName = '${productId}_${path.basename(image.path)}';
      final ref = _storage.ref().child('products/$fileName');
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Lỗi khi upload ảnh: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi upload ảnh: $e'),
          backgroundColor: MauSac.kfcRed,
        ),
      );
      return null;
    }
  }

  // Hàm xóa ảnh từ Firebase Storage
  Future<void> _deleteImage(String imageUrl) async {
    if (imageUrl.isEmpty || !imageUrl.startsWith('http')) return;
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Lỗi khi xóa ảnh: $e');
    }
  }

  Future<void> _loadCategories() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('danh_muc')
          .orderBy('ten')
          .get();

      final List<DanhMuc> loadedCategories = [];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          loadedCategories.add(DanhMuc.fromJson(data));
        } catch (e) {
          print('Lỗi khi parse danh mục ${doc.id}: $e');
          loadedCategories.add(DanhMuc(
            id: doc.id,
            ten: 'Danh mục ${doc.id}',
            hinhAnh: '',
            moTa: '',
          ));
        }
      }

      setState(() {
        _categories = loadedCategories;
        _categoriesLoaded = true;
        _isLoading = false;
      });
    } catch (e) {
      print('Lỗi khi tải danh mục: $e');
      setState(() {
        _categoriesLoaded = true;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải danh mục: $e'),
            backgroundColor: MauSac.kfcRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MauSac.denNhat,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildFilterAndSearch(),
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) => FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _buildProductList(),
                        ),
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

  Widget _buildCustomHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: MauSac.denNhat,
        border: Border(
          bottom: BorderSide(
            color: MauSac.xamDam.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Quản lý sản phẩm',
            style: TextStyle(
              color: MauSac.trang,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: MauSac.kfcRed,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _isLoading ? null : () {
                  setState(() {});
                  _loadCategories();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: MauSac.trang,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.refresh, color: MauSac.trang, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Làm mới',
                        style: TextStyle(
                          color: MauSac.trang,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndSearch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MauSac.denNhat,
        border: Border(
          bottom: BorderSide(
            color: MauSac.xamDam.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('san_pham').snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.docs.length ?? 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: MauSac.xamDam.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count sản phẩm',
                      style: TextStyle(
                        color: MauSac.xam,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: MauSac.xanhLa,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _showAddProductDialog(),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: MauSac.trang, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Thêm sản phẩm',
                            style: TextStyle(
                              color: MauSac.trang,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: MauSac.denNen,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: MauSac.xamDam.withOpacity(0.3)),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: MauSac.trang),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                hintStyle: TextStyle(color: MauSac.xam.withOpacity(0.7)),
                prefixIcon: Icon(Icons.search, color: MauSac.xam, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: MauSac.xam, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          if (_categoriesLoaded) ...[
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip('all', 'Tất cả', Icons.apps),
                  _buildFilterChip('promotion', 'Khuyến mãi', Icons.local_offer),
                  ..._categories.map((category) =>
                      _buildFilterChip(category.id, category.ten, _getCategoryIcon(category.id))),
                ],
              ),
            ),
          ] else ...[
            SizedBox(
              height: 36,
              child: Center(
                child: CircularProgressIndicator(
                  color: MauSac.kfcRed,
                  strokeWidth: 2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? MauSac.trang : MauSac.xam,
            ),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        labelStyle: TextStyle(
          color: isSelected ? MauSac.trang : MauSac.xam,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 11,
        ),
        backgroundColor: MauSac.denNen,
        selectedColor: MauSac.kfcRed,
        checkmarkColor: MauSac.trang,
        side: BorderSide(
          color: isSelected ? MauSac.kfcRed : MauSac.xamDam.withOpacity(0.3),
        ),
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
        },
      ),
    );
  }

  Widget _buildProductList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('san_pham')
          .orderBy('ten')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _buildErrorWidget(snapshot.error.toString());

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: MauSac.kfcRed),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        List<SanPham> products = [];
        for (var doc in docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            final processedData = _processProductData(data);
            products.add(SanPham.fromJson(processedData));
          } catch (e) {
            print('Lỗi khi parse sản phẩm ${doc.id}: $e');
          }
        }

        if (_searchQuery.isNotEmpty) {
          products = products.where((product) {
            return product.ten.toLowerCase().contains(_searchQuery) ||
                   product.moTa.toLowerCase().contains(_searchQuery);
          }).toList();
        }

        if (_selectedFilter != 'all') {
          if (_selectedFilter == 'promotion') {
            products = products.where((product) => product.coKhuyenMai).toList();
          } else {
            products = products.where((product) => 
                product.danhMucId == _selectedFilter).toList();
          }
        }

        if (products.isEmpty) return _buildEmptyWidget();

        final width = MediaQuery.of(context).size.width;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: width > 800 ? _buildGridView(products) : _buildListView(products),
        );
      },
    );
  }

  Map<String, dynamic> _processProductData(Map<String, dynamic> data) {
    final processedData = Map<String, dynamic>.from(data);

    processedData['gia'] = _parseToInt(data['gia']);
    final hasPromotion = _parseToBool(data['khuyenMai']);
    processedData['khuyenMai'] = hasPromotion;
    processedData['giamGia'] = hasPromotion ? _parseToIntNullable(data['giamGia']) ?? 0 : null;

    if (data.containsKey('danhMucID') && !data.containsKey('danhMucId')) {
      processedData['danhMucId'] = data['danhMucID'];
    } else if (!data.containsKey('danhMucID') && !data.containsKey('danhMucId')) {
      processedData['danhMucId'] = '';
    }

    processedData['ten'] = data['ten'] ?? 'Sản phẩm không tên';
    processedData['moTa'] = data['moTa'] ?? '';
    processedData['hinhAnh'] = data['hinhAnh'] ?? '';

    return processedData;
  }

  Widget _buildGridView(List<SanPham> products) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _buildProductCard(products[index], index);
      },
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
    );
  }

  Widget _buildListView(List<SanPham> products) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _buildProductListItem(products[index], index);
      },
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
    );
  }

  Widget _buildProductCard(SanPham product, int index) {
    return Hero(
      tag: 'product_${product.id}',
      child: Card(
        color: MauSac.denNen,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: MauSac.xamDam.withOpacity(0.2),
          ),
        ),
        child: InkWell(
          onTap: () => _showProductDetailDialog(product),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: MauSac.xamNhat,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: _buildImage(
                          product.hinhAnh,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (product.coKhuyenMai)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: MauSac.kfcRed,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '-${product.phanTramGiamGia}%',
                            style: const TextStyle(
                              color: MauSac.trang,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.visibility, color: Colors.white, size: 18),
                          onPressed: () => _showProductDetailDialog(product),
                          tooltip: 'Xem chi tiết',
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                          iconSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.ten,
                        style: const TextStyle(
                          color: MauSac.trang,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getCategoryName(product.danhMucId),
                        style: TextStyle(
                          color: MauSac.cam,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      if (product.coKhuyenMai) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_formatPrice(product.gia)} VNĐ',
                              style: TextStyle(
                                color: MauSac.xam,
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            Text(
                              '${_formatPrice(product.giaGiam)} VNĐ',
                              style: const TextStyle(
                                color: MauSac.kfcRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          '${_formatPrice(product.gia)} VNĐ',
                          style: const TextStyle(
                            color: MauSac.kfcRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const Spacer(),
                      SizedBox(
                        height: 32,
                        child: Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 32,
                                child: OutlinedButton(
                                  onPressed: () => _showEditProductDialog(product),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: MauSac.cam,
                                    side: BorderSide(color: MauSac.cam, width: 1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    minimumSize: const Size(0, 32),
                                  ),
                                  child: const Text('Sửa', style: TextStyle(fontSize: 9)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            SizedBox(
                              width: 30,
                              height: 32,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () => _showProductOptionsMenu(context, product),
                                  child: Container(
                                    width: 30,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.more_vert,
                                      color: MauSac.xam,
                                      size: 14,
                                    ),
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
          ],
        ),
      ),
    )
    );
  }

  void _showProductDetailDialog(SanPham product) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: MauSac.denNhat,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: MauSac.denNen,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Chi tiết sản phẩm',
                        style: TextStyle(
                          color: MauSac.trang,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: MauSac.xam),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Hero(
                            tag: 'product_${product.id}',
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                color: MauSac.xamNhat,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  children: [
                                    _buildImage(
                                      product.hinhAnh,
                                      width: 180,
                                      height: 180,
                                      fit: BoxFit.cover,
                                    ),
                                    if (product.coKhuyenMai)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: MauSac.kfcRed,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '-${product.phanTramGiamGia}%',
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
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow('ID sản phẩm', product.id),
                        _buildDetailRow('Tên sản phẩm', product.ten),
                        _buildDetailRow('Danh mục', _getCategoryName(product.danhMucId)),
                        if (product.coKhuyenMai) ...[
                          _buildDetailRow('Giá gốc', '${_formatPrice(product.gia)} VNĐ', isStrikethrough: true),
                          _buildDetailRow('Giá khuyến mãi', '${_formatPrice(product.giaGiam)} VNĐ', isPrice: true),
                          _buildDetailRow('Giảm giá', '${product.phanTramGiamGia}%'),
                        ] else ...[
                          _buildDetailRow('Giá', '${_formatPrice(product.gia)} VNĐ', isPrice: true),
                        ],
                        if (product.moTa.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Mô tả:',
                            style: TextStyle(
                              color: MauSac.trang,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.moTa,
                            style: TextStyle(
                              color: MauSac.xam,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showEditProductDialog(product);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: MauSac.cam,
                            side: BorderSide(color: MauSac.cam),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Chỉnh sửa'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showProductOptionsMenu(context, product);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MauSac.kfcRed,
                            foregroundColor: MauSac.trang,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.more_horiz, size: 18),
                          label: const Text('Tùy chọn'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isPrice = false, bool isStrikethrough = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: MauSac.xam,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isPrice ? MauSac.kfcRed : MauSac.trang,
                fontSize: 14,
                fontWeight: isPrice ? FontWeight.bold : FontWeight.normal,
                decoration: isStrikethrough ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProductOptionsMenu(BuildContext context, SanPham product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MauSac.denNhat,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: MauSac.xam,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tùy chọn cho "${product.ten}"',
                  style: const TextStyle(
                    color: MauSac.trang,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.visibility, color: MauSac.xanhLa),
                  title: const Text(
                    'Xem chi tiết',
                    style: TextStyle(color: MauSac.trang),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showProductDetailDialog(product);
                  },
                ),
                ListTile(
                  leading: Icon(
                    product.coKhuyenMai ? Icons.local_offer_outlined : Icons.local_offer,
                    color: MauSac.vang,
                  ),
                  title: Text(
                    product.coKhuyenMai ? 'Tắt khuyến mãi' : 'Bật khuyến mãi',
                    style: const TextStyle(color: MauSac.trang),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _togglePromotion(product);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete, color: MauSac.kfcRed),
                  title: const Text(
                    'Xóa sản phẩm',
                    style: TextStyle(color: MauSac.trang),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _deleteProduct(product);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductListItem(SanPham product, int index) {
    return Hero(
      tag: 'product_${product.id}',
      child: Card(
        color: MauSac.denNen,
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: MauSac.xamDam.withOpacity(0.2),
          ),
        ),
        child: InkWell(
          onTap: () => _showProductDetailDialog(product),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: MauSac.xamNhat,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildImage(
                          product.hinhAnh,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (product.coKhuyenMai)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: MauSac.kfcRed,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-${product.phanTramGiamGia}%',
                            style: const TextStyle(
                              color: MauSac.trang,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.ten,
                          style: const TextStyle(
                            color: MauSac.trang,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getCategoryName(product.danhMucId),
                          style: TextStyle(
                            color: MauSac.cam,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (product.coKhuyenMai) ...[
                          Wrap(
                            spacing: 6,
                            children: [
                              Text(
                                '${_formatPrice(product.gia)} VNĐ',
                                style: TextStyle(
                                  color: MauSac.xam,
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              Text(
                                '${_formatPrice(product.giaGiam)} VNĐ',
                                style: const TextStyle(
                                  color: MauSac.kfcRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(
                            '${_formatPrice(product.gia)} VNĐ',
                            style: const TextStyle(
                              color: MauSac.kfcRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        if (product.moTa.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            product.moTa,
                            style: TextStyle(
                              color: MauSac.xam,
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: IconButton(
                          onPressed: () => _showProductDetailDialog(product),
                          icon: Icon(Icons.visibility, color: MauSac.xanhLa, size: 18),
                          tooltip: 'Xem chi tiết',
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: IconButton(
                          onPressed: () => _showEditProductDialog(product),
                          icon: Icon(Icons.edit, color: MauSac.cam, size: 18),
                          tooltip: 'Sửa',
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: IconButton(
                          onPressed: () => _showProductOptionsMenu(context, product),
                          icon: const Icon(Icons.more_vert, color: MauSac.xam, size: 18),
                          tooltip: 'Thêm tùy chọn',
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: MauSac.kfcRed,
            ),
            const SizedBox(height: 16),
            const Text(
              'Có lỗi xảy ra',
              style: TextStyle(
                color: MauSac.trang,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: MauSac.xam),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() {}),
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

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: MauSac.xam,
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có sản phẩm nào',
              style: TextStyle(
                color: MauSac.trang,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Không tìm thấy sản phẩm phù hợp'
                  : _categories.isEmpty
                      ? 'Vui lòng tạo danh mục trước khi thêm sản phẩm'
                      : 'Nhấn nút "+" để thêm sản phẩm đầu tiên',
              style: TextStyle(color: MauSac.xam),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty && _categories.isNotEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showAddProductDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MauSac.xanhLa,
                  foregroundColor: MauSac.trang,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Thêm sản phẩm đầu tiên'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showAddProductDialog() async {
    if (!_categoriesLoaded || _categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng tạo danh mục trước khi thêm sản phẩm'),
          backgroundColor: MauSac.cam,
        ),
      );
      return;
    }

    final tenController = TextEditingController();
    final giaController = TextEditingController();
    final moTaController = TextEditingController();
    String selectedDanhMuc = _categories.first.id;
    bool coKhuyenMai = false;
    final giamGiaController = TextEditingController(text: '10');
    File? selectedImage;
    bool isUploading = false;

    bool tenError = false;
    bool giaError = false;
    bool giamGiaError = false;
    String tenErrorText = '';
    String giaErrorText = '';
    String giamGiaErrorText = '';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: MauSac.denNhat,
          contentPadding: const EdgeInsets.all(16),
          title: const Text(
            'Thêm sản phẩm mới',
            style: TextStyle(
              color: MauSac.trang,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: tenController,
                    style: const TextStyle(color: MauSac.trang),
                    decoration: InputDecoration(
                      labelText: 'Tên sản phẩm *',
                      labelStyle: TextStyle(color: MauSac.xam),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: tenError ? MauSac.kfcRed : MauSac.xam),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: tenError ? MauSac.kfcRed : MauSac.cam),
                      ),
                      errorText: tenError ? tenErrorText : null,
                      errorStyle: const TextStyle(color: MauSac.kfcRed),
                    ),
                    onChanged: (value) {
                      if (tenError) {
                        setDialogState(() {
                          tenError = false;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedDanhMuc,
                    style: const TextStyle(color: MauSac.trang),
                    dropdownColor: MauSac.denNhat,
                    decoration: InputDecoration(
                      labelText: 'Danh mục *',
                      labelStyle: TextStyle(color: MauSac.xam),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: MauSac.xam),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: MauSac.cam),
                      ),
                    ),
                    items: _categories.map((DanhMuc category) {
                      return DropdownMenuItem<String>(
                        value: category.id,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: _buildImage(
                                category.hinhAnh,
                                width: 24,
                                height: 24,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                category.ten,
                                style: const TextStyle(color: MauSac.trang),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => selectedDanhMuc = value!,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: giaController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: MauSac.trang),
                    decoration: InputDecoration(
                      labelText: 'Giá (VNĐ) *',
                      labelStyle: TextStyle(color: MauSac.xam),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: giaError ? MauSac.kfcRed : MauSac.xam),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: giaError ? MauSac.kfcRed : MauSac.cam),
                      ),
                      errorText: giaError ? giaErrorText : null,
                      errorStyle: const TextStyle(color: MauSac.kfcRed),
                      hintText: 'Nhập giá sản phẩm',
                      hintStyle: TextStyle(color: MauSac.xam.withOpacity(0.5)),
                    ),
                    onChanged: (value) {
                      if (giaError) {
                        setDialogState(() {
                          giaError = false;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: moTaController,
                    maxLines: 3,
                    style: const TextStyle(color: MauSac.trang),
                    decoration: InputDecoration(
                      labelText: 'Mô tả',
                      labelStyle: TextStyle(color: MauSac.xam),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: MauSac.xam),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: MauSac.cam),
                      ),
                      hintText: 'Nhập mô tả sản phẩm (không bắt buộc)',
                      hintStyle: TextStyle(color: MauSac.xam.withOpacity(0.5)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Hình ảnh sản phẩm',
                    style: TextStyle(
                      color: MauSac.trang,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isUploading
                              ? null
                              : () async {
                                  final picker = ImagePicker();
                                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                                  if (pickedFile != null) {
                                    setDialogState(() {
                                      selectedImage = File(pickedFile.path);
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MauSac.xanhLa,
                            foregroundColor: MauSac.trang,
                          ),
                          icon: const Icon(Icons.image),
                          label: Text(selectedImage == null ? 'Chọn ảnh' : 'Đổi ảnh'),
                        ),
                      ),
                      if (selectedImage != null) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: MauSac.denNen,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: MauSac.xamDam.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.local_offer, color: MauSac.vang, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Khuyến mãi',
                              style: TextStyle(
                                color: MauSac.trang,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Switch(
                              value: coKhuyenMai,
                              onChanged: (value) {
                                setDialogState(() {
                                  coKhuyenMai = value;
                                  if (!value) {
                                    giamGiaError = false;
                                  }
                                });
                              },
                              activeColor: MauSac.kfcRed,
                            ),
                          ],
                        ),
                        if (coKhuyenMai) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: giamGiaController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: MauSac.trang),
                            decoration: InputDecoration(
                              labelText: 'Phần trăm giảm giá (%) *',
                              labelStyle: TextStyle(color: MauSac.xam),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: giamGiaError ? MauSac.kfcRed : MauSac.xam),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: giamGiaError ? MauSac.kfcRed : MauSac.cam),
                              ),
                              errorText: giamGiaError ? giamGiaErrorText : null,
                              errorStyle: const TextStyle(color: MauSac.kfcRed),
                              hintText: 'Nhập % giảm giá (1-100)',
                              hintStyle: TextStyle(color: MauSac.xam.withOpacity(0.5)),
                            ),
                            onChanged: (value) {
                              if (giamGiaError) {
                                setDialogState(() {
                                  giamGiaError = false;
                                });
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: MauSac.xam)),
            ),
            ElevatedButton(
              onPressed: isUploading
                  ? null
                  : () async {
                      bool isValid = true;
                      if (tenController.text.trim().isEmpty) {
                        setDialogState(() {
                          tenError = true;
                          tenErrorText = 'Vui lòng nhập tên sản phẩm';
                          isValid = false;
                        });
                      }
                      if (giaController.text.trim().isEmpty) {
                        setDialogState(() {
                          giaError = true;
                          giaErrorText = 'Vui lòng nhập giá sản phẩm';
                          isValid = false;
                        });
                      } else {
                        final gia = int.tryParse(giaController.text.trim());
                        if (gia == null || gia <= 0) {
                          setDialogState(() {
                            giaError = true;
                            giaErrorText = 'Giá phải là số dương';
                            isValid = false;
                          });
                        }
                      }
                      if (coKhuyenMai) {
                        if (giamGiaController.text.trim().isEmpty) {
                          setDialogState(() {
                            giamGiaError = true;
                            giamGiaErrorText = 'Vui lòng nhập % giảm giá';
                            isValid = false;
                          });
                        } else {
                          final giamGia = int.tryParse(giamGiaController.text.trim());
                          if (giamGia == null || giamGia <= 0 || giamGia > 100) {
                            setDialogState(() {
                              giamGiaError = true;
                              giamGiaErrorText = 'Giảm giá phải từ 1-100%';
                              isValid = false;
                            });
                          }
                        }
                      }
                      if (isValid) {
                        setDialogState(() {
                          isUploading = true;
                        });
                        String? imageUrl = '';
                        if (selectedImage != null) {
                          final tempId = DateTime.now().millisecondsSinceEpoch.toString();
                          imageUrl = await _uploadImage(selectedImage!, tempId);
                        }
                        if (imageUrl != null) {
                          final gia = int.tryParse(giaController.text.trim()) ?? 0;
                          final giamGia = coKhuyenMai ? (int.tryParse(giamGiaController.text.trim()) ?? 0) : null;
                          await _addProduct(
                            tenController.text.trim(),
                            selectedDanhMuc,
                            gia,
                            moTaController.text.trim(),
                            imageUrl,
                            coKhuyenMai,
                            giamGia,
                          );
                          Navigator.pop(context);
                        }
                        setDialogState(() {
                          isUploading = false;
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: MauSac.kfcRed,
                foregroundColor: MauSac.trang,
              ),
              child: isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: MauSac.trang,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditProductDialog(SanPham product) async {
    if (!_categoriesLoaded || _categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Không thể tải danh mục'),
          backgroundColor: MauSac.cam,
        ),
      );
      return;
    }

    final tenController = TextEditingController(text: product.ten);
    final giaController = TextEditingController(text: product.gia.toString());
    final moTaController = TextEditingController(text: product.moTa);
    String selectedDanhMuc = product.danhMucId;
    bool coKhuyenMai = product.coKhuyenMai;
    final giamGiaController = TextEditingController(
        text: product.giamGia?.toString() ?? '10');
    File? selectedImage;
    bool isUploading = false;
    String? currentImageUrl = product.hinhAnh;

    bool tenError = false;
    bool giaError = false;
    bool giamGiaError = false;
    String tenErrorText = '';
    String giaErrorText = '';
    String giamGiaErrorText = '';

    if (!_categories.any((cat) => cat.id == selectedDanhMuc)) {
      selectedDanhMuc = _categories.first.id;
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: MauSac.denNhat,
          contentPadding: const EdgeInsets.all(16),
          title: Row(
            children: [
              const Text(
                'Sửa sản phẩm',
                style: TextStyle(
                  color: MauSac.trang,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'ID: ${product.id}',
                style: TextStyle(
                  color: MauSac.xam,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: tenController,
                    style: const TextStyle(color: MauSac.trang),
                    decoration: InputDecoration(
                      labelText: 'Tên sản phẩm *',
                      labelStyle: TextStyle(color: MauSac.xam),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: tenError ? MauSac.kfcRed : MauSac.xam),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: tenError ? MauSac.kfcRed : MauSac.cam),
                      ),
                      errorText: tenError ? tenErrorText : null,
                      errorStyle: const TextStyle(color: MauSac.kfcRed),
                    ),
                    onChanged: (value) {
                      if (tenError) {
                        setDialogState(() {
                          tenError = false;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedDanhMuc,
                    style: const TextStyle(color: MauSac.trang),
                    dropdownColor: MauSac.denNhat,
                    decoration: InputDecoration(
                      labelText: 'Danh mục *',
                      labelStyle: TextStyle(color: MauSac.xam),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: MauSac.xam),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: MauSac.cam),
                      ),
                    ),
                    items: _categories.map((DanhMuc category) {
                      return DropdownMenuItem<String>(
                        value: category.id,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: _buildImage(
                                category.hinhAnh,
                                width: 24,
                                height: 24,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                category.ten,
                                style: const TextStyle(color: MauSac.trang),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => selectedDanhMuc = value!,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: giaController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: MauSac.trang),
                    decoration: InputDecoration(
                      labelText: 'Giá (VNĐ) *',
                      labelStyle: TextStyle(color: MauSac.xam),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: giaError ? MauSac.kfcRed : MauSac.xam),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: giaError ? MauSac.kfcRed : MauSac.cam),
                      ),
                      errorText: giaError ? giaErrorText : null,
                      errorStyle: const TextStyle(color: MauSac.kfcRed),
                    ),
                    onChanged: (value) {
                      if (giaError) {
                        setDialogState(() {
                          giaError = false;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: moTaController,
                    maxLines: 3,
                    style: const TextStyle(color: MauSac.trang),
                    decoration: InputDecoration(
                      labelText: 'Mô tả',
                      labelStyle: TextStyle(color: MauSac.xam),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: MauSac.xam),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: MauSac.cam),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Hình ảnh sản phẩm',
                    style: TextStyle(
                      color: MauSac.trang,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isUploading
                              ? null
                              : () async {
                                  final picker = ImagePicker();
                                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                                  if (pickedFile != null) {
                                    setDialogState(() {
                                      selectedImage = File(pickedFile.path);
                                      currentImageUrl = null;
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MauSac.xanhLa,
                            foregroundColor: MauSac.trang,
                          ),
                          icon: const Icon(Icons.image),
                          label: Text(currentImageUrl != null || selectedImage != null ? 'Đổi ảnh' : 'Chọn ảnh'),
                        ),
                      ),
                      if (currentImageUrl != null || selectedImage != null) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: selectedImage != null
                                ? Image.file(
                                    selectedImage!,
                                    fit: BoxFit.cover,
                                  )
                                : _buildImage(
                                    currentImageUrl!,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: MauSac.denNen,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: MauSac.xamDam.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.local_offer, color: MauSac.vang, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Khuyến mãi',
                              style: TextStyle(
                                color: MauSac.trang,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Switch(
                              value: coKhuyenMai,
                              onChanged: (value) {
                                setDialogState(() {
                                  coKhuyenMai = value;
                                  if (!value) {
                                    giamGiaError = false;
                                  }
                                });
                              },
                              activeColor: MauSac.kfcRed,
                            ),
                          ],
                        ),
                        if (coKhuyenMai) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: giamGiaController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: MauSac.trang),
                            decoration: InputDecoration(
                              labelText: 'Phần trăm giảm giá (%) *',
                              labelStyle: TextStyle(color: MauSac.xam),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: giamGiaError ? MauSac.kfcRed : MauSac.xam),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: giamGiaError ? MauSac.kfcRed : MauSac.cam),
                              ),
                              errorText: giamGiaError ? giamGiaErrorText : null,
                              errorStyle: const TextStyle(color: MauSac.kfcRed),
                            ),
                            onChanged: (value) {
                              if (giamGiaError) {
                                setDialogState(() {
                                  giamGiaError = false;
                                });
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: MauSac.xam)),
            ),
            ElevatedButton(
              onPressed: isUploading
                  ? null
                  : () async {
                      bool isValid = true;
                      if (tenController.text.trim().isEmpty) {
                        setDialogState(() {
                          tenError = true;
                          tenErrorText = 'Vui lòng nhập tên sản phẩm';
                          isValid = false;
                        });
                      }
                      if (giaController.text.trim().isEmpty) {
                        setDialogState(() {
                          giaError = true;
                          giaErrorText = 'Vui lòng nhập giá sản phẩm';
                          isValid = false;
                        });
                      } else {
                        final gia = int.tryParse(giaController.text.trim());
                        if (gia == null || gia <= 0) {
                          setDialogState(() {
                            giaError = true;
                            giaErrorText = 'Giá phải là số dương';
                            isValid = false;
                          });
                        }
                      }
                      if (coKhuyenMai) {
                        if (giamGiaController.text.trim().isEmpty) {
                          setDialogState(() {
                            giamGiaError = true;
                            giamGiaErrorText = 'Vui lòng nhập % giảm giá';
                            isValid = false;
                          });
                        } else {
                          final giamGia = int.tryParse(giamGiaController.text.trim());
                          if (giamGia == null || giamGia <= 0 || giamGia > 100) {
                            setDialogState(() {
                              giamGiaError = true;
                              giamGiaErrorText = 'Giảm giá phải từ 1-100%';
                              isValid = false;
                            });
                          }
                        }
                      }
                      if (isValid) {
                        setDialogState(() {
                          isUploading = true;
                        });
                        String? imageUrl = currentImageUrl;
                        if (selectedImage != null) {
                          if (currentImageUrl != null && currentImageUrl!.startsWith('http')) {
                            await _deleteImage(currentImageUrl!);
                          }
                          imageUrl = await _uploadImage(selectedImage!, product.id);
                        }
                        if (imageUrl != null) {
                          final gia = int.tryParse(giaController.text.trim()) ?? 0;
                          final giamGia = coKhuyenMai ? (int.tryParse(giamGiaController.text.trim()) ?? 0) : null;
                          await _updateProduct(
                            product.id,
                            tenController.text.trim(),
                            selectedDanhMuc,
                            gia,
                            moTaController.text.trim(),
                            imageUrl,
                            coKhuyenMai,
                            giamGia,
                          );
                          Navigator.pop(context);
                        }
                        setDialogState(() {
                          isUploading = false;
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: MauSac.cam,
                foregroundColor: MauSac.trang,
              ),
              child: isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: MauSac.trang,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addProduct(
    String ten,
    String danhMucId,
    int gia,
    String moTa,
    String hinhAnh,
    bool coKhuyenMai,
    int? giamGia,
  ) async {
    try {
      final data = {
        'ten': ten,
        'gia': gia,
        'moTa': moTa,
        'hinhAnh': hinhAnh,
        'khuyenMai': coKhuyenMai,
        'giamGia': coKhuyenMai ? giamGia : null,
        'ngayTao': FieldValue.serverTimestamp(),
        'danhMucID': danhMucId,
        'danhMucId': danhMucId,
      };

      await FirebaseFirestore.instance.collection('san_pham').add(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm sản phẩm: $ten'),
            backgroundColor: MauSac.xanhLa,
          ),
        );
      }
    } catch (e) {
      print('Lỗi khi thêm sản phẩm: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi thêm sản phẩm: $e'),
            backgroundColor: MauSac.kfcRed,
          ),
        );
      }
    }
  }

  Future<void> _updateProduct(
    String id,
    String ten,
    String danhMucId,
    int gia,
    String moTa,
    String hinhAnh,
    bool coKhuyenMai,
    int? giamGia,
  ) async {
    try {
      final data = {
        'ten': ten,
        'gia': gia,
        'moTa': moTa,
        'hinhAnh': hinhAnh,
        'khuyenMai': coKhuyenMai,
        'giamGia': coKhuyenMai ? giamGia : null,
        'ngayCapNhat': FieldValue.serverTimestamp(),
        'danhMucID': danhMucId,
        'danhMucId': danhMucId,
      };

      await FirebaseFirestore.instance.collection('san_pham').doc(id).update(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật sản phẩm: $ten'),
            backgroundColor: MauSac.cam,
          ),
        );
      }
    } catch (e) {
      print('Lỗi khi cập nhật sản phẩm: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi cập nhật sản phẩm: $e'),
            backgroundColor: MauSac.kfcRed,
          ),
        );
      }
    }
  }

  Future<void> _togglePromotion(SanPham product) async {
    try {
      final newPromotionState = !product.coKhuyenMai;

      if (newPromotionState) {
        final giamGia = await _showPromotionDialog(product);
        if (giamGia == null) return;

        await FirebaseFirestore.instance.collection('san_pham').doc(product.id).update({
          'khuyenMai': true,
          'giamGia': giamGia,
          'ngayCapNhat': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã bật khuyến mãi ${giamGia}% cho: ${product.ten}'),
              backgroundColor: MauSac.xanhLa,
            ),
          );
        }
      } else {
        await FirebaseFirestore.instance.collection('san_pham').doc(product.id).update({
          'khuyenMai': false,
          'giamGia': null,
          'ngayCapNhat': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã tắt khuyến mãi cho: ${product.ten}'),
              backgroundColor: MauSac.xam,
            ),
          );
        }
      }
    } catch (e) {
      print('Lỗi khi cập nhật trạng thái khuyến mãi: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi cập nhật trạng thái khuyến mãi: $e'),
            backgroundColor: MauSac.kfcRed,
          ),
        );
      }
    }
  }

  Future<int?> _showPromotionDialog(SanPham product) async {
    final giamGiaController = TextEditingController(
      text: product.giamGia?.toString() ?? '10'
    );
    bool hasError = false;
    String errorText = '';

    return await showDialog<int?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: MauSac.denNhat,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MauSac.vang.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.local_offer, color: MauSac.vang, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bật khuyến mãi',
                      style: TextStyle(
                        color: MauSac.trang,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      product.ten,
                      style: TextStyle(
                        color: MauSac.xam,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MauSac.denNen,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: MauSac.xamDam.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.attach_money, color: MauSac.cam, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Giá gốc: ',
                      style: TextStyle(color: MauSac.xam, fontSize: 14),
                    ),
                    Text(
                      '${_formatPrice(product.gia)} VNĐ',
                      style: const TextStyle(
                        color: MauSac.trang,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: giamGiaController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: MauSac.trang),
                decoration: InputDecoration(
                  labelText: 'Phần trăm giảm giá (%)',
                  labelStyle: TextStyle(color: MauSac.xam),
                  prefixIcon: Icon(Icons.percent, color: MauSac.kfcRed),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: hasError ? MauSac.kfcRed : MauSac.xamDam.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: hasError ? MauSac.kfcRed : MauSac.cam,
                    ),
                  ),
                  errorText: hasError ? errorText : null,
                                    errorStyle: const TextStyle(color: MauSac.kfcRed),
                ),
                onChanged: (value) {
                  if (hasError) {
                    setDialogState(() {
                      hasError = false;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Giá sau khuyến mãi: ${_formatPrice(
                  (product.gia * (1 - (int.tryParse(giamGiaController.text.trim()) ?? 0) / 100)).round(),
                )} VNĐ',
                style: TextStyle(
                  color: MauSac.trang,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Hủy', style: TextStyle(color: MauSac.xam)),
            ),
            ElevatedButton(
              onPressed: () {
                final giamGia = int.tryParse(giamGiaController.text.trim());
                if (giamGia == null || giamGia <= 0 || giamGia > 100) {
                  setDialogState(() {
                    hasError = true;
                    errorText = 'Giảm giá phải từ 1-100%';
                  });
                  return;
                }
                Navigator.pop(context, giamGia);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: MauSac.kfcRed,
                foregroundColor: MauSac.trang,
              ),
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteProduct(SanPham product) async {
    try {
      if (product.hinhAnh.isNotEmpty && product.hinhAnh.startsWith('http')) {
        await _deleteImage(product.hinhAnh);
      }
      await FirebaseFirestore.instance.collection('san_pham').doc(product.id).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa sản phẩm: ${product.ten}'),
            backgroundColor: MauSac.xam,
          ),
        );
      }
    } catch (e) {
      print('Lỗi khi xóa sản phẩm: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa sản phẩm: $e'),
            backgroundColor: MauSac.kfcRed,
          ),
        );
      }
    }
  }

  String _getCategoryName(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) return 'Không có danh mục';
    final category = _categories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => DanhMuc(id: '', ten: 'Không xác định', hinhAnh: '', moTa: ''),
    );
    return category.ten;
  }

  IconData _getCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'chicken':
        return Icons.fastfood;
      case 'drink':
        return Icons.local_drink;
      case 'side':
        return Icons.local_dining;
      default:
        return Icons.category;
    }
  }

  String _formatPrice(int price) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return formatter.format(price);
  }
}
                  
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kfc/models/don_hang.dart';
import 'package:kfc/models/san_pham_gio_hang.dart';
import 'package:kfc/models/thong_bao.dart';
import 'package:kfc/providers/don_hang_provider.dart';
import 'package:kfc/providers/notification_provider.dart';
import 'package:kfc/services/notification_service.dart';
import 'package:kfc/theme/mau_sac.dart';
import 'package:intl/intl.dart';

class ManHinhQLDH extends StatefulWidget {
  const ManHinhQLDH({Key? key}) : super(key: key);

  @override
  State<ManHinhQLDH> createState() => _ManHinhQLDHState();
}

class _ManHinhQLDHState extends State<ManHinhQLDH> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final formatter = NumberFormat('#,###', 'vi_VN');
  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Filter states
  String _selectedFilter = 'Tất cả';
  final List<String> _filters = ['Tất cả', 'Đang xử lý', 'Đang giao', 'Đã giao', 'Đã hủy'];

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
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    // Load data after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDonHang();
    });
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDonHang() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    try {
      await Provider.of<DonHangProvider>(context, listen: false).fetchAllDonHang();
    } catch (e) {
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

  Future<void> _updateTrangThai(String id, TrangThaiDonHang trangThai) async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    try {
      final donHangProvider = Provider.of<DonHangProvider>(context, listen: false);
      final success = await donHangProvider.updateTrangThaiDonHang(id, trangThai);
      
      if (mounted) {
        if (success) {
          // Tìm đơn hàng vừa cập nhật để gửi thông báo
          final donHang = donHangProvider.donHangList.firstWhere(
            (dh) => dh.id == id,
            orElse: () => donHangProvider.donHangList.first,
          );
          
          // Gửi thông báo cho khách hàng VÀ LƯU VÀO FIREBASE
          await _sendNotificationToCustomer(donHang, trangThai);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Cập nhật thành công và đã gửi thông báo Firebase'),
                  ),
                ],
              ),
              backgroundColor: MauSac.xanhLa,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          final error = donHangProvider.error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(error ?? 'Cập nhật thất bại'),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Lỗi: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendNotificationToCustomer(DonHang donHang, TrangThaiDonHang trangThai) async {
    try {
      String status = '';
      
      // Chuyển đổi TrangThaiDonHang thành string status
      switch (trangThai) {
        case TrangThaiDonHang.dangGiao:
          status = 'shipping';
          break;
        case TrangThaiDonHang.daGiao:
          status = 'delivered';
          break;
        case TrangThaiDonHang.daHuy:
          status = 'cancelled';
          break;
        case TrangThaiDonHang.dangXuLy:
          status = 'confirmed';
          break;
        default:
          return; // Không gửi thông báo cho trạng thái khác
      }

      // Gửi thông báo và lưu vào Firebase
      await NotificationService.createFirebaseNotificationForUser(
        userId: 'current_user_id', // Thay bằng ID thực của user
        orderId: donHang.id,
        status: status,
      );

      print('✅ Đã gửi thông báo Firebase cho khách hàng');
    } catch (e) {
      print('❌ Lỗi khi gửi thông báo Firebase: $e');
      
      // Fallback: gửi local notification nếu Firebase fail
      String tieuDe = '';
      String noiDung = '';
      
      switch (trangThai) {
        case TrangThaiDonHang.dangGiao:
          tieuDe = '🚚 Đơn hàng đang được giao';
          noiDung = 'Đơn hàng #${donHang.id.substring(0, 8)} của bạn đang trên đường giao đến.';
          break;
        case TrangThaiDonHang.daGiao:
          tieuDe = '✅ Đơn hàng đã giao thành công';
          noiDung = 'Đơn hàng #${donHang.id.substring(0, 8)} đã được giao thành công.';
          break;
        case TrangThaiDonHang.daHuy:
          tieuDe = '❌ Đơn hàng đã bị hủy';
          noiDung = 'Đơn hàng #${donHang.id.substring(0, 8)} đã bị hủy.';
          break;
        default:
          return;
      }

      await NotificationService.sendLocalNotification(
        title: tieuDe,
        body: noiDung,
      );
    }
  }

  List<DonHang> _getFilteredOrders(List<DonHang> orders) {
    List<DonHang> filtered = orders;

    // Filter by status
    if (_selectedFilter != 'Tất cả') {
      switch (_selectedFilter) {
        case 'Đang xử lý':
          filtered = filtered.where((o) => o.trangThai == TrangThaiDonHang.dangXuLy).toList();
          break;
        case 'Đang giao':
          filtered = filtered.where((o) => o.trangThai == TrangThaiDonHang.dangGiao).toList();
          break;
        case 'Đã giao':
          filtered = filtered.where((o) => o.trangThai == TrangThaiDonHang.daGiao).toList();
          break;
        case 'Đã hủy':
          filtered = filtered.where((o) => o.trangThai == TrangThaiDonHang.daHuy).toList();
          break;
      }
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((order) {
        return order.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               order.tenNguoiNhan.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               order.soDienThoai.contains(_searchQuery);
      }).toList();
    }

    // Sort by date (newest first)
    filtered.sort((a, b) => b.thoiGianDat.compareTo(a.thoiGianDat));
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildCountAndAddButton(),
            _buildSearchBar(),
            _buildFilterButtons(),
            Expanded(
              child: _isLoading ? _buildLoading() : _buildOrdersList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Row(
          children: [
            // Title
            const Expanded(
              child: Text(
                'Quản lý đơn hàng',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Refresh button
            GestureDetector(
              onTap: _loadDonHang,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: MauSac.kfcRed,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: MauSac.kfcRed.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Làm mới',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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

  Widget _buildCountAndAddButton() {
    return Consumer<DonHangProvider>(
      builder: (context, donHangProvider, child) {
        final filteredOrders = _getFilteredOrders(donHangProvider.donHangList);
        final totalRevenue = filteredOrders
            .where((order) => order.trangThai == TrangThaiDonHang.daGiao)
            .fold(0.0, (sum, order) => sum + order.tongCong);
        
        return SlideTransition(
          position: _slideAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Order count
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.receipt_long,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${filteredOrders.length} đơn',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Revenue
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: MauSac.xanhLa.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: MauSac.xanhLa.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: MauSac.xanhLa,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${formatter.format(totalRevenue.round())}₫',
                        style: const TextStyle(
                          color: MauSac.xanhLa,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Statistics button
                GestureDetector(
                  onTap: () => _showStatistics(donHangProvider.donHangList),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: MauSac.xanhLa,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: MauSac.xanhLa.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.analytics,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Thống kê',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
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
      },
    );
  }

  void _showStatistics(List<DonHang> orders) {
    final today = DateTime.now();
    final todayOrders = orders.where((order) {
      return order.thoiGianDat.year == today.year &&
             order.thoiGianDat.month == today.month &&
             order.thoiGianDat.day == today.day;
    }).toList();

    final completedToday = todayOrders.where((o) => o.trangThai == TrangThaiDonHang.daGiao).length;
    final revenueToday = todayOrders
        .where((o) => o.trangThai == TrangThaiDonHang.daGiao)
        .fold(0.0, (sum, order) => sum + order.tongCong);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MauSac.denNhat,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: MauSac.xanhLa.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.analytics,
                color: MauSac.xanhLa,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Thống kê hôm nay',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatItem('Tổng đơn hàng', '${todayOrders.length}', Icons.receipt_long),
            const SizedBox(height: 12),
            _buildStatItem('Đã hoàn thành', '$completedToday', Icons.check_circle),
            const SizedBox(height: 12),
            _buildStatItem('Doanh thu', '${formatter.format(revenueToday.round())}₫', Icons.monetization_on),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng', style: TextStyle(color: MauSac.xam)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: MauSac.kfcRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm theo mã đơn, tên, SĐT...',
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.white.withOpacity(0.5),
              size: 16,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.white.withOpacity(0.5),
                      size: 16,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
        ),
      ),
    );
  }

  Widget _buildFilterButtons() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          itemBuilder: (context, index) {
            final filter = _filters[index];
            final isSelected = _selectedFilter == filter;
            
            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedFilter = filter);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? MauSac.kfcRed : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected ? null : Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: MauSac.kfcRed.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        filter,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: MauSac.kfcRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const CircularProgressIndicator(
              color: MauSac.kfcRed,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Đang tải đơn hàng...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return Consumer<DonHangProvider>(
      builder: (context, donHangProvider, child) {
        if (donHangProvider.error != null) {
          return _buildError(donHangProvider.error!);
        }

        final filteredOrders = _getFilteredOrders(donHangProvider.donHangList);
        
        if (filteredOrders.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _loadDonHang,
          color: MauSac.kfcRed,
          backgroundColor: Colors.black,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) {
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 300 + (index * 100)),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: _buildOrderItem(filteredOrders[index]),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Đã xảy ra lỗi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadDonHang,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MauSac.kfcRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    MauSac.kfcRed.withOpacity(0.1),
                    MauSac.kfcRed.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(60),
                border: Border.all(
                  color: MauSac.kfcRed.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.receipt_long,
                size: 60,
                color: MauSac.kfcRed.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Không có đơn hàng nào',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'Không tìm thấy đơn hàng phù hợp với từ khóa "$_searchQuery"'
                  : 'Chưa có đơn hàng nào trong danh mục này',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(DonHang donHang) {
    Color statusColor;
    IconData statusIcon;
    
    switch (donHang.trangThai) {
      case TrangThaiDonHang.dangXuLy:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_top;
        break;
      case TrangThaiDonHang.dangGiao:
        statusColor = Colors.blue;
        statusIcon = Icons.delivery_dining;
        break;
      case TrangThaiDonHang.daGiao:
        statusColor = MauSac.xanhLa;
        statusIcon = Icons.check_circle;
        break;
      case TrangThaiDonHang.daHuy:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDonHangDetail(donHang),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        statusIcon,
                        color: statusColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đơn hàng #${donHang.id.substring(0, 8)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${donHang.ngayDatHang} - ${donHang.gioDatHang}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: statusColor.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        donHang.trangThaiText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Customer info
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: Colors.white.withOpacity(0.6),
                      size: 12,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            donHang.tenNguoiNhan,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            donHang.soDienThoai,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${donHang.danhSachSanPham.length} món',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${formatter.format(donHang.tongCong.round())} ₫',
                            style: const TextStyle(
                              color: MauSac.kfcRed,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 10),
                
                // Action buttons
                if (donHang.trangThai != TrangThaiDonHang.daGiao &&
                    donHang.trangThai != TrangThaiDonHang.daHuy)
                  Column(
                    children: [
                      if (donHang.trangThai == TrangThaiDonHang.dangXuLy) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _updateTrangThai(donHang.id, TrangThaiDonHang.dangGiao),
                                icon: const Icon(Icons.delivery_dining, size: 14),
                                label: const Text(
                                  'Bắt đầu giao',
                                  style: TextStyle(fontSize: 10),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showCancelDialog(donHang),
                                icon: const Icon(Icons.cancel, size: 14),
                                label: const Text(
                                  'Hủy đơn',
                                  style: TextStyle(fontSize: 10),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => _showDonHangDetail(donHang),
                            child: Text(
                              'Chi tiết',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ] else if (donHang.trangThai == TrangThaiDonHang.dangGiao) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _updateTrangThai(donHang.id, TrangThaiDonHang.daGiao),
                            icon: const Icon(Icons.check_circle, size: 14),
                            label: const Text(
                              'Hoàn thành',
                              style: TextStyle(fontSize: 11),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MauSac.xanhLa,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => _showDonHangDetail(donHang),
                            child: Text(
                              'Chi tiết',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => _showDonHangDetail(donHang),
                      child: Text(
                        'Xem chi tiết',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(DonHang donHang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MauSac.denNhat,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cancel, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Hủy đơn hàng',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn hủy đơn hàng #${donHang.id.substring(0, 8)}?\n\nHành động này không thể hoàn tác.',
          style: const TextStyle(color: MauSac.xam, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không', style: TextStyle(color: MauSac.xam)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateTrangThai(donHang.id, TrangThaiDonHang.daHuy);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );
  }

  void _showDonHangDetail(DonHang donHang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _DonHangDetailSheet(
        donHang: donHang,
        onUpdateStatus: _updateTrangThai,
      ),
    );
  }
}

// Keep the existing _DonHangDetailSheet class unchanged
class _DonHangDetailSheet extends StatelessWidget {
  final DonHang donHang;
  final Function(String, TrangThaiDonHang) onUpdateStatus;

  const _DonHangDetailSheet({
    Key? key,
    required this.donHang,
    required this.onUpdateStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    
    Color statusColor;
    IconData statusIcon;
    
    switch (donHang.trangThai) {
      case TrangThaiDonHang.dangXuLy:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_top;
        break;
      case TrangThaiDonHang.dangGiao:
        statusColor = Colors.blue;
        statusIcon = Icons.delivery_dining;
        break;
      case TrangThaiDonHang.daGiao:
        statusColor = MauSac.xanhLa;
        statusIcon = Icons.check_circle;
        break;
      case TrangThaiDonHang.daHuy:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đơn hàng #${donHang.id.substring(0, 8)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${donHang.ngayDatHang} - ${donHang.gioDatHang}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    donHang.trangThaiText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thông tin khách hàng
                  _buildSection(
                    title: 'Thông tin khách hàng',
                    icon: Icons.person,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Họ tên', donHang.tenNguoiNhan),
                        const SizedBox(height: 12),
                        _buildInfoRow('Số điện thoại', donHang.soDienThoai),
                        const SizedBox(height: 12),
                        _buildInfoRow('Địa chỉ giao hàng', donHang.diaChi),
                        if (donHang.ghiChu != null && donHang.ghiChu!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow('Ghi chú', donHang.ghiChu!),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Danh sách sản phẩm
                  _buildSection(
                    title: 'Danh sách sản phẩm',
                    icon: Icons.fastfood,
                    child: Column(
                      children: [
                        ...donHang.danhSachSanPham.map((item) => _buildProductItem(item, formatter)),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Thông tin thanh toán
                  _buildSection(
                    title: 'Thông tin thanh toán',
                    icon: Icons.payment,
                    child: Column(
                      children: [
                        _buildPaymentRow('Tạm tính', '${formatter.format(donHang.tongTien.round())} ₫'),
                        const SizedBox(height: 12),
                        _buildPaymentRow('Phí giao hàng', '${formatter.format(donHang.phiGiaoHang.round())} ₫'),
                        const SizedBox(height: 16),
                        Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPaymentRow(
                          'Tổng cộng', 
                          '${formatter.format(donHang.tongCong.round())} ₫',
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          // Footer với action buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  if (donHang.trangThai != TrangThaiDonHang.daGiao &&
                      donHang.trangThai != TrangThaiDonHang.daHuy) ...[
                    if (donHang.trangThai == TrangThaiDonHang.dangXuLy) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                onUpdateStatus(donHang.id, TrangThaiDonHang.dangGiao);
                              },
                              icon: const Icon(Icons.delivery_dining),
                              label: const Text('Bắt đầu giao hàng'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                onUpdateStatus(donHang.id, TrangThaiDonHang.daHuy);
                              },
                              icon: const Icon(Icons.cancel),
                              label: const Text('Hủy đơn hàng'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red, width: 2),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (donHang.trangThai == TrangThaiDonHang.dangGiao) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            onUpdateStatus(donHang.id, TrangThaiDonHang.daGiao);
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Hoàn thành giao hàng'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MauSac.xanhLa,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.3), width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Đóng',
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
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MauSac.kfcRed.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: MauSac.kfcRed,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductItem(SanPhamGioHang item, NumberFormat formatter) {
    final sanPham = item.sanPham;
    final soLuong = item.soLuong;
    final giaGoc = sanPham.gia;
    final giaSauGiam = sanPham.coKhuyenMai ? sanPham.giaGiam : giaGoc;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Số lượng
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: MauSac.kfcRed.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$soLuong',
                style: const TextStyle(
                  color: MauSac.kfcRed,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Tên sản phẩm
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sanPham.ten,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sanPham.coKhuyenMai) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: MauSac.kfcRed.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: MauSac.kfcRed.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '-${sanPham.phanTramGiamGia}%',
                          style: const TextStyle(
                            color: MauSac.kfcRed,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${formatter.format(giaGoc)} ₫',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Giá
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${formatter.format(giaSauGiam.round())} ₫',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Thành tiền: ${formatter.format(item.tongGia.round())} ₫',
                style: const TextStyle(
                  color: MauSac.kfcRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? Colors.white : Colors.white.withOpacity(0.6),
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? MauSac.kfcRed : Colors.white,
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

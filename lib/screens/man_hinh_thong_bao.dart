import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../models/thong_bao.dart';
import '../theme/mau_sac.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:firebase_messaging/firebase_messaging.dart';

class ManHinhThongBao extends StatefulWidget {
  const ManHinhThongBao({Key? key}) : super(key: key);

  @override
  State<ManHinhThongBao> createState() => _ManHinhThongBaoState();
}

class _ManHinhThongBaoState extends State<ManHinhThongBao> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _headerAnimationController;
  late AnimationController _filterAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _filterSlideAnimation;

  String _selectedFilter = 'all';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
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
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.elasticOut,
    ));

    _filterSlideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _headerAnimationController.forward();
    _animationController.forward();
    _filterAnimationController.forward();
    
    timeago.setLocaleMessages('vi', timeago.ViMessages());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFirebaseNotifications();
      Provider.of<NotificationProvider>(context, listen: false).initialize();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _headerAnimationController.dispose();
    _filterAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initializeFirebaseNotifications() async {
    try {
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Đã cấp quyền thông báo Firebase');
        
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          print('📱 Nhận thông báo Firebase: ${message.notification?.title}');
          
          if (mounted) {
            Provider.of<NotificationProvider>(context, listen: false)
                .taiDanhSachThongBao();
          }
        });
      }
    } catch (e) {
      print('❌ Lỗi khởi tạo Firebase notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MauSac.denNen,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterSection(),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ScaleTransition(
      scale: _scaleAnimation,
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
                _buildMarkAllReadButton(),
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
          'Thông báo',
          style: TextStyle(
            color: MauSac.trang,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Cập nhật đơn hàng và khuyến mãi',
          style: TextStyle(
            color: MauSac.xam.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMarkAllReadButton() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        if (provider.soThongBaoChuaDoc == 0) {
          return const SizedBox.shrink();
        }
        return Container(
          decoration: BoxDecoration(
            color: MauSac.kfcRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MauSac.kfcRed.withOpacity(0.3)),
          ),
          child: IconButton(
            icon: const Icon(Icons.done_all, color: MauSac.kfcRed, size: 22),
            onPressed: () => provider.danhDauTatCaDaDoc(),
            padding: const EdgeInsets.all(12),
            tooltip: 'Đánh dấu tất cả đã đọc',
          ),
        );
      },
    );
  }

  Widget _buildStatsRow() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        final tongSoThongBao = provider.danhSachThongBao.length;
        final soThongBaoChuaDoc = provider.soThongBaoChuaDoc;
        
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
                  color: provider.isFirebaseConnected 
                      ? MauSac.xanhLa.withOpacity(0.1)
                      : MauSac.kfcRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  provider.isFirebaseConnected 
                      ? Icons.cloud_done 
                      : Icons.cloud_off,
                  color: provider.isFirebaseConnected 
                      ? MauSac.xanhLa 
                      : MauSac.kfcRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$tongSoThongBao thông báo',
                      style: const TextStyle(
                        color: MauSac.trang,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      soThongBaoChuaDoc > 0 
                          ? '$soThongBaoChuaDoc chưa đọc' 
                          : 'Tất cả đã đọc',
                      style: TextStyle(
                        color: MauSac.xam.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (soThongBaoChuaDoc > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: MauSac.kfcRed,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$soThongBaoChuaDoc',
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

  Widget _buildFilterSection() {
  return const SizedBox.shrink();
}

  Widget _buildFilterTab(String filter, String label, IconData icon) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: MauSac.kfcRed,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: MauSac.trang,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: MauSac.trang,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

  Widget _buildBody() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        if (provider.dangTai) {
          return _buildLoadingState();
        }

        if (provider.loi != null) {
          return _buildErrorState(provider.loi!, provider);
        }

        if (!provider.collectionExists) {
          return _buildCollectionNotExistsState();
        }

        final filteredNotifications = _getFilteredNotifications(provider.danhSachThongBao);

        if (filteredNotifications.isEmpty) {
          return _buildEmptyState();
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: _buildNotificationList(filteredNotifications, provider),
        );
      },
    );
  }

  List<ThongBao> _getFilteredNotifications(List<ThongBao> notifications) {
  return notifications;
}

  Widget _buildLoadingState() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
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
                          Colors.blue.withOpacity(0.1),
                          Colors.blue.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(70),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.blue,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Đang tải thông báo...',
              style: TextStyle(
                color: MauSac.trang,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Vui lòng chờ trong giây lát',
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

  Widget _buildEmptyState() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
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
                          Colors.blue.withOpacity(0.1),
                          Colors.blue.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(70),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.notifications_none_outlined,
                      size: 70,
                      color: Colors.blue,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Chưa có thông báo',
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
              'Hệ thống đã sẵn sàng.\nThông báo sẽ xuất hiện khi có cập nhật mới.',
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

  Widget _buildCollectionNotExistsState() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
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
                          Colors.orange.withOpacity(0.1),
                          Colors.orange.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(70),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.cloud_queue,
                      size: 70,
                      color: Colors.orange,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Hệ thống chưa khởi tạo',
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
              'Collection "thong_bao" chưa tồn tại.\nThông báo sẽ xuất hiện khi admin tạo thông báo đầu tiên.',
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

  Widget _buildErrorState(String error, NotificationProvider provider) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
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
                      Icons.cloud_off,
                      size: 70,
                      color: MauSac.kfcRed,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Lỗi kết nối',
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
              'Không thể kết nối đến Firebase.\nVui lòng kiểm tra kết nối mạng.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MauSac.xam.withOpacity(0.8),
                fontSize: 16,
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: provider.taiDanhSachThongBao,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text(
                  'Thử lại',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MauSac.kfcRed,
                  foregroundColor: MauSac.trang,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(List<ThongBao> notifications, NotificationProvider provider) {
    return RefreshIndicator(
      onRefresh: provider.taiDanhSachThongBao,
      color: MauSac.kfcRed,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final thongBao = notifications[index];
          
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300 + (index * 100)),
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
            child: _buildNotificationCard(thongBao, provider, index),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(ThongBao thongBao, NotificationProvider provider, int index) {
    final status = thongBao.duLieuThem?['status'] ?? thongBao.duLieuThem?['trangThai'] ?? '';
    final orderId = thongBao.duLieuThem?['donHangId'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: MauSac.denNhat,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: thongBao.daDoc 
              ? MauSac.xam.withOpacity(0.2)
              : _getStatusColor(status).withOpacity(0.5),
          width: thongBao.daDoc ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (!thongBao.daDoc) {
              provider.danhDauDaDoc(thongBao.id);
            }
            _handleNotificationTap(thongBao);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status and time
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _getStatusIcon(status),
                        color: _getStatusColor(status),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    _getStatusText(status),
                                    style: const TextStyle(
                                      color: MauSac.trang,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (!thongBao.daDoc)
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: MauSac.kfcRed,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (orderId.isNotEmpty)
                            Text(
                              'Đơn hàng #${orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId}',
                              style: TextStyle(
                                color: MauSac.xam.withOpacity(0.8),
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.cloud_done,
                        color: Colors.blue,
                        size: 12,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Title
                Text(
                  thongBao.tieuDe,
                  style: TextStyle(
                    color: MauSac.trang,
                    fontSize: 18,
                    fontWeight: thongBao.daDoc 
                        ? FontWeight.w600 
                        : FontWeight.bold,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 8),
                
                // Content
                Text(
                  thongBao.noiDung,
                  style: TextStyle(
                    color: MauSac.xam.withOpacity(0.9),
                    fontSize: 15,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 16),
                
                // Footer with time and actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: MauSac.xam.withOpacity(0.6),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              timeago.format(thongBao.thoiGian, locale: 'vi'),
                              style: TextStyle(
                                color: MauSac.xam.withOpacity(0.6),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (['shipping', 'delivered', 'dang_giao', 'da_giao'].contains(status))
                          GestureDetector(
                            onTap: () => _trackOrder(orderId),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: MauSac.kfcRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: MauSac.kfcRed.withOpacity(0.3)),
                              ),
                              child: const Text(
                                'Theo dõi',
                                style: TextStyle(
                                  color: MauSac.kfcRed,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _showDeleteDialog(thongBao, provider),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: MauSac.xam.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              color: MauSac.xam.withOpacity(0.6),
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods for delivery status
  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'da_xac_nhan':
        return 'ĐÃ XÁC NHẬN';
      case 'preparing':
      case 'dang_chuan_bi':
        return 'ĐANG CHUẨN BỊ';
      case 'shipping':
      case 'dang_giao':
        return 'ĐANG GIAO';
      case 'delivered':
      case 'da_giao':
        return 'ĐÃ GIAO';
      case 'cancelled':
      case 'da_huy':
        return 'ĐÃ HỦY';
      case 'created':
      case 'da_tao':
        return 'ĐÃ TẠO';
      default:
        return 'CẬP NHẬT';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'da_xac_nhan':
        return Icons.check_circle_outline;
      case 'preparing':
      case 'dang_chuan_bi':
        return Icons.restaurant;
      case 'shipping':
      case 'dang_giao':
        return Icons.local_shipping;
      case 'delivered':
      case 'da_giao':
        return Icons.check_circle;
      case 'cancelled':
      case 'da_huy':
        return Icons.cancel;
      case 'created':
      case 'da_tao':
        return Icons.receipt_long;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'da_xac_nhan':
        return Colors.blue;
      case 'preparing':
      case 'dang_chuan_bi':
        return MauSac.vang;
      case 'shipping':
      case 'dang_giao':
        return MauSac.cam;
      case 'delivered':
      case 'da_giao':
        return MauSac.xanhLa;
      case 'cancelled':
      case 'da_huy':
        return Colors.red;
      case 'created':
      case 'da_tao':
        return Colors.purple;
      default:
        return MauSac.kfcRed;
    }
  }

  void _handleNotificationTap(ThongBao thongBao) {
    final orderId = thongBao.duLieuThem?['donHangId'];
    if (orderId != null) {
      Navigator.pushNamed(
        context, 
        '/don-hang',
        arguments: {'orderId': orderId},
      );
    }
  }

  void _trackOrder(String orderId) {
    Navigator.pushNamed(
      context, 
      '/don-hang',
      arguments: {'orderId': orderId, 'showTracking': true},
    );
  }

  void _showDeleteDialog(ThongBao thongBao, NotificationProvider provider) {
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
              child: const Icon(Icons.delete_outline, color: MauSac.kfcRed, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Xóa thông báo',
                style: TextStyle(
                  color: MauSac.trang,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa thông báo này?',
          style: const TextStyle(
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
              provider.xoaThongBao(thongBao.id);
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('Đã xóa thông báo'),
                      ),
                    ],
                  ),
                  backgroundColor: MauSac.xanhLa,
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
              'Xóa',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

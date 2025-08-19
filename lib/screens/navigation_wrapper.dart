import 'package:flutter/material.dart';
import 'package:kfc/theme/mau_sac.dart';
import 'package:kfc/screens/man_hinh_trang_chu.dart';
import 'package:kfc/screens/man_hinh_tim_kiem.dart';
import 'package:kfc/screens/man_hinh_thong_bao.dart';
import 'package:kfc/screens/man_hinh_gio_hang.dart';
import 'package:kfc/screens/man_hinh_tai_khoan.dart';
import 'package:provider/provider.dart';
import 'package:kfc/providers/notification_provider.dart';
import 'package:kfc/providers/gio_hang_provider.dart';

class NavigationWrapper extends StatefulWidget {
  const NavigationWrapper({Key? key}) : super(key: key);

  @override
  State<NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper> {
  int _chiSoHienTai = 0;

  final List<Widget> _danhSachManHinh = [
    const ManHinhTrangChu(),
    const ManHinhTimKiem(),
    const ManHinhThongBao(), // Thêm màn hình thông báo vào danh sách chính
    const ManHinhGioHang(),
    const ManHinhTaiKhoan(), 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _chiSoHienTai,
        children: _danhSachManHinh,
      ),
      bottomNavigationBar: Consumer2<NotificationProvider, GioHangProvider>(
        builder: (context, notificationProvider, gioHangProvider, child) {
          final soThongBaoChuaDoc = notificationProvider.soThongBaoChuaDoc;
          final soLuongSanPham = gioHangProvider.tongSoLuong;
          
          return BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: MauSac.denNhat,
            selectedItemColor: MauSac.kfcRed,
            unselectedItemColor: MauSac.xam,
            currentIndex: _chiSoHienTai,
            onTap: (index) {
              setState(() {
                _chiSoHienTai = index;
              });
            },
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Trang chủ',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Tìm kiếm',
              ),
              // Thêm tab thông báo vào thanh điều hướng
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications),
                    if (soThongBaoChuaDoc > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: MauSac.kfcRed,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            soThongBaoChuaDoc > 99 ? '99+' : '$soThongBaoChuaDoc',
                            style: const TextStyle(
                              color: MauSac.trang,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Thông báo',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    const Icon(Icons.shopping_cart),
                    if (soLuongSanPham > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: MauSac.kfcRed,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            soLuongSanPham > 99 ? '99+' : '$soLuongSanPham',
                            style: const TextStyle(
                              color: MauSac.trang,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Giỏ hàng',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Tài khoản',
              ),
            ],
          );
        },
      ),
      // Đã xóa floating action button thông báo vì đã thêm vào thanh điều hướng chính
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kfc/providers/nguoi_dung_provider.dart';
import 'package:kfc/screens/man_hinh_dang_nhap.dart';
import 'package:kfc/screens/navigation_wrapper.dart';

class AppWrapper extends StatelessWidget {
  const AppWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NguoiDungProvider>(
      builder: (context, nguoiDungProvider, child) {
        // Nếu đã đăng nhập, hiển thị màn hình chính
        if (nguoiDungProvider.daDangNhap) {
          return const NavigationWrapper();
        }
        
        // Nếu chưa đăng nhập, hiển thị màn hình đăng nhập
        return const ManHinhDangNhap();
      },
    );
  }
}
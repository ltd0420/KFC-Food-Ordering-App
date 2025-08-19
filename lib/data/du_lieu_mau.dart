import 'package:kfc/models/danh_muc.dart';
import 'package:kfc/models/san_pham.dart';

class DuLieuMau {
  // Danh sách danh mục
  static final List<DanhMuc> danhSachDanhMuc = [
    DanhMuc(
      id: '1',
      ten: 'Gà rán - Gà quay',
      hinhAnh: 'assets/images/category_chicken.png',
      moTa: 'Gà giòn cay, gà truyền thống, gà quay giấy bạc',
    ),
    DanhMuc(
      id: '2',
      ten: 'Burger',
      hinhAnh: 'assets/images/category_burger.png',
      moTa: 'Zinger, burger tôm, burger gà quay',
    ),
    DanhMuc(
      id: '3',
      ten: 'Cơm - Mì Ý',
      hinhAnh: 'assets/images/category_rice.png',
      moTa: 'Cơm gà sốt tiêu, mì Ý bò bằm',
    ),
    DanhMuc(
      id: '4',
      ten: 'Món ăn kèm',
      hinhAnh: 'assets/images/category_sides.png',
      moTa: 'Khoai tây chiên, salad, bắp viên, tôm viên',
    ),
    DanhMuc(
      id: '5',
      ten: 'Đồ uống - Tráng miệng',
      hinhAnh: 'assets/images/category_drinks.png',
      moTa: 'Pepsi, 7Up, kem vani',
    ),
    DanhMuc(
      id: '6',
      ten: 'Combo cá nhân',
      hinhAnh: 'assets/images/category_personal.png',
      moTa: 'Gà + khoai + nước',
    ),
    DanhMuc(
      id: '7',
      ten: 'Combo nhóm',
      hinhAnh: 'assets/images/category_group.png',
      moTa: 'Nhiều món + phần lớn dành cho 3-4 người',
    ),
  ];

  // Danh sách sản phẩm
  static final List<SanPham> danhSachSanPham = [
    // Gà rán - Gà quay
    SanPham(
      id: '101',
      ten: 'Gà Rán Giòn Cay',
      gia: 45000,
      hinhAnh: 'assets/images/spicy_chicken.png',
      moTa: 'Gà được tẩm ướp với công thức đặc biệt, rán giòn với lớp phủ cay nồng.',
      danhMucId: '1',
      khuyenMai: false,
    ),
    SanPham(
      id: '102',
      ten: 'Gà Rán Truyền Thống',
      gia: 42000,
      hinhAnh: 'assets/images/original_chicken.png',
      moTa: 'Gà được tẩm ướp với 11 loại gia vị bí truyền, rán vàng giòn.',
      danhMucId: '1',
      khuyenMai: false,
    ),
    SanPham(
      id: '103',
      ten: 'Gà Quay Giấy Bạc',
      gia: 75000,
      hinhAnh: 'assets/images/grilled_chicken.png',
      moTa: 'Gà được quay trong giấy bạc giữ nguyên hương vị, thơm ngon, mọng nước.',
      danhMucId: '1',
      khuyenMai: true,
      giamGia: 10,
    ),

    // Burger
    SanPham(
      id: '201',
      ten: 'Burger Zinger',
      gia: 49000,
      hinhAnh: 'assets/images/zinger_burger.png',
      moTa: 'Burger với lớp gà giòn cay, rau tươi và sốt mayonnaise đặc biệt.',
      danhMucId: '2',
      khuyenMai: false,
    ),
    SanPham(
      id: '202',
      ten: 'Burger Tôm',
      gia: 55000,
      hinhAnh: 'assets/images/shrimp_burger.png',
      moTa: 'Burger với lớp tôm giòn, rau tươi và sốt cocktail đặc biệt.',
      danhMucId: '2',
      khuyenMai: true,
      giamGia: 15,
    ),
    SanPham(
      id: '203',
      ten: 'Burger Gà Quay',
      gia: 59000,
      hinhAnh: 'assets/images/grilled_burger.png',
      moTa: 'Burger với lớp gà quay mềm, rau tươi và sốt BBQ đặc biệt.',
      danhMucId: '2',
      khuyenMai: false,
    ),

    // Cơm - Mì Ý
    SanPham(
      id: '301',
      ten: 'Cơm Gà Sốt Tiêu',
      gia: 45000,
      hinhAnh: 'assets/images/pepper_rice.png',
      moTa: 'Cơm với gà rán và sốt tiêu đặc biệt, kèm rau xào.',
      danhMucId: '3',
      khuyenMai: false,
    ),
    SanPham(
      id: '302',
      ten: 'Mì Ý Bò Bằm',
      gia: 55000,
      hinhAnh: 'assets/images/spaghetti.png',
      moTa: 'Mì Ý với sốt bò bằm đậm đà, phô mai và rau thơm.',
      danhMucId: '3',
      khuyenMai: true,
      giamGia: 10,
    ),

    // Món ăn kèm
    SanPham(
      id: '401',
      ten: 'Khoai Tây Chiên',
      gia: 25000,
      hinhAnh: 'assets/images/fries.png',
      moTa: 'Khoai tây chiên giòn, thơm ngon.',
      danhMucId: '4',
      khuyenMai: false,
    ),
    SanPham(
      id: '402',
      ten: 'Salad Trộn',
      gia: 35000,
      hinhAnh: 'assets/images/salad.png',
      moTa: 'Salad tươi với rau xanh, cà chua, dưa chuột và sốt đặc biệt.',
      danhMucId: '4',
      khuyenMai: false,
    ),

    // Đồ uống - Tráng miệng
    SanPham(
      id: '501',
      ten: 'Pepsi',
      gia: 15000,
      hinhAnh: 'assets/images/pepsi.png',
      moTa: 'Pepsi mát lạnh, sảng khoái.',
      danhMucId: '5',
      khuyenMai: false,
    ),
    SanPham(
      id: '502',
      ten: 'Kem Vani',
      gia: 20000,
      hinhAnh: 'assets/images/ice_cream.png',
      moTa: 'Kem vani mát lạnh, ngọt ngào.',
      danhMucId: '5',
      khuyenMai: false,
    ),

    // Combo cá nhân
    SanPham(
      id: '601',
      ten: 'Combo Gà Rán',
      gia: 79000,
      hinhAnh: 'assets/images/chicken_combo.png',
      moTa: '1 miếng gà rán, 1 khoai tây chiên vừa, 1 nước ngọt.',
      danhMucId: '6',
      khuyenMai: true,
      giamGia: 20,
    ),
    SanPham(
      id: '602',
      ten: 'Combo Burger',
      gia: 89000,
      hinhAnh: 'assets/images/burger_combo.png',
      moTa: '1 burger Zinger, 1 khoai tây chiên vừa, 1 nước ngọt.',
      danhMucId: '6',
      khuyenMai: false,
    ),

    // Combo nhóm
    SanPham(
      id: '701',
      ten: 'Combo Nhóm 1',
      gia: 179000,
      hinhAnh: 'assets/images/group_combo1.png',
      moTa: '3 miếng gà rán, 2 burger, 2 khoai tây chiên lớn, 3 nước ngọt.',
      danhMucId: '7',
      khuyenMai: true,
      giamGia: 15,
    ),
    SanPham(
      id: '702',
      ten: 'Combo Nhóm 2',
      gia: 259000,
      hinhAnh: 'assets/images/group_combo2.png',
      moTa: '5 miếng gà rán, 3 burger, 3 khoai tây chiên lớn, 5 nước ngọt.',
      danhMucId: '7',
      khuyenMai: false,
    ),
  ];

  // Danh sách sản phẩm nổi bật
  static List<SanPham> danhSachSanPhamNoiBat() {
    return danhSachSanPham.where((sp) => 
      ['101', '201', '302', '601', '701'].contains(sp.id)
    ).toList();
  }

  // Danh sách sản phẩm khuyến mãi
  static List<SanPham> danhSachSanPhamKhuyenMai() {
    return danhSachSanPham.where((sp) => sp.khuyenMai == true).toList();
  }

  // Lấy sản phẩm theo danh mục
  static List<SanPham> laySanPhamTheoDanhMuc(String danhMucId) {
    return danhSachSanPham.where((sp) => sp.danhMucId == danhMucId).toList();
  }

  // Tìm kiếm sản phẩm theo tên
  static List<SanPham> timKiemSanPham(String tuKhoa) {
    return danhSachSanPham.where((sp) => 
      sp.ten.toLowerCase().contains(tuKhoa.toLowerCase()) ||
      sp.moTa.toLowerCase().contains(tuKhoa.toLowerCase())
    ).toList();
  }

  // Lấy sản phẩm liên quan
  static List<SanPham> laySanPhamLienQuan(SanPham sanPham) {
    return danhSachSanPham.where((sp) => 
      sp.danhMucId == sanPham.danhMucId && sp.id != sanPham.id
    ).take(3).toList();
  }
}

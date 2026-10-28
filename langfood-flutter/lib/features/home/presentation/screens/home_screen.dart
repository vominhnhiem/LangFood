import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/food_card_item.dart';
import '../../../../data/models/category_model.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/services/product_service.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/cart_provider.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../food_detail/presentation/screens/food_detail_screen.dart';
import '../../../food_detail/presentation/widgets/food_customization_medium_sheet.dart';
import '../../../food_detail/presentation/widgets/food_customization_expanded_sheet.dart';
import '../../../restaurant/presentation/screens/restaurant_menu_screen.dart';
import '../../../tracking/presentation/screens/live_tracking_screen.dart';
import '../../../tracking/presentation/screens/signalr_live_tracking_screen.dart';
import '../../../tracking/presentation/screens/location_picker_screen.dart';
import '../../../checkout/presentation/screens/checkout_screen.dart';

enum HomeViewState {
  normal,
  skeleton,
  empty,
  error,
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();

  List<CategoryModel> _categories = [];
  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];

  int _selectedCategoryId = -1;
  int _currentNavIndex = 0;
  HomeViewState _viewState = HomeViewState.normal;

  // Selected delivery location
  String _currentLocation = 'KTX Khu B • Tòa BA2';

  // Banner carousel
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  // Countdown timer for Flash Deals (1 hour 24 mins 45 secs)
  Timer? _countdownTimer;
  int _countdownSeconds = (1 * 3600) + (24 * 60) + 45;

  // Shimmer animation controller
  late AnimationController _shimmerController;

  final List<Map<String, dynamic>> _promoBanners = [
    {
      'title': 'Combo thi cử no căng bụng chỉ 35k',
      'subtitle': 'Freeship tận sảnh KTX Khu A & B',
      'tag': 'HOT DEAL KTX',
      'gradient': [const Color(0xFFFF5722), const Color(0xFFFF8A65)],
      'icon': Icons.school_rounded,
    },
    {
      'title': 'Tiệc trà sữa Vân Nam KTX',
      'subtitle': 'Mua 1 tặng 1 thạch trân châu hoàng kim',
      'tag': 'GIỜ VÀNG 14H-17H',
      'gradient': [const Color(0xFF6A1B9A), const Color(0xFFAB47BC)],
      'icon': Icons.local_cafe_rounded,
    },
    {
      'title': 'Gom đơn phòng 0đ ship',
      'subtitle': 'Tự động chia tiền Momo/ZaloPay nhanh gọn',
      'tag': 'TIẾT KIỆM 100%',
      'gradient': [const Color(0xFF00897B), const Color(0xFF4DB6AC)],
      'icon': Icons.groups_rounded,
    },
  ];

  // Verified Campus Sellers
  final List<Map<String, dynamic>> _verifiedSellers = [
    {
      'id': 10,
      'name': 'Cơm Gà Xối Mỡ Da Giòn Bà Tám',
      'rating': 4.9,
      'reviews': '850+',
      'time': '12 - 18 phút',
      'distance': '450m • Cổng sau KTX B',
      'image': 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=400',
      'tags': ['Freeship KTX', 'Tặng trà tắc'],
      'bestSeller': 'Cơm gà xối mỡ đùi góc tư (35k)',
    },
    {
      'id': 11,
      'name': 'Trà Sữa Nướng Vân Nam KTX',
      'rating': 4.8,
      'reviews': '1.2k+',
      'time': '10 - 15 phút',
      'distance': '200m • Tòa B4 Làng ĐH',
      'image': 'https://images.unsplash.com/photo-1558857563-b37cfb62a4d4?w=400',
      'tags': ['Mua 1 tặng 1 thạch', 'Freeship KTX'],
      'bestSeller': 'Trà sữa nướng hoàng kim (26k)',
    },
    {
      'id': 12,
      'name': 'Bún Đậu Phố Làng ĐH',
      'rating': 4.9,
      'reviews': '640+',
      'time': '15 - 20 phút',
      'distance': '600m • Chợ đêm Làng ĐH',
      'image': 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=400',
      'tags': ['Freeship KTX', 'Tặng kẹo cao su & nước sấu'],
      'bestSeller': 'Mẹt bún đậu thập cẩm (38k)',
    },
    {
      'id': 13,
      'name': 'Bánh Tráng Cuộn Cô Ba',
      'rating': 4.7,
      'reviews': '490+',
      'time': '10 - 15 phút',
      'distance': '300m • Cột cờ KTX B',
      'image': 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=400',
      'tags': ['Freeship KTX', 'Giảm 5k đơn từ 30k'],
      'bestSeller': 'Bánh tráng cuộn bơ trứng cút (18k)',
    },
  ];

  // Flash Deals items
  final List<Map<String, dynamic>> _flashDeals = [
    {
      'id': 201,
      'name': 'Cơm gà xối mỡ đùi góc tư',
      'originalPrice': 45000,
      'salePrice': 32000,
      'discount': '-29%',
      'image': 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=300',
      'sold': 19,
      'total': 25,
      'shop': 'Cơm Gà Bà Tám',
    },
    {
      'id': 204,
      'name': 'Trà sữa nướng hoàng kim',
      'originalPrice': 26000,
      'salePrice': 18000,
      'discount': '-31%',
      'image': 'https://images.unsplash.com/photo-1558857563-b37cfb62a4d4?w=300',
      'sold': 24,
      'total': 30,
      'shop': 'Trà Sữa Vân Nam',
    },
    {
      'id': 207,
      'name': 'Bún đậu chả cốm nem rán',
      'originalPrice': 48000,
      'salePrice': 35000,
      'discount': '-28%',
      'image': 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=300',
      'sold': 14,
      'total': 20,
      'shop': 'Bún Đậu Phố',
    },
    {
      'id': 209,
      'name': 'Bánh tráng cuộn bơ trứng cút',
      'originalPrice': 22000,
      'salePrice': 14000,
      'discount': '-36%',
      'image': 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=300',
      'sold': 27,
      'total': 30,
      'shop': 'Bánh Tráng Cô Ba',
    },
  ];

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _loadData();
    _startBannerTimer();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerController.dispose();
    _bannerTimer?.cancel();
    _countdownTimer?.cancel();
    _shimmerController.dispose();
    super.dispose();
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerController.hasClients) {
        int next = (_currentBannerIndex + 1) % _promoBanners.length;
        _bannerController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        setState(() {
          _countdownSeconds--;
        });
      }
    });
  }

  String _formatTime(int totalSecs) {
    int h = totalSecs ~/ 3600;
    int m = (totalSecs % 3600) ~/ 60;
    int s = totalSecs % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatCurrency(num amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return formatter.format(amount).replaceAll(' ', '');
  }

  Future<void> _loadData() async {
    try {
      final cats = await _productService.getCategories();
      final prods = await _productService.getProducts();

      if (!mounted) return;
      setState(() {
        _categories = cats.isNotEmpty ? [CategoryModel(id: -1, name: 'Tất cả'), ...cats] : MockData.getCategories();
        _allProducts = prods.isNotEmpty ? prods : MockData.getProducts();
        _filteredProducts = List.from(_allProducts);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _categories = MockData.getCategories();
        _allProducts = MockData.getProducts();
        _filteredProducts = List.from(_allProducts);
      });
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((p) {
        final matchCat = _selectedCategoryId == -1 || p.categoryId == _selectedCategoryId;
        final matchQuery = query.isEmpty ||
            p.name.toLowerCase().contains(query) ||
            p.shopName.toLowerCase().contains(query) ||
            (p.description?.toLowerCase().contains(query) ?? false);
        return matchCat && matchQuery;
      }).toList();
    });
  }

  void _onCategorySelected(int categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _applyFilter();
  }

  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  void _openRestaurantMenu(int shopId, String shopName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantMenuScreen(shopId: shopId, shopName: shopName),
      ),
    );
  }

  void _openFoodDetail(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FoodDetailScreen(product: product),
      ),
    );
  }

  void _addQuickToCart(ProductModel product) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    cartProvider.addToCart(
      product: product,
      quantity: 1,
      userId: authProvider.user?.id,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Đã thêm "${product.name}" vào giỏ!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Xem giỏ',
          textColor: Colors.yellow,
          onPressed: _openCart,
        ),
      ),
    );
  }

  String _getContextualGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return 'Chào buổi sáng, Minh! Ăn sáng nạp năng lượng nhé ☀️';
    } else if (hour >= 11 && hour < 14) {
      return 'Chào buổi trưa, Minh! Đói bụng chưa? 🍜';
    } else if (hour >= 14 && hour < 18) {
      return 'Chào buổi chiều, Minh! Trà sữa & ăn vặt KTX thôi 🧋';
    } else {
      return 'Chào buổi tối, Minh! Tối nay ăn gì ở Làng? 🍲';
    }
  }

  void _showLocationPickerSheet() {
    final locations = [
      'KTX Khu B • Tòa BA2 (Hiện tại)',
      'KTX Khu B • Tòa BA1',
      'KTX Khu B • Tòa BA4',
      'KTX Khu B • Tòa BB2',
      'KTX Khu A • Sảnh trung tâm',
      'KTX Khu A • Tòa AH1',
      'Trường ĐH Công Nghệ Thông Tin (UIT)',
      'Trường ĐH Bách Khoa (Cơ sở 2)',
      'Trường ĐH Khoa Học Tự Nhiên (CS2)',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Chọn điểm nhận đồ tại KTX / Làng ĐH',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Shipper LangFood sẽ giao đến tận sảnh tòa bạn chọn:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              // Button to open LF-06 Campus Map Pin Screen
              InkWell(
                onTap: () async {
                  Navigator.pop(ctx);
                  final selectedAddr = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
                  );
                  if (selectedAddr != null && mounted) {
                    setState(() {
                      _currentLocation = selectedAddr.split(' • ')[0];
                    });
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF5722), Color(0xFFFF8A65)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepOrange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.map_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ghim điểm nhận trên bản đồ Campus (LF-06)',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'Định vị GPS chính xác sảnh thang máy hoặc cửa phòng KTX',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: locations.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, idx) {
                    final loc = locations[idx];
                    final isCurrent = loc.contains(_currentLocation.split(' ')[0]);
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: Icon(
                        isCurrent ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                        color: isCurrent ? AppColors.primary : Colors.grey,
                      ),
                      title: Text(
                        loc,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCurrent ? AppColors.primary : Colors.black87,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _currentLocation = loc.replaceAll(' (Hiện tại)', '');
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã chuyển điểm nhận sang: $_currentLocation'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Thông báo Làng Food 🔔',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Đóng'),
                  ),
                ],
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEBEE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flash_on_rounded, color: Colors.red),
                ),
                title: const Text('Deal chớp nhoáng nghỉ trưa ⚡', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Giảm đến -35% cơm gà xối mỡ & trà sữa nướng KTX!'),
                trailing: const Text('2p trước', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delivery_dining_rounded, color: Colors.green),
                ),
                title: const Text('Freeship KTX Khu B kích hoạt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Mã FREESHIPKTX tự động giảm 15k phí giao sảnh BA2!'),
                trailing: const Text('15p trước', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showVoiceSearchModal() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic_rounded, color: AppColors.primary, size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'Đang lắng nghe...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '"Cơm gà xối mỡ Bà Tám"',
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  _searchController.text = 'Cơm gà';
                  _applyFilter();
                  Navigator.pop(ctx);
                },
                child: const Text('Áp dụng tìm kiếm'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showQrScannerModal() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Quét mã QR bàn / menu', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 180,
                width: 180,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.qr_code_2_rounded, size: 120, color: Colors.grey),
                    Container(
                      height: 2,
                      width: 160,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Hướng camera vào mã QR đặt tại bàn quán ăn KTX để gọi món trực tiếp',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  void _showGroupOrderSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.groups_rounded, color: Colors.deepOrange, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đặt nhóm phòng KTX • Chia ship 0đ',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Phòng BA2-405 • Đang có 3 bạn trong nhóm',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.share_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Link chia sẻ: langfood.vn/group/BA2-405',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text('Sao chép', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Lợi ích khi đặt nhóm KTX:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text('• Freeship 100% khi nhóm từ 3 người'),
              const Text('• Tự động chia tiền chính xác theo từng món & topping'),
              const Text('• Shipper giao gộp tới đúng sảnh phòng'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã kích hoạt chế độ Đặt Nhóm KTX! Giỏ hàng sẽ được chia tiền tự động.'),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Tạo giỏ nhóm ngay • 0đ ship', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // Default badge count is at least 3 items to showcase the requested UI
    final cartItemBadgeCount = cartProvider.totalItemsCount > 0 ? cartProvider.totalItemsCount : 3;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Interactive State Bar (Thanh điều khiển tương tác ở góc trên)
            _buildInteractiveStateBar(),

            // 2. Active Screen Content according to _viewState
            Expanded(
              child: _buildCurrentViewBody(cartProvider, authProvider, cartItemBadgeCount),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ================= 1. INTERACTIVE STATE BAR =================
  Widget _buildInteractiveStateBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.tune_rounded, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          const Text(
            'UI State:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStateChip(
                    state: HomeViewState.normal,
                    label: 'Trang chủ',
                    icon: Icons.check_circle_rounded,
                    activeColor: const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 6),
                  _buildStateChip(
                    state: HomeViewState.skeleton,
                    label: 'Skeleton (Loading)',
                    icon: Icons.hourglass_top_rounded,
                    activeColor: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 6),
                  _buildStateChip(
                    state: HomeViewState.empty,
                    label: 'Trống quán',
                    icon: Icons.store_mall_directory_outlined,
                    activeColor: const Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 6),
                  _buildStateChip(
                    state: HomeViewState.error,
                    label: 'Lỗi mạng',
                    icon: Icons.wifi_off_rounded,
                    activeColor: const Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 8),
                  // Shortcut to LF-02
                  InkWell(
                    onTap: () => _openRestaurantMenu(10, 'Cơm Gà Xối Mỡ Bà Tám'),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.restaurant_rounded, size: 13, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            '🍗 Mở LF-02 Bà Tám',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Shortcut to LF-03
                  InkWell(
                    onTap: () {
                      final sampleProduct = _allProducts.isNotEmpty ? _allProducts.first : null;
                      showFoodCustomizationMediumSheet(
                        context: context,
                        product: sampleProduct,
                        onAddedToCart: () {
                          setState(() {});
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5722), Color(0xFFFF8A65)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepOrange.withOpacity(0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.tune_rounded, size: 13, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            '🍱 Mở LF-03 Sheet',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Shortcut to LF-04 Expanded Sheet (90%)
                  InkWell(
                    onTap: () {
                      final sampleProduct = _allProducts.isNotEmpty ? _allProducts.first : null;
                      showFoodCustomizationExpandedSheet(
                        context: context,
                        product: sampleProduct,
                        onAddedToCart: () {
                          setState(() {});
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE11D48), Color(0xFFF43F5E)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.open_in_full_rounded, size: 13, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            '🍱 Mở LF-04 (90%)',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Shortcut to LF-Auth LoginScreen
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_person_rounded, size: 13, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            '🔑 Đăng nhập (Auth)',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Shortcut to LF-06 Location Picker Campus Map
                  InkWell(
                    onTap: () async {
                      final selectedAddr = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
                      );
                      if (selectedAddr != null && mounted) {
                        setState(() {
                          _currentLocation = selectedAddr.split(' • ')[0];
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.map_rounded, size: 13, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            '🗺️ LF-06 Bản đồ KTX',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Shortcut to LF-07 Checkout & Order Review
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.credit_card_rounded, size: 13, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            '💳 LF-07 Thanh toán',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Shortcut to LF-08 Live Tracking
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LiveTrackingScreen(
                            isShipper: false,
                            initialAddress: 'Tòa BA2, KTX Khu B ĐHQG',
                            isLocationLocked: true,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.two_wheeler_rounded, size: 13, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            '🛵 LF-08 Live Tracking',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Shortcut to LF-09 SignalR Live Tracking
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SignalRLiveTrackingScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.hub_rounded, size: 13, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            '🗺️ LF-09 SignalR Live',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
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

  Widget _buildStateChip({
    required HomeViewState state,
    required String label,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = _viewState == state;
    return InkWell(
      onTap: () {
        setState(() {
          _viewState = state;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white24,
            width: isSelected ? 1.2 : 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : Colors.white70,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= VIEW STATE ROUTER =================
  Widget _buildCurrentViewBody(CartProvider cartProvider, AuthProvider authProvider, int cartItemBadgeCount) {
    switch (_viewState) {
      case HomeViewState.skeleton:
        return _buildSkeletonState();
      case HomeViewState.empty:
        return _buildEmptyState();
      case HomeViewState.error:
        return _buildErrorState();
      case HomeViewState.normal:
      default:
        return _buildNormalState(cartProvider, authProvider, cartItemBadgeCount);
    }
  }

  // ================= 2. NORMAL STATE: FULL SLIVER & APPLE HIG =================
  Widget _buildNormalState(CartProvider cartProvider, AuthProvider authProvider, int cartItemBadgeCount) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Apple HIG Header & Elastic Search
          SliverToBoxAdapter(
            child: _buildAppleHigHeader(cartProvider, authProvider, cartItemBadgeCount),
          ),

          // Quick Actions: Đặt nhóm chia ship & Quán quen KTX
          SliverToBoxAdapter(
            child: _buildQuickActionsSection(),
          ),

          // Categories Horizontal Chip List (Cơm trưa Hot, Trà sữa, Mì Bún...)
          SliverToBoxAdapter(
            child: _buildCategoriesChipSection(),
          ),

          // Banner Flash Deals & Parallax
          SliverToBoxAdapter(
            child: _buildPromoBannerSlider(),
          ),

          // Deal chớp nhoáng nghỉ trưa ⚡ (Flash Sale) + Realtime Countdown Timer
          SliverToBoxAdapter(
            child: _buildFlashDealsSection(),
          ),

          // Thẻ gợi ý gom đơn phòng
          SliverToBoxAdapter(
            child: _buildRoomOrderCard(),
          ),

          // Quán ngon sinh viên chấm cao (Verified Campus Sellers)
          SliverToBoxAdapter(
            child: _buildVerifiedCampusSellersSection(),
          ),

          // Gợi ý món ăn hôm nay (Food Grid)
          SliverToBoxAdapter(
            child: _buildRecommendationsHeader(),
          ),

          // Product Grid
          if (_filteredProducts.isEmpty)
            SliverToBoxAdapter(
              child: EmptyStateView(
                icon: Icons.search_off_rounded,
                title: 'Không tìm thấy món ăn',
                message: 'Thử tìm từ khóa khác hoặc bấm xem tất cả danh mục nhé!',
                actionText: 'Xem tất cả món',
                onAction: () {
                  _searchController.clear();
                  _onCategorySelected(-1);
                },
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.73,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = _filteredProducts[index];
                    return FoodCardItem(
                      product: product,
                      onTap: () => _openFoodDetail(product),
                      onAddToCart: () => _addQuickToCart(product),
                    );
                  },
                  childCount: _filteredProducts.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }

  // ================= APPLE HIG HEADER =================
  Widget _buildAppleHigHeader(CartProvider cartProvider, AuthProvider authProvider, int cartItemBadgeCount) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Student KTX Location Selector & Actions (Bell, Cart Badge, Avatar)
          Row(
            children: [
              // Location Selector
              Expanded(
                child: InkWell(
                  onTap: _showLocationPickerSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'GIAO TẬN SẢNH',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      _currentLocation,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: Color(0xFF64748B),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bell Notification Icon
              GestureDetector(
                onTap: _showNotificationSheet,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF334155),
                        size: 22,
                      ),
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Shortcut Giỏ hàng có huy hiệu đếm số lượng (3 món)
              GestureDetector(
                onTap: _openCart,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.shopping_bag_outlined,
                        color: Color(0xFF334155),
                        size: 22,
                      ),
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Text(
                            '$cartItemBadgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Profile Avatar
              GestureDetector(
                onTap: () => _showUserMenu(authProvider),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF7043), Color(0xFFFF5722)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      authProvider.user?.fullName?.isNotEmpty == true
                          ? authProvider.user!.fullName![0].toUpperCase()
                          : (authProvider.user?.username.isNotEmpty == true
                              ? authProvider.user!.username[0].toUpperCase()
                              : 'M'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Row 2: Apple HIG Contextual Greeting & Large iOS Title
          Text(
            _getContextualGreeting(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Hôm nay ăn gì ở Làng? 🍜',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Row 3: Elastic Search with Voice Search & QR Scanner
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF64748B),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _applyFilter(),
                    style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                    decoration: const InputDecoration(
                      hintText: 'Tìm "Cơm gà", "Trà sữa", "Bún đậu"...',
                      hintStyle: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13.5,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      _applyFilter();
                    },
                    child: const Icon(
                      Icons.cancel_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                  )
                else ...[
                  // Micro Voice Search
                  GestureDetector(
                    onTap: _showVoiceSearchModal,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.mic_none_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // QR Code Scanner
                  GestureDetector(
                    onTap: _showQrScannerModal,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Color(0xFF475569),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= QUICK ACTIONS: ĐẶT NHÓM & QUÁN QUEN =================
  Widget _buildQuickActionsSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Row(
        children: [
          // Action 1: Đặt nhóm chia ship
          Expanded(
            child: GestureDetector(
              onTap: _showGroupOrderSheet,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.groups_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Đặt nhóm',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF9A3412),
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                '0đ',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Chia tiền tự động',
                            style: TextStyle(fontSize: 11, color: Color(0xFFC2410C)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Action 2: Quán quen KTX -> Opens Cơm Gà Bà Tám directly!
          Expanded(
            child: GestureDetector(
              onTap: () => _openRestaurantMenu(10, 'Cơm Gà Xối Mỡ Bà Tám'),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quán quen KTX',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                          Text(
                            'Cơm Gà Bà Tám ➔',
                            style: TextStyle(fontSize: 11, color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= DANH MỤC MÓN DẠNG CHIP ICON =================
  Widget _buildCategoriesChipSection() {
    final categoryIcons = [
      {'id': -1, 'name': 'Tất cả ⚡', 'icon': Icons.bolt_rounded, 'color': const Color(0xFFFF5722)},
      {'id': 1, 'name': 'Cơm trưa (Hot) 🔥', 'icon': Icons.rice_bowl_rounded, 'color': const Color(0xFFEA580C)},
      {'id': 2, 'name': 'Trà sữa & Cafe 🧋', 'icon': Icons.local_cafe_rounded, 'color': const Color(0xFF9333EA)},
      {'id': 3, 'name': 'Mì & Bún 🍜', 'icon': Icons.ramen_dining_rounded, 'color': const Color(0xFFD97706)},
      {'id': 4, 'name': 'Ăn vặt KTX 🍢', 'icon': Icons.tapas_rounded, 'color': const Color(0xFF059669)},
      {'id': 5, 'name': 'Bánh mì 🥖', 'icon': Icons.bakery_dining_rounded, 'color': const Color(0xFFB45309)},
      {'id': 6, 'name': 'Đồ uống 🥤', 'icon': Icons.sports_bar_rounded, 'color': const Color(0xFF0284C7)},
    ];

    return Container(
      margin: const EdgeInsets.only(top: 12),
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: categoryIcons.length,
        itemBuilder: (context, index) {
          final item = categoryIcons[index];
          final catId = item['id'] as int;
          final isSelected = _selectedCategoryId == catId;
          final itemColor = item['color'] as Color;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => _onCategorySelected(catId),
              borderRadius: BorderRadius.circular(22),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? itemColor : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected ? itemColor : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.4 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: itemColor.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 16,
                      color: isSelected ? Colors.white : itemColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item['name'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= BANNER FLASH DEALS & PARALLAX =================
  Widget _buildPromoBannerSlider() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      height: 140,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _bannerController,
            onPageChanged: (idx) {
              setState(() {
                _currentBannerIndex = idx;
              });
            },
            itemCount: _promoBanners.length,
            itemBuilder: (context, idx) {
              final banner = _promoBanners[idx];
              final gradient = banner['gradient'] as List<Color>;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              banner['tag'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            banner['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            banner['subtitle'] as String,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        banner['icon'] as IconData,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Dots indicator
          Positioned(
            bottom: 8,
            child: Row(
              children: List.generate(_promoBanners.length, (idx) {
                final isCurrent = _currentBannerIndex == idx;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isCurrent ? 20 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: isCurrent ? Colors.white : Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ================= DEAL CHỚP NHOÁNG NGHỈ TRƯA ⚡ (FLASH SALE) =================
  Widget _buildFlashDealsSection() {
    final timerString = _formatTime(_countdownSeconds);
    final parts = timerString.split(':');

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 16, 14, 4),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFEE2E2)),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Title & Realtime Countdown Timer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Colors.red, size: 20),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Deal chớp nhoáng nghỉ trưa ⚡',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),

                // Real-time Countdown timer pills
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    parts[0],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                const Text(' : ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    parts[1],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                const Text(' : ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    parts[2],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal list of flash deal dishes
          SizedBox(
            height: 204,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _flashDeals.length,
              itemBuilder: (context, idx) {
                final deal = _flashDeals[idx];
                final percentSold = deal['sold'] / deal['total'];

                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () {
                      if (deal['id'] == 201) {
                        _openRestaurantMenu(10, 'Cơm Gà Xối Mỡ Bà Tám');
                      } else {
                        final prod = _allProducts.firstWhere(
                          (p) => p.id == deal['id'],
                          orElse: () => _allProducts.first,
                        );
                        _openFoodDetail(prod);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image with discount tag
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: Image.network(
                                deal['image'] as String,
                                height: 95,
                                width: 140,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 95,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.fastfood, color: Colors.grey),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  deal['discount'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Title & Price
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                deal['name'] as String,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    _formatCurrency(deal['salePrice']),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatCurrency(deal['originalPrice']),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // Progress bar (Đã bán X/Y)
                              Stack(
                                children: [
                                  Container(
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFE4E6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: percentSold.clamp(0.0, 1.0),
                                    child: Container(
                                      height: 12,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFFF5722), Color(0xFFE11D48)],
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      'Đã bán ${deal['sold']}/${deal['total']}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Quick Add (+) Floating Button
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6, bottom: 4),
                            child: GestureDetector(
                              onTap: () {
                                final prod = _allProducts.firstWhere(
                                  (p) => p.id == deal['id'],
                                  orElse: () => _allProducts.first,
                                );
                                _addQuickToCart(prod);
                              },
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add, color: Colors.white, size: 16),
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
        ],
      ),
    );
  }

  // ================= THẺ GỢI Ý GOM ĐƠN PHÒNG =================
  Widget _buildRoomOrderCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.door_sliding_rounded, color: Colors.amber, size: 26),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phòng bạn đang gom đơn?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Tạo giỏ nhóm chia tiền ship 0đ tự động',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _showGroupOrderSheet,
            child: const Text(
              'Gom đơn ngay',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ================= QUÁN NGON SINH VIÊN CHẤM CAO (VERIFIED CAMPUS SELLERS) =================
  Widget _buildVerifiedCampusSellersSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 16, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quán ngon sinh viên chấm cao ⭐',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Verified Campus Sellers • Giao nhanh trong 15p',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Text(
                'Xem tất cả',
                style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Cards for 4 Verified Sellers
          ..._verifiedSellers.map((seller) {
            final tags = seller['tags'] as List<String>;
            final isBaTam = seller['id'] == 10 || (seller['name'] as String).contains('Bà Tám');

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () {
                  if (isBaTam) {
                    _openRestaurantMenu(seller['id'] as int, seller['name'] as String);
                  } else {
                    _searchController.text = (seller['name'] as String).split(' ')[0];
                    _applyFilter();
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Shop Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          seller['image'] as String,
                          width: 84,
                          height: 84,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 84,
                            height: 84,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.store, color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Shop Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    seller['name'] as String,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.verified_rounded, color: Colors.blue, size: 16),
                              ],
                            ),
                            const SizedBox(height: 4),

                            // Rating, Distance, Time
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                const SizedBox(width: 2),
                                Text(
                                  '${seller['rating']}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  ' (${seller['reviews']}) • ',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                Text(
                                  seller['time'] as String,
                                  style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              seller['distance'] as String,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 6),

                            // Exclusive Promotion Tags
                            Wrap(
                              spacing: 6,
                              children: tags.map((t) {
                                final isFreeship = t.contains('Freeship');
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isFreeship ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    t,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isFreeship ? const Color(0xFF166534) : const Color(0xFF92400E),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ================= GỢI Ý MÓN ĂN HÔM NAY HEADER =================
  Widget _buildRecommendationsHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'GỢI Ý HÔM NAY DÀNH CHO BẠN',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: 0.3,
              ),
            ),
          ),
          Text(
            '${_filteredProducts.length} món',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ================= 3. SKELETON STATE (ANIMATED SHIMMER) =================
  Widget _buildSkeletonState() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header skeleton
              Row(
                children: [
                  _buildShimmerBox(width: 140, height: 20),
                  const Spacer(),
                  _buildShimmerBox(width: 36, height: 36, shape: BoxShape.circle),
                  const SizedBox(width: 8),
                  _buildShimmerBox(width: 36, height: 36, shape: BoxShape.circle),
                ],
              ),
              const SizedBox(height: 14),
              _buildShimmerBox(width: 220, height: 26),
              const SizedBox(height: 10),
              _buildShimmerBox(width: double.infinity, height: 44, borderRadius: 22),
              const SizedBox(height: 16),

              // Quick action skeleton
              Row(
                children: [
                  Expanded(child: _buildShimmerBox(width: double.infinity, height: 50, borderRadius: 12)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildShimmerBox(width: double.infinity, height: 50, borderRadius: 12)),
                ],
              ),
              const SizedBox(height: 16),

              // Banner skeleton
              _buildShimmerBox(width: double.infinity, height: 130, borderRadius: 16),
              const SizedBox(height: 16),

              // Categories skeleton
              Row(
                children: List.generate(4, (_) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildShimmerBox(width: 80, height: 34, borderRadius: 17),
                  );
                }),
              ),
              const SizedBox(height: 18),

              // Flash sale skeleton
              _buildShimmerBox(width: 200, height: 20),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildShimmerBox(width: double.infinity, height: 180, borderRadius: 12)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildShimmerBox(width: double.infinity, height: 180, borderRadius: 12)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    double borderRadius = 8,
    BoxShape shape = BoxShape.rectangle,
  }) {
    final shimmerValue = _shimmerController.value;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? BorderRadius.circular(borderRadius) : null,
        gradient: LinearGradient(
          colors: const [
            Color(0xFFE2E8F0),
            Color(0xFFF8FAFC),
            Color(0xFFE2E8F0),
          ],
          stops: [
            (shimmerValue - 0.3).clamp(0.0, 1.0),
            shimmerValue.clamp(0.0, 1.0),
            (shimmerValue + 0.3).clamp(0.0, 1.0),
          ],
        ),
      ),
    );
  }

  // ================= 4. EMPTY STATE: TRỐNG QUÁN (KTX TẠM NGƯNG) =================
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFDBEAFE), width: 2),
              ),
              child: const Icon(Icons.storefront_rounded, size: 48, color: Color(0xFF3B82F6)),
            ),
            const SizedBox(height: 18),
            const Text(
              'Khu vực KTX tạm ngưng nhận đơn',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Hiện tại đang là khung giờ nghỉ ngơi (23:00 - 06:00) hoặc các quán xung quanh tòa BA2 đang chuẩn bị ca mới. Bạn có thể chuyển điểm nhận hoặc xem các quán mở 24/7.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _showLocationPickerSheet,
                  icon: const Icon(Icons.location_on_outlined, size: 18),
                  label: const Text('Đổi điểm nhận KTX'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    setState(() {
                      _viewState = HomeViewState.normal;
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Xem lại trang chủ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= 5. ERROR STATE: LỖI MẠNG KÈM NÚT THỬ LẠI =================
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFEE2E2), width: 2),
              ),
              child: const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 18),
            const Text(
              'Mất kết nối máy chủ Làng Food',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Không thể tải dữ liệu quán ngon KTX. Vui lòng kiểm tra lại kết nối Wi-Fi KTX hoặc 4G/5G của bạn rồi thử lại nhé!',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                setState(() {
                  _viewState = HomeViewState.normal;
                });
                _loadData();
              },
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Thử lại kết nối', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ================= 6. BOTTOM NAVIGATION BAR =================
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 62,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildNavItem(0, Icons.storefront_rounded, 'Khám phá'),
          _buildNavItem(1, Icons.receipt_long_rounded, 'Giỏ hàng'),
          _buildNavItem(2, Icons.notifications_none_rounded, 'Thông báo'),
          _buildNavItem(3, Icons.person_outline_rounded, 'Tài khoản'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentNavIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentNavIndex = index;
          });
          if (index == 1) {
            _openCart();
          } else if (index == 2) {
            _showNotificationSheet();
          } else if (index == 3) {
            _showUserMenu(Provider.of<AuthProvider>(context, listen: false));
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : const Color(0xFF64748B),
              size: 23,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= USER ACCOUNT MENU =================
  void _showUserMenu(AuthProvider authProvider) {
    final rootNavigator = Navigator.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      authProvider.user?.username.isNotEmpty == true
                          ? authProvider.user!.username[0].toUpperCase()
                          : 'M',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    authProvider.user?.fullName ?? authProvider.user?.username ?? 'Minh (Sinh viên KTX Khu B)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Vai trò: ${authProvider.user?.roleName ?? 'Khách hàng'} • Phòng BA2-405'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.restaurant_rounded, color: AppColors.primary),
                  title: const Text('Mở quán: Cơm Gà Xối Mỡ Bà Tám (LF-02)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _openRestaurantMenu(10, 'Cơm Gà Xối Mỡ Bà Tám');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shopping_cart_outlined, color: AppColors.primary),
                  title: const Text('Xem giỏ hàng & Thanh toán (LF-04)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _openCart();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.map_outlined, color: Colors.orange),
                  title: const Text('Bản đồ định vị KTX & Live Tracking'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RoleChooserScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.login_rounded, color: Colors.blue),
                  title: const Text('Màn hình Đăng nhập / Chuyển tài khoản'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                ),
                if (authProvider.isLoggedIn)
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.error),
                    title: const Text('Đăng xuất'),
                    onTap: () async {
                      Navigator.pop(bottomSheetContext);
                      await authProvider.logout();
                      if (!mounted) return;
                      rootNavigator.pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

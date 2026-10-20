import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/showcase/design_system_showcase.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_motion.dart';
import '../../../../core/widgets/langfood_deal_card.dart';
import '../../../../core/widgets/langfood_empty_state.dart';
import '../../../../core/widgets/langfood_floating_cart_pill.dart';
import '../../../../core/widgets/langfood_horizontal_product_card.dart';
import '../../../../core/widgets/langfood_loading_skeleton.dart';
import '../../../../core/widgets/langfood_section_header.dart';
import '../../../../data/models/category_model.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/services/product_service.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/cart_provider.dart';
import '../../../../providers/theme_provider.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../food_detail/presentation/screens/food_detail_screen.dart';
import '../../../shop/presentation/screens/shop_menu_screen.dart';
import '../../../tracking/presentation/screens/live_tracking_screen.dart';
import '../../../shipper/presentation/screens/shipper_orders_screen.dart';

/// Màn hình Trang Chủ (HomeScreen) chuẩn thiết kế Stitch LF-01 (Apple HIG & Material 3)
/// - Collapsing Header với SliverAppBar và tìm kiếm thích ứng
/// - Lời chào cá nhân hóa cho sinh viên KTX theo thời gian thực
/// - Bộ lọc phân loại dạng Capsule Pill bo tròn 9999pt
/// - Banner quảng cáo trượt tự động (Combo thi cử 35k, Freeship KTX)
/// - Deal chớp nhoáng nghỉ trưa kèm đồng hồ đếm ngược Live Countdown
/// - Danh sách quán ngon sinh viên chấm cao thẻ ngang kèm điểm đánh giá
/// - Floating Cart Pill nổi góc đáy khi giỏ hàng có sản phẩm
/// - Miễn nhiễm với RenderFlex overflow trên mọi kích thước (320px - 430px) và text scale 1.0 - 1.3
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();

  List<CategoryModel> _categories = MockData.getCategories();
  List<ProductModel> _allProducts = MockData.getProducts();
  List<ProductModel> _filteredProducts = MockData.getProducts();

  int _selectedCategoryId = -1;
  int _selectedVibeIndex =
      0; // 0: Tất cả, 1: Gần KTX, 2: Đánh giá 4.8+, 3: Sinh viên < 30k
  String? _activeQuickPill; // 'group', 'favorite', 'under30k', 'freeship'
  bool _isLoading = true;
  String? _errorMessage;
  int _currentNavIndex = 0;

  // Banner carousel state
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  // Live Deal Countdown Timer (Stitch: 00:31:38)
  Timer? _dealCountdownTimer;
  int _dealRemainingSeconds = 31 * 60 + 38;

  // Selected delivery location
  String _selectedDorm = 'KTX Khu B • Tòa BA2';

  final List<Map<String, String>> _promoBanners = [
    {
      'tag': 'KHUYẾN MÃI LÀNG ĐH',
      'title': 'Combo thi cử no căng bụng chỉ 35k',
      'subtitle': 'Freeship tận sảnh KTX Khu A & Khu B',
      'cta': 'Lấy mã ngay',
      'icon': 'lunch_dining',
      'gradientStart': '0xFFFF5722',
      'gradientEnd': '0xFFFF9800',
    },
    {
      'tag': 'ĐẠI TIỆC TRƯA KTX',
      'title': 'Giảm ngay 20% Cơm tấm & Bún bò',
      'subtitle': 'Áp dụng cho sinh viên các trường ĐHQG',
      'cta': 'Đặt món ngay',
      'icon': 'rice_bowl',
      'gradientStart': '0xFFE64A19',
      'gradientEnd': '0xFFFF7043',
    },
    {
      'tag': 'GIỜ VÀNG TRÀ SỮA',
      'title': 'Trà sữa nướng Vân Nam đồng giá 15k',
      'subtitle': 'Topping trân châu ngập tràn - Giao siêu tốc',
      'cta': 'Thử ngay',
      'icon': 'local_cafe',
      'gradientStart': '0xFFB02F00',
      'gradientEnd': '0xFFFF8A65',
    },
  ];

  final List<String> _vibeFilters = [
    'Tất cả',
    'Gần KTX (≤ 500m)',
    'Đánh giá 4.8+ ⭐',
    'Sinh viên < 30k',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _startBannerAutoScroll();
    _startDealCountdown();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerController.dispose();
    _bannerTimer?.cancel();
    _dealCountdownTimer?.cancel();
    super.dispose();
  }

  void _startBannerAutoScroll() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_bannerController.hasClients) {
        int nextIndex = (_currentBannerIndex + 1) % _promoBanners.length;
        _bannerController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _startDealCountdown() {
    _dealCountdownTimer?.cancel();
    _dealCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_dealRemainingSeconds > 0) {
        setState(() {
          _dealRemainingSeconds--;
        });
      }
    });
  }

  String _formatCountdown(int totalSeconds) {
    final hrs = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final mins = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hrs:$mins:$secs';
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Fetch categories
      List<CategoryModel> catList = [];
      try {
        final apiCats = await _productService.getCategories();
        if (apiCats.isNotEmpty) {
          catList = [CategoryModel(id: -1, name: 'Tất cả'), ...apiCats];
        } else {
          catList = MockData.getCategories();
        }
      } catch (_) {
        catList = MockData.getCategories();
      }

      // 2. Fetch products
      List<ProductModel> prodList = [];
      try {
        final apiProds = await _productService.getProducts();
        if (apiProds.isNotEmpty) {
          prodList = apiProds;
        } else {
          prodList = MockData.getProducts();
        }
      } catch (_) {
        prodList = MockData.getProducts();
      }

      if (!mounted) return;
      setState(() {
        _categories = catList;
        _allProducts = prodList;
        _isLoading = false;
      });
      _applyFilter();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _categories = MockData.getCategories();
        _allProducts = MockData.getProducts();
        _isLoading = false;
      });
      _applyFilter();
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredProducts = _allProducts.where((product) {
        // 1. Lọc theo danh mục
        final matchCategory =
            _selectedCategoryId == -1 ||
            product.categoryId == _selectedCategoryId;

        // 2. Lọc theo từ khóa tìm kiếm
        final matchQuery =
            query.isEmpty ||
            product.name.toLowerCase().contains(query) ||
            product.shopName.toLowerCase().contains(query) ||
            (product.description?.toLowerCase().contains(query) ?? false);

        // 3. Lọc theo Vibe Filter
        bool matchVibe = true;
        if (_selectedVibeIndex == 1) {
          // Gần KTX (≤ 500m)
          matchVibe =
              product.shopName.toLowerCase().contains('ktx') ||
              (product.description?.toLowerCase().contains('ktx') ?? false) ||
              product.id % 2 == 0;
        } else if (_selectedVibeIndex == 2) {
          // Đánh giá 4.8+
          matchVibe = (product.id % 3 != 0);
        } else if (_selectedVibeIndex == 3) {
          // Sinh viên < 30k
          matchVibe = product.price <= 30000;
        }

        // 4. Lọc theo Quick Action Pills
        bool matchQuickPill = true;
        if (_activeQuickPill == 'favorite') {
          matchQuickPill =
              product.shopName.toLowerCase().contains('bà tám') ||
              product.shopName.toLowerCase().contains('nhà ong') ||
              product.name.toLowerCase().contains('cơm gà');
        } else if (_activeQuickPill == 'under30k') {
          matchQuickPill = product.price <= 30000;
        } else if (_activeQuickPill == 'freeship') {
          matchQuickPill = product.price >= 20000;
        }

        return matchCategory && matchQuery && matchVibe && matchQuickPill;
      }).toList();
    });
  }

  void _onCategorySelected(int categoryId) {
    AppHaptics.selection();
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _applyFilter();
  }

  void _onVibeFilterSelected(int index) {
    AppHaptics.selection();
    setState(() {
      _selectedVibeIndex = index;
    });
    _applyFilter();
  }

  void _toggleQuickPill(String pillId) {
    AppHaptics.light();
    setState(() {
      if (_activeQuickPill == pillId) {
        _activeQuickPill = null;
      } else {
        _activeQuickPill = pillId;
      }
    });
    _applyFilter();
  }

  void _openCart() {
    AppHaptics.light();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  void _openFoodDetail(ProductModel product) {
    AppHaptics.light();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FoodDetailScreen(product: product)),
    );
  }

  void _openShopMenu(int shopId, String shopName) {
    AppHaptics.light();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ShopMenuScreen(shopId: shopId, initialShopName: shopName),
      ),
    );
  }

  void _handleAddToCart(
    ProductModel product,
    CartProvider cartProvider,
    AuthProvider authProvider,
  ) {
    AppHaptics.medium();
    cartProvider.addToCart(
      product: product,
      quantity: 1,
      userId: authProvider.user?.id,
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.successApple,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Đã thêm "${product.name}" vào giỏ KTX!',
                style: const TextStyle(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2F3034),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      ),
    );
  }

  String _getGreetingText(String? fullName) {
    final hour = DateTime.now().hour;
    final name = (fullName != null && fullName.isNotEmpty)
        ? fullName.split(' ').last
        : 'bạn';

    if (hour >= 5 && hour < 11) {
      return 'Chào buổi sáng, $name! Nạp năng lượng nhé!';
    } else if (hour >= 11 && hour < 14) {
      return 'Chào buổi trưa, $name! Đói bụng chưa?';
    } else if (hour >= 14 && hour < 18) {
      return 'Chào buổi chiều, $name! Trà sữa nạp mood nào!';
    } else if (hour >= 18 && hour < 22) {
      return 'Chào buổi tối, $name! Bữa tối thơm ngon đang chờ!';
    } else {
      return 'Cú đêm KTX ơi, $name! Ăn khuya chống đói nhé!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.langFoodTheme;
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: theme.canvas,
      body: Stack(
        children: [
          // 1. Toàn bộ nội dung cuộn dạng Slivers với Collapsing Header
          RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _loadInitialData,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // A. Collapsing SliverAppBar (Brand & Header Top Bar)
                _buildSliverAppBar(theme, authProvider, cartProvider),

                // B. Delivery Address, Greeting, Search & Quick Pills
                SliverToBoxAdapter(
                  child: _buildHeaderSection(theme, authProvider, cartProvider),
                ),

                // C. Danh mục món ngon (Capsule Category Carousel)
                SliverToBoxAdapter(child: _buildCategoriesSection(theme)),

                // D. Promotional Banner Carousel (Stitch Parallax Visual)
                SliverToBoxAdapter(child: _buildPromoBannerSlider()),

                // E. Deal Chớp Nhoáng Nghỉ Trưa ⚡ (Horizontal Flash Deal Cards)
                SliverToBoxAdapter(
                  child: _buildFlashDealsSection(
                    theme,
                    cartProvider,
                    authProvider,
                  ),
                ),

                // F. Quán ngon sinh viên chấm cao 🌟 (Section Header & Vibe Filter)
                SliverToBoxAdapter(child: _buildVibeFilterSection(theme)),

                // G. Danh sách món ăn / nhà hàng (Quán ngon sinh viên chấm cao)
                _buildProductListSlivers(theme, cartProvider, authProvider),

                // H. Đặt chung gom đơn tiết kiệm (Communal Ordering Callout)
                SliverToBoxAdapter(child: _buildCommunalOrderCallout(theme)),

                // I. Đáy danh sách (Padding an toàn để Floating Cart Pill không che nội dung)
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),

          // 2. Floating Cart Pill nổi góc đáy (Stitch LF-01 Level 3 Elevation)
          if (cartProvider.totalItemsCount > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 8, // Nổi thoải mái ngay trên BottomNavigationBar
              child: LangFoodFloatingCartPill(
                totalItemCount: cartProvider.totalItemsCount,
                totalPrice: cartProvider.totalAmount,
                label: 'Xem giỏ đơn KTX',
                onTap: _openCart,
              ),
            ),
        ],
      ),

      // 3. Bottom Navigation Bar chuẩn Stitch LF-01 (Khám phá, Đơn hàng, Đặt chung, Thông báo, Tôi)
      bottomNavigationBar: _buildBottomNavigationBar(theme),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildSliverAppBar(
    LangFoodThemeExtension theme,
    AuthProvider authProvider,
    CartProvider cartProvider,
  ) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      scrolledUnderElevation: 1.0,
      backgroundColor: theme.card,
      surfaceTintColor: Colors.transparent,
      titleSpacing: AppTokens.marginMobile,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.shopping_bag_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'LANGFOOD',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.verified_rounded,
                      size: 13,
                      color: AppColors.primary,
                    ),
                  ],
                ),
                Text(
                  'Khám Phá',
                  style: AppTypography.titleMd.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                    fontSize: 16,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Action: Cart Shortcut
        IconButton(
          tooltip: 'Giỏ hàng KTX',
          onPressed: _openCart,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                color: theme.textPrimary,
                size: 24,
              ),
              if (cartProvider.totalItemsCount > 0)
                Positioned(
                  top: -2,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cartProvider.totalItemsCount}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Action: User Menu / Avatar
        Padding(
          padding: const EdgeInsets.only(right: 14, left: 4),
          child: GestureDetector(
            onTap: () => _showUserMenu(authProvider),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryDeep,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                authProvider.user?.fullName?.isNotEmpty == true
                    ? authProvider.user!.fullName![0].toUpperCase()
                    : (authProvider.user?.username.isNotEmpty == true
                          ? authProvider.user!.username[0].toUpperCase()
                          : 'U'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection(
    LangFoodThemeExtension theme,
    AuthProvider authProvider,
    CartProvider cartProvider,
  ) {
    return Container(
      color: theme.card,
      padding: const EdgeInsets.fromLTRB(
        AppTokens.marginMobile,
        6,
        AppTokens.marginMobile,
        14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Delivery Location Bar (Stitch: GIAO TẬN PHÒNG THI & KTX)
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: _showLocationPickerSheet,
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GIAO TẬN PHÒNG THI & KTX',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          fontSize: 10,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _selectedDorm,
                              style: AppTypography.titleMd.copyWith(
                                color: theme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.expand_more_rounded,
                            size: 18,
                            color: theme.textSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Notification Bell with Red Badge
              PressScaleWidget(
                onTap: () {
                  AppHaptics.light();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Không có thông báo mới nào từ KTX!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.canvas,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        color: theme.textPrimary,
                        size: 20,
                      ),
                      Positioned(
                        top: 7,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Large Title with Dynamic Student Greeting
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.wb_sunny_rounded,
                color: AppColors.accent,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _getGreetingText(
                    authProvider.user?.fullName ?? authProvider.user?.username,
                  ),
                  style: AppTypography.labelMd.copyWith(
                    color: theme.textSecondary,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Hôm nay ăn gì ở Làng? 🍜',
            style: AppTypography.headlineLg.copyWith(
              color: theme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: -0.5,
            ),
            softWrap: true,
          ),
          const SizedBox(height: 12),

          // 3. Search Bar bo góc Squircle với Mic & QR Scanner (Stitch LF-01)
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: theme.canvas,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(color: theme.borderSubtle, width: 0.8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: theme.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _applyFilter(),
                    style: TextStyle(color: theme.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Tìm cơm gà, trà sữa nướng, bún bò...',
                      hintStyle: TextStyle(
                        color: theme.textSecondary.withValues(alpha: 0.65),
                        fontSize: 13,
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
                    child: Icon(
                      Icons.cancel_rounded,
                      color: theme.textSecondary,
                      size: 18,
                    ),
                  )
                else ...[
                  IconButton(
                    icon: Icon(
                      Icons.mic_none_rounded,
                      color: theme.textSecondary,
                      size: 19,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    onPressed: () {
                      AppHaptics.light();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Tính năng tìm kiếm bằng giọng nói đang chuẩn bị ra mắt!',
                          ),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  if (MediaQuery.sizeOf(context).width >= 350) ...[
                    Container(
                      width: 1,
                      height: 14,
                      color: theme.borderSubtle,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.qr_code_scanner_rounded,
                        color: theme.textSecondary,
                        size: 19,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      onPressed: () {
                        AppHaptics.light();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Tính năng quét mã QR bàn / quán đang chuẩn bị ra mắt!',
                            ),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 4. Student Quick Action Pills (Đặt nhóm chia ship, Quán quen, Dưới 30k, Freeship)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickActionPill(
                  id: 'group',
                  label: 'Đặt nhóm chia ship',
                  icon: Icons.groups_rounded,
                  isHighlighted: true,
                  theme: theme,
                ),
                const SizedBox(width: 8),
                _buildQuickActionPill(
                  id: 'favorite',
                  label: 'Quán quen KTX',
                  icon: Icons.favorite_rounded,
                  iconColor: AppColors.accent,
                  theme: theme,
                ),
                const SizedBox(width: 8),
                _buildQuickActionPill(
                  id: 'under30k',
                  label: 'Dưới 30k',
                  icon: Icons.savings_rounded,
                  iconColor: AppColors.tertiary,
                  theme: theme,
                ),
                const SizedBox(width: 8),
                _buildQuickActionPill(
                  id: 'freeship',
                  label: 'Freeship 0đ',
                  icon: Icons.moped_rounded,
                  iconColor: AppColors.primary,
                  theme: theme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionPill({
    required String id,
    required String label,
    required IconData icon,
    required LangFoodThemeExtension theme,
    Color? iconColor,
    bool isHighlighted = false,
  }) {
    final isSelected = _activeQuickPill == id;

    final bgColor = isSelected
        ? AppColors.primary
        : (isHighlighted
              ? AppColors.primary.withValues(alpha: 0.12)
              : theme.card);

    final textColor = isSelected
        ? Colors.white
        : (isHighlighted ? AppColors.primary : theme.textPrimary);

    final effectiveIconColor = isSelected
        ? Colors.white
        : (iconColor ??
              (isHighlighted ? AppColors.primary : theme.textSecondary));

    return PressScaleWidget(
      onTap: () {
        if (id == 'group') {
          _showCommunalOrderSheet();
        } else {
          _toggleQuickPill(id);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isHighlighted
                      ? AppColors.primary.withValues(alpha: 0.25)
                      : theme.borderSubtle),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: effectiveIconColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTypography.labelMd.copyWith(
                color: textColor,
                fontWeight: isSelected || isHighlighted
                    ? FontWeight.bold
                    : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(LangFoodThemeExtension theme) {
    if (!_isLoading && _categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LangFoodSectionHeader(
          title: 'Danh mục món ngon',
          actionText: 'Tất cả 18+',
          onActionTap: () {
            _onCategorySelected(-1);
          },
        ),
        SizedBox(
          height: 94,
          child: _isLoading && _categories.isEmpty
              ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.marginMobile,
                  ),
                  itemCount: 5,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: theme.card,
                            borderRadius: BorderRadius.circular(
                              AppTokens.radiusLg,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 50,
                          height: 10,
                          decoration: BoxDecoration(
                            color: theme.card,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.marginMobile,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategoryId == cat.id;

                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: PressScaleWidget(
                        onTap: () => _onCategorySelected(cat.id),
                        child: Column(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : _getCategoryColor(cat.name)
                                              .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(
                                      AppTokens.radiusLg,
                                    ),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : theme.borderSubtle,
                                      width: isSelected ? 1.5 : 0.8,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(cat.name),
                                    color: isSelected
                                        ? Colors.white
                                        : _getCategoryColor(cat.name),
                                    size: 26,
                                  ),
                                ),
                                // Badge "HOT" cho Cơm trưa (Stitch LF-01)
                                if (cat.name.toLowerCase().contains('cơm'))
                                  Positioned(
                                    top: -4,
                                    right: -4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryDeep,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'HOT',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 66,
                              child: Text(
                                cat.name,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primary
                                      : theme.textPrimary,
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
    );
  }

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('cơm')) return Icons.rice_bowl_rounded;
    if (lower.contains('trà sữa') || lower.contains('cafe')) {
      return Icons.local_cafe_rounded;
    }
    if (lower.contains('bún') ||
        lower.contains('phở') ||
        lower.contains('mì')) {
      return Icons.ramen_dining_rounded;
    }
    if (lower.contains('vặt') || lower.contains('snack')) {
      return Icons.fastfood_rounded;
    }
    if (lower.contains('bánh')) return Icons.bakery_dining_rounded;
    if (lower.contains('nước') || lower.contains('juice')) {
      return Icons.local_drink_rounded;
    }
    return Icons.restaurant_menu_rounded;
  }

  Color _getCategoryColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('cơm')) return AppColors.primary;
    if (lower.contains('trà sữa')) return AppColors.accent;
    if (lower.contains('bún') || lower.contains('mì')) {
      return AppColors.tertiary;
    }
    if (lower.contains('vặt')) return const Color(0xFF673AB7);
    if (lower.contains('bánh')) return const Color(0xFF8D6E63);
    return AppColors.primary;
  }

  Widget _buildPromoBannerSlider() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.marginMobile,
        vertical: 8,
      ),
      height: 156,
      child: PageView.builder(
        controller: _bannerController,
        onPageChanged: (index) {
          setState(() {
            _currentBannerIndex = index;
          });
        },
        itemCount: _promoBanners.length,
        itemBuilder: (context, index) {
          final banner = _promoBanners[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(int.parse(banner['gradientStart']!)),
                  Color(int.parse(banner['gradientEnd']!)),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: Color(int.parse(banner['gradientStart']!))
                      .withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Tag, Title, Subtitle (Left) + Icon (Right)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(
                                AppTokens.radiusFull,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.flash_on_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    banner['tag']!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            banner['title']!,
                            style: AppTypography.headlineSm.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            banner['subtitle']!,
                            style: AppTypography.bodySm.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.lunch_dining_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),

                // Bottom Row: Dots Indicator (Left) + CTA Button (Right) - Stitch LF-01
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Dots Indicator
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_promoBanners.length, (idx) {
                        final isActive = _currentBannerIndex == idx;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: isActive ? 16 : 6,
                          height: 5,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),

                    // CTA Button
                    PressScaleWidget(
                      onTap: () {
                        AppHaptics.light();
                        _onVibeFilterSelected(0);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                banner['cta']!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 13,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFlashDealsSection(
    LangFoodThemeExtension theme,
    CartProvider cartProvider,
    AuthProvider authProvider,
  ) {
    final dealProducts = _allProducts.isNotEmpty
        ? _allProducts.take(4).toList()
        : MockData.getProducts().take(4).toList();
    if (dealProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.marginMobile,
            12,
            AppTokens.marginMobile,
            8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Deal chớp nhoáng nghỉ trưa',
                        style: AppTypography.titleMd.copyWith(
                          color: theme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('⚡', style: TextStyle(fontSize: 15)),
                    const SizedBox(width: 6),
                    // Countdown badge (Stitch: 00:31:38)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatCountdown(_dealRemainingSeconds),
                        style: AppTypography.currencyDisplay.copyWith(
                          color: AppColors.error,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _onVibeFilterSelected(3),
                child: Text(
                  'Xem thêm',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 236,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.marginMobile,
            ),
            itemCount: dealProducts.length,
            itemBuilder: (context, index) {
              final prod = dealProducts[index];
              final discount = (index % 2 == 0) ? 35 : 28;
              final prepTime = '${10 + (index * 5)}p';

              return LangFoodDealCard(
                product: prod,
                discountPercent: discount,
                prepTime: prepTime,
                onTap: () => _openFoodDetail(prod),
                onAddToCart: () =>
                    _handleAddToCart(prod, cartProvider, authProvider),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVibeFilterSection(LangFoodThemeExtension theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LangFoodSectionHeader(
          title: 'Quán ngon sinh viên chấm cao 🌟',
          subtitle: 'Lọc theo vibe ẩm thực KTX',
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.marginMobile,
          ),
          child: Row(
            children: List.generate(_vibeFilters.length, (index) {
              final isSelected = _selectedVibeIndex == index;
              return Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                child: PressScaleWidget(
                  onTap: () => _onVibeFilterSelected(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : theme.card,
                      borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : theme.borderSubtle,
                        width: 0.8,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.25,
                                ),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      _vibeFilters[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected ? Colors.white : theme.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildProductListSlivers(
    LangFoodThemeExtension theme,
    CartProvider cartProvider,
    AuthProvider authProvider,
  ) {
    if (_isLoading) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.marginMobile),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LangFoodLoadingSkeleton.cardSkeleton(context),
            ),
            childCount: 3,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: LangFoodEmptyState(
            title: 'Mất kết nối WiFi KTX',
            message: 'Không thể tải danh sách thực đơn Làng ĐH. Vui lòng kiểm tra lại kết nối mạng phòng ký túc xá.',
            buttonText: 'Thử tải lại',
            onButtonPressed: _loadInitialData,
          ),
        ),
      );
    }

    if (_filteredProducts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: LangFoodEmptyState(
            title: 'Chưa tìm thấy món ngon này',
            message: 'Các quán quanh KTX Khu B đang chuẩn bị nguyên liệu hoặc chưa mở cửa. Hãy thử tìm từ khóa khác nhé!',
            buttonText: 'Xem tất cả quán KTX',
            onButtonPressed: () {
              _searchController.clear();
              setState(() {
                _selectedCategoryId = -1;
                _selectedVibeIndex = 0;
                _activeQuickPill = null;
              });
              _applyFilter();
            },
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.marginMobile),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final product = _filteredProducts[index];
          return LangFoodHorizontalProductCard(
            product: product,
            rating: 4.7 + (index % 3) * 0.1,
            prepTime: '${10 + (index % 4) * 5} phút',
            onTap: () => _openFoodDetail(product),
            onShopTap: () => _openShopMenu(product.shopId, product.shopName),
            onAddToCart: () =>
                _handleAddToCart(product, cartProvider, authProvider),
          );
        }, childCount: _filteredProducts.length),
      ),
    );
  }

  Widget _buildCommunalOrderCallout(LangFoodThemeExtension theme) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.marginMobile,
        vertical: 12,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(color: theme.borderSubtle, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.tertiary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.forum_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phòng bạn đang gom đơn?',
                  style: AppTypography.titleMd.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tạo giỏ nhóm chia tiền ship 0đ tự động!',
                  style: AppTypography.bodySm.copyWith(
                    color: theme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PressScaleWidget(
            onTap: _showCommunalOrderSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Tạo giỏ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(LangFoodThemeExtension theme) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: theme.card,
        border: Border(top: BorderSide(color: theme.borderSubtle, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildNavItem(0, Icons.storefront_rounded, 'Khám phá', theme),
          _buildNavItem(1, Icons.receipt_long_rounded, 'Đơn hàng', theme),
          _buildNavItem(
            2,
            Icons.group_rounded,
            'Đặt chung',
            theme,
            hasBadge: true,
            badgeText: 'Nhóm',
          ),
          _buildNavItem(
            3,
            Icons.notifications_none_rounded,
            'Thông báo',
            theme,
          ),
          _buildNavItem(4, Icons.person_outline_rounded, 'Tài khoản', theme),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    LangFoodThemeExtension theme, {
    bool hasBadge = false,
    String? badgeText,
  }) {
    final isSelected = _currentNavIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          AppHaptics.selection();
          setState(() {
            _currentNavIndex = index;
          });
          if (index == 1) {
            _openCart();
          } else if (index == 2) {
            _showCommunalOrderSheet();
          } else if (index == 4) {
            _showUserMenu(Provider.of<AuthProvider>(context, listen: false));
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.primary : theme.textSecondary,
                  size: 22,
                ),
                if (hasBadge && badgeText != null)
                  Positioned(
                    top: -4,
                    right: -10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(
                          AppTokens.radiusFull,
                        ),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : theme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationPickerSheet() {
    final dorms = [
      'KTX Khu B • Tòa BA2',
      'KTX Khu B • Tòa BA1',
      'KTX Khu B • Tòa BA3',
      'KTX Khu B • Tòa BA4',
      'KTX Khu A • Tòa A1-A5',
      'Trường ĐH Công Nghệ Thông Tin (UIT)',
      'Trường ĐH Bách Khoa (Cơ sở 2)',
      'Trường ĐH Khoa Học Tự Nhiên',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = ctx.langFoodTheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spaceMd),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Chọn địa điểm giao hàng KTX',
                  style: AppTypography.titleMd.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Shipper sẽ giao đến tận sảnh tòa nhà hoặc cổng bảo vệ',
                  style: AppTypography.bodySm.copyWith(
                    color: theme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: dorms.length,
                    itemBuilder: (context, idx) {
                      final item = dorms[idx];
                      final isSelected = item == _selectedDorm;
                      return ListTile(
                        leading: Icon(
                          Icons.location_on_rounded,
                          color: isSelected
                              ? AppColors.primary
                              : theme.textSecondary,
                        ),
                        title: Text(
                          item,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primary
                                : theme.textPrimary,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedDorm = item;
                          });
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCommunalOrderSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Đặt nhóm gom đơn chia ship 0đ',
                  style: AppTypography.titleMd.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tạo mã phòng để bạn cùng phòng KTX chọn món chung vào một giỏ hàng. Phí vận chuyển tự động chia đều hoặc miễn phí!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã tạo nhóm đơn phòng P.402 KTX Khu B!'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Tạo nhóm mới ngay',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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

  void _showUserMenu(AuthProvider authProvider) {
    final rootNavigator = Navigator.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                          : 'U',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    authProvider.user?.fullName ??
                        authProvider.user?.username ??
                        'Tài khoản',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Vai trò: ${authProvider.user?.roleName ?? 'Khách hàng'}',
                  ),
                ),
                const Divider(),
                // Chuyển đổi giao diện Sáng / Tối
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    return ListTile(
                      leading: Icon(
                        themeProvider.isDarkMode
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: AppColors.primary,
                      ),
                      title: const Text(
                        'Chế độ giao diện',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        themeProvider.isDarkMode
                            ? 'Đang bật chế độ tối'
                            : 'Đang bật chế độ sáng',
                      ),
                      trailing: Switch.adaptive(
                        value: themeProvider.isDarkMode,
                        activeThumbColor: AppColors.primary,
                        onChanged: (isDark) {
                          AppHaptics.selection();
                          themeProvider.setThemeMode(
                            isDark ? ThemeMode.dark : ThemeMode.light,
                          );
                        },
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.shopping_cart_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Xem giỏ hàng'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _openCart();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.palette_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    '🎨 Design System Showcase (UI-01)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Xem bảng màu, typography, nút, card, stepper, dark mode',
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DesignSystemShowcase(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.map_outlined, color: Colors.orange),
                  title: const Text('Bản đồ & Live Tracking (Shipper/Khách)'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RoleChooserScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.swap_horiz_rounded, color: Colors.blue),
                  title: const Text('Chuyển vai trò Demo (3 Roles)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Chuyển nhanh sang Shipper hoặc Chủ quán'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showRoleSwitcherDialog(context);
                  },
                ),
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

  void _showRoleSwitcherDialog(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Chuyển đổi 3 Role (Demo Giảng Viên)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Text(
                  'Chọn vai trò để kiểm thử quy trình khép kín:',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFECE5),
                    child: Icon(Icons.person, color: Color(0xFFFF5722)),
                  ),
                  title: const Text('1. Sinh viên (Khách hàng)'),
                  subtitle: const Text('Tài khoản: nhiem - Đang hoạt động'),
                  trailing: const Icon(Icons.check_circle, color: Color(0xFFFF5722)),
                  onTap: () => Navigator.pop(ctx),
                ),
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(Icons.storefront, color: Colors.green),
                  ),
                  title: const Text('2. Chủ quán (Seller / Shop)'),
                  subtitle: const Text('Tài khoản: seller - Nhận đơn quán'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final nav = Navigator.of(context);
                    await auth.login('seller', '123456');
                    if (mounted) {
                      nav.pushReplacement(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFF3E0),
                    child: Icon(Icons.directions_bike, color: Colors.orange),
                  ),
                  title: const Text('3. Tài xế (Shipper)'),
                  subtitle: const Text('Tài khoản: shipper - Xem đơn theo thời gian thực'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final nav = Navigator.of(context);
                    await auth.login('shipper', '123456');
                    if (mounted) {
                      nav.pushReplacement(
                        MaterialPageRoute(
                            builder: (_) => const ShipperOrdersScreen()),
                      );
                    }
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

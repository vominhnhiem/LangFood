import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../orders/presentation/screens/my_orders_screen.dart';
import '../../../account/presentation/screens/profile_screen.dart';
import '../../../wallet/presentation/screens/wallet_screen.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_motion.dart';
import '../../../../core/widgets/langfood_campus_route.dart';
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

import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../food_detail/presentation/screens/food_detail_screen.dart';
import '../../../shop/presentation/screens/shop_menu_screen.dart';
import 'lobby_pooling_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();

  List<CategoryModel> _categories = [];
  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];

  int _selectedCategoryId = -1;
  int _selectedVibeIndex =
      0; // 0: Tất cả, 1: Gần KTX, 2: Đánh giá 4.8+, 3: Sinh viên < 30k
  String? _activeQuickPill; // 'group', 'favorite', 'under30k', 'freeship'
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedDorm = 'KTX Khu B • Tòa BA2';

  final List<String> _vibeFilters = [
    'Tất cả',
    'Đang mở cửa',
    'Món từ 30k',
    'Sinh viên < 30k',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final categories = await _productService.getCategories();
      final products = await _productService.getProducts();
      if (!mounted) return;
      setState(() {
        _categories = [CategoryModel(id: -1, name: 'Tất cả'), ...categories];
        _allProducts = products;
        _isLoading = false;
      });
      _applyFilter();
    } catch (error) {
      debugPrint('Không tải được thực đơn: $error');
      if (!mounted) return;
      setState(() {
        _categories = [];
        _allProducts = [];
        _filteredProducts = [];
        _isLoading = false;
        _errorMessage = error.toString();
      });
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
          matchVibe = product.isShopOpen;
        } else if (_selectedVibeIndex == 2) {
          // Đánh giá 4.8+
          matchVibe = product.price >= 30000;
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
          matchQuickPill = product.isShopOpen;
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
    final cartProvider = context.read<CartProvider>();
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
                _buildSliverAppBar(theme),
                SliverToBoxAdapter(child: _buildSearch(theme)),
                SliverToBoxAdapter(child: _buildCategoriesSection(theme)),
                if (!_hasActiveFilter) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    sliver: SliverToBoxAdapter(
                      child: LangFoodCampusBanner(
                        label: 'LANGFOOD / KTX KHU B',
                        title: 'Hôm nay ăn gì ở Làng?',
                        detail: _getGreetingText(
                          authProvider.user?.fullName ??
                              authProvider.user?.username,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildFlashDealsSection(
                      theme,
                      cartProvider,
                      authProvider,
                    ),
                  ),
                ],

                // F. Thực đơn quanh KTX (Section Header & Vibe Filter)
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

          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Selector<CartProvider, (int, double)>(
              selector: (_, cart) => (cart.totalItemsCount, cart.totalAmount),
              builder: (context, totals, _) => totals.$1 == 0
                  ? const SizedBox.shrink()
                  : LangFoodFloatingCartPill(
                      totalItemCount: totals.$1,
                      totalPrice: totals.$2,
                      label: 'Xem giỏ đơn KTX',
                      onTap: _openCart,
                    ),
            ),
          ),
        ],
      ),

      // 3. Bottom Navigation Bar chuẩn Stitch LF-01 (Khám phá, Đơn hàng, Đặt chung, Thông báo, Tôi)
      bottomNavigationBar: _buildBottomNavigationBar(theme),
    );
  }

  // --- WIDGET BUILDERS ---

  bool get _hasActiveFilter =>
      _searchController.text.trim().isNotEmpty ||
      _selectedCategoryId != -1 ||
      _activeQuickPill != null ||
      _selectedVibeIndex != 0;

  Widget _buildSliverAppBar(LangFoodThemeExtension theme) {
    final scheme = Theme.of(context).colorScheme;
    return SliverAppBar(
      pinned: true,
      backgroundColor: theme.canvas,
      titleSpacing: AppTokens.marginMobile,
      toolbarHeight: 76,
      title: Semantics(
        button: true,
        child: InkWell(
          onTap: _showLocationPickerSheet,
          borderRadius: AppTokens.borderRadiusLg,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: AppTokens.borderRadiusMd,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.place_rounded,
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'GIAO ĐẾN',
                        style: AppTypography.labelSm.copyWith(
                          color: theme.textSecondary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        _selectedDorm,
                        style: AppTypography.titleMd,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            tooltip: 'Giỏ hàng KTX',
            onPressed: _openCart,
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
        ),
      ],
    );
  }

  Widget _buildSearch(LangFoodThemeExtension theme) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => _applyFilter(),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Tìm món hoặc tên quán',
              fillColor: theme.card,
              prefixIcon: Icon(Icons.search_rounded, color: scheme.secondary),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Xóa tìm kiếm',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchController.clear();
                        _applyFilter();
                      },
                    ),
            ),
          ),
          const SizedBox(height: 8),
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
                  label: 'Đang mở cửa',
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
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.center,
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
          height: 78 + MediaQuery.textScalerOf(context).scale(13) * 2,
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
                              width: 76,
                              child: Text(
                                cat.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
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

  Widget _buildFlashDealsSection(
    LangFoodThemeExtension theme,
    CartProvider cartProvider,
    AuthProvider authProvider,
  ) {
    final products = _allProducts.take(4).toList();
    if (products.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Gợi ý hôm nay',
                  style: AppTypography.titleMd.copyWith(
                    color: theme.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _onVibeFilterSelected(0),
                child: const Text('Xem thêm'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 186 + MediaQuery.textScalerOf(context).scale(28) * 2,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(
                width: 164,
                child: LangFoodDealCard(
                  product: product,
                  onTap: () => _openFoodDetail(product),
                  onAddToCart: () =>
                      _handleAddToCart(product, cartProvider, authProvider),
                ),
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
          title: 'Thực đơn quanh KTX',
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
            title: 'Chưa tải được thực đơn',
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
                  'Các món được nhóm theo quán trong giỏ hàng.',
                  style: AppTypography.bodySm.copyWith(
                    color: theme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _showCommunalOrderSheet,
            child: const Text('Tạo giỏ'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(LangFoodThemeExtension theme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.card,
        border: Border(top: BorderSide(color: theme.borderSubtle, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 39 + MediaQuery.textScalerOf(context).scale(13) * 2,
          child: Row(
            children: [
              _buildNavItem(0, Icons.storefront_rounded, 'Khám phá', theme),
              _buildNavItem(1, Icons.receipt_long_rounded, 'Đơn hàng', theme),
              _buildNavItem(2, Icons.group_rounded, 'Đặt chung', theme),
              _buildNavItem(
                3,
                Icons.notifications_none_rounded,
                'Thông báo',
                theme,
              ),
              _buildNavItem(
                4,
                Icons.person_outline_rounded,
                'Tài khoản',
                theme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    LangFoodThemeExtension theme,
  ) {
    final isSelected = index == 0;
    final scheme = Theme.of(context).colorScheme;

    return Expanded(
      child: InkWell(
        onTap: () {
          AppHaptics.selection();
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
            );
          } else if (index == 2) {
            _showCommunalOrderSheet();
          } else if (index == 3) {
            _showNotifications();
          } else if (index == 4) {
            _showUserMenu(Provider.of<AuthProvider>(context, listen: false));
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: isSelected
                    ? scheme.secondaryContainer
                    : Colors.transparent,
                borderRadius: AppTokens.borderRadiusFull,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 3,
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? scheme.onSecondaryContainer
                      : theme.textSecondary,
                  size: 21,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? scheme.onSecondaryContainer
                    : theme.textSecondary,
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
      sheetAnimationStyle: AppMotion.sheetStyle(context),
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
    final shops = <int, String>{
      for (final product in _allProducts)
        if (product.shopId > 0 && product.isAvailable && product.isShopOpen)
          product.shopId: product.shopName,
    };
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LobbyPoolingScreen(shops: shops)),
    );
  }

  void _showNotifications() {
    showModalBottomSheet<void>(
      context: context,
      sheetAnimationStyle: AppMotion.sheetStyle(context),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.notifications_none,
                size: 40,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              const Text('Thông báo đơn hàng'),
              const SizedBox(height: 8),
              const Text(
                'Theo dõi trạng thái mới nhất trong Đơn hàng của tôi.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                  );
                },
                child: const Text('Xem đơn hàng'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserMenu(AuthProvider authProvider) {
    showModalBottomSheet<void>(
      context: context,
      sheetAnimationStyle: AppMotion.sheetStyle(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                authProvider.user?.fullName ??
                    authProvider.user?.username ??
                    '',
              ),
              subtitle: const Text('Tài khoản LangFood'),
            ),
            for (final entry in <(IconData, String, Widget)>[
              (Icons.person_outline, 'Hồ sơ cá nhân', const ProfileScreen()),
              (Icons.receipt_long, 'Đơn hàng của tôi', const MyOrdersScreen()),
              (
                Icons.account_balance_wallet_outlined,
                'Ví và giao dịch',
                const WalletScreen(),
              ),
            ])
              ListTile(
                leading: Icon(entry.$1),
                title: Text(entry.$2),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => entry.$3),
                  );
                },
              ),
            SwitchListTile(
              title: const Text('Giao diện tối'),
              value: context.read<ThemeProvider>().themeMode == ThemeMode.dark,
              onChanged: (_) {
                context.read<ThemeProvider>().toggleTheme();
                Navigator.pop(sheetContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Đăng xuất'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await authProvider.logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

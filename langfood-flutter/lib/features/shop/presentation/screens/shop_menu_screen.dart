import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_motion.dart';
import '../../../../core/widgets/langfood_empty_state.dart';
import '../../../../core/widgets/langfood_floating_cart_pill.dart';
import '../../../../core/widgets/langfood_loading_skeleton.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/models/shop_model.dart';
import '../../../../data/services/product_service.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/cart_provider.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../food_detail/presentation/screens/food_detail_screen.dart';
import '../../../food_detail/presentation/widgets/food_customization_sheet.dart';
import '../widgets/shop_product_card.dart';

/// Màn hình Thực Đơn Quán Ăn (Shop Menu Screen) chuẩn thiết kế Stitch LF-02
/// - Header bìa quán với SliverAppBar thu gọn mượt mà kèm badges Freeship & Thời gian
/// - Restaurant Identity Card bo góc 24px overlap ảnh bìa: Meta bar, địa chỉ, giờ mở cửa, voucher sinh viên
/// - Sticky Category Filter Bar cuộn ngang ghim trên đỉnh khi lướt menu
/// - Thẻ món ăn ShopProductCard bố cục chuẩn LF-02
/// - Floating Cart Pill nổi ở đáy (Level 3 Elevation)
/// - Trạng thái Loading Skeleton, Empty State, Error State và Closed State
class ShopMenuScreen extends StatefulWidget {
  final int shopId;
  final String? initialShopName;
  final ShopModel? initialShop;
  final List<ProductModel>? initialProducts;
  final ProductService? productService;

  const ShopMenuScreen({
    super.key,
    required this.shopId,
    this.initialShopName,
    this.initialShop,
    this.initialProducts,
    this.productService,
  });

  @override
  State<ShopMenuScreen> createState() => _ShopMenuScreenState();
}

class _ShopMenuScreenState extends State<ShopMenuScreen> {
  late final ProductService _productService =
      widget.productService ?? ProductService();

  bool _isLoading = true;
  String? _errorMessage;
  ShopModel? _shop;
  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  List<String> _categories = ['Tất cả'];
  String _selectedCategory = 'Tất cả';
  bool _isFavorite = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  late final ScrollController _scrollController = ScrollController();
  bool _isHeaderCollapsed = false;

  @override
  void initState() {
    super.initState();
    _shop = widget.initialShop;
    _scrollController.addListener(_onScroll);
    _loadShopMenu();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final isCollapsed = _scrollController.offset > 140;
    if (isCollapsed != _isHeaderCollapsed) {
      setState(() {
        _isHeaderCollapsed = isCollapsed;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadShopMenu() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ShopModel shopData;
      final List<ProductModel> productsData;

      if (widget.initialProducts != null) {
        final isDemo =
            widget.shopId == 1 ||
            (widget.initialShopName == 'Cơm Gà Xối Mỡ Bà Tám');
        shopData =
            widget.initialShop ??
            ShopModel(
              id: widget.shopId,
              name:
                  widget.initialShopName ??
                  (isDemo ? 'Cơm Gà Xối Mỡ Bà Tám' : 'Quán ăn Làng Food'),
              address: isDemo
                  ? 'Cổng sau ĐH Khoa Học Tự Nhiên, KTX Khu B'
                  : 'Ký túc xá Khu B, ĐHQG-HCM',
              description: isDemo
                  ? 'Đùi gà da giòn rụm • Cơm chiên sốt cà chua gia truyền'
                  : null,
              imageUrl: isDemo
                  ? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800'
                  : null,
              rating: isDemo ? 4.9 : null,
              reviewCount: isDemo ? 1200 : null,
              prepTime: isDemo ? '15-20 phút' : null,
              distance: isDemo ? '350m từ KTX B' : null,
              isVerified: isDemo,
              voucherCode: isDemo ? 'SINHVIENKHOE' : null,
              voucherDiscount: isDemo ? 'Giảm 15.000₫' : null,
              voucherDescription: isDemo
                  ? 'Tặng kèm canh rong biển & trà tắc từ 2 phần'
                  : null,
              isOpen: true,
            );
        productsData = widget.initialProducts!;
      } else {
        // 1. Tải thông tin quán ăn và danh sách món ăn từ API backend
        final results = await Future.wait([
          _productService.getShopById(widget.shopId).catchError((_) {
            final isDemo =
                widget.shopId == 1 ||
                (widget.initialShopName == 'Cơm Gà Xối Mỡ Bà Tám');
            return widget.initialShop ??
                ShopModel(
                  id: widget.shopId,
                  name:
                      widget.initialShopName ??
                      (isDemo ? 'Cơm Gà Xối Mỡ Bà Tám' : 'Quán ăn Làng Food'),
                  address: isDemo
                      ? 'Cổng sau ĐH Khoa Học Tự Nhiên, KTX Khu B'
                      : 'Ký túc xá Khu B, ĐHQG-HCM',
                  description: isDemo
                      ? 'Đùi gà da giòn rụm • Cơm chiên sốt cà chua gia truyền'
                      : null,
                  imageUrl: isDemo
                      ? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800'
                      : null,
                  rating: isDemo ? 4.9 : null,
                  reviewCount: isDemo ? 1200 : null,
                  prepTime: isDemo ? '15-20 phút' : null,
                  distance: isDemo ? '350m từ KTX B' : null,
                  isVerified: isDemo,
                  voucherCode: isDemo ? 'SINHVIENKHOE' : null,
                  voucherDiscount: isDemo ? 'Giảm 15.000₫' : null,
                  voucherDescription: isDemo
                      ? 'Tặng kèm canh rong biển & trà tắc từ 2 phần'
                      : null,
                  isOpen: true,
                );
          }),
          _productService.getProductsByShop(widget.shopId).catchError((
            _,
          ) async {
            // Thử lấy danh sách món chung rồi lọc theo shopId
            final all = await _productService.getProducts();
            final byShop = all.where((p) => p.shopId == widget.shopId).toList();
            if (byShop.isNotEmpty) return byShop;
            return all; // Trả về danh sách món nếu shopId tương đồng
          }),
        ]);

        shopData = results[0] as ShopModel;
        productsData = results[1] as List<ProductModel>;
      }

      // Trích xuất các danh mục độc nhất từ danh sách món ăn
      final Set<String> catSet = {'Tất cả'};
      for (final p in productsData) {
        if (p.categoryName != null && p.categoryName!.trim().isNotEmpty) {
          catSet.add(p.categoryName!.trim());
        }
      }

      if (mounted) {
        setState(() {
          _shop = shopData;
          _allProducts = productsData;
          _filteredProducts = productsData;
          _categories = catSet.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể tải thực đơn quán ăn. Sóng WiFi KTX có vẻ đang chập chờn. Bạn kiểm tra lại 4G hoặc kết nối mạng rồi thử lại nhé!';
          _isLoading = false;
        });
      }
    }
  }

  void _onCategorySelected(String category) {
    AppHaptics.selection();
    setState(() {
      _selectedCategory = category;
      _applyFilter();
    });
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((p) {
        final matchesCat =
            _selectedCategory == 'Tất cả' ||
            (p.categoryName != null &&
                p.categoryName!.trim() == _selectedCategory);

        final matchesSearch =
            query.isEmpty ||
            p.name.toLowerCase().contains(query) ||
            (p.description?.toLowerCase().contains(query) ?? false);

        return matchesCat && matchesSearch;
      }).toList();
    });
  }

  void _openFoodDetail(ProductModel product) {
    AppHaptics.light();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FoodDetailScreen(product: product)),
    );
  }

  void _openCustomizationSheet(ProductModel product) {
    AppHaptics.light();
    FoodCustomizationSheet.show(context: context, product: product);
  }

  void _handleAddToCart(
    ProductModel product,
    CartProvider cartProvider,
    AuthProvider authProvider,
  ) {
    // Nếu món ăn có các nhóm tùy chọn (size, topping) -> mở FoodCustomizationSheet (LF-03 / LF-04)
    if (product.optionGroups.isNotEmpty) {
      _openCustomizationSheet(product);
      return;
    }

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
                'Đã thêm "${product.name}" vào giỏ đơn KTX!',
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

  void _copyPromoCode([String code = 'SINHVIENKHOE']) {
    AppHaptics.light();
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.redeem_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Đã sao chép mã $code!',
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openCart() {
    AppHaptics.light();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
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
          // 1. Nội dung cuộn dạng Slivers
          RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _loadShopMenu,
            child: _buildScrollBody(theme, cartProvider, authProvider),
          ),

          // 2. Floating Cart Pill nổi ở đáy (LF-02 / Level 3 Elevation)
          if (cartProvider.totalItemsCount > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: LangFoodFloatingCartPill(
                totalItemCount: cartProvider.totalItemsCount,
                totalPrice: cartProvider.totalAmount,
                label: 'Xem giỏ quán',
                onTap: _openCart,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScrollBody(
    LangFoodThemeExtension theme,
    CartProvider cartProvider,
    AuthProvider authProvider,
  ) {
    // A. Trạng thái Loading Skeleton
    if (_isLoading) {
      return _buildLoadingSkeletonView(theme);
    }

    // B. Trạng thái Lỗi kết nối API
    if (_errorMessage != null) {
      return _buildErrorView(theme);
    }

    // C. Trạng thái Quán tạm đóng cửa
    if (_shop != null && !_shop!.isOpen) {
      return _buildClosedView(theme);
    }

    // D. Trạng thái bình thường với đầy đủ các phân mục LF-02
    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // 1. Collapsing Hero AppBar
        _buildSliverAppBar(theme),

        // 2. Restaurant Identity Card
        SliverToBoxAdapter(child: _buildRestaurantIdentityCard(theme)),

        // 3. Thanh tìm kiếm món nếu đang mở chế độ tìm kiếm
        if (_isSearching)
          SliverToBoxAdapter(child: _buildSearchBoxInMenu(theme)),

        // 4. Sticky Category Filter Navigation Bar
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyCategoryHeaderDelegate(
            categories: _categories,
            selectedCategory: _selectedCategory,
            onCategorySelected: _onCategorySelected,
            theme: theme,
          ),
        ),

        // 5. Danh sách món ăn / Empty State nếu lọc không thấy món
        if (_filteredProducts.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: LangFoodEmptyState(
                customIllustration: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.fastfood_outlined,
                      size: 34,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                title: _allProducts.isEmpty
                    ? 'Quán chưa cập nhật thực đơn'
                    : 'Chưa có món trong mục này',
                message: _allProducts.isEmpty
                    ? 'Quán ăn đang chuẩn bị thực đơn cho sinh viên Làng ĐH. Vui lòng quay lại sau nhé!'
                    : 'Quán đang cập nhật thêm món mới cho sinh viên KTX. Hãy thử chọn danh mục khác nhé!',
                buttonText: _allProducts.isEmpty ? 'Tải lại' : 'Xem tất cả món',
                onButtonPressed: () {
                  if (_allProducts.isEmpty) {
                    _loadShopMenu();
                  } else {
                    _onCategorySelected('Tất cả');
                  }
                },
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final product = _filteredProducts[index];
              return ShopProductCard(
                product: product,
                badgeText: index == 0 ? 'Bà Tám Signature' : null,
                imageTag: index == 0 ? 'Đùi bự' : null,
                onTap: () => _openFoodDetail(product),
                onAddToCart: () =>
                    _handleAddToCart(product, cartProvider, authProvider),
              );
            }, childCount: _filteredProducts.length),
          ),

        // 6. Campus Vendor Trust Footer Badge (Stitch LF-02)
        SliverToBoxAdapter(child: _buildTrustFooterBadge(theme)),

        // 7. Đệm an toàn đáy để Floating Cart Pill không che nội dung
        const SliverToBoxAdapter(child: SizedBox(height: 90)),
      ],
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildSliverAppBar(LangFoodThemeExtension theme) {
    final shopName = _shop?.name ?? widget.initialShopName ?? 'Quán ăn KTX';
    final coverUrl = _shop?.imageUrl;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 240,
      elevation: 0,
      scrolledUnderElevation: 2.0,
      backgroundColor: theme.card,
      centerTitle: false,
      titleSpacing: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: PressScaleWidget(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: _isHeaderCollapsed
                  ? theme.surfaceContainerLow
                  : Colors.black.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _isHeaderCollapsed ? theme.textPrimary : Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
      title: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: _isHeaderCollapsed ? 1.0 : 0.0,
        child: Text(
          shopName,
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      actions: [
        // Nút tìm kiếm món trong quán
        IconButton(
          tooltip: 'Tìm trong quán',
          icon: Icon(
            _isSearching ? Icons.close_rounded : Icons.search_rounded,
            color: _isHeaderCollapsed ? theme.textPrimary : Colors.white,
          ),
          onPressed: () {
            AppHaptics.light();
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
                _applyFilter();
              }
            });
          },
        ),
        // Nút chia sẻ
        IconButton(
          tooltip: 'Chia sẻ quán',
          icon: Icon(
            Icons.share_rounded,
            color: _isHeaderCollapsed ? theme.textPrimary : Colors.white,
          ),
          onPressed: () {
            AppHaptics.light();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Đã sao chép liên kết chia sẻ quán cho bạn cùng phòng!',
                ),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
        // Nút yêu thích
        IconButton(
          tooltip: 'Yêu thích',
          icon: Icon(
            _isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: _isFavorite
                ? AppColors.accent
                : (_isHeaderCollapsed ? theme.textPrimary : Colors.white),
          ),
          onPressed: () {
            AppHaptics.selection();
            setState(() {
              _isFavorite = !_isFavorite;
            });
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Ảnh bìa Hero
            if (coverUrl != null && coverUrl.isNotEmpty)
              Image.network(
                coverUrl.startsWith('http')
                    ? coverUrl
                    : '${AppConstants.baseUrl.replaceAll(RegExp(r'/$'), '')}/${coverUrl.replaceAll(RegExp(r'^/'), '')}',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildCoverPlaceholder(),
              )
            else
              _buildCoverPlaceholder(),

            // Gradient che mờ bảo đảm chữ và icon luôn đọc rõ
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),

            // Quick Badges on Cover (Stitch LF-02: Freeship KTX & Thời gian)
            Positioned(
              bottom: 38,
              left: AppTokens.marginMobile,
              right: AppTokens.marginMobile,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.tertiary.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(
                          AppTokens.radiusFull,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_shipping_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Freeship KTX',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(
                          AppTokens.radiusFull,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            size: 13,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Chuẩn bị ~${_shop?.prepTime ?? '15-20 phút'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFBF360C), Color(0xFFE64A19), Color(0xFFFF7043)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -10,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                  child: const Icon(
                    Icons.restaurant_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'LangFood Ký Túc Xá',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantIdentityCard(LangFoodThemeExtension theme) {
    final shop = _shop;
    final isDemoFixture =
        (shop?.id == 1) ||
        (shop?.name == 'Cơm Gà Xối Mỡ Bà Tám') ||
        (widget.initialShopName == 'Cơm Gà Xối Mỡ Bà Tám');

    final shopName =
        shop?.name ?? widget.initialShopName ?? 'Quán ăn Làng Food';
    final desc =
        shop?.description ??
        (isDemoFixture
            ? 'Đùi gà da giòn rụm • Cơm chiên sốt cà chua gia truyền'
            : null);
    final rating = shop?.rating ?? (isDemoFixture ? 4.9 : null);
    final reviewCount = shop?.reviewCount ?? (isDemoFixture ? 1200 : null);
    final hasRating = rating != null;
    final prepTime = shop?.prepTime ?? (isDemoFixture ? '15-20 phút' : null);
    final distance = shop?.distance ?? (isDemoFixture ? '350m từ KTX B' : null);
    final address = shop?.address ?? 'Ký túc xá Khu B, ĐHQG-HCM';
    final isVerified = shop?.isVerified ?? isDemoFixture;
    final voucherCode =
        shop?.voucherCode ?? (isDemoFixture ? 'SINHVIENKHOE' : null);
    final voucherDiscount =
        shop?.voucherDiscount ?? (isDemoFixture ? 'Giảm 15.000₫' : null);
    final voucherDescription =
        shop?.voucherDescription ??
        (isDemoFixture ? 'Tặng kèm canh rong biển & trà tắc từ 2 phần' : null);

    return Transform.translate(
      offset: const Offset(0, -16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppTokens.marginMobile),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.borderSubtle, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Verified Badge Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    shopName,
                    style: AppTypography.headlineSm.copyWith(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                      letterSpacing: -0.3,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isVerified) ...[
                  const SizedBox(width: 8),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.22),
                        width: 0.8,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 11,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Quán quen KTX',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (desc != null && desc.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                desc,
                style: AppTypography.bodySm.copyWith(
                  fontSize: 12,
                  color: theme.textSecondary,
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),

            // Meta bar: Rating, Time, Distance (Bảo vệ chống tràn RenderFlex)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme.borderSubtle, width: 0.6),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    // Rating
                    Row(
                      children: [
                        Icon(
                          hasRating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: hasRating
                              ? AppColors.secondary
                              : theme.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          hasRating ? '$rating' : 'Quán mới',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: theme.textPrimary,
                          ),
                        ),
                        if (hasRating &&
                            reviewCount != null &&
                            reviewCount > 0) ...[
                          const SizedBox(width: 2),
                          Text(
                            '($reviewCount+ đánh giá)',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(width: 10),
                    Text('•', style: TextStyle(color: theme.borderSubtle)),
                    const SizedBox(width: 10),

                    // Time
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: theme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          prepTime ?? '15-20 phút',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (distance != null && distance.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Text('•', style: TextStyle(color: theme.borderSubtle)),
                      const SizedBox(width: 10),

                      // Distance
                      Row(
                        children: [
                          const Icon(
                            Icons.near_me_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            distance,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Campus Location & Open Status
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 15,
                  color: theme.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: theme.textSecondary),
                  ),
                ),
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.tertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Mở cửa',
                      style: TextStyle(
                        color: AppColors.tertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Student Promo Voucher Alert (Stitch LF-02) - Chỉ hiển thị khi có dữ liệu voucher
            if (voucherCode != null && voucherCode.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.redeem_rounded,
                        size: 17,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mã: $voucherCode • ${voucherDiscount ?? 'Giảm 15.000₫'}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (voucherDescription != null &&
                              voucherDescription.isNotEmpty)
                            Text(
                              voucherDescription,
                              style: TextStyle(
                                color: theme.textSecondary,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    PressScaleWidget(
                      onTap: () => _copyPromoCode(voucherCode),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusSm,
                          ),
                        ),
                        child: const Text(
                          'Dùng ngay',
                          style: TextStyle(
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
              const SizedBox(height: 12),
            ],

            // Campus Delivery Notice
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.campaign_rounded,
                    color: AppColors.secondary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.textSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: 'Đặc quyền KTX: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.textPrimary,
                            ),
                          ),
                          const TextSpan(
                            text: 'Tài xế LangFood giao tận sảnh tòa nhà hoặc cửa phòng KTX!',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBoxInMenu(LangFoodThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.marginMobile,
        0,
        AppTokens.marginMobile,
        8,
      ),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(color: theme.borderSubtle, width: 0.8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: theme.textSecondary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (_) => _applyFilter(),
                style: TextStyle(fontSize: 13, color: theme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Tìm món ăn trong quán...',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: theme.textSecondary.withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                  isDense: true,
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
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustFooterBadge(LangFoodThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Quán ăn Đối tác Đảm bảo LangFood',
                style: AppTypography.labelMd.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Đảm bảo vệ sinh an toàn thực phẩm • Hỗ trợ đổi trả nếu món ăn nguội hoặc không đúng đơn.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: theme.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // --- STATE VIEWS ---

  Widget _buildLoadingSkeletonView(LangFoodThemeExtension theme) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Cover Skeleton
        const LangFoodLoadingSkeleton(
          width: double.infinity,
          height: 200,
          borderRadius: 0,
        ),
        const SizedBox(height: 12),
        // Identity Card Skeleton
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LangFoodLoadingSkeleton(
                width: 200,
                height: 20,
                borderRadius: 4,
              ),
              const SizedBox(height: 8),
              const LangFoodLoadingSkeleton(
                width: double.infinity,
                height: 14,
                borderRadius: 4,
              ),
              const SizedBox(height: 16),
              // Category Tabs Skeleton
              Row(
                children: List.generate(
                  4,
                  (index) => const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: LangFoodLoadingSkeleton(
                      width: 72,
                      height: 32,
                      borderRadius: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Dish Cards Skeleton
              ...List.generate(
                3,
                (index) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LangFoodLoadingSkeleton(
                    width: double.infinity,
                    height: 100,
                    borderRadius: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(LangFoodThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AppColors.error,
                size: 38,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Không thể tải Menu quán',
              style: AppTypography.headlineSm.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Sóng WiFi KTX có vẻ đang chập chờn. Bạn kiểm tra lại 4G hoặc kết nối mạng rồi thử lại nhé!',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadShopMenu,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text(
                'Tải lại menu ngay',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClosedView(LangFoodThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: AppColors.secondary,
                size: 38,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTokens.radiusFull),
              ),
              child: const Text(
                'Hiện quán đang tạm nghỉ',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${_shop?.name ?? 'Quán ăn'} mở lại lúc 16:30',
              style: AppTypography.headlineSm.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quán đang chuẩn bị thêm nguyên liệu nóng sốt cho ca tối KTX. Bạn có thể quay lại sau nhé!',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.borderSubtle),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Khám phá quán khác gần KTX',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header dải danh mục dạng Sticky Persistent Header
class _StickyCategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final LangFoodThemeExtension theme;

  _StickyCategoryHeaderDelegate({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.theme,
  });

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.card,
        border: Border(
          bottom: BorderSide(color: theme.borderSubtle, width: 0.6),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.marginMobile,
          vertical: 6,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PressScaleWidget(
              onTap: () => onCategorySelected(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : theme.canvas,
                  borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : theme.borderSubtle,
                    width: isSelected ? 1.0 : 0.6,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.28),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : theme.textPrimary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyCategoryHeaderDelegate oldDelegate) {
    return oldDelegate.selectedCategory != selectedCategory ||
        oldDelegate.categories != categories;
  }
}

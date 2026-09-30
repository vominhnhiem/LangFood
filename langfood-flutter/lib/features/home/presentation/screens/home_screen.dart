import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/widgets/category_chip.dart';
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
import '../../../tracking/presentation/screens/live_tracking_screen.dart';

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
  bool _isLoading = true;
  String? _errorMessage;
  int _currentNavIndex = 0;

  // Banner carousel state
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  final List<Map<String, String>> _promoBanners = [
    {
      'title': 'FREESHIP 0Đ KTX KHU B',
      'subtitle': 'Đơn từ 20K - Giao tận sảnh tòa nhà',
      'color': '0xFFFF5722',
      'icon': 'delivery_dining',
    },
    {
      'title': 'ĐẠI TIỆC TRƯA SINH VIÊN',
      'subtitle': 'Giảm ngay 20% cơm tấm & bún bò',
      'color': '0xFFE64A19',
      'icon': 'local_fire_department',
    },
    {
      'title': 'TRÀ SỮA GIỜ VÀNG 15K',
      'subtitle': 'Topping ngập tràn - Đặt là có',
      'color': '0xFFFF9800',
      'icon': 'local_cafe',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _startBannerAutoScroll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _startBannerAutoScroll() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
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
        }
      } catch (_) {
        // Fallback to mock categories
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
        // Fallback to rich mock products
        prodList = MockData.getProducts();
      }

      if (!mounted) return;
      setState(() {
        _categories = catList;
        _allProducts = prodList;
        _filteredProducts = List.from(prodList);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _allProducts = MockData.getProducts();
        _filteredProducts = List.from(_allProducts);
        _categories = MockData.getCategories();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final matchCategory = _selectedCategoryId == -1 || product.categoryId == _selectedCategoryId;
        final matchQuery = query.isEmpty ||
            product.name.toLowerCase().contains(query) ||
            product.shopName.toLowerCase().contains(query) ||
            (product.description?.toLowerCase().contains(query) ?? false);
        return matchCategory && matchQuery;
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

  void _openFoodDetail(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FoodDetailScreen(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // shopee_bg matching Android
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header with Location, Cart Icon, Avatar, and Search Bar (matching activity_home.xml)
            _buildAppBarHeader(cartProvider, authProvider),

            // 2. Main Scrollable Body with Pull-to-Refresh
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _loadInitialData,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      )
                    : _errorMessage != null
                        ? ErrorStateView(
                            message: _errorMessage!,
                            onRetry: _loadInitialData,
                          )
                        : CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              // Promo Banner Slider (cv_promo_banner)
                              SliverToBoxAdapter(
                                child: _buildPromoBannerSlider(),
                              ),

                              // Categories Horizontal List (rv_categories)
                              SliverToBoxAdapter(
                                child: _buildCategoriesSection(),
                              ),

                              // "GỢI Ý HÔM NAY" Header (matching activity_home.xml)
                              SliverToBoxAdapter(
                                child: Container(
                                  margin: const EdgeInsets.only(top: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  color: Colors.white,
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
                                      const Text(
                                        'GỢI Ý HÔM NAY',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF212121),
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Product Grid (rv_recommend)
                              if (_filteredProducts.isEmpty)
                                SliverToBoxAdapter(
                                  child: EmptyStateView(
                                    icon: Icons.search_off_rounded,
                                    title: 'Không tìm thấy món ăn',
                                    message: 'Thử tìm từ khóa khác hoặc chuyển sang danh mục khác xem sao nhé!',
                                    actionText: 'Xem tất cả món',
                                    onAction: () {
                                      _searchController.clear();
                                      _onCategorySelected(-1);
                                    },
                                  ),
                                )
                              else
                                SliverPadding(
                                  padding: const EdgeInsets.all(10),
                                  sliver: SliverGrid(
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.74,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                    ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final product = _filteredProducts[index];
                                        return FoodCardItem(
                                          product: product,
                                          onTap: () => _openFoodDetail(product),
                                          onAddToCart: () {
                                            cartProvider.addToCart(
                                              product: product,
                                              quantity: 1,
                                              userId: authProvider.user?.id,
                                            );
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Đã thêm "${product.name}" vào giỏ!'),
                                                backgroundColor: AppColors.primary,
                                                duration: const Duration(seconds: 2),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          },
                                        );
                                      },
                                      childCount: _filteredProducts.length,
                                    ),
                                  ),
                                ),

                              const SliverToBoxAdapter(
                                child: SizedBox(height: 20),
                              ),
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),

      // 3. Bottom Navigation Bar matching bnv_main in Android XML
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildAppBarHeader(CartProvider cartProvider, AuthProvider authProvider) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          // Top Row: Location & Cart Badge & Profile
          Row(
            children: [
              // Location info
              const Icon(
                Icons.my_location_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Giao tới: KTX Khu B, Thủ Đức',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Cart Button with Badge
              GestureDetector(
                onTap: _openCart,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        color: Color(0xFF424242),
                        size: 26,
                      ),
                    ),
                    if (cartProvider.totalItemsCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '${cartProvider.totalItemsCount}',
                            textAlign: TextAlign.center,
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
              const SizedBox(width: 12),

              // Profile Avatar
              GestureDetector(
                onTap: () => _showUserMenu(authProvider),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryLight.withOpacity(0.4),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Center(
                    child: Text(
                      authProvider.user?.fullName?.isNotEmpty == true
                          ? authProvider.user!.fullName![0].toUpperCase()
                          : (authProvider.user?.username.isNotEmpty == true
                              ? authProvider.user!.username[0].toUpperCase()
                              : 'U'),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Search Bar matching cv_search in activity_home.xml
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(
                  Icons.search,
                  color: Color(0xFF888888),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _applyFilter(),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Săn deal Khu B, Freeship 0đ...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
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
                    child: const Icon(
                      Icons.cancel,
                      color: Color(0xFF888888),
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBannerSlider() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      height: 130,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5722), Color(0xFFFF8A65)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'HOT DEAL KTX',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            banner['title']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            banner['subtitle']!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lunch_dining_rounded,
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
                return Container(
                  width: _currentBannerIndex == idx ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: _currentBannerIndex == idx ? Colors.white : Colors.white.withOpacity(0.4),
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

  Widget _buildCategoriesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 6, bottom: 10),
            child: Text(
              'Danh mục món ăn',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
          ),
          SizedBox(
            height: 96,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return CategoryChip(
                  category: category,
                  isSelected: _selectedCategoryId == category.id,
                  onTap: () => _onCategorySelected(category.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildNavItem(0, Icons.storefront_rounded, 'Trang chủ'),
          _buildNavItem(1, Icons.receipt_long_rounded, 'Đơn hàng'),
          _buildNavItem(2, Icons.notifications_none_rounded, 'Thông báo'),
          _buildNavItem(3, Icons.person_outline_rounded, 'Tôi'),
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
          } else if (index == 3) {
            _showUserMenu(Provider.of<AuthProvider>(context, listen: false));
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : const Color(0xFF757575),
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : const Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
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
                    authProvider.user?.fullName ?? authProvider.user?.username ?? 'Tài khoản',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Vai trò: ${authProvider.user?.roleName ?? 'Khách hàng'}'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.shopping_cart_outlined, color: AppColors.primary),
                  title: const Text('Xem giỏ hàng'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _openCart();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.map_outlined, color: Colors.orange),
                  title: const Text('Bản đồ & Live Tracking (Shipper/Khách)'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RoleChooserScreen()),
                    );
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
}

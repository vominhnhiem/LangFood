import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/models/product_option_model.dart';
import '../../../../data/services/product_service.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/cart_provider.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../food_detail/presentation/widgets/food_customization_medium_sheet.dart';
import '../../../food_detail/presentation/widgets/food_customization_expanded_sheet.dart';

enum RestaurantViewState {
  normal,
  skeleton,
  closed,
}

class RestaurantMenuScreen extends StatefulWidget {
  final int shopId;
  final String shopName;

  const RestaurantMenuScreen({
    super.key,
    this.shopId = 10,
    this.shopName = 'Cơm Gà Xối Mỡ Bà Tám',
  });

  @override
  State<RestaurantMenuScreen> createState() => _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends State<RestaurantMenuScreen> with SingleTickerProviderStateMixin {
  RestaurantViewState _viewState = RestaurantViewState.normal;
  bool _isFavorite = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  int _selectedCategoryIndex = 0;
  final ScrollController _scrollController = ScrollController();

  late AnimationController _shimmerController;

  // Categories for Ba Tam Chicken Rice
  final List<String> _categories = [
    'Bán chạy nhất 🔥',
    'Cơm gà xối mỡ 🍗',
    'Topping no bụng 🍚',
    'Giải khát sinh viên 🥤',
  ];

  // Full dishes list for Ba Tam
  List<ProductModel> _allDishes = [
    // Bán chạy nhất & Cơm gà
    ProductModel(
      id: 201,
      name: 'Cơm Gà Xối Mỡ Da Giòn (Đùi Góc Tư)',
      description: 'Đùi gà góc tư chiên xối mỡ nóng hổi vàng ươm giòn rụm, cơm chiên cà chua thơm lừng hạt ngọc tơi xốp, ăn kèm dưa leo, cà chua và sốt tương gừng bí truyền.',
      price: 35000,
      imageUrl: 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=600',
      shopId: 10,
      shopName: 'Cơm Gà Xối Mỡ Bà Tám',
      categoryId: 1,
      categoryName: 'Cơm gà xối mỡ 🍗',
      isAvailable: true,
      isShopOpen: true,
      optionGroups: [
        ProductOptionGroupModel(
          id: 1,
          name: 'Chọn thêm món no bụng',
          isMultiple: true,
          options: [
            ProductOptionModel(id: 11, name: 'Trứng ốp la lòng đào', price: 5000),
            ProductOptionModel(id: 12, name: 'Canh rong biển thịt bằm', price: 8000),
            ProductOptionModel(id: 13, name: 'Cơm xối mỡ thêm 1 chén', price: 5000),
            ProductOptionModel(id: 14, name: 'Tặng kèm trà tắc giải ngấy (0đ)', price: 0, isSelected: true),
          ],
        ),
        ProductOptionGroupModel(
          id: 2,
          name: 'Độ giòn da & Sốt đùi gà',
          isMultiple: false,
          options: [
            ProductOptionModel(id: 21, name: 'Da giòn xối mỡ truyền thống (chuẩn)', price: 0, isSelected: true),
            ProductOptionModel(id: 22, name: 'Lắc sốt mắm tỏi mật ong thơm lừng', price: 3000),
            ProductOptionModel(id: 23, name: 'Sốt cay Hàn Quốc đậm đà', price: 3000),
          ],
        ),
        ProductOptionGroupModel(
          id: 3,
          name: 'Gia vị nước chấm',
          isMultiple: false,
          options: [
            ProductOptionModel(id: 31, name: 'Nước tương tỏi ớt gừng gia truyền (chuẩn)', price: 0, isSelected: true),
            ProductOptionModel(id: 32, name: 'Nước mắm chua ngọt cay nhiều', price: 0),
            ProductOptionModel(id: 33, name: 'Tương ớt xí muội ngọt dịu', price: 0),
          ],
        ),
      ],
    ),
    ProductModel(
      id: 202,
      name: 'Cơm Gà Xối Mỡ Sốt Cay Hàn Quốc',
      description: 'Đùi gà xối mỡ sốt cay ngọt Gochujang rắc mè trắng rang thơm béo, cay nồng đậm vị rất bắt cơm sinh viên.',
      price: 38000,
      imageUrl: 'https://images.unsplash.com/photo-1562967914-608f82629710?w=600',
      shopId: 10,
      shopName: 'Cơm Gà Xối Mỡ Bà Tám',
      categoryId: 1,
      categoryName: 'Cơm gà xối mỡ 🍗',
      isAvailable: true,
      isShopOpen: true,
      optionGroups: [
        ProductOptionGroupModel(
          id: 4,
          name: 'Thêm topping',
          isMultiple: true,
          options: [
            ProductOptionModel(id: 41, name: 'Thêm trứng ốp la lòng đào', price: 5000),
            ProductOptionModel(id: 42, name: 'Kim chi chua cay ăn kèm', price: 6000),
          ],
        ),
      ],
    ),
    ProductModel(
      id: 203,
      name: 'Cơm Gà Luộc Chặt Lá Chanh',
      description: 'Gà ta thả vườn thịt chắc ngọt da vàng giòn, luộc ráo nước thơm phức hương lá chanh Bắc, ăn kèm muối tiêu chanh ớt.',
      price: 35000,
      imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600',
      shopId: 10,
      shopName: 'Cơm Gà Xối Mỡ Bà Tám',
      categoryId: 1,
      categoryName: 'Cơm gà xối mỡ 🍗',
      isAvailable: true,
      isShopOpen: true,
    ),
    ProductModel(
      id: 204,
      name: 'Cơm Gà Xối Mỡ Cánh Gà Mắm Tỏi',
      description: '2 cánh gà chiên giòn rụm tẩm sốt nước mắm nhỉ pha tỏi ớt kẹo ngọt thơm lừng, món khoái khẩu giờ tan học.',
      price: 32000,
      imageUrl: 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=600',
      shopId: 10,
      shopName: 'Cơm Gà Xối Mỡ Bà Tám',
      categoryId: 1,
      categoryName: 'Cơm gà xối mỡ 🍗',
      isAvailable: true,
      isShopOpen: true,
    ),
    ProductModel(
      id: 205,
      name: 'Cơm Gà Xối Mỡ Xé Phay Hành Tây',
      description: 'Thịt gà xối mỡ xé phay trộn gỏi bắp cải, hành tây tím ngâm giấm đường chua ngọt và rau răm cay nồng.',
      price: 32000,
      imageUrl: 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=600',
      shopId: 10,
      shopName: 'Cơm Gà Xối Mỡ Bà Tám',
      categoryId: 1,
      categoryName: 'Cơm gà xối mỡ 🍗',
      isAvailable: true,
      isShopOpen: true,
    ),

    // Topping no bụng 🍚
    ProductModel(
      id: 211,
      name: 'Trứng ốp la lòng đào',
      description: 'Trứng gà tươi chiên lòng đào viền giòn tan, béo ngậy khi dằm vào cơm chiên nóng.',
      price: 5000,
      imageUrl: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=300',
      shopId: 10,
      shopName: 'Cơm Gà Xối Mỡ Bà Tám',
      categoryId: 2,
      categoryName: 'Topping no bụng 🍚',
      isAvailable: true,
      isShopOpen: true,
    ),
    ProductModel(
      id: 212,
      name: 'Cơm xối mỡ thêm 1 chén',
      description: 'Cơm chiên hạt ngọc sốt cà chua thơm dẻo, phủ mỡ hành và tóp mỡ giòn.',
      price: 5000,
      imageUrl: 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=300',
      shopId: 10,
      shopName: 'Cơm Gà Xối Mỡ Bà Tám',
      categoryId: 2,
      categoryName: 'Topping no bụng 🍚',
      isAvailable: true,
      isShopOpen: true,
    ),
    ProductModel(
      id: 213,
      name: 'Canh rong biển thịt bằm',
      description: 'Rong biển khô nấu cùng thịt heo nạc bằm ngọt nước, rắc tiêu sọ và hành hoa.',
      price: 8000,
      imageUrl: 'https://images.unsplash.com/photo-1547592180-85f173990554?w=300',
      shopId: 10,
      shopName: 'Cơm Gà Xối Mỡ Bà Tám',
      categoryId: 2,
      categoryName: 'Topping no bụng 🍚',
      isAvailable: true,
      isShopOpen: true,
    ),
    ProductModel(
      id: 214,
      name: 'Kim chi chua cay giòn',
      description: 'Kim chi cải thảo chuẩn vị Hàn Quốc cay nồng chua dịu giải ngấy cực đỉnh.',
      price: 6000,
      imageUrl: 'https://images.unsplash.com/photo-1583032015879-661f2f81498b?w=300',
      shopId: 10,
      shopName: 'Cơm Gà Xối Mỡ Bà Tám',
      categoryId: 2,
      categoryName: 'Topping no bụng 🍚',
      isAvailable: true,
      isShopOpen: true,
    ),

    // Giải khát sinh viên 🥤
    ProductModel(
      id: 221,
      name: 'Trà tắc khổng lồ 700ml',
      description: 'Ly size lớn 700ml trà lài thơm nức vắt nước cốt tắc tươi mật ong, xua tan oi bức Làng ĐH.',
      price: 10000,
      imageUrl: 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=300',
      shopId: 10,
      shopName: 'Cơm Gà Xối Mỡ Bà Tám',
      categoryId: 3,
      categoryName: 'Giải khát sinh viên 🥤',
      isAvailable: true,
      isShopOpen: true,
    ),
    ProductModel(
      id: 222,
      name: 'Trà sữa Thái xanh thạch phô mai',
      description: 'Trà Thái xanh béo ngậy mát lạnh thơm nức cùng thạch phô mai dẻo giòn.',
      price: 15000,
      imageUrl: 'https://images.unsplash.com/photo-1558857563-b37cfb62a4d4?w=300',
      shopId: 10,
      shopName: 'Cơm Gà Xối Mỡ Bà Tám',
      categoryId: 3,
      categoryName: 'Giải khát sinh viên 🥤',
      isAvailable: true,
      isShopOpen: true,
    ),
    ProductModel(
      id: 223,
      name: 'Nước sấu ngâm Hà Nội hạt giòn',
      description: 'Nước sấu chua ngọt thanh mát thơm vị gừng tươi cùng 3 quả sấu giòn sần sật.',
      price: 12000,
      imageUrl: 'https://images.unsplash.com/photo-1556881286-fc6915169721?w=300',
      shopId: 10,
      shopName: 'Cơm Gà Xối Mỡ Bà Tám',
      categoryId: 3,
      categoryName: 'Giải khát sinh viên 🥤',
      isAvailable: true,
      isShopOpen: true,
    ),
  ];

  final ProductService _productService = ProductService();

  @override
  void initState() {
    super.initState();
    _loadRealDishes();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  Future<void> _loadRealDishes() async {
    try {
      final list = await _productService.getProductsByShop(widget.shopId);
      if (list.isNotEmpty && mounted) {
        setState(() {
          _allDishes = list;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  String _formatCurrency(num amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return formatter.format(amount).replaceAll(' ', '');
  }

  List<ProductModel> _getFilteredDishes() {
    if (_searchQuery.trim().isEmpty) {
      if (_selectedCategoryIndex == 0) {
        // Bán chạy nhất: return top 3 dishes
        return _allDishes.take(3).toList();
      } else if (_selectedCategoryIndex == 1) {
        // Cơm gà xối mỡ
        return _allDishes.where((p) => p.categoryId == 1).toList();
      } else if (_selectedCategoryIndex == 2) {
        // Topping no bụng
        return _allDishes.where((p) => p.categoryId == 2).toList();
      } else {
        // Giải khát sinh viên
        return _allDishes.where((p) => p.categoryId == 3).toList();
      }
    } else {
      final q = _searchQuery.toLowerCase().trim();
      return _allDishes.where((p) {
        return p.name.toLowerCase().contains(q) ||
            (p.description?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
  }

  // ================= OPEN LF-03 (MEDIUM SHEET TÙY BIẾN MÓN) =================
  void _openMediumCustomizationSheet(ProductModel product) {
    showFoodCustomizationMediumSheet(
      context: context,
      product: product,
      onAddedToCart: () {
        setState(() {});
      },
    );
  }

  void _shareShopLink() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.link_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Đã sao chép link: langfood.vn/shop/com-ga-ba-tam'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: Colors.red,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(_isFavorite ? 'Đã lưu vào "Quán quen KTX" ❤️' : 'Đã bỏ lưu quán'),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top State Inspector Bar
            _buildStateInspectorBar(),

            // 2. Body View according to state
            Expanded(
              child: _buildCurrentStateBody(cartProvider),
            ),
          ],
        ),
      ),
      // 3. Floating Bottom Cart Bar (LF-04 Link)
      bottomNavigationBar: _viewState == RestaurantViewState.normal
          ? _buildFloatingBottomCartBar(cartProvider)
          : null,
    );
  }

  // ================= 1. STATE INSPECTOR BAR =================
  Widget _buildStateInspectorBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
      ),
      child: Row(
        children: [
          const Icon(Icons.tune_rounded, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          const Text(
            'LF-02 State:',
            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStateChip(
                    state: RestaurantViewState.normal,
                    label: 'Menu Chính',
                    icon: Icons.restaurant_menu_rounded,
                    activeColor: const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 6),
                  _buildStateChip(
                    state: RestaurantViewState.skeleton,
                    label: 'Đang tải (Skeleton)',
                    icon: Icons.hourglass_top_rounded,
                    activeColor: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 6),
                  _buildStateChip(
                    state: RestaurantViewState.closed,
                    label: 'Tạm đóng cửa',
                    icon: Icons.lock_clock_rounded,
                    activeColor: const Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 8),
                  // Direct trigger for LF-03 Medium Sheet
                  InkWell(
                    onTap: () {
                      final sampleProduct = _allDishes.isNotEmpty ? _allDishes.first : null;
                      showFoodCustomizationMediumSheet(
                        context: context,
                        product: sampleProduct,
                        onAddedToCart: () {
                          setState(() {});
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5722), Color(0xFFFF8A65)],
                        ),
                        borderRadius: BorderRadius.circular(14),
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
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Direct trigger for LF-04 Expanded Sheet (90%)
                  InkWell(
                    onTap: () {
                      final sampleProduct = _allDishes.isNotEmpty ? _allDishes.first : null;
                      showFoodCustomizationExpandedSheet(
                        context: context,
                        product: sampleProduct,
                        onAddedToCart: () {
                          setState(() {});
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE11D48), Color(0xFFF43F5E)],
                        ),
                        borderRadius: BorderRadius.circular(14),
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
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
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
    required RestaurantViewState state,
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
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white24,
            width: isSelected ? 1.2 : 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isSelected ? Colors.white : Colors.white70),
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

  Widget _buildCurrentStateBody(CartProvider cartProvider) {
    switch (_viewState) {
      case RestaurantViewState.skeleton:
        return _buildSkeletonView();
      case RestaurantViewState.closed:
        return _buildClosedView();
      case RestaurantViewState.normal:
      default:
        return _buildNormalMenuView(cartProvider);
    }
  }

  // ================= 2. NORMAL MENU VIEW: SLIVER ARCHITECTURE =================
  Widget _buildNormalMenuView(CartProvider cartProvider) {
    final dishes = _getFilteredDishes();

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Sliver Header with Frosted Glass Liquid Buttons
        _buildSliverHeader(),

        // Restaurant Info & Badges & Promo Banner Card
        SliverToBoxAdapter(
          child: _buildShopInfoCard(),
        ),

        // Sticky Category Filter Tabs
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyCategoryHeaderDelegate(
            categories: _categories,
            selectedIndex: _selectedCategoryIndex,
            onCategorySelected: (idx) {
              setState(() {
                _selectedCategoryIndex = idx;
                _searchQuery = '';
                _searchController.clear();
              });
            },
          ),
        ),

        // In-shop Search Bar (when searching is enabled)
        if (_isSearching)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      autofocus: true,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Tìm món trong quán Cơm Gà Bà Tám...',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSearching = false;
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                    child: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

        // Section Title
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Kết quả tìm kiếm cho "$_searchQuery"'
                      : _categories[_selectedCategoryIndex],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${dishes.length} món',
                    style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Dish List
        if (dishes.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text('Không tìm thấy món phù hợp trong quán', style: TextStyle(color: Colors.grey)),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = dishes[index];
                return _buildDishItemCard(product);
              },
              childCount: dishes.length,
            ),
          ),

        // Bottom space so floating bar doesn't obstruct content
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  // ================= SLIVER APP BAR & FROSTED GLASS BUTTONS =================
  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 230,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildFrostedGlassButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
        ),
      ),
      actions: [
        _buildFrostedGlassButton(
          icon: Icons.search_rounded,
          onTap: () {
            setState(() {
              _isSearching = !_isSearching;
            });
          },
        ),
        const SizedBox(width: 8),
        _buildFrostedGlassButton(
          icon: Icons.share_rounded,
          onTap: _shareShopLink,
        ),
        const SizedBox(width: 8),
        _buildFrostedGlassButton(
          icon: _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          iconColor: _isFavorite ? Colors.red : Colors.white,
          onTap: _toggleFavorite,
        ),
        const SizedBox(width: 14),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover Image: Crispy Golden Chicken Rice
            Image.network(
              'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=1200',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.deepOrange.shade400,
                child: const Icon(Icons.restaurant, size: 64, color: Colors.white),
              ),
            ),
            // Gradient Overlay for readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.55),
                    Colors.transparent,
                    Colors.black.withOpacity(0.65),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Bottom Cover Floating Title
            Positioned(
              left: 16,
              bottom: 16,
              right: 16,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt_outlined, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Ảnh thật từ quán tại KTX',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
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

  Widget _buildFrostedGlassButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(icon, color: iconColor, size: 19),
            onPressed: onTap,
          ),
        ),
      ),
    );
  }

  // ================= SHOP INFO & BADGES & PROMO BANNER CARD =================
  Widget _buildShopInfoCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shop Name & Verified Icon
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.shopName,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const Icon(Icons.verified_rounded, color: Colors.blue, size: 20),
            ],
          ),
          const SizedBox(height: 8),

          // Badges: "Quán quen KTX" & "Freeship KTX"
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium_rounded, color: Color(0xFFB45309), size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Quán quen KTX',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.two_wheeler_rounded, color: Color(0xFF15803D), size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Freeship KTX',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Metadata: Rating ⭐ 4.9 (1.2k+), Time 15-20 min, Distance 350m
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 3),
              const Text(
                '4.9',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const Text(
                ' (1.2k+ đánh giá) • ',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const Icon(Icons.schedule_rounded, color: Colors.green, size: 15),
              const SizedBox(width: 3),
              const Text(
                '15-20 phút • ',
                style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
              ),
              const Text(
                '350m từ KTX B',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Real-time status: 🟢 Mở cửa (09:00 - 21:30)
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Đang mở cửa',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
              ),
              const Text(
                ' • Giờ bán: 09:00 - 21:30 (Cả trưa & tối)',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Exclusive Promo Banner: SINHVIENKHOE
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDBA74)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_offer_rounded, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Mã SINHVIENKHOE',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9A3412),
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            '• Tặng canh rong biển',
                            style: TextStyle(fontSize: 11, color: Color(0xFFC2410C)),
                          ),
                        ],
                      ),
                      Text(
                        'Đặc quyền Freeship tận sảnh/cửa phòng KTX Khu A & B',
                        style: TextStyle(fontSize: 11, color: Color(0xFF9A3412)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary, width: 0.8),
                  ),
                  child: const Text(
                    'ĐÃ ÁP DỤNG',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= DISH ITEM CARD WITH "TÙY CHỌN +" BUTTON =================
  Widget _buildDishItemCard(ProductModel product) {
    final bool isBestSeller = product.id == 201;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openMediumCustomizationSheet(product),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dish Image
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      product.imageUrl ?? 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=300',
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 90,
                        height: 90,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.fastfood, color: Colors.grey),
                      ),
                    ),
                  ),
                  if (isBestSeller)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '-22%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Dish Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (product.description != null)
                      Text(
                        product.description!,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),

                    // Price & "Tùy chọn +" Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              _formatCurrency(product.price),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            if (isBestSeller) ...[
                              const SizedBox(width: 6),
                              Text(
                                _formatCurrency(45000),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ],
                        ),

                        // Action Button: "Tùy chọn +"
                        GestureDetector(
                          onTap: () => _openMediumCustomizationSheet(product),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Tùy chọn',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 3),
                                Icon(Icons.add, size: 14, color: Colors.white),
                              ],
                            ),
                          ),
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
    );
  }

  // ================= 3. FLOATING BOTTOM CART BAR (LF-04 LINK) =================
  Widget _buildFloatingBottomCartBar(CartProvider cartProvider) {
    final int itemsCount = cartProvider.totalItemsCount > 0 ? cartProvider.totalItemsCount : 3;
    final double rawAmount = cartProvider.totalAmount > 0 ? cartProvider.totalAmount : 115000;
    // Apply 15k student voucher
    final double discountedAmount = (rawAmount - 15000).clamp(0, double.infinity);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Cart Icon with Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                ),
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$itemsCount',
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
            const SizedBox(width: 12),

            // Price & Voucher info
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _formatCurrency(discountedAmount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatCurrency(rawAmount),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 11,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Đã trừ 15k voucher SINHVIENKHOE',
                    style: TextStyle(color: Color(0xFF34D399), fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // Button "Xem giỏ →"
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Xem giỏ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= 4. SKELETON LOADING VIEW =================
  Widget _buildSkeletonView() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShimmerBox(width: double.infinity, height: 220),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerBox(width: 240, height: 24),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildShimmerBox(width: 100, height: 20),
                        const SizedBox(width: 8),
                        _buildShimmerBox(width: 90, height: 20),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildShimmerBox(width: double.infinity, height: 48, borderRadius: 12),
                    const SizedBox(height: 20),
                    Row(
                      children: List.generate(4, (_) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildShimmerBox(width: 80, height: 32, borderRadius: 16),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    ...List.generate(3, (_) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            _buildShimmerBox(width: 84, height: 84, borderRadius: 12),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildShimmerBox(width: 160, height: 16),
                                  const SizedBox(height: 8),
                                  _buildShimmerBox(width: 200, height: 12),
                                  const SizedBox(height: 10),
                                  _buildShimmerBox(width: 80, height: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
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
  }) {
    final shimmerValue = _shimmerController.value;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
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

  // ================= 5. CLOSED VIEW (TẠM ĐÓNG CỬA) =================
  Widget _buildClosedView() {
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
              child: const Icon(Icons.lock_clock_rounded, size: 48, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 18),
            const Text(
              'Quán Cơm Gà Bà Tám hiện tạm nghỉ',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Quán đã phục vụ hết số lượng gà xối mỡ đợt trưa hoặc nằm ngoài khung giờ nhận đơn (09:00 - 21:30). Hẹn gặp lại bạn vào ca tối lúc 16:30 nhé!',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                setState(() {
                  _viewState = RestaurantViewState.normal;
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Xem lại thực đơn quán'),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= STICKY PERSISTENT HEADER DELEGATE =================
class _StickyCategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onCategorySelected;

  _StickyCategoryHeaderDelegate({
    required this.categories,
    required this.selectedIndex,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: categories.length,
        itemBuilder: (context, idx) {
          final isSelected = selectedIndex == idx;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => onCategorySelected(idx),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  categories[idx],
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF334155),
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
  double get maxExtent => 50;

  @override
  double get minExtent => 50;

  @override
  bool shouldRebuild(covariant _StickyCategoryHeaderDelegate oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex;
  }
}

// ================= MEDIUM SHEET LF-03: TÙY BIẾN MÓN SINH VIÊN =================
class _FoodCustomizationMediumSheet extends StatefulWidget {
  final ProductModel product;
  final VoidCallback onAddToCartSuccess;

  const _FoodCustomizationMediumSheet({
    required this.product,
    required this.onAddToCartSuccess,
  });

  @override
  State<_FoodCustomizationMediumSheet> createState() => _FoodCustomizationMediumSheetState();
}

class _FoodCustomizationMediumSheetState extends State<_FoodCustomizationMediumSheet> {
  final TextEditingController _noteController = TextEditingController();
  int _quantity = 1;
  late List<ProductOptionGroupModel> _optionGroups;

  @override
  void initState() {
    super.initState();
    // Deep clone option groups
    _optionGroups = widget.product.optionGroups.map((g) {
      return ProductOptionGroupModel(
        id: g.id,
        productId: g.productId,
        name: g.name,
        isMultiple: g.isMultiple,
        options: g.options.map((opt) {
          return ProductOptionModel(
            id: opt.id,
            groupId: opt.groupId,
            name: opt.name,
            price: opt.price,
            isSelected: opt.isSelected,
          );
        }).toList(),
      );
    }).toList();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  double _calculateTotalPerItem() {
    double total = widget.product.price;
    for (var g in _optionGroups) {
      for (var opt in g.options) {
        if (opt.isSelected) {
          total += opt.price;
        }
      }
    }
    return total;
  }

  double _calculateTotalPrice() {
    return _calculateTotalPerItem() * _quantity;
  }

  String _formatCurrency(num amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return formatter.format(amount).replaceAll(' ', '');
  }

  void _handleAddToCart() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final List<String> selectedNames = [];
    for (var g in _optionGroups) {
      for (var opt in g.options) {
        if (opt.isSelected) {
          selectedNames.add(opt.name);
        }
      }
    }

    String? optionsJson;
    if (selectedNames.isNotEmpty) {
      optionsJson = selectedNames.join(', ');
    }

    final itemPriceWithCustomization = _calculateTotalPerItem();
    final prod = widget.product.copyWith(price: itemPriceWithCustomization);

    cartProvider.addToCart(
      product: prod,
      quantity: _quantity,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      selectedOptionsJson: optionsJson,
      unitPrice: itemPriceWithCustomization,
      userId: authProvider.user?.id,
    );

    widget.onAddToCartSuccess();
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm $_quantity x "${widget.product.name}" vào giỏ hàng!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Xem giỏ',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _calculateTotalPrice();

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header with Dish Thumbnail, Name, Base Price & Close Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.product.imageUrl ?? 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=200',
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 64, height: 64, color: Colors.grey.shade200),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(widget.product.price),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Options List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: [
                if (_optionGroups.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        widget.product.description ?? 'Món ngon chuẩn vị KTX',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ..._optionGroups.map((group) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                group.name,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: group.isMultiple ? const Color(0xFFEFF6FF) : const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  group.isMultiple ? 'Chọn nhiều' : 'Chọn 1',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: group.isMultiple ? Colors.blue : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ...group.options.map((opt) {
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  if (group.isMultiple) {
                                    opt.isSelected = !opt.isSelected;
                                  } else {
                                    for (var o in group.options) {
                                      o.isSelected = false;
                                    }
                                    opt.isSelected = true;
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Icon(
                                      group.isMultiple
                                          ? (opt.isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded)
                                          : (opt.isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded),
                                      color: opt.isSelected ? AppColors.primary : Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        opt.name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: opt.isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: opt.isSelected ? const Color(0xFF0F172A) : const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                    if (opt.price > 0)
                                      Text(
                                        '+${_formatCurrency(opt.price)}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }),

                // Student Note Input
                const Text(
                  'Ghi chú cho quán (nếu có):',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _noteController,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Ví dụ: Cho em nhiều mỡ hành, không lấy đồ chua...',
                      hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Bottom Bar: Quantity & Total & Add to Cart Button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Quantity Stepper [- 1 +]
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 16),
                        onPressed: () {
                          if (_quantity > 1) {
                            setState(() {
                              _quantity--;
                            });
                          }
                        },
                      ),
                      Text(
                        '$_quantity',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 16),
                        onPressed: () {
                          setState(() {
                            _quantity++;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Add to Cart Button
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _handleAddToCart,
                    child: Text(
                      'Thêm vào giỏ • ${_formatCurrency(total)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/product_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/cart_provider.dart';
import '../../../cart/presentation/screens/cart_screen.dart';

enum LF03SheetState {
  normal,
  skeleton,
  outOfStock,
  error,
}

/// Helper function to open LF-03 Medium Sheet with Apple HIG physics
Future<void> showFoodCustomizationMediumSheet({
  required BuildContext context,
  ProductModel? product,
  VoidCallback? onAddedToCart,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.40),
    builder: (ctx) {
      return FoodCustomizationMediumSheet(
        product: product,
        onAddedToCart: onAddedToCart,
      );
    },
  );
}

class FoodCustomizationMediumSheet extends StatefulWidget {
  final ProductModel? product;
  final VoidCallback? onAddedToCart;
  final bool isStandalonePage;

  const FoodCustomizationMediumSheet({
    super.key,
    this.product,
    this.onAddedToCart,
    this.isStandalonePage = false,
  });

  @override
  State<FoodCustomizationMediumSheet> createState() => _FoodCustomizationMediumSheetState();
}

class _FoodCustomizationMediumSheetState extends State<FoodCustomizationMediumSheet>
    with SingleTickerProviderStateMixin {
  // Inspector states
  bool _isDarkMode = false;
  LF03SheetState _sheetState = LF03SheetState.normal;
  bool _showHigOverlay = false;

  // Customization state
  int _selectedSizeIndex = 1; // 0: Nhỏ (+0), 1: Tiêu Chuẩn (+10k - default), 2: Khổng Lồ (+25k)
  final Set<int> _selectedToppingIndices = {0, 1}; // Default includes Trứng ốp la & Canh rong biển
  int _quantity = 1;
  final TextEditingController _noteController = TextEditingController();

  // Animation for spring physics
  late AnimationController _springController;
  late Animation<double> _slideAnimation;

  // Sizes definition
  final List<Map<String, dynamic>> _sizes = [
    {
      'name': 'Nhỏ',
      'price': 0,
      'badge': 'Ăn nhẹ',
      'description': 'Đùi góc tư vừa vặn, 1 chén cơm xối mỡ thơm',
    },
    {
      'name': 'Tiêu Chuẩn',
      'price': 10000,
      'badge': 'Khuyên dùng 🔥',
      'description': 'Đùi gà góc tư to đẫy đà, 1.5 chén cơm chiên cà chua',
    },
    {
      'name': 'Khổng Lồ',
      'price': 25000,
      'badge': 'No căng thi cử',
      'description': 'Đùi góc tư x2 cơm xối mỡ, kèm đĩa đồ chua & dưa leo',
    },
  ];

  // Toppings definition
  final List<Map<String, dynamic>> _toppings = [
    {
      'name': 'Trứng ốp la lòng đào',
      'price': 5000,
      'description': 'Trứng gà ta viền giòn lòng đào béo ngậy',
    },
    {
      'name': 'Canh rong biển thịt bằm',
      'price': 8000,
      'description': 'Nước hầm xương thịt bằm ngọt thanh giải ngấy',
    },
    {
      'name': 'Sốt chua ngọt mật ong',
      'price': 3000,
      'description': 'Sốt mắm tỏi mật ong bí truyền quết da gà',
    },
    {
      'name': 'Cơm xối mỡ thêm 1 chén',
      'price': 5000,
      'description': 'Cơm chiên hạt ngọc sốt cà phủ mỡ hành tóp mỡ',
    },
    {
      'name': 'Kim chi chua cay giòn',
      'price': 6000,
      'description': 'Kim chi cải thảo giòn rụm cay nồng',
    },
  ];

  // Quick note chips
  final List<String> _quickNoteChips = [
    'Ít cay',
    'Cơm mềm',
    'Nhiều dưa leo',
    'Để riêng canh',
    'Nhiều mỡ hành',
  ];

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    // Cubic(0.32, 0.72, 0, 1) - Apple HIG Spring / Fluid curve
    _slideAnimation = CurvedAnimation(
      parent: _springController,
      curve: const Cubic(0.32, 0.72, 0.0, 1.0),
    );
    _springController.forward();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _springController.dispose();
    super.dispose();
  }

  double _getBasePrice() {
    return widget.product?.price ?? 35000;
  }

  double _calculateTotalPerItem() {
    double total = _getBasePrice();
    // Add selected size
    total += (_sizes[_selectedSizeIndex]['price'] as int).toDouble();
    // Add selected toppings
    for (int idx in _selectedToppingIndices) {
      total += (_toppings[idx]['price'] as int).toDouble();
    }
    return total;
  }

  double _calculateFinalTotal() {
    return _calculateTotalPerItem() * _quantity;
  }

  String _formatCurrency(num amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return formatter.format(amount).replaceAll(' ', '');
  }

  void _triggerHaptic([_LF03HapticType type = _LF03HapticType.light]) {
    try {
      if (type == _LF03HapticType.selection) {
        HapticFeedback.selectionClick();
      } else if (type == _LF03HapticType.medium) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    } catch (_) {}
  }

  void _handleAddToCart() {
    if (_sheetState == LF03SheetState.outOfStock) return;

    _triggerHaptic(_LF03HapticType.medium);

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final sizeName = _sizes[_selectedSizeIndex]['name'];
    final selectedToppingNames = _selectedToppingIndices
        .map((idx) => _toppings[idx]['name'] as String)
        .toList();

    String optionsSummary = 'Size: $sizeName';
    if (selectedToppingNames.isNotEmpty) {
      optionsSummary += ' • ${selectedToppingNames.join(', ')}';
    }

    final itemPriceWithCustomization = _calculateTotalPerItem();
    final baseProd = widget.product ??
        ProductModel(
          id: 201,
          name: 'Cơm Gà Xối Mỡ Da Giòn (Đùi Góc Tư)',
          price: itemPriceWithCustomization,
          shopId: 10,
          shopName: 'Cơm Gà Xối Mỡ Bà Tám',
          imageUrl: 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=600',
        );

    final prod = baseProd.copyWith(price: itemPriceWithCustomization);

    cartProvider.addToCart(
      product: prod,
      quantity: _quantity,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      selectedOptionsJson: optionsSummary,
      unitPrice: itemPriceWithCustomization,
      userId: authProvider.user?.id,
    );

    widget.onAddedToCart?.call();

    if (widget.isStandalonePage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm $_quantity x "${prod.name}" vào giỏ hàng!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Đã thêm $_quantity x "${prod.name}" ($sizeName) vào giỏ!'),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Xem giỏ',
            textColor: Colors.yellow,
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
  }

  @override
  Widget build(BuildContext context) {
    final themeBg = _isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final themeSurface = _isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);
    final themeTextPrimary = _isDarkMode ? Colors.white : const Color(0xFF000000);
    final themeTextSecondary = _isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70);
    final themeBorder = _isDarkMode ? const Color(0xFF38383A) : const Color(0xFFE5E5EA);

    Widget sheetContent = Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        minHeight: MediaQuery.of(context).size.height * 0.52,
      ),
      decoration: BoxDecoration(
        color: themeBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Grab Handle & Top Inspector Controls
              _buildTopBarAndInspector(themeBg, themeTextPrimary, themeTextSecondary, themeBorder),

              // 2. Scrollable Body (Product Header, Size Radios, Topping Checkboxes, Notes)
              Flexible(
                child: _buildSheetBody(themeBg, themeSurface, themeTextPrimary, themeTextSecondary, themeBorder),
              ),

              // 3. Sticky Action Bar (Stepper + CTA Button)
              _buildStickyActionBar(themeBg, themeTextPrimary, themeBorder),
            ],
          ),

          // 4. HIG Specs Overlay (When toggled on)
          if (_showHigOverlay) _buildHigSpecsOverlayGuide(),
        ],
      ),
    );

    if (widget.isStandalonePage) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Backdrop with Dim 40% & Blur
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  color: Colors.black.withOpacity(0.40),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),
            ),
            // Background context display: "Cơm Gà Xối Mỡ Da Giòn Bà Tám - KTX Khu B"
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.storefront_rounded, color: Colors.orange, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Bối cảnh: Cơm Gà Xối Mỡ Bà Tám - KTX Khu B',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(_slideAnimation),
                child: sheetContent,
              ),
            ),
          ],
        ),
      );
    }

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(_slideAnimation),
      child: sheetContent,
    );
  }

  // ================= 1. TOP BAR & INTERACTIVE INSPECTOR =================
  Widget _buildTopBarAndInspector(
    Color themeBg,
    Color themeTextPrimary,
    Color themeTextSecondary,
    Color themeBorder,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Grab Handle (36pt x 5pt pill shape)
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 6),
          width: 36,
          height: 5,
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.white30 : Colors.black26,
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),

        // Interactive Inspector Bar (Apple HIG Specs & State controls)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: themeBorder),
          ),
          child: Row(
            children: [
              // Light / Dark Mode Toggle
              InkWell(
                onTap: () {
                  _triggerHaptic(_LF03HapticType.selection);
                  setState(() {
                    _isDarkMode = !_isDarkMode;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  child: Row(
                    children: [
                      Icon(
                        _isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        size: 14,
                        color: _isDarkMode ? Colors.amber : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isDarkMode ? 'Dark' : 'Light',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: themeTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(width: 1, height: 16, color: themeBorder),
              const SizedBox(width: 6),

              // State Switcher (Normal, Skeleton, Empty, Error)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildInspectorChip(LF03SheetState.normal, 'Normal', Icons.check_circle_rounded, Colors.green),
                      const SizedBox(width: 4),
                      _buildInspectorChip(LF03SheetState.skeleton, 'Skeleton', Icons.hourglass_top_rounded, Colors.amber),
                      const SizedBox(width: 4),
                      _buildInspectorChip(LF03SheetState.outOfStock, 'Hết món', Icons.block_rounded, Colors.red),
                      const SizedBox(width: 4),
                      _buildInspectorChip(LF03SheetState.error, 'Lỗi mạng', Icons.wifi_off_rounded, Colors.purple),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 6),
              Container(width: 1, height: 16, color: themeBorder),
              const SizedBox(width: 6),

              // HIG Specs Overlay Toggle
              InkWell(
                onTap: () {
                  _triggerHaptic(_LF03HapticType.selection);
                  setState(() {
                    _showHigOverlay = !_showHigOverlay;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: _showHigOverlay ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.grid_4x4_rounded,
                        size: 13,
                        color: _showHigOverlay ? Colors.white : themeTextSecondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Specs',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: _showHigOverlay ? Colors.white : themeTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Close button & Header Row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tùy biến món ăn',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: themeTextSecondary,
                  letterSpacing: -0.2,
                ),
              ),
              // Compact Close Circle Button
              InkWell(
                onTap: () {
                  _triggerHaptic(_LF03HapticType.light);
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: themeTextPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: themeBorder),
      ],
    );
  }

  Widget _buildInspectorChip(LF03SheetState state, String label, IconData icon, Color color) {
    final isSelected = _sheetState == state;
    return InkWell(
      onTap: () {
        _triggerHaptic(_LF03HapticType.selection);
        setState(() {
          _sheetState = state;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: isSelected ? color : Colors.grey),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= 2. SHEET BODY WITH STATES =================
  Widget _buildSheetBody(
    Color themeBg,
    Color themeSurface,
    Color themeTextPrimary,
    Color themeTextSecondary,
    Color themeBorder,
  ) {
    if (_sheetState == LF03SheetState.skeleton) {
      return _buildSkeletonContent(themeSurface);
    }

    if (_sheetState == LF03SheetState.error) {
      return _buildErrorBannerContent(themeTextPrimary, themeTextSecondary);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        // Out of stock warning banner
        if (_sheetState == LF03SheetState.outOfStock)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tạm hết nguyên liệu đùi gà xối mỡ',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                      ),
                      Text(
                        'Quán đang xối mỡ mẻ gà mới lúc 12:30. Quý khách vui lòng chọn món khác nhé!',
                        style: TextStyle(fontSize: 11, color: Color(0xFFB91C1C)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Product Header Card
        _buildProductHeader(themeSurface, themeTextPrimary, themeTextSecondary),
        const SizedBox(height: 18),

        // Size Section (Radio - Bắt buộc)
        _buildSizeSection(themeSurface, themeTextPrimary, themeTextSecondary, themeBorder),
        const SizedBox(height: 18),

        // Toppings Section (Checkbox - Tùy chọn)
        _buildToppingSection(themeSurface, themeTextPrimary, themeTextSecondary, themeBorder),
        const SizedBox(height: 18),

        // Special Notes Section with Quick Chips
        _buildSpecialNotesSection(themeSurface, themeTextPrimary, themeTextSecondary, themeBorder),
      ],
    );
  }

  // ================= PRODUCT HEADER =================
  Widget _buildProductHeader(Color themeSurface, Color themeTextPrimary, Color themeTextSecondary) {
    final dishName = widget.product?.name ?? 'Cơm Gà Xối Mỡ Da Giòn (Đùi Góc Tư)';
    final shopName = widget.product?.shopName ?? 'Cơm Gà Xối Mỡ Bà Tám - KTX Khu B';
    final imageUrl = widget.product?.imageUrl ?? 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=600';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeSurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              imageUrl,
              width: 74,
              height: 74,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(width: 74, height: 74, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dishName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: themeTextPrimary,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  shopName,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: themeTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      _formatCurrency(_getBasePrice()),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatCurrency(45000),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '-22%',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= SIZE SECTION (RADIO - BẮT BUỘC) =================
  Widget _buildSizeSection(
    Color themeSurface,
    Color themeTextPrimary,
    Color themeTextSecondary,
    Color themeBorder,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Chọn Size',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: themeTextPrimary),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Bắt buộc',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        ...List.generate(_sizes.length, (idx) {
          final size = _sizes[idx];
          final isSelected = _selectedSizeIndex == idx;
          final extraPrice = size['price'] as int;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected ? (_isDarkMode ? const Color(0xFF3A2A20) : const Color(0xFFFFF7ED)) : themeSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppColors.primary : themeBorder,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: InkWell(
              onTap: () {
                _triggerHaptic(_LF03HapticType.selection);
                setState(() {
                  _selectedSizeIndex = idx;
                });
              },
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Radio Icon
                    Icon(
                      isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                      color: isSelected ? AppColors.primary : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 10),

                    // Size Info & Badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                size['name'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? AppColors.primary : themeTextPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withOpacity(0.15)
                                      : (_isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  size['badge'] as String,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? AppColors.primary : themeTextSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            size['description'] as String,
                            style: TextStyle(fontSize: 11, color: themeTextSecondary),
                          ),
                        ],
                      ),
                    ),

                    // Price text
                    Text(
                      extraPrice == 0 ? '+0₫' : '+${_formatCurrency(extraPrice)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.primary : themeTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ================= TOPPING SECTION (CHECKBOX - TÙY CHỌN) =================
  Widget _buildToppingSection(
    Color themeSurface,
    Color themeTextPrimary,
    Color themeTextSecondary,
    Color themeBorder,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Toppings & Món kèm',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: themeTextPrimary),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Tùy chọn',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        ...List.generate(_toppings.length, (idx) {
          final topping = _toppings[idx];
          final isChecked = _selectedToppingIndices.contains(idx);
          final price = topping['price'] as int;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isChecked ? (_isDarkMode ? const Color(0xFF3A2A20) : const Color(0xFFFFF7ED)) : themeSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isChecked ? AppColors.primary : themeBorder,
                width: isChecked ? 1.5 : 1,
              ),
            ),
            child: InkWell(
              onTap: () {
                _triggerHaptic(_LF03HapticType.selection);
                setState(() {
                  if (isChecked) {
                    _selectedToppingIndices.remove(idx);
                  } else {
                    _selectedToppingIndices.add(idx);
                  }
                });
              },
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Checkbox Icon
                    Icon(
                      isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                      color: isChecked ? AppColors.primary : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 10),

                    // Topping Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topping['name'] as String,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: isChecked ? AppColors.primary : themeTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            topping['description'] as String,
                            style: TextStyle(fontSize: 11, color: themeTextSecondary),
                          ),
                        ],
                      ),
                    ),

                    // Price
                    Text(
                      '+${_formatCurrency(price)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isChecked ? AppColors.primary : themeTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ================= SPECIAL NOTES WITH QUICK CHIPS =================
  Widget _buildSpecialNotesSection(
    Color themeSurface,
    Color themeTextPrimary,
    Color themeTextSecondary,
    Color themeBorder,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ghi chú đặc biệt cho quán',
          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: themeTextPrimary),
        ),
        const SizedBox(height: 8),

        // Quick Suggestion Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _quickNoteChips.map((chipText) {
              final isApplied = _noteController.text.contains(chipText);
              return Padding(
                padding: const EdgeInsets.only(right: 6, bottom: 8),
                child: InkWell(
                  onTap: () {
                    _triggerHaptic(_LF03HapticType.selection);
                    setState(() {
                      if (_noteController.text.isEmpty) {
                        _noteController.text = chipText;
                      } else if (!_noteController.text.contains(chipText)) {
                        _noteController.text = '${_noteController.text}, $chipText';
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isApplied
                          ? AppColors.primary.withOpacity(0.15)
                          : (_isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isApplied ? AppColors.primary : themeBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isApplied ? Icons.check : Icons.add,
                          size: 12,
                          color: isApplied ? AppColors.primary : themeTextSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          chipText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isApplied ? FontWeight.bold : FontWeight.w500,
                            color: isApplied ? AppColors.primary : themeTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Text input field
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: themeSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: themeBorder),
          ),
          child: TextField(
            controller: _noteController,
            style: TextStyle(fontSize: 13, color: themeTextPrimary),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Nhập dặn dò (ví dụ: Nhiều sốt tương, để riêng canh nóng...)',
              hintStyle: TextStyle(fontSize: 12, color: themeTextSecondary),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  // ================= 3. STICKY ACTION BAR =================
  Widget _buildStickyActionBar(Color themeBg, Color themeTextPrimary, Color themeBorder) {
    final finalTotal = _calculateFinalTotal();
    final isOutOfStock = _sheetState == LF03SheetState.outOfStock;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: themeBg,
        border: Border(top: BorderSide(color: themeBorder)),
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
          // Stepper [-] 1 [+]
          Container(
            decoration: BoxDecoration(
              color: _isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: themeBorder),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_rounded, size: 18),
                  color: _quantity > 1 ? themeTextPrimary : Colors.grey,
                  onPressed: isOutOfStock
                      ? null
                      : () {
                          if (_quantity > 1) {
                            _triggerHaptic(_LF03HapticType.light);
                            setState(() {
                              _quantity--;
                            });
                          }
                        },
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                  child: Text(
                    '$_quantity',
                    key: ValueKey<int>(_quantity),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: themeTextPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_rounded, size: 18),
                  color: AppColors.primary,
                  onPressed: isOutOfStock
                      ? null
                      : () {
                          _triggerHaptic(_LF03HapticType.light);
                          setState(() {
                            _quantity++;
                          });
                        },
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Main CTA Button
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isOutOfStock ? Colors.grey : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: isOutOfStock ? 0 : 3,
                shadowColor: AppColors.primary.withOpacity(0.4),
              ),
              onPressed: isOutOfStock ? null : _handleAddToCart,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isOutOfStock ? Icons.block_rounded : Icons.shopping_bag_outlined,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOutOfStock ? 'Hết nguyên liệu' : 'Thêm vào giỏ • ${_formatCurrency(finalTotal)}',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
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

  // ================= SKELETON STATE VIEW =================
  Widget _buildSkeletonContent(Color themeSurface) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 74, height: 74, decoration: BoxDecoration(color: themeSurface, borderRadius: BorderRadius.circular(14))),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 180, height: 18, decoration: BoxDecoration(color: themeSurface, borderRadius: BorderRadius.circular(6))),
                    const SizedBox(height: 8),
                    Container(width: 120, height: 12, decoration: BoxDecoration(color: themeSurface, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 8),
                    Container(width: 90, height: 16, decoration: BoxDecoration(color: themeSurface, borderRadius: BorderRadius.circular(6))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(width: 100, height: 16, decoration: BoxDecoration(color: themeSurface, borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 12),
          Container(width: double.infinity, height: 48, decoration: BoxDecoration(color: themeSurface, borderRadius: BorderRadius.circular(12))),
          const SizedBox(height: 8),
          Container(width: double.infinity, height: 48, decoration: BoxDecoration(color: themeSurface, borderRadius: BorderRadius.circular(12))),
          const SizedBox(height: 20),
          Container(width: 120, height: 16, decoration: BoxDecoration(color: themeSurface, borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 12),
          Container(width: double.infinity, height: 48, decoration: BoxDecoration(color: themeSurface, borderRadius: BorderRadius.circular(12))),
        ],
      ),
    );
  }

  // ================= ERROR STATE VIEW =================
  Widget _buildErrorBannerContent(Color themeTextPrimary, Color themeTextSecondary) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wifi_off_rounded, color: Colors.red, size: 38),
          ),
          const SizedBox(height: 16),
          Text(
            'Lỗi kết nối tùy biến món',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: themeTextPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Không thể đồng bộ danh sách topping & giá mới nhất từ quán Bà Tám qua Wi-Fi KTX.',
            style: TextStyle(fontSize: 12, color: themeTextSecondary),
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
                _sheetState = LF03SheetState.normal;
              });
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Thử lại kết nối'),
          ),
        ],
      ),
    );
  }

  // ================= 4. HIG SPECS OVERLAY GUIDE =================
  Widget _buildHigSpecsOverlayGuide() {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.8), width: 2),
        ),
        child: Stack(
          children: [
            // Specs Callout 1: 28pt continuous corner radius
            Positioned(
              top: 6,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Corner Radius: 28pt (Apple HIG)',
                  style: TextStyle(color: Colors.black, fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Specs Callout 2: 16pt margin & 8pt grid
            Positioned(
              top: 100,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Margin: 16pt • Grid: 8pt',
                  style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Specs Callout 3: Provider Mapping
            Positioned(
              bottom: 80,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.cyanAccent),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Provider Mapping:',
                      style: TextStyle(color: Colors.cyanAccent, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'ProductOptionsState ➔ CartProvider.addItem()',
                      style: TextStyle(color: Colors.white, fontSize: 8.5),
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
}

enum _LF03HapticType {
  light,
  selection,
  medium,
}

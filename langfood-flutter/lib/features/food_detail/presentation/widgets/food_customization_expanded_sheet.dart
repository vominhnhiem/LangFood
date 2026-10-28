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

enum LF04SheetState {
  normal, // Chuẩn (Expanded 90%)
  outOfTopping, // Hết Topping
  skeleton, // Đang tải (Skeleton Shimmer)
  error, // Lỗi mạng (Error State)
}

enum _LF04HapticType {
  selection,
  light,
  medium,
}

/// Helper function to open LF-04 Expanded Sheet (90% Height)
Future<void> showFoodCustomizationExpandedSheet({
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
      return FoodCustomizationExpandedSheet(
        product: product,
        onAddedToCart: onAddedToCart,
      );
    },
  );
}

class FoodCustomizationExpandedSheet extends StatefulWidget {
  final ProductModel? product;
  final VoidCallback? onAddedToCart;
  final bool isStandalonePage;

  const FoodCustomizationExpandedSheet({
    super.key,
    this.product,
    this.onAddedToCart,
    this.isStandalonePage = false,
  });

  @override
  State<FoodCustomizationExpandedSheet> createState() => _FoodCustomizationExpandedSheetState();
}

class _FoodCustomizationExpandedSheetState extends State<FoodCustomizationExpandedSheet>
    with SingleTickerProviderStateMixin {
  // Inspector & State
  bool _isDarkMode = false;
  LF04SheetState _sheetState = LF04SheetState.normal;
  bool _showHigOverlay = false;
  bool _isExpanded90 = true; // Toggle between 90% (Expanded) and 50% (Medium)

  // Selection states
  // Nhóm 1: Chọn khẩu phần (Radio - Bắt buộc)
  int _selectedPortionIndex = 0; // 0: Tiêu chuẩn (35k), 1: Gấp đôi cơm (+5k), 2: Khổng Lồ 2 Đùi (+25k)

  // Nhóm 2: Độ cay & Sốt mắm tỏi (Filter Chips - Chọn 1)
  int _selectedSpicyIndex = 0; // 0: Vừa cay ớt xiêm, 1: Cay nhiều, 2: Không cay, 3: Sốt để riêng

  // Nhóm 3: Topping & Món kèm (Checkbox - Tùy chọn đa mục)
  // Mặc định: Trứng ốp la (5k) + Canh rong biển (8k)
  final Set<int> _selectedToppingIndices = {0, 1};

  // Nhóm 4: Ghi chú cho bếp
  final TextEditingController _noteController = TextEditingController();
  int _quantity = 1;

  // Spring animation
  late AnimationController _springController;
  late Animation<double> _slideAnimation;

  // Definition of Nhóm 1: Khẩu phần
  final List<Map<String, dynamic>> _portions = [
    {
      'name': 'Tiêu chuẩn',
      'price': 0,
      'badge': 'Khuyên dùng 🔥',
      'description': '1 đùi gà góc tư vàng giòn + 1.5 chén cơm chiên cà chua',
    },
    {
      'name': 'Gấp đôi cơm chiên',
      'price': 5000,
      'badge': 'Ăn no học bài 📚',
      'description': 'Thêm 1 chén cơm chiên xối mỡ tóp mỡ giòn rụm',
    },
    {
      'name': 'Khổng Lồ 2 Đùi mùa thi',
      'price': 25000,
      'badge': 'Siêu no căng 🍗🍗',
      'description': '2 đùi gà góc tư đẫy đà + 2 đĩa cơm chiên + canh rong biển lớn',
    },
  ];

  // Definition of Nhóm 2: Độ cay & Sốt mắm tỏi
  final List<Map<String, dynamic>> _spicyOptions = [
    {
      'name': 'Vừa cay ớt xiêm 🌶️',
      'sub': 'Cay the nhẹ chuẩn vị Bà Tám',
    },
    {
      'name': 'Cay nhiều 🔥',
      'sub': 'Thêm ớt hiểm xay rim mắm',
    },
    {
      'name': 'Không cay mắm ngọt 🍯',
      'sub': 'Ngọt thanh mắm tỏi phi thơm',
    },
    {
      'name': 'Sốt để riêng 🥣',
      'sub': 'Chấm riêng giữ da siêu giòn',
    },
  ];

  // Definition of Nhóm 3: Topping & Món kèm
  final List<Map<String, dynamic>> _toppings = [
    {
      'name': 'Trứng ốp la lòng đào',
      'price': 5000,
      'description': 'Trứng gà ta viền giòn rụm, lòng đào béo ngậy',
      'badge': 'Phổ biến nhất',
      'isOutOfStock': false,
    },
    {
      'name': 'Canh rong biển thịt bằm',
      'price': 8000,
      'description': 'Nước hầm xương thịt bằm ngọt thanh giải ngấy',
      'badge': 'Nóng hổi',
      'isOutOfStock': false,
    },
    {
      'name': 'Cơm chiên thêm 1 chén',
      'price': 5000,
      'description': 'Cơm hạt ngọc xào sốt cà rưới mỡ hành tóp mỡ',
      'badge': null,
      'isOutOfStock': false,
    },
    {
      'name': 'Kim chi dưa chua giải ngấy',
      'price': 4000,
      'description': 'Kim chi cải thảo giòn sần sật lên men tự nhiên',
      'badge': null,
      'isOutOfStock': false,
    },
  ];

  // Definition of Quick note chips
  final List<String> _quickNoteChips = [
    'Ít dầu mỡ',
    'Nhiều sốt mắm',
    'Giao tận sảnh KTX',
    'Để riêng canh',
    'Cơm mềm',
    'Thêm dưa leo',
  ];

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    // Cubic(0.32, 0.72, 0, 1) - Apple HIG Fluid Curve
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
    // Khẩu phần
    total += (_portions[_selectedPortionIndex]['price'] as int).toDouble();
    // Toppings
    if (_sheetState != LF04SheetState.outOfTopping) {
      for (int idx in _selectedToppingIndices) {
        total += (_toppings[idx]['price'] as int).toDouble();
      }
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

  void _triggerHaptic([_LF04HapticType type = _LF04HapticType.light]) {
    try {
      if (type == _LF04HapticType.selection) {
        HapticFeedback.selectionClick();
      } else if (type == _LF04HapticType.medium) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    } catch (_) {}
  }

  void _handleAddToCart() {
    if (_sheetState == LF04SheetState.skeleton || _sheetState == LF04SheetState.error) return;

    _triggerHaptic(_LF04HapticType.medium);

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final portionName = _portions[_selectedPortionIndex]['name'];
    final spicyName = _spicyOptions[_selectedSpicyIndex]['name'];

    List<String> chosenToppings = [];
    if (_sheetState != LF04SheetState.outOfTopping) {
      chosenToppings = _selectedToppingIndices.map((i) => _toppings[i]['name'] as String).toList();
    }

    String optionsSummary = 'Khẩu phần: $portionName • Sốt: $spicyName';
    if (chosenToppings.isNotEmpty) {
      optionsSummary += ' • Topping: ${chosenToppings.join(', ')}';
    }

    final itemPriceWithCustomization = _calculateTotalPerItem();
    final baseProd = widget.product ??
        ProductModel(
          id: 201,
          name: 'Cơm Gà Xối Mỡ Da Giòn Bà Tám',
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
          content: Text('Đã thêm $_quantity x "${prod.name}" vào giỏ!'),
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
                child: Text('Đã thêm $_quantity x "${prod.name}" (${_formatCurrency(_calculateFinalTotal())}) vào giỏ!'),
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
    final themeSurface = _isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF8F9FA);
    final themeTextPrimary = _isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final themeTextSecondary = _isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF64748B);
    final themeBorder = _isDarkMode ? const Color(0xFF38383A) : const Color(0xFFE2E8F0);

    // Height detent: 90% when expanded, 50% when medium
    final targetHeightFactor = _isExpanded90 ? 0.90 : 0.52;

    Widget sheetContent = AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: const Cubic(0.32, 0.72, 0.0, 1.0),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * targetHeightFactor,
        minHeight: MediaQuery.of(context).size.height * 0.48,
      ),
      decoration: BoxDecoration(
        color: themeBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Grab Handle & Top Control Bar
              _buildTopBar(themeBg, themeTextPrimary, themeTextSecondary, themeBorder),

              // 2. Interactive Inspector State Selector
              _buildInspectorBar(themeSurface, themeTextPrimary, themeTextSecondary, themeBorder),

              // 3. Scrollable Content Body
              Flexible(
                child: _buildScrollableBody(themeBg, themeSurface, themeTextPrimary, themeTextSecondary, themeBorder),
              ),

              // 4. Sticky Bottom Action Bar
              _buildStickyActionBar(themeBg, themeTextPrimary, themeBorder),
            ],
          ),

          // HIG Specs Overlay (if active)
          if (_showHigOverlay) _buildHigSpecsOverlay(),
        ],
      ),
    );

    // If standalone page, wrap with dimmed backdrop
    if (widget.isStandalonePage) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Backdrop Dim 40% & Blur
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
            // Background restaurant watermark
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restaurant_rounded, color: Colors.orange, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Bối cảnh: Cơm Gà Xối Mỡ Da Giòn Bà Tám - KTX Khu B',
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

  // ================= 1. TOP BAR & GRAB HANDLE =================
  Widget _buildTopBar(Color bg, Color textPrimary, Color textSecondary, Color border) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border.withOpacity(0.5), width: 0.8)),
      ),
      child: Column(
        children: [
          // Apple HIG Pill Grab Handle (36x5pt)
          GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null) {
                if (details.primaryVelocity! > 250) {
                  // Drag down -> switch to medium or close
                  if (_isExpanded90) {
                    setState(() => _isExpanded90 = false);
                  } else {
                    Navigator.pop(context);
                  }
                } else if (details.primaryVelocity! < -250) {
                  // Drag up -> expand to 90%
                  setState(() => _isExpanded90 = true);
                }
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.white30 : Colors.black26,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),

          // Title & Quick Actions
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _isExpanded90 ? 'LF-04: EXPANDED 90%' : 'LF-03: MEDIUM 50%',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Tùy biến món ăn',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),

              // Detent Height Switcher (50% <-> 90%)
              InkWell(
                onTap: () {
                  _triggerHaptic(_LF04HapticType.selection);
                  setState(() => _isExpanded90 = !_isExpanded90);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isExpanded90 ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _isExpanded90 ? 'Thu 50%' : 'Mở 90%',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Close X Button
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.white12 : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded, size: 16, color: textSecondary),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 2. INSPECTOR STATE SELECTOR =================
  Widget _buildInspectorBar(Color surface, Color textPrimary, Color textSecondary, Color border) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: _isDarkMode ? const Color(0xFF242426) : const Color(0xFFF1F5F9),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.tune_rounded, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            const Text(
              'Trạng thái:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(width: 8),

            // State: Normal
            _buildStateChip(
              state: LF04SheetState.normal,
              label: 'Chuẩn (90%)',
              icon: Icons.check_circle_outline_rounded,
              color: const Color(0xFF10B981),
            ),
            const SizedBox(width: 6),

            // State: Out of Topping
            _buildStateChip(
              state: LF04SheetState.outOfTopping,
              label: 'Hết Topping',
              icon: Icons.remove_shopping_cart_rounded,
              color: const Color(0xFFF59E0B),
            ),
            const SizedBox(width: 6),

            // State: Skeleton
            _buildStateChip(
              state: LF04SheetState.skeleton,
              label: 'Đang tải (Shimmer)',
              icon: Icons.hourglass_top_rounded,
              color: const Color(0xFF6366F1),
            ),
            const SizedBox(width: 6),

            // State: Error
            _buildStateChip(
              state: LF04SheetState.error,
              label: 'Lỗi mạng',
              icon: Icons.wifi_off_rounded,
              color: const Color(0xFFEF4444),
            ),
            const SizedBox(width: 8),

            // Toggle Dark Mode
            InkWell(
              onTap: () {
                _triggerHaptic(_LF04HapticType.selection);
                setState(() => _isDarkMode = !_isDarkMode);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.amber.withOpacity(0.2) : Colors.indigo.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                      size: 13,
                      color: _isDarkMode ? Colors.amber : Colors.indigo,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isDarkMode ? 'Light' : 'Dark',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _isDarkMode ? Colors.amber : Colors.indigo,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),

            // HIG Specs Overlay Toggle
            InkWell(
              onTap: () {
                _triggerHaptic(_LF04HapticType.selection);
                setState(() => _showHigOverlay = !_showHigOverlay);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _showHigOverlay ? AppColors.primary : Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.grid_on_rounded,
                      size: 13,
                      color: _showHigOverlay ? Colors.white : textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'HIG Specs',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _showHigOverlay ? Colors.white : textSecondary,
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

  Widget _buildStateChip({
    required LF04SheetState state,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _sheetState == state;
    return InkWell(
      onTap: () {
        _triggerHaptic(_LF04HapticType.selection);
        setState(() => _sheetState = state);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.transparent : color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isSelected ? Colors.white : color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= 3. SCROLLABLE BODY =================
  Widget _buildScrollableBody(
    Color bg,
    Color surface,
    Color textPrimary,
    Color textSecondary,
    Color border,
  ) {
    if (_sheetState == LF04SheetState.skeleton) {
      return _buildSkeletonView(surface);
    }

    if (_sheetState == LF04SheetState.error) {
      return _buildErrorView(textPrimary, textSecondary);
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        // 1. Hero Food Information Card
        _buildHeroFoodCard(surface, textPrimary, textSecondary, border),
        const SizedBox(height: 18),

        // 2. Nhóm 1: Chọn khẩu phần (Radio - Bắt buộc)
        _buildSectionHeader(
          title: '1. Chọn khẩu phần',
          isRequired: true,
          badgeText: 'Bắt buộc chọn 1',
          textPrimary: textPrimary,
        ),
        const SizedBox(height: 8),
        ...List.generate(_portions.length, (index) {
          final portion = _portions[index];
          final isSelected = _selectedPortionIndex == index;
          return _buildPortionRadioItem(portion, index, isSelected, textPrimary, textSecondary, border);
        }),
        const SizedBox(height: 18),

        // 3. Nhóm 2: Độ cay & Sốt mắm tỏi đặc chế (Filter Chips)
        _buildSectionHeader(
          title: '2. Độ cay & Sốt đặc chế',
          isRequired: true,
          badgeText: 'Bí truyền Bà Tám',
          textPrimary: textPrimary,
        ),
        const SizedBox(height: 8),
        _buildSpicyFilterChips(surface, textPrimary, textSecondary, border),
        const SizedBox(height: 18),

        // 4. Nhóm 3: Topping & Món kèm (Checkbox - Tùy chọn đa mục)
        _buildSectionHeader(
          title: '3. Topping & Món kèm',
          isRequired: false,
          badgeText: _sheetState == LF04SheetState.outOfTopping ? 'Tạm hết món' : 'Chọn nhiều món',
          textPrimary: textPrimary,
          isWarning: _sheetState == LF04SheetState.outOfTopping,
        ),
        const SizedBox(height: 8),
        if (_sheetState == LF04SheetState.outOfTopping)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Topping hiện tại đã hết suất trưa. Món chính vẫn được phục vụ bình thường!',
                    style: TextStyle(fontSize: 12, color: Colors.brown, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          )
        else
          ...List.generate(_toppings.length, (index) {
            final topping = _toppings[index];
            final isSelected = _selectedToppingIndices.contains(index);
            return _buildToppingCheckboxItem(topping, index, isSelected, textPrimary, textSecondary, border);
          }),
        const SizedBox(height: 18),

        // 5. Nhóm 4: Ghi chú cho bếp & Chip gợi ý nhanh
        _buildSectionHeader(
          title: '4. Ghi chú cho bếp',
          isRequired: false,
          badgeText: 'Tùy chọn',
          textPrimary: textPrimary,
        ),
        const SizedBox(height: 8),
        _buildNotesSection(surface, textPrimary, textSecondary, border),
        const SizedBox(height: 24),
      ],
    );
  }

  // ================= SUB-COMPONENTS =================
  Widget _buildHeroFoodCard(Color surface, Color textPrimary, Color textSecondary, Color border) {
    final originalPrice = 45000;
    final currentPrice = _getBasePrice();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Food Image with discount badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  widget.product?.imageUrl ??
                      'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=400',
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 96,
                    height: 96,
                    color: Colors.orange.shade100,
                    child: const Icon(Icons.fastfood, color: Colors.orange, size: 40),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '-22%',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Quán quen KTX',
                        style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                    const Text(
                      '4.9 (1.2k+)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Dish Name
                Text(
                  widget.product?.name ?? 'Cơm Gà Xối Mỡ Da Giòn (Đùi Góc Tư)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Description
                Text(
                  'Đùi gà xối mỡ vàng ươm da giòn rụm sốt mắm tỏi bí truyền, cơm chiên cà chua thơm phức hạt ngọc.',
                  style: TextStyle(fontSize: 11.5, color: textSecondary, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Price
                Row(
                  children: [
                    Text(
                      _formatCurrency(currentPrice),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatCurrency(originalPrice),
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        decoration: TextDecoration.lineThrough,
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

  Widget _buildSectionHeader({
    required String title,
    required bool isRequired,
    required String badgeText,
    required Color textPrimary,
    bool isWarning = false,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: isWarning
                ? Colors.red.withOpacity(0.12)
                : (isRequired ? AppColors.primary.withOpacity(0.12) : Colors.blue.withOpacity(0.12)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            badgeText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isWarning ? Colors.red : (isRequired ? AppColors.primary : Colors.blue.shade700),
            ),
          ),
        ),
      ],
    );
  }

  // Nhóm 1 Item
  Widget _buildPortionRadioItem(
    Map<String, dynamic> portion,
    int index,
    bool isSelected,
    Color textPrimary,
    Color textSecondary,
    Color border,
  ) {
    final price = portion['price'] as int;

    return InkWell(
      onTap: () {
        _triggerHaptic(_LF04HapticType.selection);
        setState(() => _selectedPortionIndex = index);
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : border,
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        portion['name'] as String,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      if (portion['badge'] != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            portion['badge'] as String,
                            style: const TextStyle(fontSize: 9.5, color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    portion['description'] as String,
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                ],
              ),
            ),
            Text(
              price > 0 ? '+${_formatCurrency(price)}' : 'Đã gồm',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Nhóm 2 Filter Chips
  Widget _buildSpicyFilterChips(Color surface, Color textPrimary, Color textSecondary, Color border) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_spicyOptions.length, (index) {
        final opt = _spicyOptions[index];
        final isSelected = _selectedSpicyIndex == index;
        return InkWell(
          onTap: () {
            _triggerHaptic(_LF04HapticType.selection);
            setState(() => _selectedSpicyIndex = index);
          },
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : border,
                width: 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                  ),
                Text(
                  opt['name'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // Nhóm 3 Item
  Widget _buildToppingCheckboxItem(
    Map<String, dynamic> topping,
    int index,
    bool isSelected,
    Color textPrimary,
    Color textSecondary,
    Color border,
  ) {
    final price = topping['price'] as int;

    return InkWell(
      onTap: () {
        _triggerHaptic(_LF04HapticType.selection);
        setState(() {
          if (isSelected) {
            _selectedToppingIndices.remove(index);
          } else {
            _selectedToppingIndices.add(index);
          }
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              color: isSelected ? AppColors.primary : textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        topping['name'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      if (topping['badge'] != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            topping['badge'] as String,
                            style: TextStyle(fontSize: 9.5, color: Colors.green.shade700, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    topping['description'] as String,
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                ],
              ),
            ),
            Text(
              '+${_formatCurrency(price)}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Nhóm 4 Notes & Chips
  Widget _buildNotesSection(Color surface, Color textPrimary, Color textSecondary, Color border) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick suggestions
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _quickNoteChips.map((chipText) {
            return InkWell(
              onTap: () {
                _triggerHaptic(_LF04HapticType.selection);
                setState(() {
                  final cur = _noteController.text;
                  if (cur.isEmpty) {
                    _noteController.text = chipText;
                  } else if (!cur.contains(chipText)) {
                    _noteController.text = '$cur, $chipText';
                  }
                });
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 12, color: AppColors.primary),
                    const SizedBox(width: 3),
                    Text(
                      chipText,
                      style: TextStyle(fontSize: 11, color: textPrimary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),

        // TextField
        TextField(
          controller: _noteController,
          maxLines: 2,
          maxLength: 100,
          style: TextStyle(fontSize: 13, color: textPrimary),
          decoration: InputDecoration(
            hintText: 'Ví dụ: Cơm ít mỡ, nhiều mỡ hành, giao trước 12h phòng BA2-405...',
            hintStyle: TextStyle(fontSize: 12, color: textSecondary),
            filled: true,
            fillColor: surface,
            counterStyle: TextStyle(fontSize: 10, color: textSecondary),
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ================= 4. STICKY BOTTOM ACTION BAR =================
  Widget _buildStickyActionBar(Color bg, Color textPrimary, Color border) {
    final finalTotal = _calculateFinalTotal();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border.withOpacity(0.6), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Campus Promise Tag
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bolt_rounded, size: 14, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  'Cam kết giao nóng tận phòng KTX Khu A & B trong 20 phút',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ),

          // Stepper + CTA Button
          Row(
            children: [
              // Stepper [-] 1 [+]
              Container(
                decoration: BoxDecoration(
                  color: _isDarkMode ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_rounded, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 38, minHeight: 44),
                      onPressed: _quantity > 1
                          ? () {
                              _triggerHaptic(_LF04HapticType.light);
                              setState(() => _quantity--);
                            }
                          : null,
                    ),
                    Container(
                      constraints: const BoxConstraints(minWidth: 28),
                      alignment: Alignment.center,
                      child: Text(
                        '$_quantity',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 38, minHeight: 44),
                      onPressed: () {
                        _triggerHaptic(_LF04HapticType.light);
                        setState(() => _quantity++);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Main CTA Button
              Expanded(
                child: ElevatedButton(
                  onPressed: _handleAddToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: AppColors.primary.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_bag_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Thêm vào giỏ • ${_formatCurrency(finalTotal)}',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
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
  }

  // ================= SKELETON STATE =================
  Widget _buildSkeletonView(Color surface) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 90,
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16)),
        ),
        const SizedBox(height: 16),
        Container(
          height: 120,
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16)),
        ),
        const SizedBox(height: 16),
        Container(
          height: 80,
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16)),
        ),
      ],
    );
  }

  // ================= ERROR STATE =================
  Widget _buildErrorView(Color textPrimary, Color textSecondary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 54, color: Colors.redAccent),
            const SizedBox(height: 14),
            Text(
              'Không thể tải chi tiết tùy biến món',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Vui lòng kiểm tra lại kết nối Wi-Fi KTX hoặc thử lại.',
              style: TextStyle(fontSize: 12, color: textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() => _sheetState = LF04SheetState.normal),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Thử lại ngay'),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HIG SPECS OVERLAY =================
  Widget _buildHigSpecsOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red.withOpacity(0.7), width: 2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                color: Colors.red.withOpacity(0.85),
                child: const Text(
                  '📐 HIG SPECS: Corner 28pt | Padding 16pt | Grid 8pt | Sheet Detent: 90% Expanded | Spring 380ms',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                color: Colors.blue.withOpacity(0.85),
                child: const Text(
                  '🔗 PROVIDER MAPPING: ProductOptionsState ➔ CartProvider.addItem(ProductModel, quantity, note, options)',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

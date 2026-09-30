import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/models/product_option_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/cart_provider.dart';
import '../../../cart/presentation/screens/cart_screen.dart';

class FoodDetailScreen extends StatefulWidget {
  final ProductModel product;

  const FoodDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  final TextEditingController _noteController = TextEditingController();
  int _quantity = 1;
  late List<ProductOptionGroupModel> _optionGroups;

  @override
  void initState() {
    super.initState();
    // Deep clone option groups to maintain local selection state
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
    for (var group in _optionGroups) {
      for (var opt in group.options) {
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

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return formatter.format(amount).replaceAll(' ', '');
  }

  void _handleAddToCart() {
    if (!widget.product.isShopOpen) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Collect selected options names for cart item note
    final List<String> selectedNames = [];
    for (var group in _optionGroups) {
      for (var opt in group.options) {
        if (opt.isSelected) {
          selectedNames.add(opt.name);
        }
      }
    }

    String? optionsJson;
    if (selectedNames.isNotEmpty) {
      optionsJson = selectedNames.join(', ');
    }

    cartProvider.addToCart(
      product: widget.product,
      quantity: _quantity,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      selectedOptionsJson: optionsJson,
      userId: authProvider.user?.id,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm $_quantity x "${widget.product.name}" vào giỏ hàng!'),
        backgroundColor: AppColors.primary,
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
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final finalTotal = _calculateTotalPrice();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Scrollable content matching activity_food_detail.xml
          Positioned.fill(
            bottom: 80, // Leave room for layoutCart bottom bar
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food Image (height 260dp, full width)
                  _buildFoodImageBanner(),

                  // Food Info (Name, Price, Seller, Options, Note, Description)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Food Name (bold 22sp #333333)
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Food Price (bold 20sp #FF5722)
                        Text(
                          _formatCurrency(widget.product.price),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Seller Card (cardSeller)
                        _buildSellerCard(),

                        _buildDivider(),

                        // Option Groups / Toppings Section ("Lựa chọn thêm")
                        if (_optionGroups.isNotEmpty) ...[
                          const Text(
                            'Lựa chọn thêm',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ..._optionGroups.map((group) => _buildOptionGroup(group)),
                          _buildDivider(),
                        ],

                        // Note Section ("Ghi chú cho quán")
                        const Text(
                          'Ghi chú cho quán',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _noteController,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Ví dụ: Ít cay, không hành, để riêng nước mắm...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF9F9F9),
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ),

                        _buildDivider(),

                        // Description Section ("Mô tả món ăn")
                        const Text(
                          'Mô tả món ăn',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.product.description?.isNotEmpty == true
                              ? widget.product.description!
                              : 'Món ăn thơm ngon, chuẩn vị sinh viên KTX được chế biến từ nguyên liệu tươi sạch mỗi ngày.',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF757575),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top Floating Back Button (btnBack)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),

          // Bottom Cart Layout (layoutCart matching activity_food_detail.xml)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomCartBar(finalTotal),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodImageBanner() {
    return SizedBox(
      width: double.infinity,
      height: 260,
      child: widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty
          ? Image.network(
              widget.product.imageUrl!.startsWith('http')
                  ? widget.product.imageUrl!
                  : '${AppConstants.baseUrl.replaceAll(RegExp(r'/$'), '')}/${widget.product.imageUrl!.replaceAll(RegExp(r'^/'), '')}',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildFallbackFoodImage(),
            )
          : _buildFallbackFoodImage(),
    );
  }

  Widget _buildFallbackFoodImage() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Icon(
          Icons.fastfood_rounded,
          color: Colors.grey.shade400,
          size: 64,
        ),
      ),
    );
  }

  Widget _buildSellerCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryLight.withOpacity(0.5),
            child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.shopName.isNotEmpty
                      ? widget.product.shopName
                      : 'Quán ăn Làng Food KTX',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Xem gian hàng quán >',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionGroup(ProductOptionGroupModel group) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Group Name + Hint (item_option_group.xml)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  group.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    group.isMultiple ? 'Chọn nhiều' : 'Chọn 1',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF616161),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Options list
          ...group.options.map((option) {
            return InkWell(
              onTap: () {
                setState(() {
                  if (group.isMultiple) {
                    option.isSelected = !option.isSelected;
                  } else {
                    for (var opt in group.options) {
                      opt.isSelected = (opt.id == option.id);
                    }
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    if (group.isMultiple)
                      Checkbox(
                        value: option.isSelected,
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) {
                          setState(() {
                            option.isSelected = val ?? false;
                          });
                        },
                      )
                    else
                      Radio<int>(
                        value: option.id,
                        groupValue: group.options.firstWhere(
                          (o) => o.isSelected,
                          orElse: () => group.options.first,
                        ).id,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() {
                            for (var opt in group.options) {
                              opt.isSelected = (opt.id == val);
                            }
                          });
                        },
                      ),
                    Expanded(
                      child: Text(
                        option.name,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF212121),
                        ),
                      ),
                    ),
                    Text(
                      option.price > 0 ? '+${_formatCurrency(option.price)}' : 'Miễn phí',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: option.price > 0 ? AppColors.primary : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomCartBar(double finalTotal) {
    final isOpen = widget.product.isShopOpen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Quantity Selector (- [qty] +)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 18),
                    color: _quantity > 1 ? AppColors.primary : Colors.grey.shade400,
                    onPressed: _quantity > 1
                        ? () {
                            setState(() {
                              _quantity--;
                            });
                          }
                        : null,
                  ),
                  Text(
                    '$_quantity',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    color: AppColors.primary,
                    onPressed: () {
                      setState(() {
                        _quantity++;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Add To Cart Button (btnAddToCart)
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: isOpen ? _handleAddToCart : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOpen ? AppColors.primary : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    isOpen
                        ? 'THÊM VÀO GIỎ - ${_formatCurrency(finalTotal)}'
                        : 'Quán đang tạm nghỉ',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Divider(color: Color(0xFFEEEEEE), height: 1),
    );
  }
}

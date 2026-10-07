import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../data/models/cart_item_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/cart_provider.dart';
import '../../../tracking/presentation/screens/live_tracking_screen.dart';
import '../../../tracking/presentation/screens/location_picker_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return formatter.format(amount).replaceAll(' ', '');
  }

  void _showCheckoutDialog(BuildContext context, String shopName, double amount, int itemsCount) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 28),
              const SizedBox(width: 8),
              const Text('Xác nhận đặt đơn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quán: $shopName', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('Số lượng: $itemsCount món'),
              const SizedBox(height: 6),
              Text('Địa chỉ nhận: Sảnh KTX Khu B, Thủ Đức'),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng tiền:'),
                  Text(
                    _formatCurrency(amount),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LocationPickerScreen(),
                  ),
                );
              },
              child: const Text('Xác nhận & Set định vị'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final shopMap = cartProvider.itemsByShop;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8), // matching activity_cart.xml
      appBar: AppBar(
        title: const Text(
          'Giỏ hàng của tôi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF212121)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (cartProvider.items.isNotEmpty)
            TextButton(
              onPressed: () {
                cartProvider.clearCart(authProvider.user?.id);
              },
              child: const Text(
                'Xóa hết',
                style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: cartProvider.items.isEmpty
          ? EmptyStateView(
              icon: Icons.remove_shopping_cart_outlined,
              title: 'Giỏ hàng đang trống',
              message: 'Bạn chưa có món ngon nào trong giỏ. Hãy dạo quanh Làng Food và thêm món ngay nhé!',
              actionText: 'Khám phá món ngon',
              onAction: () => Navigator.pop(context),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: shopMap.entries.map((entry) {
                final shopId = entry.key;
                final items = entry.value;
                final shopName = cartProvider.getShopName(shopId);
                final shopTotal = cartProvider.getShopSubtotal(shopId);

                return _buildShopGroupCard(
                  context,
                  shopId: shopId,
                  shopName: shopName,
                  items: items,
                  shopTotal: shopTotal,
                  cartProvider: cartProvider,
                  authProvider: authProvider,
                );
              }).toList(),
            ),

      // Bottom Total Summary Bar matching layoutTotalPrice in activity_cart.xml
      bottomNavigationBar: cartProvider.items.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tổng thanh toán',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF757575),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatCurrency(cartProvider.totalAmount),
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        _showCheckoutDialog(
                          context,
                          'Tất cả các quán',
                          cartProvider.totalAmount,
                          cartProvider.totalItemsCount,
                        );
                      },
                      child: Text(
                        'Thanh toán (${cartProvider.totalItemsCount})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildShopGroupCard(
    BuildContext context, {
    required int shopId,
    required String shopName,
    required List<CartItemModel> items,
    required double shopTotal,
    required CartProvider cartProvider,
    required AuthProvider authProvider,
  }) {
    int totalItemsInShop = 0;
    for (var i in items) {
      totalItemsInShop += i.quantity;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Shop Title & Avatar (matching item_cart_group.xml)
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shopName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$totalItemsInShop món • KTX Khu B',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Items inside this shop group (matching item_cart.xml)
          ...items.map((item) {
            return _buildCartItemTile(context, item, cartProvider, authProvider);
          }),

          const Divider(height: 1),

          // Subtotal for this shop + Quick checkout button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tổng tiền quán:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(
                      _formatCurrency(shopTotal),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: () {
                    _showCheckoutDialog(context, shopName, shopTotal, totalItemsInShop);
                  },
                  child: const Text(
                    'Đặt đơn quán này',
                    style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemTile(
    BuildContext context,
    CartItemModel item,
    CartProvider cartProvider,
    AuthProvider authProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Food Image 70x70 matching item_cart.xml
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 66,
              height: 66,
              child: item.product.imageUrl != null && item.product.imageUrl!.isNotEmpty
                  ? Image.network(
                      item.product.imageUrl!.startsWith('http')
                          ? item.product.imageUrl!
                          : '${AppConstants.baseUrl.replaceAll(RegExp(r'/$'), '')}/${item.product.imageUrl!.replaceAll(RegExp(r'^/'), '')}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildItemPlaceholder(),
                    )
                  : _buildItemPlaceholder(),
            ),
          ),
          const SizedBox(width: 12),

          // Name, Options, Price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.selectedOptionsJson != null && item.selectedOptionsJson!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '+ ${item.selectedOptionsJson}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (item.note != null && item.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Lưu ý: ${item.note}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(item.totalPrice),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Quantity controls (- [count] +)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    cartProvider.updateQuantity(item, -1, authProvider.user?.id);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.remove, size: 16, color: Color(0xFF757575)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    cartProvider.updateQuantity(item, 1, authProvider.user?.id);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.add, size: 16, color: Color(0xFF757575)),
                  ),
                ),
              ],
            ),
          ),

          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
            onPressed: () {
              cartProvider.removeItem(item, authProvider.user?.id);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemPlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: const Center(
        child: Icon(Icons.fastfood, color: Colors.grey, size: 28),
      ),
    );
  }
}

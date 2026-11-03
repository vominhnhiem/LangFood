import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/display_format.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/cart_provider.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../checkout/presentation/screens/checkout_screen.dart';
import '../../../tracking/presentation/screens/location_picker_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  Future<void> _checkout(BuildContext context) async {
    if (!context.read<AuthProvider>().isLoggedIn) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (!context.mounted || !context.read<AuthProvider>().isLoggedIn) return;
    }
    final cart = context.read<CartProvider>();
    await cart.flush();
    if (!context.mounted) return;
    if (cart.syncError != null || cart.isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(cart.syncError ?? 'Đang tải giỏ hàng.')),
      );
      return;
    }
    final location = await Navigator.push<DeliveryLocation>(
      context,
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );
    if (!context.mounted || location == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          deliveryAddress: location.address,
          deliveryLocation: location,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final userId = context.watch<AuthProvider>().user?.id;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: cart.isLoading || !cart.canEdit
                  ? null
                  : () => cart.clearCart(userId),
              child: const Text('Xóa hết'),
            ),
        ],
      ),
      body: Column(
        children: [
          if (cart.isSyncing) const LinearProgressIndicator(),
          if (cart.syncError != null)
            MaterialBanner(
              content: Text(cart.syncError!),
              actions: [
                TextButton(
                  onPressed: cart.isSyncing ? null : cart.retrySync,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          Expanded(
            child: cart.isLoading
                ? const Center(child: CircularProgressIndicator())
                : cart.items.isEmpty
                ? const Center(child: Text('Giỏ hàng đang trống.'))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: cart.itemsByShop.entries
                        .map(
                          (shop) => Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cart.getShopName(shop.key),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  ...shop.value.map(
                                    (item) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.product.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(money(item.totalPrice)),
                                          if (item
                                              .selectedOptionsSummary
                                              .isNotEmpty)
                                            Text(item.selectedOptionsSummary),
                                          if (item.note?.isNotEmpty ?? false)
                                            Text(item.note!),
                                          Row(
                                            children: [
                                              IconButton(
                                                tooltip: 'Giảm số lượng',
                                                onPressed: !cart.canEdit
                                                    ? null
                                                    : () => cart.updateQuantity(
                                                        item,
                                                        -1,
                                                        userId,
                                                      ),
                                                icon: const Icon(
                                                  Icons.remove_circle_outline,
                                                ),
                                              ),
                                              Text('${item.quantity}'),
                                              IconButton(
                                                tooltip: 'Tăng số lượng',
                                                onPressed: !cart.canEdit
                                                    ? null
                                                    : () => cart.updateQuantity(
                                                        item,
                                                        1,
                                                        userId,
                                                      ),
                                                icon: const Icon(
                                                  Icons.add_circle_outline,
                                                ),
                                              ),
                                              const Spacer(),
                                              IconButton(
                                                tooltip: 'Xóa món',
                                                onPressed: () => cart
                                                    .removeItem(item, userId),
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: cart.items.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed:
                      cart.isLoading || cart.isSyncing || cart.syncError != null
                      ? null
                      : () => _checkout(context),
                  child: Text('Tiếp tục • ${money(cart.totalAmount)}'),
                ),
              ),
            ),
    );
  }
}

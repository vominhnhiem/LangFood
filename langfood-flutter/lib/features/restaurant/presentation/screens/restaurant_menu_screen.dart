import 'package:flutter/material.dart';

import '../../../../core/widgets/food_card_item.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/services/product_service.dart';
import '../../../food_detail/presentation/screens/food_detail_screen.dart';
import '../../../cart/presentation/screens/cart_screen.dart';

class RestaurantMenuScreen extends StatefulWidget {
  final int shopId;
  final String shopName;
  const RestaurantMenuScreen({
    super.key,
    required this.shopId,
    required this.shopName,
  });
  @override
  State<RestaurantMenuScreen> createState() => _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends State<RestaurantMenuScreen> {
  late Future<List<ProductModel>> _products;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _products = ProductService().getProductsByShop(widget.shopId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.shopName),
      actions: [
        IconButton(
          icon: const Icon(Icons.shopping_bag_outlined),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ),
        ),
      ],
    ),
    body: FutureBuilder<List<ProductModel>>(
      future: _products,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(
            child: TextButton(
              onPressed: () => setState(_reload),
              child: const Text('Không tải được menu. Thử lại'),
            ),
          );
        final products = (snapshot.data ?? <ProductModel>[])
            .where((p) => p.status == 1 && p.isAvailable)
            .toList();
        if (products.isEmpty)
          return const Center(child: Text('Quán chưa có món ăn.'));
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 260,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 310,
          ),
          itemBuilder: (_, i) => FoodCardItem(
            product: products[i],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FoodDetailScreen(product: products[i]),
              ),
            ),
          ),
        );
      },
    ),
  );
}

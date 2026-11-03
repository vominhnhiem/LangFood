import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/food_card_item.dart';
import '../../../../core/widgets/account_menu.dart';
import '../../../orders/presentation/screens/my_orders_screen.dart';
import '../../../../data/models/category_model.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/services/product_service.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/cart_provider.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../food_detail/presentation/screens/food_detail_screen.dart';
import '../../../restaurant/presentation/screens/restaurant_menu_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = ProductService();
  final _search = TextEditingController();
  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  int? _categoryId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object>([
        _service.getProducts(),
        _service.getCategories(),
      ]);
      if (!mounted) return;
      setState(() {
        _products = results[0] as List<ProductModel>;
        _categories = results[1] as List<CategoryModel>;
      });
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();
    final query = _search.text.trim().toLowerCase();
    final products = _products
        .where(
          (p) =>
              (_categoryId == null || p.categoryId == _categoryId) &&
              (p.name.toLowerCase().contains(query) ||
                  p.shopName.toLowerCase().contains(query)),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Làng Food'),
        actions: [
          IconButton(
            tooltip: 'Giỏ hàng (${cart.totalItemsCount})',
            icon: Badge(
              label: Text('${cart.totalItemsCount}'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
          if (!auth.isLoggedIn)
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              child: const Text('Đăng nhập'),
            )
          else ...[
            IconButton(
              tooltip: 'Đơn hàng của tôi',
              icon: const Icon(Icons.receipt_long_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
              ),
            ),
            const AccountMenu(),
          ],
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Tìm món ăn hoặc quán',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (_categories.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('Tất cả'),
                      selected: _categoryId == null,
                      onSelected: (_) => setState(() => _categoryId = null),
                    ),
                  ),
                  ..._categories.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c.name),
                        selected: _categoryId == c.id,
                        onSelected: (_) => setState(() => _categoryId = c.id),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: products.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 100),
                              Center(child: Text('Chưa có món ăn phù hợp.')),
                            ],
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: products.length,
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
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
                                  builder: (_) =>
                                      FoodDetailScreen(product: products[i]),
                                ),
                              ),
                              onAddToCart:
                                  products[i].isAvailable &&
                                      products[i].isShopOpen
                                  ? () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FoodDetailScreen(
                                          product: products[i],
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                  ),
          ),
          if (!_loading && _error == null && _products.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: {for (final p in _products) p.shopId: p.shopName}
                    .entries
                    .map(
                      (shop) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(shop.value),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RestaurantMenuScreen(
                                shopId: shop.key,
                                shopName: shop.value,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import 'seller_dashboard_screen.dart';

class ShopOrdersScreen extends StatelessWidget {
  const ShopOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return SellerDashboardScreen.live(
      key: ValueKey((user?.id, user?.shopId)),
      shopId: user?.shopId,
      shopName: user?.shopName,
    );
  }
}

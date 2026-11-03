import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../features/account/presentation/screens/profile_screen.dart';
import '../../features/orders/presentation/screens/my_orders_screen.dart';
import '../../features/wallet/presentation/screens/wallet_screen.dart';
import '../../features/restaurant/presentation/screens/merchant_products_screen.dart';

class AccountMenu extends StatelessWidget {
  final Future<void> Function()? beforeLogout;
  const AccountMenu({super.key, this.beforeLogout});
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      tooltip: 'Tài khoản',
      icon: const Icon(Icons.account_circle_outlined),
      onSelected: (value) async {
        if (value == 'logout') {
          await beforeLogout?.call();
          if (!context.mounted) return;
          await context.read<AuthProvider>().logout();
          if (context.mounted)
            Navigator.of(context).popUntil((route) => route.isFirst);
          return;
        }
        final Widget screen = switch (value) {
          'orders' => const MyOrdersScreen(),
          'wallet' => const WalletScreen(),
          'menu' => const MerchantProductsScreen(),
          _ => const ProfileScreen(),
        };
        if (context.mounted)
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          );
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Text(user.fullName ?? user.username),
        ),
        const PopupMenuItem(value: 'profile', child: Text('Tài khoản')),
        if (!user.isSeller && !user.isShipper)
          const PopupMenuItem(value: 'orders', child: Text('Đơn hàng của tôi')),
        if (user.isSeller)
          const PopupMenuItem(value: 'menu', child: Text('Quản lý menu')),
        if (user.isSeller || user.isShipper)
          const PopupMenuItem(value: 'wallet', child: Text('Ví và giao dịch')),
        const PopupMenuItem(value: 'logout', child: Text('Đăng xuất')),
      ],
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/showcase/design_system_showcase.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/auth/presentation/screens/pending_approval_screen.dart';
import 'features/restaurant/presentation/screens/shop_orders_screen.dart';
import 'features/shipper/presentation/screens/shipper_orders_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/theme_provider.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      try {
        await dotenv.load(fileName: '.env');
      } catch (_) {}

      // Bắt toàn bộ lỗi từ Flutter framework rendering
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint(
          'FLUTTER_FRAMEWORK_ERROR: ${details.exceptionAsString()}\n${details.stack}',
        );
      };

      runApp(const LangFoodApp());
    },
    (Object error, StackTrace stack) {
      debugPrint('UNCAUGHT_ASYNC_ZONE_ERROR: $error\n$stack');
    },
  );
}

class LangFoodApp extends StatelessWidget {
  const LangFoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (_) => CartProvider(),
          update: (_, auth, cart) {
            final provider = cart ?? CartProvider();
            provider.bindUser(auth.user?.id);
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routes: {'/showcase': (_) => const DesignSystemShowcase()},
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // If logged in, direct to appropriate dashboard based on role
    if (authProvider.isLoggedIn) {
      final user = authProvider.user;
      final isShipper =
          user?.isShipper == true ||
          user?.roleId == 3 ||
          user?.shipperId != null ||
          user?.username.toLowerCase() == 'shipper';
      final isShop = user?.isSeller == true || user?.roleId == 2;

      // Đối tác Chủ quán hoặc Shipper phải được Admin duyệt mới vào giao diện quản lý
      if ((isShipper || isShop) && user?.isApproved != true) {
        return const PendingApprovalScreen();
      }

      if (isShipper) {
        return const ShipperOrdersScreen();
      } else if (isShop) {
        return const ShopOrdersScreen();
      }
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}

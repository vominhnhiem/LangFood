import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_constants.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/shipper/presentation/screens/shipper_orders_screen.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Bắt toàn bộ lỗi từ Flutter framework rendering
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('=== [FLUTTER FRAMEWORK ERROR] ===');
      debugPrint(details.exceptionAsString());
      debugPrint(details.stack.toString());
    };

    runApp(const LangFoodApp());
  }, (error, stackTrace) {
    debugPrint('=== [UNCAUGHT ASYNC / RUNTIME ERROR] ===');
    debugPrint(error.toString());
    debugPrint(stackTrace.toString());
  });
}

class LangFoodApp extends StatelessWidget {
  const LangFoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            surface: AppColors.surface,
          ),
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // If already logged in from SharedPreferences, direct to appropriate screen
    if (authProvider.isLoggedIn) {
      final user = authProvider.user;
      final isShipper = user?.roleId == 3 || user?.shipperId != null || user?.username.toLowerCase() == 'shipper';
      if (isShipper) {
        return const ShipperOrdersScreen();
      }
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}

import 'package:flutter/material.dart';
import '../models/user.dart';
import '../screens/admin/admin_home.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/common/splash_screen.dart';
import '../screens/common/welcome_screen.dart';
import '../screens/customer/customer_home.dart';
import '../screens/supplier/supplier_home.dart';
import 'route_names.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final builders = <String, WidgetBuilder>{
      RouteNames.splash: (_) => const SplashScreen(),
      RouteNames.welcome: (_) => const WelcomeScreen(),
      RouteNames.login: (_) => const LoginScreen(),
      RouteNames.register: (_) => const RegisterScreen(),
      RouteNames.adminHome: (_) => const AdminHome(),
      RouteNames.supplierHome: (_) => const SupplierHome(),
      RouteNames.customerHome: (_) => const CustomerHome(),
    };

    final builder = builders[settings.name];
    if (builder == null) {
      return MaterialPageRoute(
        builder: (_) => Scaffold(body: Center(child: Text("No route defined for ${settings.name}"))),
      );
    }
    return MaterialPageRoute(builder: builder, settings: settings);
  }

  /// The dashboard route a logged-in user should land on, based on role.
  static String homeRouteFor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return RouteNames.adminHome;
      case UserRole.supplier:
        return RouteNames.supplierHome;
      case UserRole.customer:
        return RouteNames.customerHome;
    }
  }
}

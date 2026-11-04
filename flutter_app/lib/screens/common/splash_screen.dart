import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../routing/app_router.dart';
import '../../routing/route_names.dart';

/// Shown once on launch while we check for a stored session, then routes
/// straight into the right dashboard (auto-login) or the Welcome screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 700),
  )..forward();
  late final Animation<double> _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<double> _scale = Tween(begin: 0.85, end: 1.0)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decideNextRoute());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _decideNextRoute() async {
    final auth = context.read<AuthProvider>();
    final loggedIn = await auth.tryAutoLogin();
    await Future.delayed(const Duration(milliseconds: 500)); // let the entrance animation land
    if (!mounted) return;
    final nextRoute = loggedIn ? AppRouter.homeRouteFor(auth.user!.role) : RouteNames.welcome;
    Navigator.of(context).pushReplacementNamed(nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.hero),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96, height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.build_circle_outlined, size: 52, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    AppConstants.appName,
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    AppConstants.tagline,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 40),
                  const SizedBox(
                    width: 26, height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

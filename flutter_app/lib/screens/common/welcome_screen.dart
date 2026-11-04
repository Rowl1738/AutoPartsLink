import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../routing/route_names.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Decorative background shapes for visual interest.
          Positioned(
            top: -60, right: -60,
            child: _decorCircle(160, Colors.white.withValues(alpha: 0.08)),
          ),
          Positioned(
            top: 90, left: -40,
            child: _decorCircle(90, Colors.white.withValues(alpha: 0.06)),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100, height: 100,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.build_circle_outlined, color: Colors.white, size: 56),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          AppConstants.appName,
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.3),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          AppConstants.tagline,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Get started",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Request parts, compare quotes and track orders all in one place.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pushNamed(RouteNames.login),
                          child: const Text("Log In"),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pushNamed(RouteNames.register),
                          child: const Text("Create an Account"),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorCircle(double size, Color color) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

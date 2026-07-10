import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";

import "../../../core/theme/app_theme.dart";

/// Animated splash shown while the session bootstraps (router redirects
/// away the moment auth state resolves).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset("assets/images/shayrelogo.png", width: 132)
                .animate()
                .fadeIn(duration: 450.ms)
                .scale(begin: const Offset(.85, .85), curve: Curves.easeOutBack),
            const SizedBox(height: 20),
            Text(
              "Shared rides. Split fares.",
              style: TextStyle(color: Colors.white.withOpacity(.75), fontSize: 15),
            ).animate(delay: 250.ms).fadeIn(duration: 400.ms).moveY(begin: 8),
            const SizedBox(height: 36),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                  strokeWidth: 2.4, color: AppColors.brand),
            ).animate(delay: 500.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}

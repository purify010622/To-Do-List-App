import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Engaging splash screen with creative animations
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to home after animation completes
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon with scale and rotation animation
            Icon(
              Icons.check_circle,
              size: 120,
              color: Colors.white,
            )
                .animate()
                .scale(
                  duration: 800.ms,
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  curve: Curves.elasticOut,
                )
                .then()
                .shimmer(
                  duration: 1000.ms,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
            const SizedBox(height: 32),
            // App name with fade and slide animation
            Text(
              'Todo App',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 400.ms)
                .slideY(
                  begin: 0.5,
                  end: 0,
                  duration: 600.ms,
                  delay: 400.ms,
                  curve: Curves.easeOut,
                ),
            const SizedBox(height: 16),
            // Tagline with fade animation
            Text(
              'Organize your life, one task at a time',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 800.ms)
                .slideY(
                  begin: 0.3,
                  end: 0,
                  duration: 600.ms,
                  delay: 800.ms,
                  curve: Curves.easeOut,
                ),
            const SizedBox(height: 48),
            // Loading indicator
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withValues(alpha: 0.8),
                ),
                strokeWidth: 3,
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 1200.ms)
                .scale(
                  duration: 400.ms,
                  delay: 1200.ms,
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1, 1),
                ),
          ],
        ),
      ),
    );
  }
}

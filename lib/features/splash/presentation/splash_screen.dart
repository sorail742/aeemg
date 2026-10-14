import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _starsController;

  final List<_Star> _stars = [];

  @override
  void initState() {
    super.initState();

    // Create random stars
    final random = math.Random();
    for (int i = 0; i < 50; i++) {
      _stars.add(
        _Star(
          x: random.nextDouble(),
          y: random.nextDouble() * 0.7, // Stars only in the top 70% of screen
          size: random.nextDouble() * 2 + 1,
          blinkOffset: random.nextDouble(),
        ),
      );
    }

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    _starsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Navigate to home after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        context.go('/home');
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _starsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A), // Dark night sky
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF040B16), // Deep deep blue
                  Color(0xFF0D1B2A), // Deep blue
                  Color(0xFF1B3644), // Teal-ish blue near horizon
                ],
              ),
            ),
          ),

          // Animated Stars
          AnimatedBuilder(
            animation: _starsController,
            builder: (context, child) {
              return CustomPaint(
                painter: _StarsPainter(_stars, _starsController.value),
                size: Size.infinite,
              );
            },
          ),

          // Mosque Silhouette (Bottom)
          Align(
            alignment: Alignment.bottomCenter,
            child: Opacity(
              opacity: 0.15,
              child: Icon(
                Icons.mosque,
                size: MediaQuery.sizeOf(context).width,
                color: AppColors.white,
              ),
            ),
          ),

          // Center Content (Logo)
          Center(
            child: FadeTransition(
              opacity: _fadeController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brightGreen.withValues(alpha: 0.2),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(90),
                      child: Image.asset(
                        'assets/images/aeemg_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Placeholder if the logo isn't there yet
                          return Container(
                            color: AppColors.white,
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Text (Meaning of AEEMG)
          Align(
            alignment: Alignment.bottomCenter,
            child: FadeTransition(
              opacity: _fadeController,
              child: const Padding(
                padding: EdgeInsets.only(bottom: 40, left: 20, right: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'A E E M G',
                      style: TextStyle(
                        color: AppColors.brightGreen,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Association des Élèves et Étudiants\nMusulmans de Guinée',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Star {
  final double x;
  final double y;
  final double size;
  final double blinkOffset;

  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.blinkOffset,
  });
}

class _StarsPainter extends CustomPainter {
  final List<_Star> stars;
  final double animationValue;

  _StarsPainter(this.stars, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.white;

    for (var star in stars) {
      // Calculate individual blink using offset
      final blink =
          (math.sin((animationValue + star.blinkOffset) * math.pi * 2) + 1) / 2;
      paint.color = AppColors.white.withValues(alpha: 0.3 + (blink * 0.7));

      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarsPainter oldDelegate) =>
      animationValue != oldDelegate.animationValue;
}

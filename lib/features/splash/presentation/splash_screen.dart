import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/ds/islamic_background.dart';

/// Écran d'ouverture (v3) : ciel étoilé, logo cerclé d'or, barre de chargement.
/// Court (2,2 s) ; presque immédiat quand les animations sont réduites.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const duration = Duration(milliseconds: 2200);
  static const reducedDuration = Duration(milliseconds: 600);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: SplashScreen.duration,
  );
  Timer? _timer;

  // Graine fixe : le même ciel à chaque ouverture.
  late final List<_Star> _stars = _Star.sky(math.Random(7), 36);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer != null) return;
    final reduced = AppMotion.reduced(context);
    if (reduced) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
    _timer = Timer(
      reduced ? SplashScreen.reducedDuration : SplashScreen.duration,
      () {
        if (mounted) context.go('/home');
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appear = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.45, curve: AppMotion.standard),
    );
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IslamicBackground(
        withPattern: true,
        child: Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(painter: _StarsPainter(_stars, _controller)),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: ExcludeSemantics(
                child: Icon(
                  Icons.mosque,
                  size: width * 0.7,
                  color: AppColors.emerald.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned.fill(
              child: SafeArea(
                child: FadeTransition(
                  opacity: appear,
                  child: Column(
                    children: [
                      const Spacer(),
                      ScaleTransition(
                        scale: Tween(begin: 0.88, end: 1.0).animate(appear),
                        child: const _Logo(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'A E E M G',
                        style: AppTypography.h1.copyWith(
                          color: AppColors.brightGreen,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Association des Élèves et Étudiants\n'
                        'Musulmans de Guinée',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall,
                      ),
                      const Spacer(),
                      _LoadingBar(progress: _controller),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  static const double _size = 132;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.4),
            blurRadius: 48,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/aeemg_logo.png',
          fit: BoxFit.cover,
          cacheWidth: (_size * MediaQuery.devicePixelRatioOf(context)).round(),
          semanticLabel: 'Logo AEEMG',
          errorBuilder: (_, _, _) => const ColoredBox(
            color: AppColors.darkTeal,
            child: Icon(Icons.mosque_rounded, color: AppColors.gold, size: 48),
          ),
        ),
      ),
    );
  }
}

/// Fine barre en dégradé qui se remplit pendant l'ouverture.
class _LoadingBar extends StatelessWidget {
  const _LoadingBar({required this.progress});

  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Chargement',
      child: ClipRRect(
        borderRadius: AppRadius.pillBorder,
        child: SizedBox(
          width: 120,
          height: 4,
          child: ColoredBox(
            color: AppColors.cardSurfaceLight,
            child: AnimatedBuilder(
              animation: progress,
              builder: (context, _) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.value,
                child: const DecoratedBox(
                  decoration: BoxDecoration(gradient: AppGradients.primary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Star {
  const _Star(this.x, this.y, this.radius, this.phase);

  /// Étoiles dans les 70 % hauts de l'écran (au-dessus de la mosquée).
  static List<_Star> sky(math.Random random, int count) => [
    for (var i = 0; i < count; i++)
      _Star(
        random.nextDouble(),
        random.nextDouble() * 0.7,
        random.nextDouble() * 1.4 + 0.6,
        random.nextDouble(),
      ),
  ];

  final double x;
  final double y;
  final double radius;
  final double phase;
}

/// Étoiles qui scintillent : repeint par l'animation, sans reconstruire les widgets.
class _StarsPainter extends CustomPainter {
  _StarsPainter(this.stars, this.animation) : super(repaint: animation);

  final List<_Star> stars;
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final star in stars) {
      final blink =
          (math.sin((animation.value * 2 + star.phase) * math.pi * 2) + 1) / 2;
      paint.color = AppColors.white.withValues(alpha: 0.2 + blink * 0.6);
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarsPainter oldDelegate) => stars != oldDelegate.stars;
}

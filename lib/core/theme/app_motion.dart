import 'package:flutter/widgets.dart';

/// Mouvement (design system v3) : des animations courtes, qui guident sans ralentir.
/// Toute animation décorative est coupée quand le système demande de réduire les
/// animations (accessibilité, `MediaQuery.disableAnimations`).
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  /// Décalage entre deux éléments d'une liste qui apparaissent l'un après l'autre.
  static const Duration stagger = Duration(milliseconds: 45);

  /// Au-delà, les éléments apparaissent ensemble : une longue liste ne doit pas « traîner ».
  static const int maxStaggered = 8;

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutBack;

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Dégradés du design system v3. Peu nombreux et toujours sombres : la couleur sert à
/// guider l'œil (action, mise en avant), jamais à décorer pour décorer.
abstract final class AppGradients {
  /// Bouton principal : émeraude lumineux vers émeraude profond.
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brightGreen, AppColors.emerald, AppColors.emeraldHover],
  );

  /// Bandeau d'en-tête (accueil, écrans de section).
  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.heroStart, AppColors.darkTeal, AppColors.heroEnd],
    stops: [0, 0.55, 1],
  );

  /// Mise en avant dorée (contenus islamiques, distinctions).
  static const LinearGradient gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.goldLight, AppColors.gold],
  );

  /// Surface des cartes : un léger reflet en haut donne du relief sans ombre.
  static const LinearGradient surface = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.surfaceTop, AppColors.cardSurface],
  );

  /// Halo émeraude en haut de chaque écran.
  static const RadialGradient glow = RadialGradient(
    center: Alignment(-0.9, -1.15),
    radius: 1.25,
    colors: [AppColors.glow, AppColors.transparent],
  );
}

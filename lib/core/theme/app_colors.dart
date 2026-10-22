import 'package:flutter/material.dart';

/// Palette AEEMG — sombre, sobre, une seule couleur d'action (émeraude) et un accent
/// (or) réservé aux contenus islamiques et aux mises en avant. Contrastes vérifiés
/// WCAG AA : texte principal 15:1, secondaire 7:1, texte sur émeraude 8:1.
abstract final class AppColors {
  // ── Fonds ────────────────────────────────────────────────
  static const Color deepNavy = Color(0xFF0B1220); // Fond d'écran
  static const Color darkCharcoal = Color(0xFF0F1729); // Bas du dégradé de fond
  static const Color darkTeal = Color(0xFF0B3B2E); // Surfaces teintées émeraude

  // ── Surfaces ─────────────────────────────────────────────
  static const Color cardSurface = Color(
    0xFF131C2E,
  ); // Cartes, champs, feuilles
  static const Color cardSurfaceLight = Color(
    0xFF1E2A40,
  ); // Surface surélevée, survol
  static const Color border = Color(
    0xFF243149,
  ); // Bordures fines et séparateurs
  static const Color surfaceTop = Color(
    0xFF172239,
  ); // Reflet en haut des cartes (v3)

  // ── Dégradés et halos (v3) ───────────────────────────────
  static const Color heroStart = Color(0xFF0F5C47);
  static const Color heroEnd = Color(0xFF0D1E33);
  static const Color glow = Color(0x2410B981); // Halo émeraude du fond (14 %)

  // ── Action ───────────────────────────────────────────────
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldHover = Color(0xFF059669);
  static const Color emeraldActive = Color(0xFF047857);
  static const Color brightGreen = Color(0xFF34D399);
  static const Color lightEmerald = Color(0xFFA7F3D0);

  // ── Accent ───────────────────────────────────────────────
  static const Color gold = Color(0xFFE2B044);
  static const Color goldLight = Color(0xFFF2CF7A);

  // ── Textes ───────────────────────────────────────────────
  static const Color white = Color(0xFFF1F5F9);
  static const Color black = Color(0xFF0B1220);
  static const Color textSecondary = Color(0xFFA3B0C2);
  static const Color textTertiary = Color(0xFF6E7C91);

  // ── Sémantique ───────────────────────────────────────────
  static const Color error = Color(0xFFF26D6D);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF0A93B);
  static const Color info = Color(0xFF5BA8F5);
  static const Color focusRing = Color(0x8010B981);

  /// Teinte d'accent secondaire (raccourci Dons, catégories) — v3.
  static const Color violet = Color(0xFFC4B5FD);

  // ── Utilitaires ──────────────────────────────────────────
  // Seul fichier autorisé à utiliser `Colors.` de Material (contrôle design-tokens, AMEL-022).
  static const Color transparent = Color(0x00000000);

  /// Voile sombre sous les médias, superpositions et ombres (`scrim.withValues(alpha: …)`).
  static const Color scrim = Color(0xFF000000);

  /// Couleurs des noms d'expéditeurs dans les groupes (lisibles sur fond sombre).
  static const List<Color> avatarPalette = [
    Color(0xFF6EE7B7),
    Color(0xFF93C5FD),
    Color(0xFFFCD34D),
    Color(0xFFF9A8D4),
    Color(0xFFC4B5FD),
    Color(0xFFFDBA74),
    Color(0xFF67E8F9),
    Color(0xFFBEF264),
  ];

  // ── Alias de compatibilité ───────────────────────────────
  static const Color primary = emerald;
  static const Color primaryLight = brightGreen;
  static const Color primaryDark = emeraldHover;
  static const Color onPrimary = deepNavy;
  static const Color accent = gold;

  static const Color background = deepNavy;
  static const Color surface = cardSurface;
  static const Color textPrimary = white;

  static const Color warmGray = textSecondary;
  static const Color mediumGray = textSecondary;
  static const Color lightGray = textTertiary;
  static const Color inputBorder = border;
  static const Color offWhite = white;
  static const Color softMint = lightEmerald;

  static const Color scaffold = deepNavy;
  static const Color navBar = Color(0xFF0E1626);
  static const Color appBar = deepNavy;
}

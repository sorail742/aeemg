import 'package:flutter/material.dart';

/// Palette Premium Islamique — Thème AEEMG
abstract final class AppColors {
  // ── Fonds Premium ──────────────────────────────────────────
  static const Color darkCharcoal = Color(0xFF0F172A); // Slate profond
  static const Color deepNavy = Color(0xFF020617);     // Fond d'écran principal très sombre
  static const Color darkTeal = Color(0xFF064E3B);     // Vert émeraude très profond (Header)
  
  // ── Cartes et Surfaces (Glassmorphism) ────────────────────
  static const Color cardSurface = Color(0xFF1E293B);  // Couleur des cartes
  static const Color cardSurfaceLight = Color(0xFF334155); // Bordures ou survol
  
  // ── Accents & Identité ─────────────────────────────────────
  static const Color emerald = Color(0xFF10B981);      // Vert Islamique moderne et vibrant
  static const Color emeraldHover = Color(0xFF059669);
  static const Color emeraldActive = Color(0xFF047857);
  static const Color brightGreen = Color(0xFF34D399);  // Vert clair pour icônes
  static const Color lightEmerald = Color(0xFFA7F3D0); 
  
  static const Color gold = Color(0xFFF59E0B);         // Or riche (Etoiles, icônes premium)
  static const Color goldLight = Color(0xFFFCD34D);

  // ── Textes ────────────────────────────────────────────────
  static const Color white = Color(0xFFF8FAFC);
  static const Color black = Color(0xFF020617);
  static const Color textSecondary = Color(0xFF94A3B8); // Gris bleuté élégant
  static const Color textTertiary = Color(0xFF64748B);

  // ── Sémantique ────────────────────────────────────────────
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color focusRing = Color(0x8010B981);

  // ── Alias de compatibilité ────────────────────────────────
  static const Color primary = emerald;
  static const Color primaryLight = brightGreen;
  static const Color primaryDark = emeraldHover;
  static const Color accent = gold;
  
  static const Color background = deepNavy;
  static const Color surface = cardSurface;
  static const Color textPrimary = white;
  
  // Compatibilité avec les anciens écrans
  static const Color warmGray = textSecondary;
  static const Color mediumGray = textSecondary;
  static const Color lightGray = textTertiary;
  static const Color inputBorder = cardSurfaceLight;
  static const Color offWhite = white;
  static const Color softMint = lightEmerald;
  
  static const Color scaffold = deepNavy;
  static const Color navBar = Color(0xFF0F172A);
  static const Color appBar = Color(0xFF0F172A);
}

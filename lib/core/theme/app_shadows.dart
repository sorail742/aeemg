import 'package:flutter/material.dart';

/// Sur fond sombre, la profondeur passe par les surfaces et les bordures : les ombres
/// restent discrètes et réservées aux éléments flottants.
abstract final class AppShadows {
  static const List<BoxShadow> card = [];

  static const List<BoxShadow> elevated = [
    BoxShadow(color: Color(0x66000000), offset: Offset(0, 8), blurRadius: 24),
  ];

  /// Halo sous le bouton principal et l'élément actif (v3).
  static const List<BoxShadow> glow = [
    BoxShadow(color: Color(0x5510B981), offset: Offset(0, 6), blurRadius: 18),
  ];

  /// Barre de navigation flottante.
  static const List<BoxShadow> floating = [
    BoxShadow(color: Color(0x80000000), offset: Offset(0, 10), blurRadius: 30),
  ];

  static const List<BoxShadow> focusRing = [
    BoxShadow(color: Color(0x8010B981), blurRadius: 0, spreadRadius: 3),
  ];
}

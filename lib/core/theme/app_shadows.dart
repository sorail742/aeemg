import 'package:flutter/material.dart';

/// Sur fond sombre, la profondeur passe par les surfaces et les bordures : les ombres
/// restent discrètes et réservées aux éléments flottants.
abstract final class AppShadows {
  static const List<BoxShadow> card = [];

  static const List<BoxShadow> elevated = [
    BoxShadow(color: Color(0x66000000), offset: Offset(0, 8), blurRadius: 24),
  ];

  static const List<BoxShadow> focusRing = [
    BoxShadow(color: Color(0x8010B981), blurRadius: 0, spreadRadius: 3),
  ];
}

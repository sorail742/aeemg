import 'package:flutter/material.dart';

/// Rayons : 12 pour les éléments interactifs (champs, boutons), 16 pour les cartes.
abstract final class AppRadius {
  static const double subtle = 2;
  static const double small = 6;
  static const double medium = 12;
  static const double large = 16;
  static const double card = 16;
  static const double input = 12;
  static const double pill = 9999;

  static BorderRadius get cardBorder => BorderRadius.circular(card);
  static BorderRadius get inputBorder => BorderRadius.circular(input);
  static BorderRadius get pillBorder => BorderRadius.circular(pill);
}

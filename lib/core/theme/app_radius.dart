import 'package:flutter/material.dart';

abstract final class AppRadius {
  static const double subtle = 2;
  static const double small = 4;
  static const double medium = 12;
  static const double large = 16;
  static const double card = 20;
  static const double input = 30;
  static const double pill = 9999;

  static BorderRadius get cardBorder => BorderRadius.circular(card);
  static BorderRadius get inputBorder => BorderRadius.circular(input);
  static BorderRadius get pillBorder => BorderRadius.circular(pill);
}

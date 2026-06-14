import 'package:flutter/material.dart';

abstract final class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(2, 4),
      blurRadius: 20,
    ),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x1F000000),
      offset: Offset(0, 10),
      blurRadius: 32,
    ),
  ];

  static const List<BoxShadow> focusRing = [
    BoxShadow(
      color: Color(0x8000D881),
      blurRadius: 0,
      spreadRadius: 3,
    ),
  ];
}

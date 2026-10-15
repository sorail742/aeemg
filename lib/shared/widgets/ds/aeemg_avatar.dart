import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Avatar à initiales (v3) : couleur stable dérivée du nom (même personne, même couleur
/// partout), anneau fin et image facultative.
class AeemgAvatar extends StatelessWidget {
  const AeemgAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40,
  });

  final String name;
  final String? imageUrl;
  final double size;

  static Color colorFor(String name) {
    final hash = name.codeUnits.fold<int>(
      0,
      (h, c) => (h * 31 + c) & 0x7fffffff,
    );
    return AppColors.avatarPalette[hash % AppColors.avatarPalette.length];
  }

  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }

  @override
  Widget build(BuildContext context) {
    final tint = colorFor(name);
    final url = imageUrl;
    return Semantics(
      image: true,
      label: name,
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: tint.withValues(alpha: 0.55), width: 1.5),
        ),
        child: ClipOval(
          child: url != null && url.isNotEmpty
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _Initials(name: name, tint: tint),
                )
              : _Initials(name: name, tint: tint),
        ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.name, required this.tint});

  final String name;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: tint.withValues(alpha: 0.18),
      child: Center(
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Text(
              AeemgAvatar.initialsOf(name),
              style: AppTypography.h4.copyWith(color: tint),
            ),
          ),
        ),
      ),
    );
  }
}

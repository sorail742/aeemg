import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/quran_models.dart';

class AyahTile extends StatelessWidget {
  const AyahTile({
    super.key,
    required this.ayah,
    required this.showTranslation,
    required this.arabicFontSize,
    required this.isBookmarked,
    required this.onBookmarkToggle,
    this.onPlayAudio,
    this.isPlaying = false,
    this.showSurahLabel = false,
    this.surahNameFrench,
    this.onRecite,
  });

  final AyahInfo ayah;
  final bool showTranslation;
  final double arabicFontSize;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final VoidCallback? onPlayAudio;
  final bool isPlaying;
  final bool showSurahLabel;
  final String? surahNameFrench;
  final VoidCallback? onRecite;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isPlaying
            ? AppColors.emerald.withValues(alpha: 0.1)
            : AppColors.cardSurface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPlaying
              ? AppColors.emerald.withValues(alpha: 0.5)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AyahBadge(number: ayah.ayahNumber),
              const Spacer(),
              if (onPlayAudio != null)
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_circle : Icons.play_circle_outline,
                    color: isPlaying
                        ? AppColors.emerald
                        : AppColors.textTertiary,
                    size: 28,
                  ),
                  onPressed: onPlayAudio,
                  tooltip: 'Écouter',
                ),
              IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked ? AppColors.gold : AppColors.textTertiary,
                  size: 28,
                ),
                onPressed: onBookmarkToggle,
                tooltip: 'Signet',
              ),
              if (onRecite != null)
                IconButton(
                  icon: const Icon(
                    Icons.mic_none,
                    color: AppColors.emerald,
                    size: 28,
                  ),
                  onPressed: onRecite,
                  tooltip: 'Réciter',
                ),
            ],
          ),
          if (showSurahLabel && surahNameFrench != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$surahNameFrench · ${ayah.ayahNumber}',
              style: AppTypography.caption.copyWith(color: AppColors.emerald),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            ayah.arabic,
            style: AppTypography.quranArabic(
              size: arabicFontSize,
            ).copyWith(color: isPlaying ? AppColors.emerald : AppColors.white),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
          if (ayah.isSajdah) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.gold,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Verse de prosternation (Sajda)',
                  style: AppTypography.caption.copyWith(color: AppColors.gold),
                ),
              ],
            ),
          ],
          if (showTranslation) ...[
            const SizedBox(height: AppSpacing.lg),
            const Divider(color: AppColors.textTertiary, thickness: 0.3),
            const SizedBox(height: AppSpacing.md),
            Text(
              ayah.translation,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AyahBadge extends StatelessWidget {
  const _AyahBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.emerald.withValues(alpha: 0.3),
          width: 1.5,
        ),
        color: AppColors.emerald.withValues(alpha: 0.1),
      ),
      alignment: Alignment.center,
      child: Transform.rotate(
        angle: 0.785398, // 45 degrees
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.emerald.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Transform.rotate(
            angle: -0.785398,
            child: Text(
              '$number',
              style: AppTypography.h4.copyWith(color: AppColors.emerald),
            ),
          ),
        ),
      ),
    );
  }
}

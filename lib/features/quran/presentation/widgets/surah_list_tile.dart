import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ds/aeemg_card.dart';
import '../../data/models/quran_models.dart';

class SurahListTile extends StatelessWidget {
  const SurahListTile({
    super.key,
    required this.surah,
    required this.onTap,
  });

  final SurahInfo surah;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AeemgCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.smMd),
        child: Row(
          children: [
            // Ornement style rub el hizb / motif islamique pour le numéro
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(12),
                color: AppColors.emerald.withValues(alpha: 0.15),
                border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4)),
              ),
              alignment: Alignment.center,
              child: Transform.rotate(
                angle: 0.785398, // 45 degrees
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
                  ),
                  alignment: Alignment.center,
                  child: Transform.rotate(
                    angle: -0.785398,
                    child: Text(
                      '${surah.number}',
                      style: AppTypography.h4.copyWith(color: AppColors.emerald),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(surah.nameFrench, style: AppTypography.h3),
                  const SizedBox(height: 2),
                  Text(
                    '${surah.revelationLabel} · ${surah.verseCount} versets',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            Text(
              surah.nameArabic,
              style: AppTypography.quranArabic(size: 24).copyWith(color: AppColors.gold),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}

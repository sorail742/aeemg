import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/supabase_errors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/ds/aeemg_buttons.dart';
import '../../../shared/widgets/ds/aeemg_card.dart';
import '../../../shared/widgets/ds/aeemg_section.dart';
import '../../../shared/widgets/ds/islamic_background.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/mosque_repository.dart';

final mosqueRepositoryProvider = Provider<MosqueRepository>((ref) {
  return MosqueRepository(ref.watch(supabaseClientProvider));
});

final mosqueNeedsProvider = FutureProvider((ref) async {
  return ref.read(mosqueRepositoryProvider).fetchNeeds();
});

class MosqueScreen extends ConsumerWidget {
  const MosqueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needsAsync = ref.watch(mosqueNeedsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Espace islamique')),
      body: IslamicBackground(
        withPattern: true,
        child: SafeArea(
          top: false,
          child: RefreshIndicator(
            color: AppColors.emerald,
            backgroundColor: AppColors.cardSurface,
            onRefresh: () async => ref.invalidate(mosqueNeedsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.md,
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Text('Découvrez votre religion', style: AppTypography.h1),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Outils, ressources et suivi spirituel au quotidien.',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.smMd,
                  crossAxisSpacing: AppSpacing.smMd,
                  childAspectRatio: 1.3,
                  children: [
                    _FeatureCard(
                      title: 'Coran',
                      subtitle: 'Lecture et audio',
                      icon: Icons.menu_book_outlined,
                      onTap: () => context.push('/quran'),
                    ),
                    _FeatureCard(
                      title: 'Quiz',
                      subtitle: 'Testez vos acquis',
                      icon: Icons.quiz_outlined,
                      onTap: () => context.push('/islamic/quiz'),
                    ),
                    _FeatureCard(
                      title: 'Suivi spirituel',
                      subtitle: 'Prières et jeûnes',
                      icon: Icons.insights_outlined,
                      onTap: () => context.push('/islamic/tracking'),
                    ),
                    _FeatureCard(
                      title: 'Hadiths',
                      subtitle: 'Classés par thèmes',
                      icon: Icons.collections_bookmark_outlined,
                      onTap: () => context.push('/hadith'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                AeemgCard(
                  onTap: () => context.push('/islamic'),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_stories_outlined,
                          color: AppColors.brightGreen,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Rappels islamiques', style: AppTypography.h4),
                            const SizedBox(height: 4),
                            Text(
                              'Invocations, adhkar et méditations',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const AeemgSectionHeader(title: 'Besoins de la mosquée'),
                needsAsync.when(
                  loading: () => const LinearProgressIndicator(minHeight: 2),
                  error: (e, _) => AeemgEmptyState(
                    compact: true,
                    icon: Icons.cloud_off_outlined,
                    title: 'Besoins indisponibles',
                    message: friendlySupabaseError(e),
                  ),
                  data: (needs) {
                    if (needs.isEmpty) {
                      return const AeemgEmptyState(
                        compact: true,
                        icon: Icons.handshake_outlined,
                        title: 'Aucun besoin signalé',
                        message:
                            'Les besoins matériels de la mosquée apparaîtront ici.',
                      );
                    }
                    return Column(
                      children: needs.asMap().entries.map((entry) {
                        final need = entry.value;
                        final progress = need.quantityNeeded > 0
                            ? need.quantityFulfilled / need.quantityNeeded
                            : 0.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: AeemgCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.handshake_outlined,
                                      color: AppColors.gold,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        need.title,
                                        style: AppTypography.h4,
                                      ),
                                    ),
                                  ],
                                ),
                                if (need.description != null) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    need.description!,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Objectif',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                    Text(
                                      '${(progress * 100).toStringAsFixed(0)}%',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.emerald,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: progress.clamp(0, 1),
                                    minHeight: 6,
                                    color: AppColors.emerald,
                                    backgroundColor: AppColors.cardSurfaceLight,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  '${need.quantityFulfilled} / ${need.quantityNeeded} collecté(s)',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                AeemgPrimaryButton(
                  label: "S'inscrire comme bénévole",
                  icon: Icons.volunteer_activism,
                  onPressed: user == null
                      ? null
                      : () => _showVolunteerDialog(context, ref, user.id),
                ),
                if (user == null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Connectez-vous pour vous inscrire.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVolunteerDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) {
    final missionController = TextEditingController();
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bénévolat'),
        content: TextField(
          controller: missionController,
          decoration: const InputDecoration(
            labelText: 'Mission (ex. Iftar, vendredi)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              final mission = missionController.text.trim();
              if (mission.isEmpty) return;
              await ref
                  .read(mosqueRepositoryProvider)
                  .signUpVolunteer(userId: userId, mission: mission);
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Inscription enregistrée.')),
                );
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AeemgCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.brightGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.brightGreen, size: 22),
          ),
          const Spacer(),
          Text(
            title,
            style: AppTypography.h4,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

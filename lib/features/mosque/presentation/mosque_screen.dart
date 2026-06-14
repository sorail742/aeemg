import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/ds/aeemg_buttons.dart';
import '../../../shared/widgets/ds/aeemg_card.dart';
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
      appBar: AppBar(
        title: Text('Espace Islamique', style: AppTypography.h2.copyWith(color: AppColors.white)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: IslamicBackground(
        withPattern: true,
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.emerald,
            backgroundColor: AppColors.cardSurface,
            onRefresh: () async => ref.invalidate(mosqueNeedsProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.emerald, AppColors.gold.withValues(alpha: 0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [BoxShadow(color: AppColors.emerald.withValues(alpha: 0.3), blurRadius: 20)],
                    ),
                    child: const Icon(Icons.mosque, size: 48, color: AppColors.white),
                  ).animate().scale(curve: Curves.easeOutBack),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Découvrez votre religion',
                  textAlign: TextAlign.center,
                  style: AppTypography.h1.copyWith(fontSize: 26, color: AppColors.white),
                ).animate(delay: 100.ms).fade(),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Outils, ressources et suivi spirituel au quotidien.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ).animate(delay: 150.ms).fade(),
                const SizedBox(height: AppSpacing.xl),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.9,
                  children: [
                    _FeatureCard(
                      title: 'Coran Complet',
                      subtitle: 'Lecture & Audio',
                      icon: Icons.menu_book,
                      color: AppColors.gold,
                      delay: 200,
                      onTap: () => context.push('/quran'),
                    ),
                    _FeatureCard(
                      title: 'Quiz Islamique',
                      subtitle: 'Testez vos connaissances',
                      icon: Icons.quiz,
                      color: AppColors.brightGreen,
                      delay: 300,
                      onTap: () => context.push('/islamic/quiz'),
                    ),
                    _FeatureCard(
                      title: 'Suivi Spirituel',
                      subtitle: 'Prières & Jeûnes',
                      icon: Icons.track_changes,
                      color: const Color(0xFF0EA5E9), // Cyan
                      delay: 400,
                      onTap: () => context.push('/islamic/tracking'),
                    ),
                    _FeatureCard(
                      title: '99 Hadiths',
                      subtitle: 'Par thèmes',
                      icon: Icons.collections_bookmark,
                      color: AppColors.emerald,
                      delay: 500,
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
                        child: const Icon(Icons.auto_stories, color: AppColors.emerald),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Rappels Islamiques', style: AppTypography.h3),
                            const SizedBox(height: 4),
                            Text(
                              'Invocations, adhkar et méditations',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                    ],
                  ),
                ).animate(delay: 600.ms).fade().slideY(begin: 0.1),
                const SizedBox(height: AppSpacing.xl),
                Text('Mosquée AEEMG', style: AppTypography.h2).animate(delay: 700.ms).fade(),
                const SizedBox(height: AppSpacing.sm),
                needsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.emerald)),
                  error: (e, _) => Center(child: Text('Erreur : $e', style: const TextStyle(color: AppColors.error))),
                  data: (needs) {
                    if (needs.isEmpty) {
                      return AeemgCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Center(
                          child: Text('Aucun besoin signalé pour le moment.', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      ).animate(delay: 800.ms).fade();
                    }
                    return Column(
                      children: needs.asMap().entries.map((entry) {
                        final index = entry.key;
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
                                    const Icon(Icons.handshake, color: AppColors.gold, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(need.title, style: AppTypography.h3)),
                                  ],
                                ),
                                if (need.description != null) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(need.description!, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                                ],
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Objectif', style: AppTypography.caption.copyWith(color: AppColors.textTertiary)),
                                    Text(
                                      '${(progress * 100).toStringAsFixed(0)}%',
                                      style: AppTypography.caption.copyWith(color: AppColors.emerald, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: progress.clamp(0, 1),
                                    minHeight: 8,
                                    color: AppColors.emerald,
                                    backgroundColor: AppColors.cardSurfaceLight,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  '${need.quantityFulfilled} / ${need.quantityNeeded} collecté(s)',
                                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ).animate(delay: Duration(milliseconds: 800 + (index * 100))).fade().slideX(begin: 0.05),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                AeemgPrimaryButton(
                  label: "S'inscrire comme bénévole",
                  icon: Icons.volunteer_activism,
                  onPressed: user == null ? null : () => _showVolunteerDialog(context, ref, user.id),
                ).animate(delay: 1000.ms).fade(),
                if (user == null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Connectez-vous pour vous inscrire.',
                    style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVolunteerDialog(BuildContext context, WidgetRef ref, String userId) {
    final missionController = TextEditingController();
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: Row(
          children: [
            const Icon(Icons.volunteer_activism, color: AppColors.gold),
            const SizedBox(width: AppSpacing.sm),
            Text('Bénévolat', style: AppTypography.h3),
          ],
        ),
        content: TextField(
          controller: missionController,
          style: const TextStyle(color: AppColors.white),
          decoration: InputDecoration(
            labelText: 'Mission (ex. Iftar, vendredi)',
            labelStyle: TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.cardSurfaceLight.withValues(alpha: 0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.emerald.withValues(alpha: 0.5)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: AppColors.deepNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final mission = missionController.text.trim();
              if (mission.isEmpty) return;
              await ref.read(mosqueRepositoryProvider).signUpVolunteer(userId: userId, mission: mission);
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Inscription enregistrée !'),
                  backgroundColor: AppColors.emerald,
                ));
              }
            },
            child: const Text('Confirmer', style: TextStyle(fontWeight: FontWeight.bold)),
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
    required this.color,
    required this.onTap,
    required this.delay,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const Spacer(),
                Text(
                  title,
                  style: AppTypography.h3.copyWith(fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: delay.ms).fade().scale();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/supabase_errors.dart';
import '../../../../shared/widgets/ds/aeemg_card.dart';
import '../../../../shared/widgets/ds/aeemg_hero.dart';
import '../../../../shared/widgets/ds/aeemg_motion.dart';
import '../../../../shared/widgets/ds/aeemg_section.dart';
import '../../../../shared/widgets/ds/islamic_background.dart';
import '../data/models/quiz_model.dart';
import 'providers/quiz_provider.dart';

class QuizListScreen extends ConsumerWidget {
  const QuizListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizzesAsync = ref.watch(quizzesProvider);
    var index = 0;
    Widget item(Widget child) => child.reveal(context, index: index++);

    final List<Widget> content = quizzesAsync.when(
      loading: () => const [
        AeemgSkeletonTile(),
        SizedBox(height: AppSpacing.sm),
        AeemgSkeletonTile(),
      ],
      error: (error, _) => [
        AeemgEmptyState(
          compact: true,
          icon: Icons.cloud_off_outlined,
          title: 'Quiz indisponibles',
          message: friendlySupabaseError(error),
        ),
      ],
      data: (quizzes) {
        if (quizzes.isEmpty) {
          return const [
            AeemgEmptyState(
              compact: true,
              icon: Icons.quiz_outlined,
              title: 'Aucun quiz pour le moment',
              message: 'De nouveaux quiz seront bientôt proposés.',
            ),
          ];
        }
        final byCategory = <String, List<QuizModel>>{};
        for (final q in quizzes) {
          byCategory.putIfAbsent(q.category, () => []).add(q);
        }
        return [
          for (final entry in byCategory.entries) ...[
            item(AeemgSectionHeader(title: entry.key)),
            for (final quiz in entry.value)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: item(
                  _QuizCard(
                    quiz: quiz,
                    onTap: () {
                      ref.read(currentQuizProvider.notifier).startQuiz(quiz);
                      context.push('/islamic/quiz/play');
                    },
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ];
      },
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IslamicBackground(
        withPattern: true,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm + MediaQuery.paddingOf(context).top,
            AppSpacing.md,
            AppSpacing.xxl,
          ),
          children: [
            Row(
              children: [
                AeemgRoundIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Retour',
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/home'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.smMd),
            item(
              AeemgHero(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Quiz islamique', style: AppTypography.h1),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Testez et approfondissez vos connaissances.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.lightEmerald,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.emoji_events_rounded,
                      size: 52,
                      color: AppColors.goldLight,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...content,
          ],
        ),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({required this.quiz, required this.onTap});

  final QuizModel quiz;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AeemgCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.violet.withValues(alpha: 0.28),
                  AppColors.violet.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: Border.all(
                color: AppColors.violet.withValues(alpha: 0.35),
              ),
            ),
            child: const Icon(Icons.quiz_rounded, color: AppColors.violet),
          ),
          const SizedBox(width: AppSpacing.smMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quiz.title, style: AppTypography.h4),
                const SizedBox(height: 2),
                Text(
                  quiz.description,
                  style: AppTypography.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${quiz.questions.length} questions',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              gradient: AppGradients.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: AppColors.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

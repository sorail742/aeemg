import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ds/aeemg_card.dart';
import '../../../../shared/widgets/ds/islamic_background.dart';
import 'providers/quiz_provider.dart';

class QuizListScreen extends ConsumerWidget {
  const QuizListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizzesAsync = ref.watch(quizzesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.9),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text('Quiz Islamique', style: AppTypography.h2.copyWith(color: AppColors.white)),
      ),
      body: IslamicBackground(
        withPattern: true,
        child: quizzesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.emerald)),
          error: (err, _) => Center(child: Text('Erreur : $err', style: const TextStyle(color: AppColors.error))),
          data: (quizzes) {
            if (quizzes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.textTertiary.withValues(alpha: 0.1),
                      ),
                      child: const Icon(Icons.quiz_outlined, size: 64, color: AppColors.textTertiary),
                    ).animate().scale(curve: Curves.easeOutBack),
                    const SizedBox(height: AppSpacing.md),
                    Text('Aucun quiz disponible pour le moment.', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              );
            }

            final Map<String, List> categorizedQuizzes = {};
            for (var q in quizzes) {
              categorizedQuizzes.putIfAbsent(q.category, () => []).add(q);
            }

            return ListView(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.xl,
              ),
              physics: const BouncingScrollPhysics(),
              children: categorizedQuizzes.entries.toList().asMap().entries.map((categoryEntry) {
                final catIndex = categoryEntry.key;
                final entry = categoryEntry.value;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(2)),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          entry.key.toUpperCase(),
                          style: AppTypography.h3.copyWith(color: AppColors.gold, letterSpacing: 1.2),
                        ),
                      ],
                    ).animate(delay: Duration(milliseconds: 100 * catIndex)).fade().slideX(),
                    const SizedBox(height: AppSpacing.md),
                    ...entry.value.asMap().entries.map((quizEntry) {
                      final qIndex = quizEntry.key;
                      final quiz = quizEntry.value;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: AeemgCard(
                          onTap: () {
                            ref.read(currentQuizProvider.notifier).startQuiz(quiz);
                            context.push('/islamic/quiz/play');
                          },
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.emerald.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.extension, color: AppColors.emerald),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(quiz.title, style: AppTypography.h3),
                                    const SizedBox(height: 4),
                                    Text(
                                      quiz.description,
                                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.gold.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${quiz.questions.length} questions',
                                        style: AppTypography.caption.copyWith(color: AppColors.gold, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.cardSurfaceLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.play_arrow_rounded, color: AppColors.white),
                              ),
                            ],
                          ),
                        ),
                      ).animate(delay: Duration(milliseconds: 100 * catIndex + 50 * qIndex)).fade().slideY(begin: 0.1);
                    }),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}

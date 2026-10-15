import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ds/aeemg_buttons.dart';
import '../../../../shared/widgets/ds/aeemg_card.dart';
import '../../../../shared/widgets/ds/islamic_background.dart';
import 'providers/quiz_provider.dart';

class QuizPlayScreen extends ConsumerWidget {
  const QuizPlayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentQuizProvider);
    final notifier = ref.read(currentQuizProvider.notifier);

    if (session.quiz == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.transparent),
        body: const Center(
          child: Text(
            'Aucun quiz sélectionné',
            style: TextStyle(color: AppColors.white),
          ),
        ),
      );
    }

    final quiz = session.quiz!;

    if (session.isFinished) {
      final scoreRatio = session.score / quiz.questions.length;
      final isExcellent = scoreRatio >= 0.8;

      return Scaffold(
        backgroundColor: AppColors.background,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: AppColors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.white),
          title: Text(
            quiz.title,
            style: AppTypography.h2.copyWith(color: AppColors.white),
          ),
        ),
        body: IslamicBackground(
          withPattern: true,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: AeemgCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xxl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            (isExcellent ? AppColors.gold : AppColors.emerald)
                                .withValues(alpha: 0.15),
                      ),
                      child: Icon(
                        isExcellent
                            ? Icons.emoji_events
                            : Icons.check_circle_outline,
                        size: 80,
                        color: isExcellent ? AppColors.gold : AppColors.emerald,
                      ),
                    ).animate().scale(
                      curve: Curves.easeOutBack,
                      duration: 600.ms,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      isExcellent ? 'Macha Allah !' : 'Alhamdulillah !',
                      style: AppTypography.h1.copyWith(
                        color: isExcellent ? AppColors.gold : AppColors.emerald,
                      ),
                    ).animate(delay: 200.ms).fade(),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Quiz Terminé',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ).animate(delay: 300.ms).fade(),
                    const SizedBox(height: AppSpacing.xl),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.emerald.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Score final :', style: AppTypography.body),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            '${session.score} / ${quiz.questions.length}',
                            style: AppTypography.h1.copyWith(
                              color: AppColors.emerald,
                            ),
                          ),
                        ],
                      ),
                    ).animate(delay: 400.ms).fade().slideY(),
                    const SizedBox(height: AppSpacing.xxl),
                    AeemgPrimaryButton(
                      label: 'Terminer',
                      icon: Icons.done_all,
                      onPressed: () => context.pop(),
                    ).animate(delay: 500.ms).fade().slideY(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final question = quiz.questions[session.currentQuestionIndex];
    final progress = (session.currentQuestionIndex + 1) / quiz.questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.9),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text(
          'Question ${session.currentQuestionIndex + 1}/${quiz.questions.length}',
          style: AppTypography.h2.copyWith(color: AppColors.gold),
        ),
        centerTitle: true,
      ),
      body: IslamicBackground(
        withPattern: true,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: AppColors.emerald.withValues(
                            alpha: 0.2,
                          ),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.emerald,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AeemgCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          question.question,
                          style: AppTypography.h2.copyWith(
                            fontSize: 20,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ).animate().fade().slideY(begin: -0.05),
                      const SizedBox(height: AppSpacing.xl),
                      ...List.generate(question.options.length, (index) {
                        final isSelected = session.selectedOptionIndex == index;
                        final isCorrect = index == question.correctOptionIndex;

                        Color bgColor = AppColors.cardSurface;
                        Color borderColor = AppColors.transparent;

                        if (session.isAnswered) {
                          if (isCorrect) {
                            bgColor = AppColors.emerald.withValues(alpha: 0.2);
                            borderColor = AppColors.emerald;
                          } else if (isSelected) {
                            bgColor = AppColors.error.withValues(alpha: 0.2);
                            borderColor = AppColors.error;
                          }
                        } else if (isSelected) {
                          borderColor = AppColors.gold;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child:
                              InkWell(
                                    onTap: session.isAnswered
                                        ? null
                                        : () => notifier.answerQuestion(index),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.all(
                                        AppSpacing.lg,
                                      ),
                                      decoration: BoxDecoration(
                                        color: bgColor,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: borderColor,
                                          width:
                                              isSelected ||
                                                  (session.isAnswered &&
                                                      isCorrect)
                                              ? 2
                                              : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color:
                                                  isSelected ||
                                                      (session.isAnswered &&
                                                          isCorrect)
                                                  ? borderColor.withValues(
                                                      alpha: 0.2,
                                                    )
                                                  : AppColors.cardSurfaceLight,
                                              border: Border.all(
                                                color:
                                                    isSelected ||
                                                        (session.isAnswered &&
                                                            isCorrect)
                                                    ? borderColor
                                                    : AppColors.textTertiary,
                                              ),
                                            ),
                                            child: Text(
                                              String.fromCharCode(
                                                65 + index,
                                              ), // A, B, C, D...
                                              style: TextStyle(
                                                color:
                                                    isSelected ||
                                                        (session.isAnswered &&
                                                            isCorrect)
                                                    ? borderColor
                                                    : AppColors.textSecondary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.md),
                                          Expanded(
                                            child: Text(
                                              question.options[index],
                                              style: AppTypography.body
                                                  .copyWith(
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.w500,
                                                    color: AppColors.white,
                                                  ),
                                            ),
                                          ),
                                          if (session.isAnswered && isCorrect)
                                            const Icon(
                                              Icons.check_circle,
                                              color: AppColors.emerald,
                                            ).animate().scale(),
                                          if (session.isAnswered &&
                                              isSelected &&
                                              !isCorrect)
                                            const Icon(
                                              Icons.cancel,
                                              color: AppColors.error,
                                            ).animate().scale(),
                                        ],
                                      ),
                                    ),
                                  )
                                  .animate(
                                    delay: Duration(
                                      milliseconds: 100 * index + 100,
                                    ),
                                  )
                                  .fade()
                                  .slideX(begin: 0.05),
                        );
                      }),
                      if (session.isAnswered) ...[
                        const SizedBox(height: AppSpacing.xl),
                        AeemgCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: AppColors.gold,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'Explication',
                                    style: AppTypography.h3.copyWith(
                                      color: AppColors.gold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                question.explanation,
                                style: AppTypography.bodySmall.copyWith(
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fade().slideY(begin: 0.1),
                      ],
                    ],
                  ),
                ),
              ),
              if (session.isAnswered)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AeemgPrimaryButton(
                    label:
                        session.currentQuestionIndex ==
                            quiz.questions.length - 1
                        ? 'Voir le résultat'
                        : 'Question suivante',
                    icon:
                        session.currentQuestionIndex ==
                            quiz.questions.length - 1
                        ? Icons.emoji_events
                        : Icons.arrow_forward,
                    onPressed: () => notifier.nextQuestion(),
                  ).animate().fade(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/ds/aeemg_buttons.dart';
import '../../../shared/widgets/ds/aeemg_card.dart';
import '../../../shared/widgets/ds/islamic_background.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _controller = TextEditingController();
  int _rating = 4;
  bool _isSending = false;

  final List<String> _ratingLabels = [
    '',
    'Mauvais',
    'Passable',
    'Bien',
    'Très bien',
    'Excellent !',
  ];
  final List<Color> _ratingColors = [
    AppColors.transparent,
    AppColors.error,
    AppColors.warning,
    AppColors.gold,
    AppColors.emerald,
    AppColors.brightGreen,
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;
    final client = ref.read(supabaseClientProvider);
    if (client == null) return;
    setState(() => _isSending = true);
    try {
      final user = ref.read(currentUserProvider);
      await client.from('feedback').insert({
        'user_id': user?.id,
        'message': message,
        'rating': _rating,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Merci pour votre retour !'),
            backgroundColor: AppColors.emerald,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratingColor = _ratingColors[_rating];

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.9),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text(
          'Retour beta',
          style: AppTypography.h2.copyWith(color: AppColors.white),
        ),
      ),
      body: IslamicBackground(
        withPattern: true,
        child: ListView(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.xl,
          ),
          physics: const BouncingScrollPhysics(),
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emerald.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppColors.emerald.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emerald.withValues(alpha: 0.2),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.feedback_outlined,
                  size: 48,
                  color: AppColors.emerald,
                ),
              ).animate().scale(curve: Curves.easeOutBack),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Aidez-nous à améliorer AEEMG',
              style: AppTypography.h2,
              textAlign: TextAlign.center,
            ).animate(delay: 100.ms).fade(),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Votre avis nous aide à construire une meilleure expérience.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ).animate(delay: 150.ms).fade(),
            const SizedBox(height: AppSpacing.xl),

            AeemgCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Note globale', style: AppTypography.h3),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final starIndex = i + 1;
                      return GestureDetector(
                        onTap: () => setState(() => _rating = starIndex),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child:
                              Icon(
                                    starIndex <= _rating
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    size: 40,
                                    color: starIndex <= _rating
                                        ? ratingColor
                                        : AppColors.textTertiary,
                                  )
                                  .animate(target: starIndex <= _rating ? 1 : 0)
                                  .scale(begin: const Offset(0.9, 0.9)),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Center(
                    child: Text(
                      _ratingLabels[_rating],
                      style: AppTypography.h3.copyWith(color: ratingColor),
                    ),
                  ),
                ],
              ),
            ).animate(delay: 200.ms).fade().slideY(begin: 0.1),
            const SizedBox(height: AppSpacing.lg),

            AeemgCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Votre message', style: AppTypography.h3),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _controller,
                    maxLines: 5,
                    style: const TextStyle(color: AppColors.white),
                    decoration: InputDecoration(
                      hintText:
                          'Ce qui fonctionne, ce qui manque, vos suggestions…',
                      hintStyle: TextStyle(color: AppColors.textTertiary),
                      filled: true,
                      fillColor: AppColors.cardSurfaceLight.withValues(
                        alpha: 0.5,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.emerald.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate(delay: 300.ms).fade().slideY(begin: 0.1),
            const SizedBox(height: AppSpacing.xl),

            AeemgPrimaryButton(
              label: 'Envoyer mon retour',
              icon: Icons.send,
              isLoading: _isSending,
              onPressed: _submit,
            ).animate(delay: 400.ms).fade().slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }
}

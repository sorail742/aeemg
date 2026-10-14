import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/calendar_export.dart';
import '../../../shared/widgets/ds/aeemg_buttons.dart';
import '../../../shared/widgets/ds/aeemg_card.dart';
import '../../../shared/widgets/ds/islamic_background.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/models/event.dart';
import 'providers/events_provider.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.event});

  final AeemgEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final locale = ref.watch(localeCodeProvider);
    final rsvpCountAsync = ref.watch(rsvpCountProvider(event.id));
    final dateFormat = DateFormat('EEEE d MMMM yyyy · HH:mm', 'fr');

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: IslamicBackground(
        withPattern: true,
        child: ListView(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight,
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.xl,
          ),
          physics: const BouncingScrollPhysics(),
          children: [
            Center(
              child:
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold.withValues(alpha: 0.15),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.event,
                      size: 64,
                      color: AppColors.gold,
                    ),
                  ).animate().fade().scale(
                    begin: const Offset(0.8, 0.8),
                    curve: Curves.easeOutBack,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.emerald.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  event.typeLabel.toUpperCase(),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.emerald,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ).animate(delay: 100.ms).fade().slideY(begin: 0.2),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              event.title,
              textAlign: TextAlign.center,
              style: AppTypography.h1.copyWith(color: AppColors.white),
            ).animate(delay: 200.ms).fade().slideY(begin: 0.1),
            const SizedBox(height: AppSpacing.xl),

            AeemgCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurfaceLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.schedule,
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date et Heure', style: AppTypography.caption),
                            Text(
                              dateFormat.format(event.startsAt),
                              style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (event.location != null) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Divider(
                        color: AppColors.textTertiary,
                        thickness: 0.3,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.cardSurfaceLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.place,
                            color: AppColors.emerald,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Lieu', style: AppTypography.caption),
                              Text(
                                event.location!,
                                style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ).animate(delay: 300.ms).fade().slideY(begin: 0.1),

            const SizedBox(height: AppSpacing.lg),

            if (event.description != null) ...[
              Text(
                'Description',
                style: AppTypography.h3,
              ).animate(delay: 400.ms).fade(),
              const SizedBox(height: AppSpacing.sm),
              Text(
                event.description!,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ).animate(delay: 450.ms).fade(),
              const SizedBox(height: AppSpacing.lg),
            ],

            rsvpCountAsync.when(
              data: (count) => Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardSurfaceLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.people_alt_outlined,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '$count participant(s) inscrit(s)',
                      style: AppTypography.body.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 500.ms).fade(),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),

            const SizedBox(height: AppSpacing.xl),

            AeemgPrimaryButton(
              onPressed: () async {
                final uri = Uri.parse(googleCalendarUrl(event));
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: Icons.event_available,
              label: AppStrings.t('add_calendar', locale),
            ).animate(delay: 600.ms).fade().slideY(begin: 0.1),

            const SizedBox(height: AppSpacing.lg),
            const Divider(color: AppColors.textTertiary, thickness: 0.3),
            const SizedBox(height: AppSpacing.lg),

            if (user != null) ...[
              Text(
                'Votre participation',
                style: AppTypography.h3,
                textAlign: TextAlign.center,
              ).animate(delay: 700.ms).fade(),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        await ref
                            .read(eventsRepositoryProvider)
                            .setRsvp(
                              eventId: event.id,
                              userId: user.id,
                              status: 'not_going',
                            );
                        ref.invalidate(rsvpCountProvider(event.id));
                      },
                      icon: const Icon(Icons.close),
                      label: const Text(
                        'Absent',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ).animate(delay: 800.ms).fade().slideX(begin: -0.1),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        foregroundColor: AppColors.deepNavy,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        await ref
                            .read(eventsRepositoryProvider)
                            .setRsvp(
                              eventId: event.id,
                              userId: user.id,
                              status: 'going',
                            );
                        ref.invalidate(rsvpCountProvider(event.id));
                      },
                      icon: const Icon(Icons.check),
                      label: const Text(
                        'Présent',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ).animate(delay: 800.ms).fade().slideX(begin: 0.1),
                  ),
                ],
              ),
            ] else
              Center(
                child: Text(
                  'Connectez-vous pour vous inscrire à cet événement.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ).animate(delay: 700.ms).fade(),
          ],
        ),
      ),
    );
  }
}

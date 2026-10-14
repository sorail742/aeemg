import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/ds/aeemg_card.dart';
import '../../../shared/widgets/ds/islamic_background.dart';
import '../data/tracking_repository.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  DateTime _selectedDate = DateTime.now();

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    // Normaliser la date (enlever l'heure)
    final dateKey = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final track = ref.watch(dailyTrackProvider(dateKey));
    final trackNotifier = ref.read(dailyTrackProvider(dateKey).notifier);
    final dateFormat = DateFormat('EEEE d MMMM yyyy', 'fr');

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.9),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text(
          'Suivi Spirituel',
          style: AppTypography.h2.copyWith(color: AppColors.white),
        ),
      ),
      body: IslamicBackground(
        withPattern: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.xl,
          ),
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Date Selector
              AeemgCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_left,
                        color: AppColors.emerald,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.emerald.withValues(
                          alpha: 0.1,
                        ),
                      ),
                      onPressed: _previousDay,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Aujourd\'hui' ==
                                        dateFormat
                                            .format(DateTime.now())
                                            .toLowerCase() &&
                                    dateKey ==
                                        DateTime(
                                          DateTime.now().year,
                                          DateTime.now().month,
                                          DateTime.now().day,
                                        )
                                ? 'Aujourd\'hui'
                                : '',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            dateFormat.format(_selectedDate).toUpperCase(),
                            textAlign: TextAlign.center,
                            style: AppTypography.h3.copyWith(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.chevron_right,
                        color:
                            _selectedDate.isBefore(
                              DateTime(
                                DateTime.now().year,
                                DateTime.now().month,
                                DateTime.now().day,
                              ),
                            )
                            ? AppColors.emerald
                            : AppColors.textTertiary,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            _selectedDate.isBefore(
                              DateTime(
                                DateTime.now().year,
                                DateTime.now().month,
                                DateTime.now().day,
                              ),
                            )
                            ? AppColors.emerald.withValues(alpha: 0.1)
                            : AppColors.transparent,
                      ),
                      onPressed:
                          _selectedDate.isBefore(
                            DateTime(
                              DateTime.now().year,
                              DateTime.now().month,
                              DateTime.now().day,
                            ),
                          )
                          ? _nextDay
                          : null,
                    ),
                  ],
                ),
              ).animate().fade().slideY(begin: -0.1),
              const SizedBox(height: AppSpacing.xl),

              // Prières
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const Icon(Icons.mosque, color: AppColors.gold, size: 24),
                    const SizedBox(width: AppSpacing.sm),
                    Text("Prières obligatoires", style: AppTypography.h2),
                  ],
                ),
              ).animate(delay: 100.ms).fade(),
              const SizedBox(height: AppSpacing.md),
              AeemgCard(
                child: Column(
                  children: [
                    _TrackingItem(
                      title: 'Fajr',
                      isDone: track.fajr,
                      onToggle: trackNotifier.toggleFajr,
                      icon: Icons.wb_twilight,
                    ),
                    const Divider(
                      color: AppColors.textTertiary,
                      thickness: 0.2,
                      height: 1,
                    ),
                    _TrackingItem(
                      title: 'Dhuhr',
                      isDone: track.dhuhr,
                      onToggle: trackNotifier.toggleDhuhr,
                      icon: Icons.wb_sunny,
                    ),
                    const Divider(
                      color: AppColors.textTertiary,
                      thickness: 0.2,
                      height: 1,
                    ),
                    _TrackingItem(
                      title: 'Asr',
                      isDone: track.asr,
                      onToggle: trackNotifier.toggleAsr,
                      icon: Icons.wb_sunny_outlined,
                    ),
                    const Divider(
                      color: AppColors.textTertiary,
                      thickness: 0.2,
                      height: 1,
                    ),
                    _TrackingItem(
                      title: 'Maghrib',
                      isDone: track.maghrib,
                      onToggle: trackNotifier.toggleMaghrib,
                      icon: Icons.nights_stay_outlined,
                    ),
                    const Divider(
                      color: AppColors.textTertiary,
                      thickness: 0.2,
                      height: 1,
                    ),
                    _TrackingItem(
                      title: 'Isha',
                      isDone: track.isha,
                      onToggle: trackNotifier.toggleIsha,
                      icon: Icons.nights_stay,
                    ),
                  ],
                ),
              ).animate(delay: 200.ms).fade().slideY(begin: 0.1),

              const SizedBox(height: AppSpacing.xl),

              // Jeûne
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const Icon(
                      Icons.restaurant_menu,
                      color: AppColors.emerald,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text("Jeûne", style: AppTypography.h2),
                  ],
                ),
              ).animate(delay: 300.ms).fade(),
              const SizedBox(height: AppSpacing.md),
              AeemgCard(
                child: _TrackingItem(
                  title: 'Avez-vous jeûné ce jour ?',
                  isDone: track.fasting,
                  onToggle: trackNotifier.toggleFasting,
                  icon: Icons.restaurant_outlined,
                  activeColor: AppColors.gold,
                ),
              ).animate(delay: 400.ms).fade().slideY(begin: 0.1),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackingItem extends StatelessWidget {
  final String title;
  final bool isDone;
  final VoidCallback onToggle;
  final IconData icon;
  final Color activeColor;

  const _TrackingItem({
    required this.title,
    required this.isDone,
    required this.onToggle,
    required this.icon,
    this.activeColor = AppColors.emerald,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDone
                    ? activeColor.withValues(alpha: 0.15)
                    : AppColors.cardSurfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDone ? activeColor : AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: AppTypography.h3.copyWith(
                  color: isDone ? AppColors.white : AppColors.textSecondary,
                  fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isDone)
              const Icon(
                Icons.check_circle,
                color: AppColors.emerald,
                size: 28,
              ).animate().scale(curve: Curves.easeOutBack, duration: 400.ms)
            else
              const Icon(
                Icons.radio_button_unchecked,
                color: AppColors.textTertiary,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}

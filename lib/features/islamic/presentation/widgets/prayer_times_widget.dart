import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ds/aeemg_card.dart';
import '../../../../core/services/adhan_service.dart';
import '../../data/prayer_repository.dart';

class PrayerTimesWidget extends ConsumerStatefulWidget {
  const PrayerTimesWidget({super.key});

  @override
  ConsumerState<PrayerTimesWidget> createState() => _PrayerTimesWidgetState();
}

class _PrayerTimesWidgetState extends ConsumerState<PrayerTimesWidget> {
  Timer? _timer;
  Duration _timeUntilNext = Duration.zero;

  @override
  void initState() {
    super.initState();
    AdhanService().init();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCountdown();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateCountdown() {
    final prayerData = ref.read(prayerTimesProvider).value;
    if (prayerData == null) return;

    final now = DateTime.now();
    DateTime? nextTime;

    switch (prayerData.nextPrayer) {
      case Prayer.fajr:
        nextTime = prayerData.times.fajr;
        break;
      case Prayer.sunrise:
        nextTime = prayerData.times.sunrise;
        break;
      case Prayer.dhuhr:
        nextTime = prayerData.times.dhuhr;
        break;
      case Prayer.asr:
        nextTime = prayerData.times.asr;
        break;
      case Prayer.maghrib:
        nextTime = prayerData.times.maghrib;
        break;
      case Prayer.isha:
        nextTime = prayerData.times.isha;
        break;
      case Prayer.none:
        break;
    }

    if (nextTime != null && nextTime.isAfter(now)) {
      setState(() {
        _timeUntilNext = nextTime!.difference(now);
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "-$hours:$minutes:$seconds";
  }

  String _prayerName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'Fajr';
      case Prayer.sunrise:
        return 'Chourouq';
      case Prayer.dhuhr:
        return 'Dhuhr';
      case Prayer.asr:
        return 'Asr';
      case Prayer.maghrib:
        return 'Maghrib';
      case Prayer.isha:
        return 'Isha';
      case Prayer.none:
        return '';
    }
  }

  Future<void> _updateAlarms(PrayerData data, AdhanPreferences prefs) async {
    final adhan = AdhanService();
    await adhan.cancelAll();

    // We only schedule if the time is in the future
    final now = DateTime.now();

    Future<void> scheduleIf(
      bool enabled,
      int id,
      String title,
      DateTime time,
    ) async {
      if (enabled && time.isAfter(now)) {
        await adhan.scheduleAdhan(
          id: id,
          title: title,
          body: 'Il est l\'heure de la prière',
          scheduledTime: time,
        );
      }
    }

    await scheduleIf(prefs.fajr, 1, 'Adhan Fajr', data.times.fajr);
    await scheduleIf(prefs.dhuhr, 2, 'Adhan Dhuhr', data.times.dhuhr);
    await scheduleIf(prefs.asr, 3, 'Adhan Asr', data.times.asr);
    await scheduleIf(prefs.maghrib, 4, 'Adhan Maghrib', data.times.maghrib);
    await scheduleIf(prefs.isha, 5, 'Adhan Isha', data.times.isha);
  }

  @override
  Widget build(BuildContext context) {
    final prayerAsync = ref.watch(prayerTimesProvider);
    final adhanPrefs = ref.watch(adhanPreferencesProvider);

    ref.listen<AdhanPreferences>(adhanPreferencesProvider, (previous, next) {
      final data = ref.read(prayerTimesProvider).value;
      if (data != null) {
        _updateAlarms(data, next);
      }
    });

    return prayerAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) =>
          const AeemgCard(child: Text("Erreur lors du chargement des prières")),
      data: (prayerData) {
        if (prayerData == null) {
          return AeemgCard(
            child: Column(
              children: [
                const Icon(Icons.location_off, color: AppColors.warmGray),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  "Les heures de prière utilisent votre position approximative, "
                  "jamais enregistrée.",
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall,
                ),
                // La permission n'est demandée qu'ici, sur action de l'utilisateur (SEC-025).
                TextButton(
                  onPressed: () async {
                    final permission = await Geolocator.checkPermission();
                    if (permission == LocationPermission.deniedForever) {
                      await Geolocator.openAppSettings();
                    }
                    ref.read(locationRequestAllowedProvider.notifier).state =
                        true;
                    ref.invalidate(prayerTimesProvider);
                  },
                  child: const Text(
                    "Activer la localisation",
                    style: TextStyle(color: AppColors.brightGreen),
                  ),
                ),
              ],
            ),
          );
        }

        final times = prayerData.times;
        final format = DateFormat('HH:mm');

        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.darkTeal, AppColors.emerald],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.emerald.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.emerald.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppColors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        prayerData.locationName,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        DateFormat('d MMM yyyy', 'fr').format(DateTime.now()),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          // Could open a specific settings modal, but we'll show a snackbar to guide them
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Touchez la cloche sous chaque prière pour activer son alarme.',
                              ),
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.settings_suggest,
                          color: AppColors.gold,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (prayerData.nextPrayer != Prayer.none) ...[
                Text(
                  'Prochaine prière : ${_prayerName(prayerData.nextPrayer)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.white.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  _formatDuration(_timeUntilNext),
                  style: AppTypography.h1.copyWith(
                    color: AppColors.white,
                    fontSize: 32,
                  ),
                ),
              ] else ...[
                Text(
                  'Toutes les prières sont passées',
                  style: AppTypography.h2.copyWith(color: AppColors.white),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _PrayerTimeItem(
                      name: 'Fajr',
                      time: format.format(times.fajr),
                      isNext: prayerData.nextPrayer == Prayer.fajr,
                      alarmEnabled: adhanPrefs.fajr,
                      onToggleAlarm: (v) => ref
                          .read(adhanPreferencesProvider.notifier)
                          .toggle('fajr', v),
                    ),
                  ),
                  Expanded(
                    child: _PrayerTimeItem(
                      name: 'Dhuhr',
                      time: format.format(times.dhuhr),
                      isNext: prayerData.nextPrayer == Prayer.dhuhr,
                      alarmEnabled: adhanPrefs.dhuhr,
                      onToggleAlarm: (v) => ref
                          .read(adhanPreferencesProvider.notifier)
                          .toggle('dhuhr', v),
                    ),
                  ),
                  Expanded(
                    child: _PrayerTimeItem(
                      name: 'Asr',
                      time: format.format(times.asr),
                      isNext: prayerData.nextPrayer == Prayer.asr,
                      alarmEnabled: adhanPrefs.asr,
                      onToggleAlarm: (v) => ref
                          .read(adhanPreferencesProvider.notifier)
                          .toggle('asr', v),
                    ),
                  ),
                  Expanded(
                    child: _PrayerTimeItem(
                      name: 'Maghrib',
                      time: format.format(times.maghrib),
                      isNext: prayerData.nextPrayer == Prayer.maghrib,
                      alarmEnabled: adhanPrefs.maghrib,
                      onToggleAlarm: (v) => ref
                          .read(adhanPreferencesProvider.notifier)
                          .toggle('maghrib', v),
                    ),
                  ),
                  Expanded(
                    child: _PrayerTimeItem(
                      name: 'Isha',
                      time: format.format(times.isha),
                      isNext: prayerData.nextPrayer == Prayer.isha,
                      alarmEnabled: adhanPrefs.isha,
                      onToggleAlarm: (v) => ref
                          .read(adhanPreferencesProvider.notifier)
                          .toggle('isha', v),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PrayerTimeItem extends ConsumerWidget {
  final String name;
  final String time;
  final bool isNext;
  final bool alarmEnabled;
  final ValueChanged<bool> onToggleAlarm;

  const _PrayerTimeItem({
    required this.name,
    required this.time,
    this.isNext = false,
    required this.alarmEnabled,
    required this.onToggleAlarm,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Text(
          name,
          style: AppTypography.caption.copyWith(
            color: isNext
                ? AppColors.white
                : AppColors.white.withValues(alpha: 0.6),
            fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: AppTypography.body.copyWith(
            color: isNext
                ? AppColors.white
                : AppColors.white.withValues(alpha: 0.8),
            fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            await AdhanService().requestPermissions();
            onToggleAlarm(!alarmEnabled);
          },
          child: Icon(
            alarmEnabled ? Icons.notifications_active : Icons.notifications_off,
            size: 16,
            color: alarmEnabled
                ? AppColors.gold
                : AppColors.white.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}

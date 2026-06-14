import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/ds/aeemg_card.dart';
import '../../../shared/widgets/ds/islamic_background.dart';
import '../../events/presentation/event_detail_screen.dart';
import '../../events/presentation/providers/events_provider.dart';

class AgendaScreen extends ConsumerStatefulWidget {
  const AgendaScreen({super.key});

  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  bool _isFastingDay(DateTime day) {
    final hijri = HijriCalendar.fromDate(day);
    if (hijri.hMonth == 9) return true; // Ramadan
    if (hijri.hDay == 13 || hijri.hDay == 14 || hijri.hDay == 15) return true; // Ayyam al-Bid
    if (day.weekday == DateTime.monday || day.weekday == DateTime.thursday) return true; // Sunnah
    return false;
  }

  String? _fastingReason(DateTime day) {
    final hijri = HijriCalendar.fromDate(day);
    if (hijri.hMonth == 9) return "Jeûne de Ramadan";
    if (hijri.hDay == 13 || hijri.hDay == 14 || hijri.hDay == 15) return "Ayyam al-Bid (Jours Blancs)";
    if (day.weekday == DateTime.monday) return "Jeûne recommandé du Lundi";
    if (day.weekday == DateTime.thursday) return "Jeûne recommandé du Jeudi";
    return null;
  }

  String? _fastingDetail(DateTime day) {
    final hijri = HijriCalendar.fromDate(day);
    if (hijri.hMonth == 9) return "Le jeûne du mois de Ramadan est l'un des cinq piliers de l'Islam, prescrit pour atteindre la piété.";
    if (hijri.hDay == 13 || hijri.hDay == 14 || hijri.hDay == 15) return "Le Prophète ﷺ a dit : « Si tu jeûnes trois jours dans le mois, jeûne le 13, le 14 et le 15. » (Tirmidhi). Ce jeûne équivaut à jeûner toute l'année.";
    if (day.weekday == DateTime.monday || day.weekday == DateTime.thursday) return "Le Prophète ﷺ a dit : « Les œuvres sont présentées (à Allah) le lundi et le jeudi, et j'aime que mes œuvres soient présentées alors que je jeûne. » (Tirmidhi)";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsForMonthProvider(_focusedDay));
    final hijri = HijriCalendar.fromDate(_focusedDay);
    final hijriLabel = '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} H';

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.8),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text('Agenda', style: AppTypography.h2.copyWith(color: AppColors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                ),
                child: Text(
                  hijriLabel,
                  style: AppTypography.caption.copyWith(color: AppColors.gold, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
      body: IslamicBackground(
        withPattern: true,
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: AeemgCard(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: TableCalendar<dynamic>(
                  firstDay: DateTime.utc(2024),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selectedDay = selected;
                      _focusedDay = focused;
                    });
                  },
                  onPageChanged: (focused) => setState(() => _focusedDay = focused),
                  eventLoader: (day) {
                    List<dynamic> dayEvents = [];
                    if (_isFastingDay(day)) {
                      dayEvents.add('Fasting');
                    }
                    final actualEvents = eventsAsync.maybeWhen(
                      data: (events) => events.where((e) => isSameDay(e.startsAt, day)).toList(),
                      orElse: () => [],
                    );
                    dayEvents.addAll(actualEvents);
                    return dayEvents;
                  },
                  calendarStyle: CalendarStyle(
                    defaultTextStyle: const TextStyle(color: AppColors.white),
                    weekendTextStyle: const TextStyle(color: AppColors.textSecondary),
                    outsideTextStyle: TextStyle(color: AppColors.textTertiary.withValues(alpha: 0.5)),
                    todayDecoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: AppColors.emerald,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppColors.emerald, blurRadius: 8, spreadRadius: 1),
                      ],
                    ),
                    markerDecoration: const BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleTextStyle: AppTypography.h3.copyWith(color: AppColors.gold),
                    leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.gold),
                    rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.gold),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(color: AppColors.emerald.withValues(alpha: 0.8), fontWeight: FontWeight.bold),
                    weekendStyle: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                  ),
                  calendarBuilders: CalendarBuilders<dynamic>(
                    markerBuilder: (context, day, events) {
                      if (events.isEmpty) return const SizedBox();
                      final hasFasting = events.contains('Fasting');
                      final hasEvent = events.any((e) => e != 'Fasting');
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (hasFasting)
                            Container(
                              margin: const EdgeInsets.only(top: 36),
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.emerald,
                              ),
                            ),
                          if (hasFasting && hasEvent) const SizedBox(width: 4),
                          if (hasEvent)
                            Container(
                              margin: const EdgeInsets.only(top: 36),
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.gold,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ).animate().fade().scale(begin: const Offset(0.95, 0.95)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Divider(color: AppColors.textTertiary, thickness: 0.3),
            ),
            Expanded(
              child: AsyncValueWidget(
                value: eventsAsync,
                empty: Center(child: Text('Aucun événement ce mois-ci.', style: TextStyle(color: AppColors.textSecondary))),
                data: (events) {
                  final displayDay = _selectedDay ?? _focusedDay;
                  final filtered = events.where((e) => isSameDay(e.startsAt, displayDay)).toList();
                  final dateFormat = DateFormat('d MMM · HH:mm', 'fr');
                  final fReason = _fastingReason(displayDay);
                  final fDetail = _fastingDetail(displayDay);

                  if (filtered.isEmpty && fReason == null) {
                    return Center(child: Text('Aucun événement ce jour.', style: TextStyle(color: AppColors.textSecondary))).animate().fade();
                  }

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      if (fReason != null)
                        AeemgCard(
                          variant: AeemgCardVariant.active,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.emerald.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.nightlight_round, color: AppColors.emerald),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fReason,
                                      style: AppTypography.h3.copyWith(color: AppColors.emerald),
                                    ),
                                    if (fDetail != null) ...[
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        fDetail,
                                        style: AppTypography.caption.copyWith(color: AppColors.white),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animate().fade().slideX(begin: 0.05),
                      if (fReason != null && filtered.isNotEmpty) const SizedBox(height: AppSpacing.md),
                      ...filtered.asMap().entries.map((entry) {
                        final index = entry.key;
                        final event = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: AeemgCard(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => EventDetailScreen(event: event),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.event, color: AppColors.gold),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(event.title, style: AppTypography.h3),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        '${event.typeLabel} · ${dateFormat.format(event.startsAt)}',
                                        style: AppTypography.caption.copyWith(color: AppColors.gold),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                              ],
                            ),
                          ).animate(delay: Duration(milliseconds: 100 * (index + 1))).fade().slideX(begin: 0.05),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

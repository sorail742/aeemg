import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyTrack {
  final DateTime date;
  final bool fajr;
  final bool dhuhr;
  final bool asr;
  final bool maghrib;
  final bool isha;
  final bool fasting;

  DailyTrack({
    required this.date,
    this.fajr = false,
    this.dhuhr = false,
    this.asr = false,
    this.maghrib = false,
    this.isha = false,
    this.fasting = false,
  });

  DailyTrack copyWith({
    DateTime? date,
    bool? fajr,
    bool? dhuhr,
    bool? asr,
    bool? maghrib,
    bool? isha,
    bool? fasting,
  }) {
    return DailyTrack(
      date: date ?? this.date,
      fajr: fajr ?? this.fajr,
      dhuhr: dhuhr ?? this.dhuhr,
      asr: asr ?? this.asr,
      maghrib: maghrib ?? this.maghrib,
      isha: isha ?? this.isha,
      fasting: fasting ?? this.fasting,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fajr': fajr,
      'dhuhr': dhuhr,
      'asr': asr,
      'maghrib': maghrib,
      'isha': isha,
      'fasting': fasting,
    };
  }

  factory DailyTrack.fromJson(DateTime date, Map<String, dynamic> json) {
    return DailyTrack(
      date: date,
      fajr: json['fajr'] ?? false,
      dhuhr: json['dhuhr'] ?? false,
      asr: json['asr'] ?? false,
      maghrib: json['maghrib'] ?? false,
      isha: json['isha'] ?? false,
      fasting: json['fasting'] ?? false,
    );
  }
}

final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  return TrackingRepository();
});

final dailyTrackProvider =
    StateNotifierProvider.family<DailyTrackNotifier, DailyTrack, DateTime>((
      ref,
      date,
    ) {
      final repo = ref.watch(trackingRepositoryProvider);
      return DailyTrackNotifier(repo, date);
    });

class DailyTrackNotifier extends StateNotifier<DailyTrack> {
  final TrackingRepository _repository;
  final DateTime _date;

  DailyTrackNotifier(this._repository, this._date)
    : super(DailyTrack(date: _date)) {
    _load();
  }

  Future<void> _load() async {
    final track = await _repository.getTrackForDate(_date);
    if (track != null) {
      state = track;
    }
  }

  Future<void> toggleFajr() async {
    state = state.copyWith(fajr: !state.fajr);
    await _repository.saveTrack(state);
  }

  Future<void> toggleDhuhr() async {
    state = state.copyWith(dhuhr: !state.dhuhr);
    await _repository.saveTrack(state);
  }

  Future<void> toggleAsr() async {
    state = state.copyWith(asr: !state.asr);
    await _repository.saveTrack(state);
  }

  Future<void> toggleMaghrib() async {
    state = state.copyWith(maghrib: !state.maghrib);
    await _repository.saveTrack(state);
  }

  Future<void> toggleIsha() async {
    state = state.copyWith(isha: !state.isha);
    await _repository.saveTrack(state);
  }

  Future<void> toggleFasting() async {
    state = state.copyWith(fasting: !state.fasting);
    await _repository.saveTrack(state);
  }
}

class TrackingRepository {
  static const String _prefix = 'daily_track_';

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<DailyTrack?> getTrackForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _prefix + _formatDate(date);
    final jsonString = prefs.getString(key);

    if (jsonString != null) {
      try {
        final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
        return DailyTrack.fromJson(date, jsonMap);
      } catch (e) {
        return null;
      }
    }
    return DailyTrack(date: date);
  }

  Future<void> saveTrack(DailyTrack track) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _prefix + _formatDate(track.date);
    final jsonString = jsonEncode(track.toJson());
    await prefs.setString(key, jsonString);
  }
}

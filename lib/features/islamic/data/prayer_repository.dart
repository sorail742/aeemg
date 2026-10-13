import 'package:adhan/adhan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'package:shared_preferences/shared_preferences.dart';

final prayerTimesProvider = FutureProvider<PrayerData?>((ref) async {
  final repo = ref.watch(prayerRepositoryProvider);
  return repo.getTodayPrayerTimes();
});

final prayerRepositoryProvider = Provider<PrayerRepository>((ref) {
  return PrayerRepository();
});

class AdhanPreferences {
  final bool fajr;
  final bool dhuhr;
  final bool asr;
  final bool maghrib;
  final bool isha;

  const AdhanPreferences({
    this.fajr = false,
    this.dhuhr = false,
    this.asr = false,
    this.maghrib = false,
    this.isha = false,
  });

  AdhanPreferences copyWith({
    bool? fajr,
    bool? dhuhr,
    bool? asr,
    bool? maghrib,
    bool? isha,
  }) {
    return AdhanPreferences(
      fajr: fajr ?? this.fajr,
      dhuhr: dhuhr ?? this.dhuhr,
      asr: asr ?? this.asr,
      maghrib: maghrib ?? this.maghrib,
      isha: isha ?? this.isha,
    );
  }
}

class AdhanPreferencesNotifier extends StateNotifier<AdhanPreferences> {
  AdhanPreferencesNotifier() : super(const AdhanPreferences()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AdhanPreferences(
      fajr: prefs.getBool('adhan_fajr') ?? false,
      dhuhr: prefs.getBool('adhan_dhuhr') ?? false,
      asr: prefs.getBool('adhan_asr') ?? false,
      maghrib: prefs.getBool('adhan_maghrib') ?? false,
      isha: prefs.getBool('adhan_isha') ?? false,
    );
  }

  Future<void> toggle(String prayer, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('adhan_$prayer', value);
    switch (prayer) {
      case 'fajr':
        state = state.copyWith(fajr: value);
        break;
      case 'dhuhr':
        state = state.copyWith(dhuhr: value);
        break;
      case 'asr':
        state = state.copyWith(asr: value);
        break;
      case 'maghrib':
        state = state.copyWith(maghrib: value);
        break;
      case 'isha':
        state = state.copyWith(isha: value);
        break;
    }
    // Update schedules logic would be called here via a listener in the UI or directly
  }
}

final adhanPreferencesProvider =
    StateNotifierProvider<AdhanPreferencesNotifier, AdhanPreferences>((ref) {
      return AdhanPreferencesNotifier();
    });

class PrayerData {
  final PrayerTimes times;
  final Prayer nextPrayer;
  final String locationName;

  PrayerData(this.times, this.nextPrayer, this.locationName);
}

class PrayerRepository {
  Future<PrayerData?> getTodayPrayerTimes() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null; // Handle fallback or error
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );

      final coordinates = Coordinates(position.latitude, position.longitude);

      // Obtenir la ville
      String cityName = "Localisation inconnue";
      try {
        List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          cityName =
              placemarks.first.locality ??
              placemarks.first.subAdministrativeArea ??
              "Votre position";
        }
      } catch (_) {}

      // Calcul avec la méthode de la Ligue Musulmane Mondiale (MWL) ou UOIF
      // On utilise Muslim World League par défaut pour l'Afrique de l'Ouest
      final params = CalculationMethod.muslim_world_league.getParameters();
      params.madhab = Madhab.shafi; // Includes Maliki, Hanbali and Shafi

      final date = DateComponents.from(DateTime.now());
      final prayerTimes = PrayerTimes(coordinates, date, params);

      return PrayerData(prayerTimes, prayerTimes.nextPrayer(), cityName);
    } catch (e) {
      return null;
    }
  }
}

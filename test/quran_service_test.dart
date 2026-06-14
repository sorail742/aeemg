import 'package:aeemg/features/quran/data/quran_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as q;

void main() {
  const service = QuranService();

  group('QuranService', () {
    test('expose 114 sourates', () {
      expect(service.getAllSurahs().length, q.totalSurahCount);
    });

    test('Al-Fatiha contient 7 versets en arabe et français', () {
      final ayahs = service.getSurahAyahs(1);
      expect(ayahs.length, 7);
      expect(ayahs.first.arabic, isNotEmpty);
      expect(ayahs.first.translation, isNotEmpty);
    });

    test('filtre les sourates par numéro', () {
      final all = service.getAllSurahs();
      final filtered = service.filterSurahs('36', all);
      expect(filtered.any((s) => s.number == 36), isTrue);
    });

    test('juz 1 contient des versets', () {
      final ayahs = service.getJuzAyahs(1);
      expect(ayahs, isNotEmpty);
      expect(ayahs.first.surahNumber, greaterThan(0));
    });

    test('mushaf page 1 contient des segments', () {
      final page = service.getMushafPage(1);
      expect(page.pageNumber, 1);
      expect(page.segments, isNotEmpty);
    });

    test('getPageForAyah retourne une page valide', () {
      final page = service.getPageForAyah(1, 1);
      expect(page, inInclusiveRange(1, 604));
    });
  });
}

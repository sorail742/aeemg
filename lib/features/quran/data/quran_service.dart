import 'package:quran/quran.dart' as q;

import 'models/quran_models.dart';

/// Accès au Coran complet hors ligne (114 sourates, traduction française).
class QuranService {
  const QuranService();

  static const _translation = q.Translation.frHamidullah;

  List<SurahInfo> getAllSurahs() {
    return List.generate(q.totalSurahCount, (index) {
      final number = index + 1;
      return SurahInfo(
        number: number,
        nameArabic: q.getSurahNameArabic(number),
        nameFrench: q.getSurahNameFrench(number),
        nameEnglish: q.getSurahNameEnglish(number),
        verseCount: q.getVerseCount(number),
        revelationPlace: q.getPlaceOfRevelation(number),
      );
    });
  }

  SurahInfo getSurah(int number) => getAllSurahs()[number - 1];

  List<AyahInfo> getSurahAyahs(int surahNumber) {
    final count = q.getVerseCount(surahNumber);
    return List.generate(count, (index) {
      final ayah = index + 1;
      return AyahInfo(
        surahNumber: surahNumber,
        ayahNumber: ayah,
        arabic: q.getVerse(surahNumber, ayah, verseEndSymbol: true),
        translation: q.getVerseTranslation(
          surahNumber,
          ayah,
          translation: _translation,
        ),
        isSajdah: q.isSajdahVerse(surahNumber, ayah),
      );
    });
  }

  List<AyahInfo> getJuzAyahs(int juzNumber) {
    if (juzNumber < 1 || juzNumber > q.totalJuzCount) {
      throw ArgumentError('Juz invalide : $juzNumber');
    }
    final segments = q.getSurahAndVersesFromJuz(juzNumber);
    final ayahs = <AyahInfo>[];
    for (final entry in segments.entries) {
      final surah = entry.key;
      final start = entry.value[0];
      final end = entry.value[1];
      for (var ayah = start; ayah <= end; ayah++) {
        ayahs.add(
          AyahInfo(
            surahNumber: surah,
            ayahNumber: ayah,
            arabic: q.getVerse(surah, ayah, verseEndSymbol: true),
            translation: q.getVerseTranslation(
              surah,
              ayah,
              translation: _translation,
            ),
            isSajdah: q.isSajdahVerse(surah, ayah),
          ),
        );
      }
    }
    return ayahs;
  }

  List<SurahInfo> filterSurahs(String query, List<SurahInfo> surahs) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return surahs;
    return surahs.where((s) {
      return s.nameFrench.toLowerCase().contains(q) ||
          s.nameEnglish.toLowerCase().contains(q) ||
          s.nameArabic.contains(query.trim()) ||
          '${s.number}'.contains(q);
    }).toList();
  }

  List<VerseSearchHit> searchInTranslation(String query) {
    final term = query.trim();
    if (term.length < 2) return [];

    final result = q.searchWordsInTranslation(
      [term],
      translation: _translation,
    );
    final hits = <VerseSearchHit>[];
    for (final item in (result['result'] as List? ?? [])) {
      final map = item as Map;
      final surah = map['surah'] as int;
      final ayah = map['verse'] as int;
      final preview = q.getVerseTranslation(
        surah,
        ayah,
        translation: _translation,
      );
      hits.add(
        VerseSearchHit(
          surahNumber: surah,
          ayahNumber: ayah,
          preview: preview,
        ),
      );
      if (hits.length >= 40) break;
    }
    return hits;
  }

  MushafPage getMushafPage(int pageNumber) {
    if (pageNumber < 1 || pageNumber > q.totalPagesCount) {
      throw ArgumentError('Page invalide : $pageNumber');
    }
    final raw = q.getPageData(pageNumber);
    final segments = <MushafPageSegment>[];
    int? juzNumber;

    for (final item in raw) {
      final map = item as Map;
      final surah = map['surah'] as int;
      final start = map['start'] as int;
      final end = map['end'] as int;
      juzNumber ??= q.getJuzNumber(surah, start);

      final ayahs = <AyahInfo>[];
      for (var ayah = start; ayah <= end; ayah++) {
        ayahs.add(
          AyahInfo(
            surahNumber: surah,
            ayahNumber: ayah,
            arabic: q.getVerse(surah, ayah, verseEndSymbol: true),
            translation: q.getVerseTranslation(
              surah,
              ayah,
              translation: _translation,
            ),
            isSajdah: q.isSajdahVerse(surah, ayah),
          ),
        );
      }

      segments.add(
        MushafPageSegment(
          surahNumber: surah,
          startAyah: start,
          endAyah: end,
          showSurahHeader: start == 1,
          ayahs: ayahs,
        ),
      );
    }

    return MushafPage(
      pageNumber: pageNumber,
      juzNumber: juzNumber ?? 1,
      segments: segments,
    );
  }

  int getPageForAyah(int surahNumber, int ayahNumber) {
    return q.getPageNumber(surahNumber, ayahNumber);
  }
}

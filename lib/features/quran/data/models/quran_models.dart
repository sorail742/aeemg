class SurahInfo {
  const SurahInfo({
    required this.number,
    required this.nameArabic,
    required this.nameFrench,
    required this.nameEnglish,
    required this.verseCount,
    required this.revelationPlace,
  });

  final int number;
  final String nameArabic;
  final String nameFrench;
  final String nameEnglish;
  final int verseCount;
  final String revelationPlace;

  String get revelationLabel =>
      revelationPlace.toLowerCase() == 'makkah' ? 'Mecquoise' : 'Médinoise';
}

class AyahInfo {
  const AyahInfo({
    required this.surahNumber,
    required this.ayahNumber,
    required this.arabic,
    required this.translation,
    required this.isSajdah,
  });

  final int surahNumber;
  final int ayahNumber;
  final String arabic;
  final String translation;
  final bool isSajdah;
}

class QuranBookmark {
  const QuranBookmark({
    required this.surahNumber,
    required this.ayahNumber,
    required this.savedAt,
  });

  final int surahNumber;
  final int ayahNumber;
  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
        'surah': surahNumber,
        'ayah': ayahNumber,
        'saved_at': savedAt.toIso8601String(),
      };

  factory QuranBookmark.fromJson(Map<String, dynamic> json) => QuranBookmark(
        surahNumber: json['surah'] as int,
        ayahNumber: json['ayah'] as int,
        savedAt: DateTime.parse(json['saved_at'] as String),
      );
}

class QuranLastRead {
  const QuranLastRead({
    required this.surahNumber,
    required this.ayahNumber,
  });

  final int surahNumber;
  final int ayahNumber;

  Map<String, dynamic> toJson() => {
        'surah': surahNumber,
        'ayah': ayahNumber,
      };

  factory QuranLastRead.fromJson(Map<String, dynamic> json) => QuranLastRead(
        surahNumber: json['surah'] as int,
        ayahNumber: json['ayah'] as int,
      );
}

class ReciterInfo {
  const ReciterInfo({required this.id, required this.label});

  final String id;
  final String label;
}

class MushafPageSegment {
  const MushafPageSegment({
    required this.surahNumber,
    required this.startAyah,
    required this.endAyah,
    required this.showSurahHeader,
    required this.ayahs,
  });

  final int surahNumber;
  final int startAyah;
  final int endAyah;
  final bool showSurahHeader;
  final List<AyahInfo> ayahs;
}

class MushafPage {
  const MushafPage({
    required this.pageNumber,
    required this.juzNumber,
    required this.segments,
  });

  final int pageNumber;
  final int juzNumber;
  final List<MushafPageSegment> segments;
}

class QuranAudioTarget {
  const QuranAudioTarget({
    required this.surahNumber,
    this.ayahNumber,
    required this.isSurah,
  });

  final int surahNumber;
  final int? ayahNumber;
  final bool isSurah;

  String get label => isSurah
      ? 'Sourate $surahNumber'
      : 'Sourate $surahNumber · $ayahNumber';
}

class VerseSearchHit {
  const VerseSearchHit({
    required this.surahNumber,
    required this.ayahNumber,
    required this.preview,
  });

  final int surahNumber;
  final int ayahNumber;
  final String preview;
}

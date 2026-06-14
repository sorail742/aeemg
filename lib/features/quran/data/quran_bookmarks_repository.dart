import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/quran_models.dart';

class QuranBookmarksRepository {
  QuranBookmarksRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _bookmarksKey = 'quran_bookmarks';
  static const _lastReadKey = 'quran_last_read';
  static const _showTranslationKey = 'quran_show_translation';
  static const _arabicFontSizeKey = 'quran_arabic_font_size';
  static const _reciterKey = 'quran_reciter_id';
  static const _lastMushafPageKey = 'quran_last_mushaf_page';

  Future<List<QuranBookmark>> fetchBookmarks() async {
    final raw = _prefs.getString(_bookmarksKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => QuranBookmark.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  Future<void> addBookmark(int surah, int ayah) async {
    final bookmarks = await fetchBookmarks();
    final exists = bookmarks.any(
      (b) => b.surahNumber == surah && b.ayahNumber == ayah,
    );
    if (exists) return;

    bookmarks.insert(
      0,
      QuranBookmark(
        surahNumber: surah,
        ayahNumber: ayah,
        savedAt: DateTime.now(),
      ),
    );
    await _saveBookmarks(bookmarks);
  }

  Future<void> removeBookmark(int surah, int ayah) async {
    final bookmarks = await fetchBookmarks();
    bookmarks.removeWhere(
      (b) => b.surahNumber == surah && b.ayahNumber == ayah,
    );
    await _saveBookmarks(bookmarks);
  }

  Future<bool> isBookmarked(int surah, int ayah) async {
    final bookmarks = await fetchBookmarks();
    return bookmarks.any(
      (b) => b.surahNumber == surah && b.ayahNumber == ayah,
    );
  }

  Future<QuranLastRead?> getLastRead() async {
    final raw = _prefs.getString(_lastReadKey);
    if (raw == null) return null;
    return QuranLastRead.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveLastRead(int surah, int ayah) async {
    await _prefs.setString(
      _lastReadKey,
      jsonEncode(QuranLastRead(surahNumber: surah, ayahNumber: ayah).toJson()),
    );
  }

  bool get showTranslation => _prefs.getBool(_showTranslationKey) ?? true;

  Future<void> setShowTranslation(bool value) async {
    await _prefs.setBool(_showTranslationKey, value);
  }

  double get arabicFontSize => _prefs.getDouble(_arabicFontSizeKey) ?? 28;

  Future<void> setArabicFontSize(double value) async {
    await _prefs.setDouble(_arabicFontSizeKey, value);
  }

  String get reciterId => _prefs.getString(_reciterKey) ?? 'arAlafasy';

  Future<void> setReciterId(String id) async {
    await _prefs.setString(_reciterKey, id);
  }

  int get lastMushafPage => _prefs.getInt(_lastMushafPageKey) ?? 1;

  Future<void> saveLastMushafPage(int page) async {
    await _prefs.setInt(_lastMushafPageKey, page);
  }

  Future<void> _saveBookmarks(List<QuranBookmark> bookmarks) async {
    await _prefs.setString(
      _bookmarksKey,
      jsonEncode(bookmarks.map((b) => b.toJson()).toList()),
    );
  }
}

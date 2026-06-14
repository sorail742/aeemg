import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/offline_cache_provider.dart';
import '../../data/quran_audio_service.dart';
import '../../data/quran_bookmarks_repository.dart';
import '../../data/quran_service.dart';
import '../../data/models/quran_models.dart';

final quranServiceProvider = Provider<QuranService>((ref) {
  return const QuranService();
});

final quranBookmarksRepositoryProvider = Provider<QuranBookmarksRepository>((ref) {
  return QuranBookmarksRepository(ref.watch(sharedPreferencesProvider));
});

final quranAudioServiceProvider = ChangeNotifierProvider<QuranAudioService>((ref) {
  final service = QuranAudioService();
  ref.onDispose(() => service.dispose());
  return service;
});

final allSurahsProvider = Provider<List<SurahInfo>>((ref) {
  return ref.watch(quranServiceProvider).getAllSurahs();
});

final quranBookmarksProvider = FutureProvider<List<QuranBookmark>>((ref) async {
  return ref.read(quranBookmarksRepositoryProvider).fetchBookmarks();
});

final quranLastReadProvider = FutureProvider<QuranLastRead?>((ref) async {
  return ref.read(quranBookmarksRepositoryProvider).getLastRead();
});

final quranShowTranslationProvider = StateProvider<bool>((ref) {
  return ref.read(quranBookmarksRepositoryProvider).showTranslation;
});

final quranArabicFontSizeProvider = StateProvider<double>((ref) {
  return ref.read(quranBookmarksRepositoryProvider).arabicFontSize;
});

final quranReciterProvider = StateProvider<String>((ref) {
  return ref.read(quranBookmarksRepositoryProvider).reciterId;
});

final quranLastMushafPageProvider = StateProvider<int>((ref) {
  return ref.read(quranBookmarksRepositoryProvider).lastMushafPage;
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/quran_service.dart';
import 'providers/quran_provider.dart';
import 'widgets/ayah_tile.dart';
import 'widgets/quran_audio_bar.dart';

class JuzReaderScreen extends ConsumerStatefulWidget {
  const JuzReaderScreen({super.key, required this.juzNumber});

  final int juzNumber;

  @override
  ConsumerState<JuzReaderScreen> createState() => _JuzReaderScreenState();
}

class _JuzReaderScreenState extends ConsumerState<JuzReaderScreen> {
  final Set<String> _bookmarked = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBookmarks());
  }

  Future<void> _loadBookmarks() async {
    final bookmarks =
        await ref.read(quranBookmarksRepositoryProvider).fetchBookmarks();
    if (!mounted) return;
    setState(() {
      _bookmarked
        ..clear()
        ..addAll(
          bookmarks.map((b) => '${b.surahNumber}:${b.ayahNumber}'),
        );
    });
  }

  Future<void> _toggleBookmark(int surah, int ayah) async {
    final repo = ref.read(quranBookmarksRepositoryProvider);
    final key = '$surah:$ayah';
    if (_bookmarked.contains(key)) {
      await repo.removeBookmark(surah, ayah);
      setState(() => _bookmarked.remove(key));
    } else {
      await repo.addBookmark(surah, ayah);
      setState(() => _bookmarked.add(key));
    }
    ref.invalidate(quranBookmarksProvider);
    await repo.saveLastRead(surah, ayah);
    ref.invalidate(quranLastReadProvider);
  }

  Future<void> _playAyah(int surah, int ayah) async {
    final audio = ref.read(quranAudioServiceProvider);
    final reciter = ref.read(quranReciterProvider);
    final target = audio.currentTarget;
    if (target != null &&
        !target.isSurah &&
        target.surahNumber == surah &&
        target.ayahNumber == ayah &&
        audio.isPlaying) {
      await audio.togglePlayPause();
    } else {
      await audio.playAyah(surah, ayah, reciter);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final service = const QuranService();
    final ayahs = service.getJuzAyahs(widget.juzNumber);
    final surahs = ref.watch(allSurahsProvider);
    final showTranslation = ref.watch(quranShowTranslationProvider);
    final arabicSize = ref.watch(quranArabicFontSizeProvider);
    final audio = ref.watch(quranAudioServiceProvider);
    final playingTarget = audio.currentTarget;

    return Scaffold(
      appBar: AppBar(
        title: Text('Juz ${widget.juzNumber}', style: AppTypography.h3),
        actions: [
          IconButton(
            icon: const Icon(Icons.record_voice_over_outlined),
            onPressed: () => showReciterPicker(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: ayahs.length,
              itemBuilder: (context, index) {
                final ayah = ayahs[index];
                final surah = surahs[ayah.surahNumber - 1];
                final key = '${ayah.surahNumber}:${ayah.ayahNumber}';
                final showLabel = index == 0 ||
                    ayahs[index - 1].surahNumber != ayah.surahNumber;
                final isPlayingAyah = playingTarget != null &&
                    !playingTarget.isSurah &&
                    playingTarget.surahNumber == ayah.surahNumber &&
                    playingTarget.ayahNumber == ayah.ayahNumber &&
                    audio.isPlaying;

                return AyahTile(
                  ayah: ayah,
                  showTranslation: showTranslation,
                  arabicFontSize: arabicSize,
                  isBookmarked: _bookmarked.contains(key),
                  isPlaying: isPlayingAyah,
                  showSurahLabel: showLabel,
                  surahNameFrench: surah.nameFrench,
                  onPlayAudio: () => _playAyah(ayah.surahNumber, ayah.ayahNumber),
                  onBookmarkToggle: () =>
                      _toggleBookmark(ayah.surahNumber, ayah.ayahNumber),
                );
              },
            ),
          ),
          const QuranAudioBar(),
        ],
      ),
    );
  }
}

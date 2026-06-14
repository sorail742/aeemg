import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quran/quran.dart' as q;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/ds/islamic_background.dart';
import '../data/models/quran_models.dart';
import 'providers/quran_provider.dart';
import 'widgets/ayah_tile.dart';
import 'widgets/quran_audio_bar.dart';

class SurahReaderScreen extends ConsumerStatefulWidget {
  const SurahReaderScreen({
    super.key,
    required this.surahNumber,
    this.initialAyah = 1,
  });

  final int surahNumber;
  final int initialAyah;

  @override
  ConsumerState<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends ConsumerState<SurahReaderScreen> {
  final _scrollController = ScrollController();
  late final List<GlobalKey> _ayahKeys;
  late final List<AyahInfo> _ayahs;
  late final SurahInfo _surah;
  final Set<String> _bookmarked = {};

  @override
  void initState() {
    super.initState();
    final service = ref.read(quranServiceProvider);
    _surah = service.getSurah(widget.surahNumber);
    _ayahs = service.getSurahAyahs(widget.surahNumber);
    _ayahKeys = List.generate(_ayahs.length, (_) => GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookmarks();
      _scrollToInitialAyah();
    });
  }

  Future<void> _loadBookmarks() async {
    final repo = ref.read(quranBookmarksRepositoryProvider);
    final bookmarks = await repo.fetchBookmarks();
    if (!mounted) return;
    setState(() {
      _bookmarked
        ..clear()
        ..addAll(
          bookmarks
              .where((b) => b.surahNumber == widget.surahNumber)
              .map((b) => '${b.surahNumber}:${b.ayahNumber}'),
        );
    });
  }

  void _scrollToInitialAyah() {
    if (widget.initialAyah <= 1) return;
    final index = widget.initialAyah - 1;
    if (index >= _ayahKeys.length) return;
    final context = _ayahKeys[index].currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleBookmark(int ayah) async {
    final repo = ref.read(quranBookmarksRepositoryProvider);
    final key = '${widget.surahNumber}:$ayah';
    if (_bookmarked.contains(key)) {
      await repo.removeBookmark(widget.surahNumber, ayah);
      setState(() => _bookmarked.remove(key));
    } else {
      await repo.addBookmark(widget.surahNumber, ayah);
      setState(() => _bookmarked.add(key));
    }
    ref.invalidate(quranBookmarksProvider);
  }

  void _saveProgress(int ayah) {
    ref.read(quranBookmarksRepositoryProvider).saveLastRead(
          widget.surahNumber,
          ayah,
        );
    ref.invalidate(quranLastReadProvider);
  }

  Future<void> _playSurah() async {
    final reciter = ref.read(quranReciterProvider);
    await ref.read(quranAudioServiceProvider).playSurah(
          widget.surahNumber,
          reciter,
        );
    setState(() {});
  }

  Future<void> _playAyah(int ayah) async {
    final audio = ref.read(quranAudioServiceProvider);
    final reciter = ref.read(quranReciterProvider);
    final target = audio.currentTarget;
    if (target != null &&
        !target.isSurah &&
        target.surahNumber == widget.surahNumber &&
        target.ayahNumber == ayah &&
        audio.isPlaying) {
      await audio.togglePlayPause();
    } else {
      await audio.playAyah(widget.surahNumber, ayah, reciter);
    }
    setState(() {});
  }

  void _openMushafPage() {
    final page = ref.read(quranServiceProvider).getPageForAyah(
          widget.surahNumber,
          widget.initialAyah,
        );
    context.push('/quran/mushaf', extra: page);
  }

  @override
  Widget build(BuildContext context) {
    final showTranslation = ref.watch(quranShowTranslationProvider);
    final arabicSize = ref.watch(quranArabicFontSizeProvider);
    final audio = ref.watch(quranAudioServiceProvider);
    final playingTarget = audio.currentTarget;

    ref.listen(quranAudioServiceProvider, (previous, next) {
      if (next.isPlaying && next.currentTarget != null) {
        final target = next.currentTarget!;
        if (target.surahNumber == widget.surahNumber && target.ayahNumber != null) {
          final index = target.ayahNumber! - 1;
          if (index >= 0 && index < _ayahKeys.length) {
            final ctx = _ayahKeys[index].currentContext;
            if (ctx != null) {
              Scrollable.ensureVisible(
                ctx,
                duration: const Duration(milliseconds: 300),
                alignment: 0.3, // Align slightly above center
              );
            }
          }
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.8),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_surah.nameFrench, style: AppTypography.h3.copyWith(color: AppColors.white)),
            Text(
              _surah.nameArabic,
              style: AppTypography.quranArabic(size: 16).copyWith(color: AppColors.gold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_stories, color: AppColors.emerald),
            tooltip: 'Voir dans le Mushaf',
            onPressed: _openMushafPage,
          ),
          IconButton(
            icon: const Icon(Icons.headphones, color: AppColors.emerald),
            tooltip: 'Écouter la sourate',
            onPressed: _playSurah,
          ),
          IconButton(
            icon: Icon(
              showTranslation ? Icons.translate : Icons.translate_outlined,
              color: AppColors.emerald,
            ),
            tooltip: 'Traduction française',
            onPressed: () async {
              final next = !showTranslation;
              ref.read(quranShowTranslationProvider.notifier).state = next;
              await ref
                  .read(quranBookmarksRepositoryProvider)
                  .setShowTranslation(next);
            },
          ),
          PopupMenuButton<double>(
            icon: const Icon(Icons.text_fields, color: AppColors.emerald),
            tooltip: 'Taille du texte arabe',
            color: AppColors.cardSurface,
            onSelected: (size) async {
              ref.read(quranArabicFontSizeProvider.notifier).state = size;
              await ref
                  .read(quranBookmarksRepositoryProvider)
                  .setArabicFontSize(size);
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 24.0, child: Text('Petit', style: TextStyle(color: AppColors.white))),
              PopupMenuItem(value: 28.0, child: Text('Moyen', style: TextStyle(color: AppColors.white))),
              PopupMenuItem(value: 36.0, child: Text('Grand', style: TextStyle(color: AppColors.white))),
            ],
          ),
        ],
      ),
      body: IslamicBackground(
        withPattern: true,
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: _ayahs.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                            decoration: BoxDecoration(
                              image: const DecorationImage(
                                image: AssetImage('assets/images/header_pattern.png'), // Placeholder or fallback
                                fit: BoxFit.cover,
                                opacity: 0.1,
                              ),
                              border: Border(
                                top: BorderSide(color: AppColors.gold.withValues(alpha: 0.5), width: 2),
                                bottom: BorderSide(color: AppColors.gold.withValues(alpha: 0.5), width: 2),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _surah.nameArabic,
                                  style: AppTypography.quranArabic(size: 40).copyWith(color: AppColors.gold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  '${_surah.revelationLabel} · ${_surah.verseCount} versets',
                                  style: AppTypography.caption.copyWith(color: AppColors.emerald, letterSpacing: 1.2),
                                ),
                              ],
                            ),
                          ).animate().fade().scale(begin: const Offset(0.95, 0.95)),
                          
                          if (widget.surahNumber != 9 && widget.surahNumber != 1) ...[
                            const SizedBox(height: AppSpacing.xl),
                            Text(
                              q.basmala,
                              style: AppTypography.quranArabic(size: arabicSize + 4).copyWith(color: AppColors.white),
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                            ).animate(delay: 200.ms).fade(),
                          ],
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ),
                    );
                  }

                  if (index == _ayahs.length + 1) {
                    final prevSurah = widget.surahNumber > 1 ? widget.surahNumber - 1 : null;
                    final nextSurah = widget.surahNumber < 114 ? widget.surahNumber + 1 : null;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (prevSurah != null)
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.emerald,
                                  side: BorderSide(color: AppColors.emerald.withValues(alpha: 0.5)),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                icon: const Icon(Icons.arrow_back),
                                label: Text(
                                  ref.read(quranServiceProvider).getSurah(prevSurah).nameFrench,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onPressed: () => context.pushReplacement(
                                  '/quran/surah/$prevSurah',
                                ),
                              ),
                            )
                          else
                            const Spacer(),
                          const SizedBox(width: AppSpacing.md),
                          if (nextSurah != null)
                            Expanded(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.emerald,
                                  foregroundColor: AppColors.deepNavy,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                icon: const Icon(Icons.arrow_forward),
                                label: Text(
                                  ref.read(quranServiceProvider).getSurah(nextSurah).nameFrench,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                onPressed: () => context.pushReplacement(
                                  '/quran/surah/$nextSurah',
                                ),
                              ),
                            )
                          else
                            const Spacer(),
                        ],
                      ),
                    );
                  }

                  final ayah = _ayahs[index - 1];
                  final ayahNumber = ayah.ayahNumber;
                  final key = '${widget.surahNumber}:$ayahNumber';
                  final isPlayingAyah = playingTarget != null &&
                      playingTarget.surahNumber == widget.surahNumber &&
                      playingTarget.ayahNumber == ayahNumber &&
                      audio.isPlaying;

                  return KeyedSubtree(
                    key: _ayahKeys[index - 1],
                    child: AyahTile(
                      ayah: ayah,
                      showTranslation: showTranslation,
                      arabicFontSize: arabicSize,
                      isBookmarked: _bookmarked.contains(key),
                      isPlaying: isPlayingAyah,
                      onPlayAudio: () => _playAyah(ayahNumber),
                      onRecite: () {
                        context.push('/quran/test/${widget.surahNumber}');
                      },
                      onBookmarkToggle: () {
                        _toggleBookmark(ayahNumber);
                        _saveProgress(ayahNumber);
                      },
                    ).animate(delay: Duration(milliseconds: 30 * (index < 10 ? index : 0))).fade().slideY(begin: 0.1),
                  );
                },
              ),
            ),
            const QuranAudioBar(),
          ],
        ),
      ),
    );
  }
}

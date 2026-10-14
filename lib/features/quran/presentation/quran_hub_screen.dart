import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quran/quran.dart' as q;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/ds/aeemg_buttons.dart';
import '../../../shared/widgets/ds/aeemg_card.dart';
import '../../../shared/widgets/ds/islamic_background.dart';
import '../data/models/quran_models.dart';
import '../data/quran_audio_service.dart';
import '../data/quran_service.dart';
import 'providers/quran_provider.dart';
import 'widgets/quran_audio_bar.dart';
import 'widgets/surah_list_tile.dart';

class QuranHubScreen extends ConsumerStatefulWidget {
  const QuranHubScreen({super.key});

  @override
  ConsumerState<QuranHubScreen> createState() => _QuranHubScreenState();
}

class _QuranHubScreenState extends ConsumerState<QuranHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<VerseSearchHit> _verseHits = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    setState(() {
      _searchQuery = query;
      _verseHits = query.trim().length >= 2
          ? ref.read(quranServiceProvider).searchInTranslation(query)
          : [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final surahs = ref.watch(allSurahsProvider);
    final filtered = ref
        .read(quranServiceProvider)
        .filterSurahs(_searchQuery, surahs);
    final lastReadAsync = ref.watch(quranLastReadProvider);
    final bookmarksAsync = ref.watch(quranBookmarksProvider);
    final lastMushafPage = ref.watch(quranLastMushafPageProvider);
    final reciterId = ref.watch(quranReciterProvider);
    final reciterLabel = QuranAudioService.reciters
        .firstWhere((r) => r.id == reciterId)
        .label;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.9),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text(
          'Le Noble Coran',
          style: AppTypography.h2.copyWith(color: AppColors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.record_voice_over_outlined,
              color: AppColors.gold,
            ),
            tooltip: reciterLabel,
            onPressed: () => showReciterPicker(context, ref),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.emerald,
          labelColor: AppColors.emerald,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Sourates'),
            Tab(text: 'Mushaf'),
            Tab(text: 'Juz'),
            Tab(text: 'Signets'),
          ],
        ),
      ),
      body: IslamicBackground(
        withPattern: true,
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).padding.top + kToolbarHeight + 48,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  hintText: 'Rechercher une sourate ou un mot…',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.emerald,
                  ),
                  filled: true,
                  fillColor: AppColors.cardSurface.withValues(alpha: 0.8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.emerald.withValues(alpha: 0.5),
                    ),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                ),
              ).animate().fade().slideY(begin: -0.2),
            ),
            if (_verseHits.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  itemCount: _verseHits.length,
                  itemBuilder: (context, index) {
                    final hit = _verseHits[index];
                    final surah = surahs[hit.surahNumber - 1];
                    return SizedBox(
                      width: 260,
                      child: Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: AeemgCard(
                          onTap: () => context.push(
                            '/quran/surah/${hit.surahNumber}',
                            extra: hit.ayahNumber,
                          ),
                          padding: const EdgeInsets.all(AppSpacing.smMd),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${surah.nameFrench} ${hit.ayahNumber}',
                                style: AppTypography.h3.copyWith(
                                  color: AppColors.gold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  hit.preview,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ).animate().fade(),
              ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _SurahsTab(
                    surahs: filtered,
                    lastReadAsync: lastReadAsync,
                    onOpenSurah: (n) => context.push('/quran/surah/$n'),
                    onResume: (surah, ayah) =>
                        context.push('/quran/surah/$surah', extra: ayah),
                  ),
                  _MushafTab(
                    lastPage: lastMushafPage,
                    onOpen: (page) =>
                        context.push('/quran/mushaf', extra: page),
                  ),
                  _JuzTab(onOpenJuz: (n) => context.push('/quran/juz/$n')),
                  bookmarksAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.emerald,
                      ),
                    ),
                    error: (e, _) => Center(
                      child: Text(
                        '$e',
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                    data: (bookmarks) => _BookmarksTab(
                      bookmarks: bookmarks,
                      surahs: surahs,
                      onOpen: (surah, ayah) =>
                          context.push('/quran/surah/$surah', extra: ayah),
                      onRemove: (surah, ayah) async {
                        await ref
                            .read(quranBookmarksRepositoryProvider)
                            .removeBookmark(surah, ayah);
                        ref.invalidate(quranBookmarksProvider);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const QuranAudioBar(),
          ],
        ),
      ),
    );
  }
}

class _MushafTab extends StatelessWidget {
  const _MushafTab({required this.lastPage, required this.onOpen});

  final int lastPage;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        AeemgCard(
          variant: AeemgCardVariant.active,
          onTap: () => onOpen(lastPage),
          child: Row(
            children: [
              const Icon(Icons.auto_stories, color: AppColors.gold, size: 40),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mode Mushaf', style: AppTypography.h2),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '604 pages · texte arabe officiel',
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Continuer page $lastPage',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.emerald,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textTertiary),
            ],
          ),
        ).animate().fade().slideY(begin: 0.1),
        const SizedBox(height: AppSpacing.md),
        AeemgPrimaryButton(
          label: 'Ouvrir page 1',
          icon: Icons.first_page,
          onPressed: () => onOpen(1),
        ).animate(delay: 100.ms).fade(),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => onOpen(lastPage),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.white,
            side: BorderSide(color: AppColors.emerald.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.bookmark_outline, color: AppColors.emerald),
          label: Text('Reprendre page $lastPage'),
        ).animate(delay: 200.ms).fade(),
      ],
    );
  }
}

class _SurahsTab extends StatelessWidget {
  const _SurahsTab({
    required this.surahs,
    required this.lastReadAsync,
    required this.onOpenSurah,
    required this.onResume,
  });

  final List<SurahInfo> surahs;
  final AsyncValue<QuranLastRead?> lastReadAsync;
  final ValueChanged<int> onOpenSurah;
  final void Function(int surah, int ayah) onResume;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      itemCount: surahs.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return lastReadAsync.when(
            data: (last) {
              if (last == null) return const SizedBox.shrink();
              final service = const QuranService();
              final surah = service.getSurah(last.surahNumber);
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AeemgCard(
                  variant: AeemgCardVariant.active,
                  onTap: () => onResume(last.surahNumber, last.ayahNumber),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.menu_book,
                          color: AppColors.emerald,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Continuer la lecture',
                              style: AppTypography.h3,
                            ),
                            Text(
                              '${surah.nameFrench} · verset ${last.ayahNumber}',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.play_circle_fill,
                        color: AppColors.emerald,
                        size: 28,
                      ),
                    ],
                  ),
                ).animate().fade().scale(begin: const Offset(0.95, 0.95)),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          );
        }
        final surah = surahs[index - 1];
        // Apply a staggered animation to the list items
        return SurahListTile(
              surah: surah,
              onTap: () => onOpenSurah(surah.number),
            )
            .animate(
              delay: Duration(milliseconds: 50 * (index < 15 ? index : 0)),
            ) // Only animate first 15 to avoid lag
            .fade()
            .slideX(begin: 0.05);
      },
    );
  }
}

class _JuzTab extends StatelessWidget {
  const _JuzTab({required this.onOpenJuz});

  final ValueChanged<int> onOpenJuz;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: q.totalJuzCount,
      itemBuilder: (context, index) {
        final juzNumber = index + 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child:
              AeemgCard(
                    onTap: () => onOpenJuz(juzNumber),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.smMd,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.gold.withValues(alpha: 0.15),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.3),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$juzNumber',
                            style: AppTypography.h3.copyWith(
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'Juz $juzNumber',
                            style: AppTypography.h3,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.textTertiary,
                        ),
                      ],
                    ),
                  )
                  .animate(
                    delay: Duration(
                      milliseconds: 20 * (index < 20 ? index : 0),
                    ),
                  )
                  .fade()
                  .slideY(begin: 0.05),
        );
      },
    );
  }
}

class _BookmarksTab extends StatelessWidget {
  const _BookmarksTab({
    required this.bookmarks,
    required this.surahs,
    required this.onOpen,
    required this.onRemove,
  });

  final List<QuranBookmark> bookmarks;
  final List<SurahInfo> surahs;
  final void Function(int surah, int ayah) onOpen;
  final Future<void> Function(int surah, int ayah) onRemove;

  @override
  Widget build(BuildContext context) {
    if (bookmarks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bookmark_border,
                size: 64,
                color: AppColors.textTertiary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Aucun signet.\nAppuyez sur l\'icône signet pendant la lecture.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ).animate().fade();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final b = bookmarks[index];
        final surah = surahs[b.surahNumber - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child:
              AeemgCard(
                    onTap: () => onOpen(b.surahNumber, b.ayahNumber),
                    child: Row(
                      children: [
                        const Icon(Icons.bookmark, color: AppColors.gold),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${surah.nameFrench} · Verset ${b.ayahNumber}',
                                style: AppTypography.h3,
                              ),
                              Text(
                                surah.nameArabic,
                                style: AppTypography.quranArabic(size: 18),
                                textDirection: TextDirection.rtl,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                          ),
                          onPressed: () =>
                              onRemove(b.surahNumber, b.ayahNumber),
                        ),
                      ],
                    ),
                  )
                  .animate(delay: Duration(milliseconds: 50 * index))
                  .fade()
                  .slideX(begin: 0.1),
        );
      },
    );
  }
}

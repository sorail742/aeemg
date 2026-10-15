import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quran/quran.dart' as q;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/supabase_errors.dart';
import '../../../shared/widgets/ds/aeemg_buttons.dart';
import '../../../shared/widgets/ds/aeemg_card.dart';
import '../../../shared/widgets/ds/aeemg_hero.dart';
import '../../../shared/widgets/ds/aeemg_motion.dart';
import '../../../shared/widgets/ds/aeemg_section.dart';
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
      body: IslamicBackground(
        withPattern: true,
        child: Column(
          children: [
            // Pas d'AppBar : en-tête sous la barre d'état.
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm + MediaQuery.paddingOf(context).top,
                AppSpacing.md,
                0,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      AeemgRoundIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'Retour',
                        // Ouvert par un lien direct (web) : retour à l'accueil.
                        onPressed: () => context.canPop()
                            ? context.pop()
                            : context.go('/home'),
                      ),
                      const Spacer(),
                      AeemgRoundIconButton(
                        icon: Icons.record_voice_over_outlined,
                        tooltip: 'Récitateur : $reciterLabel',
                        onPressed: () => showReciterPicker(context, ref),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.smMd),
                  AeemgHero(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.mdLg,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Le Noble Coran', style: AppTypography.h1),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '114 sourates · 30 juz',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.lightEmerald,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'القرآن الكريم',
                          textDirection: TextDirection.rtl,
                          style: AppTypography.quranArabic(
                            size: 30,
                          ).copyWith(color: AppColors.goldLight),
                        ),
                      ],
                    ),
                  ).reveal(context),
                  const SizedBox(height: AppSpacing.md),
                  _QuranTabs(controller: _tabController),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.smMd,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher une sourate ou un mot…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          tooltip: 'Effacer',
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                ),
              ),
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
                    loading: () => const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: AeemgSkeletonTile(),
                    ),
                    error: (e, _) => AeemgEmptyState(
                      icon: Icons.bookmark_border_rounded,
                      title: 'Signets indisponibles',
                      message: friendlySupabaseError(e),
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
                  variant: AeemgCardVariant.accent,
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
                ).reveal(context),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          );
        }
        final surah = surahs[index - 1];
        // Cascade limitée aux premiers éléments ; coupée si les animations sont réduites.
        return SurahListTile(
          surah: surah,
          onTap: () => onOpenSurah(surah.number),
        ).reveal(context, index: index);
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

/// Onglets en pilule : l'onglet actif porte le dégradé du bouton principal.
class _QuranTabs extends StatelessWidget {
  const _QuranTabs({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppRadius.pillBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: AppRadius.pillBorder,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: AppColors.transparent,
        labelColor: AppColors.onPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTypography.caption.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Sourates'),
          Tab(text: 'Mushaf'),
          Tab(text: 'Juz'),
          Tab(text: 'Signets'),
        ],
      ),
    );
  }
}

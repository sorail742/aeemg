import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quran/quran.dart' as q;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/ds/islamic_background.dart';
import '../data/models/quran_models.dart';
import '../data/quran_service.dart';
import 'providers/quran_provider.dart';

class MushafReaderScreen extends ConsumerStatefulWidget {
  const MushafReaderScreen({super.key, this.initialPage = 1});

  final int initialPage;

  @override
  ConsumerState<MushafReaderScreen> createState() => _MushafReaderScreenState();
}

class _MushafReaderScreenState extends ConsumerState<MushafReaderScreen> {
  late final PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(1, q.totalPagesCount);
    _pageController = PageController(initialPage: _currentPage - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    final page = index + 1;
    setState(() => _currentPage = page);
    ref.read(quranBookmarksRepositoryProvider).saveLastMushafPage(page);
    ref.read(quranLastMushafPageProvider.notifier).state = page;
  }

  Future<void> _jumpToPage() async {
    final controller = TextEditingController(text: '$_currentPage');
    final page = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: Text(
          'Aller à la page',
          style: AppTypography.h3.copyWith(color: AppColors.white),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.white),
          decoration: InputDecoration(
            labelText: 'Page (1–604)',
            labelStyle: TextStyle(color: AppColors.textSecondary),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.emerald.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.emerald),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.emerald),
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              Navigator.pop(context, value);
            },
            child: const Text(
              'OK',
              style: TextStyle(
                color: AppColors.deepNavy,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (page != null && page >= 1 && page <= q.totalPagesCount) {
      _pageController.jumpToPage(page - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = const QuranService();
    final arabicSize = ref.watch(quranArabicFontSizeProvider);
    final surahs = ref.watch(allSurahsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.8),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text(
          'Mushaf · Page $_currentPage',
          style: AppTypography.h2.copyWith(color: AppColors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.pin_outlined, color: AppColors.gold),
            tooltip: 'Aller à une page',
            onPressed: _jumpToPage,
          ),
        ],
      ),
      body: IslamicBackground(
        withPattern: true,
        child: PageView.builder(
          controller: _pageController,
          itemCount: q.totalPagesCount,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) {
            final page = service.getMushafPage(index + 1);
            return _MushafPageView(
              page: page,
              surahs: surahs,
              arabicFontSize:
                  arabicSize + 4, // Make mushaf slightly bigger by default
            );
          },
        ),
      ),
    );
  }
}

class _MushafPageView extends StatelessWidget {
  const _MushafPageView({
    required this.page,
    required this.surahs,
    required this.arabicFontSize,
  });

  final MushafPage page;
  final List<SurahInfo> surahs;
  final double arabicFontSize;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF3E0), // Soft sepia/parchment color
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Page ${page.pageNumber}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.deepNavy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Juz ${page.juzNumber}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.deepNavy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(color: AppColors.gold, thickness: 1),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: page.segments.expand((segment) {
                    final surah = surahs[segment.surahNumber - 1];
                    return [
                      if (segment.showSurahHeader) ...[
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.2),
                            border: Border.all(color: AppColors.gold),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                surah.nameArabic,
                                style: AppTypography.quranArabic(
                                  size: arabicFontSize + 6,
                                ).copyWith(color: AppColors.deepNavy),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                surah.nameFrench,
                                textAlign: TextAlign.center,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.deepNavy,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (segment.surahNumber != 9 &&
                            segment.surahNumber != 1) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            q.basmala,
                            style: AppTypography.quranArabic(
                              size: arabicFontSize + 2,
                            ).copyWith(color: AppColors.deepNavy),
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      Text.rich(
                        TextSpan(
                          children: segment.ayahs.map((ayah) {
                            return TextSpan(
                              text: '${ayah.arabic} ',
                              style:
                                  AppTypography.quranArabic(
                                    size: arabicFontSize,
                                  ).copyWith(
                                    color: AppColors.deepNavy,
                                    height: 2.2,
                                  ),
                            );
                          }).toList(),
                        ),
                        textAlign: TextAlign.justify,
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ];
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ).animate().fade(duration: 400.ms),
    );
  }
}

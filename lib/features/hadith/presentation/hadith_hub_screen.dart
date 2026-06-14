import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/ds/aeemg_card.dart';
import '../../../shared/widgets/ds/islamic_background.dart';
import 'providers/hadith_provider.dart';

class HadithHubScreen extends ConsumerStatefulWidget {
  const HadithHubScreen({super.key});

  @override
  ConsumerState<HadithHubScreen> createState() => _HadithHubScreenState();
}

class _HadithHubScreenState extends ConsumerState<HadithHubScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initializationAsync = ref.watch(hadithsInitializationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.8),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text('Les Hadiths', style: AppTypography.h2.copyWith(color: AppColors.white)),
      ),
      body: IslamicBackground(
        withPattern: true,
        child: initializationAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
          error: (err, stack) => Center(child: Text('Erreur : $err', style: const TextStyle(color: AppColors.error))),
          data: (_) {
            final service = ref.read(hadithServiceProvider);
            final hadiths = service.searchHadiths(_searchQuery);
            final categories = hadiths.map((h) => h.category).toSet().toList();

            return Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight + 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: AppColors.white),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un hadith ou un thème…',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                      filled: true,
                      fillColor: AppColors.cardSurface.withValues(alpha: 0.8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.5)),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                    ),
                  ).animate().fade().slideY(begin: -0.2),
                ),
                Expanded(
                  child: hadiths.isEmpty
                      ? Center(child: Text('Aucun hadith trouvé.', style: TextStyle(color: AppColors.textSecondary)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          physics: const BouncingScrollPhysics(),
                          itemCount: categories.length,
                          itemBuilder: (context, catIndex) {
                            final category = categories[catIndex];
                            final categoryHadiths = hadiths
                                .where((h) => h.category == category)
                                .toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: AppColors.gold,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(
                                        category,
                                        style: AppTypography.h3.copyWith(color: AppColors.gold),
                                      ),
                                    ],
                                  ),
                                ).animate(delay: Duration(milliseconds: 100 * catIndex)).fade(),
                                ...categoryHadiths.map((hadith) => Padding(
                                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                      child: AeemgCard(
                                        padding: const EdgeInsets.all(AppSpacing.lg),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.gold.withValues(alpha: 0.15),
                                                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.format_quote, color: AppColors.gold, size: 16),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Hadith #${hadith.id}',
                                                        style: AppTypography.caption.copyWith(
                                                          color: AppColors.gold,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: AppSpacing.md),
                                            Text(
                                              hadith.text,
                                              style: AppTypography.body.copyWith(height: 1.6),
                                            ),
                                            if (hadith.source.isNotEmpty) ...[
                                              const SizedBox(height: AppSpacing.md),
                                              const Divider(color: AppColors.textTertiary, thickness: 0.3),
                                              const SizedBox(height: AppSpacing.sm),
                                              Row(
                                                children: [
                                                  const Icon(Icons.menu_book, color: AppColors.textSecondary, size: 16),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      hadith.source,
                                                      style: AppTypography.caption.copyWith(
                                                        fontStyle: FontStyle.italic,
                                                        color: AppColors.textSecondary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ).animate(delay: Duration(milliseconds: 100 * catIndex + 100)).fade().slideX(begin: 0.05),
                                    ),
                                  ),
                                const SizedBox(height: AppSpacing.lg),
                              ],
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

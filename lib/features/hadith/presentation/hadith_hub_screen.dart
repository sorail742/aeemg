import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/supabase_errors.dart';
import '../../../shared/widgets/ds/aeemg_card.dart';
import '../../../shared/widgets/ds/aeemg_hero.dart';
import '../../../shared/widgets/ds/aeemg_motion.dart';
import '../../../shared/widgets/ds/aeemg_section.dart';
import '../../../shared/widgets/ds/aeemg_star_badge.dart';
import '../../../shared/widgets/ds/islamic_background.dart';
import '../data/models/hadith_model.dart';
import 'providers/hadith_provider.dart';

class HadithHubScreen extends ConsumerStatefulWidget {
  const HadithHubScreen({super.key});

  @override
  ConsumerState<HadithHubScreen> createState() => _HadithHubScreenState();
}

class _HadithHubScreenState extends ConsumerState<HadithHubScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  /// Thème filtré, ou null pour tous les thèmes.
  String? _category;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => setState(() => _searchQuery = _searchController.text),
    );
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
      body: IslamicBackground(
        withPattern: true,
        child: initializationAsync.when(
          loading: () => _Layout(
            header: _header(context, const []),
            children: const [
              AeemgSkeletonTile(),
              SizedBox(height: AppSpacing.sm),
              AeemgSkeletonTile(),
            ],
          ),
          error: (error, _) => _Layout(
            header: _header(context, const []),
            children: [
              AeemgEmptyState(
                compact: true,
                icon: Icons.error_outline_rounded,
                title: 'Hadiths indisponibles',
                message: friendlySupabaseError(error),
              ),
            ],
          ),
          data: (_) {
            final service = ref.read(hadithServiceProvider);
            final categories = service.getCategories();
            final hadiths = service
                .searchHadiths(_searchQuery)
                .where((h) => _category == null || h.category == _category)
                .toList();

            return _Layout(
              header: _header(context, categories),
              children: hadiths.isEmpty
                  ? const [
                      AeemgEmptyState(
                        compact: true,
                        icon: Icons.search_off_rounded,
                        title: 'Aucun hadith trouvé',
                        message: 'Essayez un autre mot ou un autre thème.',
                      ),
                    ]
                  : [
                      for (var i = 0; i < hadiths.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.smMd,
                          ),
                          child: _HadithCard(
                            hadith: hadiths[i],
                          ).reveal(context, index: i),
                        ),
                    ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(BuildContext context, List<String> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            AeemgRoundIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Retour',
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/home'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.smMd),
        AeemgHero(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Les Hadiths', style: AppTypography.h1),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Paroles du Prophète ﷺ, classées par thème.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.lightEmerald,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'الحديث',
                textDirection: TextDirection.rtl,
                style: AppTypography.quranArabic(
                  size: 30,
                ).copyWith(color: AppColors.goldLight),
              ),
            ],
          ),
        ).reveal(context),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher un hadith ou un thème…',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    tooltip: 'Effacer',
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: _searchController.clear,
                  )
                : null,
          ),
        ),
        if (categories.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.smMd),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _CategoryChip(
                  label: 'Tous',
                  selected: _category == null,
                  onTap: () => setState(() => _category = null),
                ),
                for (final c in categories)
                  _CategoryChip(
                    label: c,
                    selected: _category == c,
                    onTap: () => setState(() => _category = c),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// En-tête fixe sous la barre d'état, puis liste défilante.
class _Layout extends StatelessWidget {
  const _Layout({required this.header, required this.children});

  final Widget header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm + MediaQuery.paddingOf(context).top,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: [
        header,
        const SizedBox(height: AppSpacing.md),
        ...children,
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.pillBorder,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: selected ? AppGradients.gold : null,
              color: selected ? null : AppColors.cardSurface,
              borderRadius: AppRadius.pillBorder,
              border: Border.all(
                color: selected ? AppColors.gold : AppColors.border,
              ),
            ),
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: selected ? AppColors.deepNavy : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HadithCard extends StatelessWidget {
  const _HadithCard({required this.hadith});

  final Hadith hadith;

  @override
  Widget build(BuildContext context) {
    return AeemgCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: const BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.card),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AeemgStarBadge(
                          label: '${hadith.id}',
                          size: 36,
                          tint: AppColors.gold,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            hadith.category.toUpperCase(),
                            style: AppTypography.overline.copyWith(
                              color: AppColors.goldLight,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Copier le hadith',
                          icon: const Icon(
                            Icons.copy_rounded,
                            size: 18,
                            color: AppColors.textTertiary,
                          ),
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(
                                text: '${hadith.text}\n— ${hadith.source}',
                              ),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Hadith copié.')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      hadith.text,
                      style: AppTypography.bodyLarge.copyWith(height: 1.6),
                    ),
                    if (hadith.source.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.smMd),
                      Row(
                        children: [
                          const Icon(
                            Icons.menu_book_outlined,
                            color: AppColors.textTertiary,
                            size: 16,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              hadith.source,
                              style: AppTypography.caption.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

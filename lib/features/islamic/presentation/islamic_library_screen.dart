import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/ds/aeemg_card.dart';
import '../../../shared/widgets/ds/islamic_background.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/islamic_repository.dart';
import 'providers/islamic_provider.dart';

class IslamicLibraryScreen extends ConsumerStatefulWidget {
  const IslamicLibraryScreen({super.key});

  @override
  ConsumerState<IslamicLibraryScreen> createState() =>
      _IslamicLibraryScreenState();
}

class _IslamicLibraryScreenState extends ConsumerState<IslamicLibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contentsAsync = ref.watch(islamicLibraryProvider);
    final favoritesAsync = ref.watch(islamicFavoritesProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.9),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text(
          'Rappels islamiques',
          style: AppTypography.h2.copyWith(color: AppColors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Bibliothèque'),
            Tab(text: 'Favoris'),
          ],
        ),
      ),
      body: IslamicBackground(
        withPattern: true,
        child: contentsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.emerald),
          ),
          error: (e, _) => Center(
            child: Text(
              'Erreur : $e',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
          data: (contents) {
            final favoriteIds = favoritesAsync.maybeWhen(
              data: (ids) => ids,
              orElse: () => <String>{},
            );
            final favorites = contents
                .where((c) => favoriteIds.contains(c.id))
                .toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _ContentList(
                  contents: contents,
                  favoriteIds: favoriteIds,
                  userId: user?.id,
                  onChanged: () => ref.invalidate(islamicFavoritesProvider),
                ),
                favorites.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.favorite_border,
                              size: 64,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Aucun favori pour le moment.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : _ContentList(
                        contents: favorites,
                        favoriteIds: favoriteIds,
                        userId: user?.id,
                        onChanged: () =>
                            ref.invalidate(islamicFavoritesProvider),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ContentList extends ConsumerWidget {
  const _ContentList({
    required this.contents,
    required this.favoriteIds,
    required this.userId,
    required this.onChanged,
  });

  final List<IslamicContent> contents;
  final Set<String> favoriteIds;
  final String? userId;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (contents.isEmpty) {
      return Center(
        child: Text(
          'Bibliothèque vide pour le moment.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + kToolbarHeight + 64,
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.xl,
      ),
      physics: const BouncingScrollPhysics(),
      itemCount: contents.length,
      itemBuilder: (context, index) {
        final item = contents[index];
        final isFavorite = favoriteIds.contains(item.id);
        final isVerse = item.contentType == 'verse';
        final iconColor = isVerse ? AppColors.gold : AppColors.emerald;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child:
              AeemgCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    onTap: () => _showDetail(context, item, isFavorite, ref),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isVerse ? Icons.menu_book : Icons.auto_stories,
                            color: iconColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title ?? item.contentType,
                                style: AppTypography.h3,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (userId != null)
                          IconButton(
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite
                                  ? AppColors.gold
                                  : AppColors.textTertiary,
                            ),
                            onPressed: () async {
                              final repo = ref.read(islamicRepositoryProvider);
                              if (isFavorite) {
                                await repo.removeFavorite(userId!, item.id);
                              } else {
                                await repo.addFavorite(userId!, item.id);
                              }
                              onChanged();
                            },
                          ),
                      ],
                    ),
                  )
                  .animate(delay: Duration(milliseconds: 50 * index))
                  .fade()
                  .slideX(begin: 0.05),
        );
      },
    );
  }

  void _showDetail(
    BuildContext context,
    IslamicContent item,
    bool isFavorite,
    WidgetRef ref,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.emerald.withValues(alpha: 0.2)),
        ),
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(item.title ?? 'Rappel', style: AppTypography.h2),
            if (item.source != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                item.source!,
                style: AppTypography.caption.copyWith(color: AppColors.gold),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text(item.body, style: AppTypography.body.copyWith(height: 1.6)),
            if (item.translationPeul != null) ...[
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Peul',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.emerald,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                item.translationPeul!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.white,
                      side: BorderSide(
                        color: AppColors.emerald.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      final text = [
                        if (item.title != null) item.title,
                        item.body,
                        if (item.source != null) '— ${item.source}',
                      ].join('\n');
                      Clipboard.setData(ClipboardData(text: text));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Texte copié.'),
                          backgroundColor: AppColors.emerald,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 20),
                    label: const Text('Copier'),
                  ),
                ),
                if (userId != null) ...[
                  const SizedBox(width: AppSpacing.md),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor:
                          (isFavorite
                                  ? AppColors.gold
                                  : AppColors.cardSurfaceLight)
                              .withValues(alpha: 0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(14),
                    ),
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? AppColors.gold
                          : AppColors.textSecondary,
                    ),
                    onPressed: () async {
                      final repo = ref.read(islamicRepositoryProvider);
                      if (isFavorite) {
                        await repo.removeFavorite(userId!, item.id);
                      } else {
                        await repo.addFavorite(userId!, item.id);
                      }
                      onChanged();
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

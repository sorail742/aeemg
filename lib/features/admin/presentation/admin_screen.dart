import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/ds/aeemg_card.dart';
import '../../../shared/widgets/ds/aeemg_buttons.dart';
import '../../../shared/widgets/ds/islamic_background.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../members/presentation/providers/members_provider.dart';
import '../data/admin_repository.dart';
import 'widgets/admin_finance_dialog.dart';
import 'widgets/admin_islamic_dialog.dart';

// ── Providers ──────────────────────────────────────────────────
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(supabaseClientProvider));
});

final adminStatsProvider = FutureProvider<AdminStats>((ref) {
  return ref.read(adminRepositoryProvider).fetchStats();
});

final betaSummaryProvider = FutureProvider<BetaFeedbackSummary>((ref) {
  return ref.read(adminRepositoryProvider).fetchBetaSummary();
});

final adminMembersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(adminRepositoryProvider).fetchAllMembers();
});

final adminAnnouncementsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) {
  return ref.read(adminRepositoryProvider).fetchAnnouncements();
});

final adminEventsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(adminRepositoryProvider).fetchEvents();
});

final adminDonationsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) {
  return ref.read(adminRepositoryProvider).fetchDonations();
});

final adminPostsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(adminRepositoryProvider).fetchPosts();
});

final adminIslamicProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(adminRepositoryProvider).fetchIslamicContents();
});

final adminMonthlyReportsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) {
  return ref.read(adminRepositoryProvider).fetchMonthlyReports();
});

// ── Sections de navigation ────────────────────────────────────
enum AdminSection { dashboard, members, infos, finances, moderation, islam }

extension AdminSectionExtension on AdminSection {
  String get label {
    switch (this) {
      case AdminSection.dashboard:
        return 'Tableau de bord';
      case AdminSection.members:
        return 'Membres';
      case AdminSection.infos:
        return 'Événements & Infos';
      case AdminSection.finances:
        return 'Finances';
      case AdminSection.moderation:
        return 'Modération';
      case AdminSection.islam:
        return 'Contenu Islamique';
    }
  }

  IconData get icon {
    switch (this) {
      case AdminSection.dashboard:
        return Icons.dashboard_outlined;
      case AdminSection.members:
        return Icons.people_outline;
      case AdminSection.infos:
        return Icons.campaign_outlined;
      case AdminSection.finances:
        return Icons.account_balance_wallet_outlined;
      case AdminSection.moderation:
        return Icons.gpp_maybe_outlined;
      case AdminSection.islam:
        return Icons.auto_stories_outlined;
    }
  }

  IconData get iconFilled {
    switch (this) {
      case AdminSection.dashboard:
        return Icons.dashboard;
      case AdminSection.members:
        return Icons.people;
      case AdminSection.infos:
        return Icons.campaign;
      case AdminSection.finances:
        return Icons.account_balance_wallet;
      case AdminSection.moderation:
        return Icons.gpp_maybe;
      case AdminSection.islam:
        return Icons.auto_stories;
    }
  }

  Color get color {
    switch (this) {
      case AdminSection.dashboard:
        return AppColors.emerald;
      case AdminSection.members:
        return const Color(0xFF3A86FF);
      case AdminSection.infos:
        return AppColors.gold;
      case AdminSection.finances:
        return AppColors.emerald;
      case AdminSection.moderation:
        return AppColors.error;
      case AdminSection.islam:
        return AppColors.gold;
    }
  }
}

// ── Écran Admin ────────────────────────────────────────────────
class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  AdminSection _currentSection = AdminSection.dashboard;
  bool _sidebarOpen = false;
  late AnimationController _sidebarController;
  late Animation<double> _sidebarAnimation;

  static const double _sidebarWidth = 260.0;

  @override
  void initState() {
    super.initState();
    _sidebarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _sidebarAnimation = CurvedAnimation(
      parent: _sidebarController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _sidebarController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() => _sidebarOpen = !_sidebarOpen);
    if (_sidebarOpen) {
      _sidebarController.forward();
    } else {
      _sidebarController.reverse();
    }
  }

  void _selectSection(AdminSection section) {
    setState(() {
      _currentSection = section;
    });
    _toggleSidebar();
  }

  Widget _buildCurrentSection() {
    switch (_currentSection) {
      case AdminSection.dashboard:
        return _StatsTab();
      case AdminSection.members:
        return _MembersTab();
      case AdminSection.infos:
        return _InfosTab();
      case AdminSection.finances:
        return _FinancesTab();
      case AdminSection.moderation:
        return _ModerationTab();
      case AdminSection.islam:
        return _IslamTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.emerald),
        ),
        error: (e, _) => Center(
          child: Text('$e', style: const TextStyle(color: AppColors.error)),
        ),
        data: (profile) {
          if (profile == null || !profile.isStaff) {
            return IslamicBackground(
              withPattern: true,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.error.withValues(alpha: 0.1),
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        color: AppColors.error,
                        size: 64,
                      ),
                    ).animate().scale(curve: Curves.easeOutBack),
                    const SizedBox(height: 20),
                    Text('Accès réservé', style: AppTypography.h1),
                    const SizedBox(height: 8),
                    Text(
                      'Cette section est réservée au staff AEEMG.',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          }

          return IslamicBackground(
            withPattern: true,
            child: Stack(
              children: [
                // ── Contenu Principal ──────────────────────────
                Column(
                  children: [
                    // AppBar
                    SafeArea(
                      bottom: false,
                      child: _AdminAppBar(
                        sidebarOpen: _sidebarOpen,
                        currentSection: _currentSection,
                        profile: profile,
                        onMenuTap: _toggleSidebar,
                      ),
                    ),
                    // Body
                    Expanded(child: _buildCurrentSection()),
                  ],
                ),

                // ── Overlay sombre ─────────────────────────────
                AnimatedBuilder(
                  animation: _sidebarAnimation,
                  builder: (context, _) {
                    if (_sidebarAnimation.value == 0) {
                      return const SizedBox.shrink();
                    }
                    return GestureDetector(
                      onTap: _toggleSidebar,
                      child: Container(
                        color: Colors.black.withValues(
                          alpha: _sidebarAnimation.value * 0.6,
                        ),
                      ),
                    );
                  },
                ),

                // ── Sidebar ────────────────────────────────────
                AnimatedBuilder(
                  animation: _sidebarAnimation,
                  builder: (context, child) {
                    final offset =
                        -_sidebarWidth * (1 - _sidebarAnimation.value);
                    return Transform.translate(
                      offset: Offset(offset, 0),
                      child: child,
                    );
                  },
                  child: _AdminSidebar(
                    currentSection: _currentSection,
                    profile: profile,
                    onSectionSelected: _selectSection,
                    onClose: _toggleSidebar,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ADMIN APP BAR
// ══════════════════════════════════════════════════════════════
class _AdminAppBar extends StatelessWidget {
  final bool sidebarOpen;
  final AdminSection currentSection;
  final dynamic profile;
  final VoidCallback onMenuTap;

  const _AdminAppBar({
    required this.sidebarOpen,
    required this.currentSection,
    required this.profile,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: AppColors.cardSurface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          // Menu button
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: sidebarOpen
                  ? AppColors.gold.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  sidebarOpen ? Icons.close : Icons.menu,
                  key: ValueKey(sidebarOpen),
                  color: sidebarOpen ? AppColors.gold : AppColors.white,
                ),
              ),
              onPressed: onMenuTap,
            ),
          ),
          const SizedBox(width: 8),
          // Icon de la section
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: currentSection.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              currentSection.iconFilled,
              color: currentSection.color,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  currentSection.label,
                  style: AppTypography.h3.copyWith(fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Administration AEEMG',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Badge admin
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            ),
            child: Text(
              (profile.roleLabel as String).toUpperCase(),
              style: AppTypography.caption.copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: -0.05);
  }
}

// ══════════════════════════════════════════════════════════════
// SIDEBAR
// ══════════════════════════════════════════════════════════════
class _AdminSidebar extends StatelessWidget {
  final AdminSection currentSection;
  final dynamic profile;
  final ValueChanged<AdminSection> onSectionSelected;
  final VoidCallback onClose;

  const _AdminSidebar({
    required this.currentSection,
    required this.profile,
    required this.onSectionSelected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 30,
              offset: const Offset(10, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec profil
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.gold.withValues(alpha: 0.15),
                      AppColors.emerald.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold.withValues(alpha: 0.2),
                            border: Border.all(color: AppColors.gold, width: 2),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            color: AppColors.gold,
                            size: 26,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: onClose,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      profile.fullName as String? ?? 'Administrateur',
                      style: AppTypography.h2.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (profile.roleLabel as String).toUpperCase(),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.emerald,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Navigation items
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'NAVIGATION',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                    letterSpacing: 1.5,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  children: AdminSection.values.map((section) {
                    final isActive = currentSection == section;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: InkWell(
                        onTap: () => onSectionSelected(section),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? section.color.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: isActive
                                ? Border.all(
                                    color: section.color.withValues(alpha: 0.3),
                                  )
                                : Border.all(color: Colors.transparent),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isActive ? section.iconFilled : section.icon,
                                color: isActive
                                    ? section.color
                                    : AppColors.textSecondary,
                                size: 22,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  section.label,
                                  style: AppTypography.body.copyWith(
                                    color: isActive
                                        ? AppColors.white
                                        : AppColors.textSecondary,
                                    fontWeight: isActive
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (isActive)
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: section.color,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Footer
              const Divider(color: AppColors.cardSurfaceLight, height: 1),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: AppColors.textTertiary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AEEMG Admin Panel',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────
Widget _emptyTile(String text) => Center(
  child: Padding(
    padding: const EdgeInsets.all(AppSpacing.xl),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.textTertiary.withValues(alpha: 0.1),
          ),
          child: const Icon(
            Icons.inbox_outlined,
            size: 48,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(text, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    ),
  ),
);

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  const _ConfirmDialog(this.title, this.content);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: const TextStyle(color: AppColors.white)),
      content: Text(
        content,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'Annuler',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'Confirmer',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 1 : STATS
// ══════════════════════════════════════════════════════════════
class _StatsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final feedbackAsync = ref.watch(betaSummaryProvider);

    return RefreshIndicator(
      color: AppColors.emerald,
      onRefresh: () async {
        ref.invalidate(adminStatsProvider);
        ref.invalidate(betaSummaryProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          statsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.emerald),
            ),
            error: (e, _) => Text(
              'Erreur : $e',
              style: const TextStyle(color: AppColors.error),
            ),
            data: (s) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vue d\'ensemble', style: AppTypography.h2),
                const SizedBox(height: AppSpacing.md),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 1.4,
                  children: [
                    _StatCard(
                      icon: Icons.people,
                      label: 'Membres',
                      value: '${s.totalMembers}',
                      sub: '+${s.newMembersThisMonth} ce mois',
                      color: const Color(0xFF3A86FF),
                    ),
                    _StatCard(
                      icon: Icons.chat_bubble,
                      label: 'Messages',
                      value: '${s.totalMessages}',
                      sub: 'Total envoyés',
                      color: AppColors.emerald,
                    ),
                    _StatCard(
                      icon: Icons.event,
                      label: 'Événements',
                      value: '${s.upcomingEvents}',
                      sub: 'À venir',
                      color: AppColors.gold,
                    ),
                    _StatCard(
                      icon: Icons.volunteer_activism,
                      label: 'Dons',
                      value: '${s.totalDonations.toStringAsFixed(0)} GNF',
                      sub: 'Total collecté',
                      color: AppColors.error,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Retours Beta', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.md),
          feedbackAsync.when(
            loading: () =>
                const LinearProgressIndicator(color: AppColors.emerald),
            error: (e, _) => Text(
              'Erreur : $e',
              style: const TextStyle(color: AppColors.error),
            ),
            data: (summary) {
              if (summary.count == 0) return _emptyTile('Aucun retour beta.');
              return Column(
                children: [
                  AeemgCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.gold, size: 32),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          '${summary.averageRating.toStringAsFixed(1)} / 5',
                          style: AppTypography.h1,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.emerald.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${summary.count} avis',
                            style: const TextStyle(
                              color: AppColors.emerald,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...summary.recent
                      .take(5)
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: AeemgCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ...List.generate(
                                      5,
                                      (i) => Icon(
                                        Icons.star,
                                        size: 14,
                                        color: i < (item['rating'] as int? ?? 0)
                                            ? AppColors.gold
                                            : Colors.white24,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      DateFormat('d MMM', 'fr').format(
                                        DateTime.parse(
                                          item['created_at'] as String,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  item['message'] as String? ??
                                      'Aucun commentaire',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AeemgCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: AppTypography.h2.copyWith(fontSize: 20)),
          Text(
            sub,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 2 : MEMBRES
// ══════════════════════════════════════════════════════════════
class _MembersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(adminMembersProvider);
    final repo = ref.read(adminRepositoryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.emerald,
        elevation: 6,
        icon: const Icon(Icons.person_add, color: AppColors.white),
        label: const Text(
          'Créer membre',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () => _showCreateUserDialog(context),
      ),
      body: RefreshIndicator(
        color: AppColors.emerald,
        onRefresh: () async => ref.invalidate(adminMembersProvider),
        child: membersAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.emerald),
          ),
          error: (e, _) => Center(
            child: Text(
              'Erreur : $e',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
          data: (members) {
            if (members.isEmpty) return _emptyTile('Aucun membre trouvé.');
            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: members.length,
              itemBuilder: (context, i) {
                final m = members[i];
                final role = m['role'] as String? ?? 'member';
                return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AeemgCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.emerald.withValues(
                                alpha: 0.15,
                              ),
                              backgroundImage: m['avatar_url'] != null
                                  ? NetworkImage(m['avatar_url'] as String)
                                  : null,
                              child: m['avatar_url'] == null
                                  ? Text(
                                      (m['full_name'] as String? ?? 'U')[0]
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.emerald,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m['full_name'] as String? ?? 'Inconnu',
                                    style: AppTypography.h3,
                                  ),
                                  Text(
                                    m['phone'] as String? ??
                                        m['email'] as String? ??
                                        '',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (role == 'admin'
                                            ? AppColors.gold
                                            : (role == 'staff'
                                                  ? AppColors.emerald
                                                  : AppColors.textTertiary))
                                        .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                role.toUpperCase(),
                                style: AppTypography.caption.copyWith(
                                  color: role == 'admin'
                                      ? AppColors.gold
                                      : (role == 'staff'
                                            ? AppColors.emerald
                                            : AppColors.textSecondary),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              color: AppColors.cardSurfaceLight,
                              icon: const Icon(
                                Icons.more_vert,
                                color: AppColors.textSecondary,
                              ),
                              onSelected: (val) async {
                                if (val == 'delete') {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => const _ConfirmDialog(
                                      'Supprimer ce membre ?',
                                      'Cette action est irréversible.',
                                    ),
                                  );
                                  if (confirm == true) {
                                    await repo.deleteMember(m['id'] as String);
                                    ref.invalidate(adminMembersProvider);
                                  }
                                } else {
                                  await repo.updateMemberRole(
                                    m['id'] as String,
                                    val,
                                  );
                                  ref.invalidate(adminMembersProvider);
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'member',
                                  child: Text(
                                    'Mettre membre',
                                    style: TextStyle(color: AppColors.white),
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'staff',
                                  child: Text(
                                    'Promouvoir staff',
                                    style: TextStyle(color: AppColors.emerald),
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'admin',
                                  child: Text(
                                    'Promouvoir admin',
                                    style: TextStyle(color: AppColors.gold),
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    'Supprimer',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                    .animate(delay: Duration(milliseconds: 40 * i))
                    .fade()
                    .slideX(begin: 0.05);
              },
            );
          },
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 3 : INFOS & ÉVÉNEMENTS
// ══════════════════════════════════════════════════════════════
class _InfosTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(adminAnnouncementsProvider);
    final eventsAsync = ref.watch(adminEventsProvider);
    final repo = ref.read(adminRepositoryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'event',
            backgroundColor: AppColors.emerald,
            elevation: 6,
            icon: const Icon(Icons.event, color: AppColors.white),
            label: const Text(
              'Créer un événement',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () => _showEventDialog(context, ref, repo),
          ),
          const SizedBox(height: AppSpacing.sm),
          FloatingActionButton.extended(
            heroTag: 'announcement',
            backgroundColor: AppColors.gold,
            elevation: 6,
            icon: const Icon(Icons.campaign, color: AppColors.black),
            label: const Text(
              'Nouvelle annonce',
              style: TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () => _showAnnouncementDialog(context, ref, repo),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Événements en attente
          eventsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.emerald),
            ),
            error: (e, _) =>
                const SizedBox.shrink(), // Silently ignore if column missing
            data: (events) {
              final unapproved = events
                  .where((e) => !(e['is_approved'] as bool? ?? true))
                  .toList();
              if (unapproved.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Événements en attente (${unapproved.length})',
                        style: AppTypography.h2,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...unapproved.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AeemgCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.event,
                                color: AppColors.gold,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e['title'] as String? ?? '',
                                    style: AppTypography.h3,
                                  ),
                                  Text(
                                    e['location'] as String? ??
                                        'Lieu non précisé',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.check_circle,
                                color: AppColors.emerald,
                              ),
                              tooltip: 'Approuver',
                              onPressed: () async {
                                await repo.approveEvent(e['id'] as String);
                                ref.invalidate(adminEventsProvider);
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: AppColors.error,
                                size: 20,
                              ),
                              onPressed: () async {
                                await repo.deleteEvent(e['id'] as String);
                                ref.invalidate(adminEventsProvider);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              );
            },
          ),
          // Tous les événements
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.emerald,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text('Tous les événements', style: AppTypography.h2),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          eventsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.emerald),
            ),
            error: (e, _) => Text(
              'Erreur événements : $e',
              style: const TextStyle(color: AppColors.error),
            ),
            data: (events) {
              if (events.isEmpty) return _emptyTile('Aucun événement.');
              return Column(
                children: events.map((e) {
                  final approved = e['is_approved'] as bool? ?? true;
                  final startsAt = e['starts_at'] != null
                      ? DateFormat(
                          'd MMM yyyy',
                          'fr',
                        ).format(DateTime.parse(e['starts_at'] as String))
                      : '—';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AeemgCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  (approved
                                          ? AppColors.emerald
                                          : AppColors.gold)
                                      .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.event,
                              color: approved
                                  ? AppColors.emerald
                                  : AppColors.gold,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e['title'] as String? ?? '',
                                  style: AppTypography.h3,
                                ),
                                Text(
                                  startsAt,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (!approved)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.gold.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'EN ATTENTE',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.gold,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (!approved)
                            IconButton(
                              icon: const Icon(
                                Icons.check_circle,
                                color: AppColors.emerald,
                                size: 20,
                              ),
                              onPressed: () async {
                                await repo.approveEvent(e['id'] as String);
                                ref.invalidate(adminEventsProvider);
                              },
                            ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                              size: 20,
                            ),
                            onPressed: () async {
                              await repo.deleteEvent(e['id'] as String);
                              ref.invalidate(adminEventsProvider);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          // Annonces
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text('Annonces publiées', style: AppTypography.h2),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          announcementsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(
              'Erreur annonces : $e',
              style: const TextStyle(color: AppColors.error),
            ),
            data: (announcements) {
              if (announcements.isEmpty) {
                return _emptyTile('Aucune annonce publiée.');
              }
              return Column(
                children: announcements
                    .map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AeemgCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: (a['is_important'] as bool? ?? false)
                                      ? AppColors.error
                                      : AppColors.gold,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            a['title'] as String? ?? '',
                                            style: AppTypography.h3,
                                          ),
                                        ),
                                        if (a['is_important'] as bool? ?? false)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.error.withValues(
                                                alpha: 0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'URGENT',
                                              style: AppTypography.caption
                                                  .copyWith(
                                                    color: AppColors.error,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    // content est la vraie colonne (pas body)
                                    Text(
                                      a['content'] as String? ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  await repo.deleteAnnouncement(
                                    a['id'] as String,
                                  );
                                  ref.invalidate(adminAnnouncementsProvider);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showAnnouncementDialog(
    BuildContext context,
    WidgetRef ref,
    AdminRepository repo,
  ) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    bool isImportant = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
          ),
          title: Row(
            children: [
              const Icon(Icons.campaign, color: AppColors.gold),
              const SizedBox(width: 8),
              Text('Nouvelle annonce', style: AppTypography.h2),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  labelText: 'Titre',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.cardSurfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                maxLines: 4,
                style: const TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  labelText: 'Contenu',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.cardSurfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: isImportant,
                    onChanged: (v) => setState(() => isImportant = v!),
                    activeColor: AppColors.error,
                  ),
                  const Text(
                    'Marquer comme urgent',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Annuler',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.black,
              ),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                await repo.createAnnouncement(
                  title: titleCtrl.text.trim(),
                  content: contentCtrl.text.trim(),
                  isImportant: isImportant,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                ref.invalidate(adminAnnouncementsProvider);
              },
              child: const Text(
                'Publier',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 4 : FINANCES
// ══════════════════════════════════════════════════════════════
class _FinancesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donationsAsync = ref.watch(adminDonationsProvider);
    final reportsAsync = ref.watch(adminMonthlyReportsProvider);
    final repo = ref.read(adminRepositoryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.emerald,
        elevation: 6,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: const Text(
          'Nouveau bilan',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AdminFinanceDialog(
              repository: repo,
              onSuccess: () => ref.invalidate(adminMonthlyReportsProvider),
            ),
          );
        },
      ),
      body: RefreshIndicator(
        color: AppColors.emerald,
        onRefresh: () async {
          ref.invalidate(adminDonationsProvider);
          ref.invalidate(adminMonthlyReportsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // ── Résumé dons ──────────────────────────────────
            donationsAsync.when(
              loading: () => const SizedBox(
                height: 80,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.emerald),
                ),
              ),
              error: (e, _) => Text(
                'Erreur dons : $e',
                style: const TextStyle(color: AppColors.error),
              ),
              data: (donations) {
                final total = donations.fold<double>(
                  0,
                  (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0),
                );
                return AeemgCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: AppColors.error,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total des dons reçus',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${total.toStringAsFixed(0)} GNF',
                              style: AppTypography.h1.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                            Text(
                              '${donations.length} dons enregistrés',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            // ── Bilans mensuels ───────────────────────────────
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.emerald,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Bilans mensuels publiés', style: AppTypography.h2),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            reportsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.emerald),
              ),
              error: (e, _) => Text(
                'Erreur bilans : $e',
                style: const TextStyle(color: AppColors.error),
              ),
              data: (reports) {
                if (reports.isEmpty) {
                  return _emptyTile(
                    'Aucun bilan publié. Créez-en un via le bouton ci-dessous.',
                  );
                }
                final monthNames = [
                  '',
                  'Janvier',
                  'Février',
                  'Mars',
                  'Avril',
                  'Mai',
                  'Juin',
                  'Juillet',
                  'Août',
                  'Septembre',
                  'Octobre',
                  'Novembre',
                  'Décembre',
                ];
                return Column(
                  children: reports.asMap().entries.map((entry) {
                    final r = entry.value;
                    final income = (r['total_income'] as num?)?.toDouble() ?? 0;
                    final expense =
                        (r['total_expense'] as num?)?.toDouble() ?? 0;
                    final balance = income - expense;
                    final isPositive = balance >= 0;
                    final month = r['month'] as int? ?? 1;
                    final year = r['year'] as int? ?? DateTime.now().year;
                    return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: AeemgCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.emerald.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.account_balance,
                                        color: AppColors.emerald,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${monthNames[month]} $year',
                                            style: AppTypography.h3,
                                          ),
                                          Text(
                                            'Bilan officiel',
                                            style: AppTypography.caption
                                                .copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            (isPositive
                                                    ? AppColors.emerald
                                                    : AppColors.error)
                                                .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${isPositive ? '+' : ''}${balance.toStringAsFixed(0)} GNF',
                                        style: AppTypography.caption.copyWith(
                                          color: isPositive
                                              ? AppColors.emerald
                                              : AppColors.error,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _FinanceCell(
                                        label: 'Recettes',
                                        value:
                                            '${income.toStringAsFixed(0)} GNF',
                                        color: AppColors.emerald,
                                        icon: Icons.arrow_downward,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: _FinanceCell(
                                        label: 'Dépenses',
                                        value:
                                            '${expense.toStringAsFixed(0)} GNF',
                                        color: AppColors.error,
                                        icon: Icons.arrow_upward,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                        .animate(delay: Duration(milliseconds: 50 * entry.key))
                        .fade()
                        .slideY(begin: 0.05);
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            // ── Historique des dons ───────────────────────────
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Historique des dons', style: AppTypography.h2),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            donationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const SizedBox.shrink(),
              data: (donations) {
                if (donations.isEmpty) {
                  return _emptyTile('Aucun don enregistré.');
                }
                return Column(
                  children: donations.asMap().entries.map((entry) {
                    final d = entry.value;
                    // donor_name vient de profiles join
                    final profile = d['profiles'] as Map<String, dynamic>?;
                    final donorName = d['is_anonymous'] as bool? ?? false
                        ? 'Anonyme'
                        : profile?['full_name'] as String? ?? 'Inconnu';
                    final category = d['category'] as String? ?? 'general';
                    final status = d['status'] as String? ?? 'pending';
                    final statusColor = status == 'completed'
                        ? AppColors.emerald
                        : (status == 'failed'
                              ? AppColors.error
                              : AppColors.gold);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child:
                          AeemgCard(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withValues(
                                          alpha: 0.15,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.volunteer_activism,
                                        color: AppColors.error,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            donorName,
                                            style: AppTypography.h3,
                                          ),
                                          Text(
                                            category,
                                            style: AppTypography.caption
                                                .copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${d['amount']} GNF',
                                          style: AppTypography.h3.copyWith(
                                            color: AppColors.error,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            status.toUpperCase(),
                                            style: AppTypography.caption
                                                .copyWith(
                                                  color: statusColor,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                              .animate(
                                delay: Duration(milliseconds: 40 * entry.key),
                              )
                              .fade()
                              .slideX(begin: 0.05),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _FinanceCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _FinanceCell({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  style: AppTypography.bodySmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 5 : MODÉRATION
// ══════════════════════════════════════════════════════════════
class _ModerationTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(adminPostsProvider);
    final repo = ref.read(adminRepositoryProvider);

    return RefreshIndicator(
      color: AppColors.error,
      onRefresh: () async => ref.invalidate(adminPostsProvider),
      child: postsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.error),
        ),
        error: (e, _) => Center(
          child: Text(
            'Erreur : $e',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
        data: (posts) {
          if (posts.isEmpty) return _emptyTile('Aucune publication à modérer.');
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: posts.length,
            itemBuilder: (context, i) {
              final p = posts[i];
              final author =
                  (p['profiles'] as Map<String, dynamic>?)?['full_name']
                      as String? ??
                  'Inconnu';
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AeemgCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            color: AppColors.textSecondary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            author,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.error,
                                size: 20,
                              ),
                              tooltip: 'Supprimer',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => const _ConfirmDialog(
                                    'Supprimer ce post ?',
                                    'Cette action est irréversible.',
                                  ),
                                );
                                if (confirm == true) {
                                  await repo.deletePost(p['id'] as String);
                                  ref.invalidate(adminPostsProvider);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurfaceLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          p['content'] as String? ?? '',
                          style: AppTypography.body.copyWith(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate(delay: Duration(milliseconds: 40 * i)).fade();
            },
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 6 : ISLAM
// ══════════════════════════════════════════════════════════════
class _IslamTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentsAsync = ref.watch(adminIslamicProvider);
    final repo = ref.read(adminRepositoryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.gold,
        elevation: 6,
        icon: const Icon(Icons.add, color: AppColors.black),
        label: const Text(
          'Nouveau contenu',
          style: TextStyle(color: AppColors.black, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AdminIslamicDialog(
              repository: repo,
              onSuccess: () => ref.invalidate(adminIslamicProvider),
            ),
          );
        },
      ),
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () async => ref.invalidate(adminIslamicProvider),
        child: contentsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          ),
          error: (e, _) => Center(
            child: Text(
              'Erreur : $e',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
          data: (contents) {
            if (contents.isEmpty) return _emptyTile('Aucun contenu islamique.');
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                80,
              ),
              itemCount: contents.length,
              itemBuilder: (context, i) {
                final c = contents[i];
                final type = c['content_type'] as String? ?? 'Inconnu';
                final typeColor = type == 'verse'
                    ? AppColors.gold
                    : (type == 'hadith'
                          ? AppColors.emerald
                          : const Color(0xFF3A86FF));
                return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AeemgCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                type == 'verse'
                                    ? Icons.menu_book
                                    : (type == 'hadith'
                                          ? Icons.auto_stories
                                          : Icons.format_quote),
                                color: typeColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c['title'] as String? ?? type,
                                    style: AppTypography.h3,
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: typeColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      type,
                                      style: AppTypography.caption.copyWith(
                                        color: typeColor,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.error,
                                size: 20,
                              ),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => const _ConfirmDialog(
                                    'Supprimer le contenu ?',
                                    '',
                                  ),
                                );
                                if (confirm == true) {
                                  await repo.deleteIslamicContent(
                                    c['id'] as String,
                                  );
                                  ref.invalidate(adminIslamicProvider);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                    .animate(delay: Duration(milliseconds: 40 * i))
                    .fade()
                    .slideX(begin: 0.05);
              },
            );
          },
        ),
      ),
    );
  }
}

void _showCreateUserDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.cardSurface,
      title: Text('Créer un utilisateur', style: AppTypography.h3),
      content: const Text(
        'Pour des raisons de sécurité imposées par la base de données (Supabase), '
        'la création directe d\'un compte utilisateur depuis l\'application va déconnecter votre session actuelle.\n\n'
        'Pour inviter un utilisateur, demandez-lui de télécharger l\'application et de s\'inscrire, '
        'ou bien ajoutez-le manuellement depuis l\'interface d\'administration web de Supabase.',
        style: TextStyle(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Compris',
            style: TextStyle(color: AppColors.emerald),
          ),
        ),
      ],
    ),
  );
}

void _showEventDialog(
  BuildContext context,
  WidgetRef ref,
  AdminRepository repo,
) {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final locCtrl = TextEditingController();
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: Text('Nouvel événement', style: AppTypography.h3),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(
                  labelText: 'Titre de l\'événement',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.emerald),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.emerald, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.emerald),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.emerald, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: locCtrl,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(
                  labelText: 'Lieu',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.emerald),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.emerald, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                title: const Text(
                  'Date et heure',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                subtitle: Text(
                  DateFormat('dd MMM yyyy - HH:mm', 'fr').format(selectedDate),
                  style: const TextStyle(color: AppColors.white),
                ),
                trailing: const Icon(
                  Icons.calendar_today,
                  color: AppColors.emerald,
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    if (context.mounted) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDate),
                      );
                      if (time != null) {
                        setState(() {
                          selectedDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  }
                },
              ),
            ],
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
          AeemgPrimaryButton(
            label: 'Créer',
            onPressed: () async {
              if (titleCtrl.text.isNotEmpty && locCtrl.text.isNotEmpty) {
                await repo.createEvent(
                  title: titleCtrl.text,
                  description: descCtrl.text,
                  location: locCtrl.text,
                  startsAt: selectedDate,
                );
                ref.invalidate(adminEventsProvider);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    ),
  );
}

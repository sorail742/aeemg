import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/ds/aeemg_buttons.dart';
import '../../../shared/widgets/ds/aeemg_card.dart';
import '../../../shared/widgets/ds/islamic_background.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../members/presentation/providers/members_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(myProfileProvider);
    final isAuthenticated = user != null;
    final userContact = user?.email ?? user?.phone;
    final profile = profileAsync.value;
    final displayName = !isAuthenticated
        ? 'Visiteur'
        : profile?.fullName ?? userContact ?? 'Membre AEEMG';
    final isStaff = profile?.isStaff ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profil')),
      body: IslamicBackground(
        withPattern: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.xxl,
          ),
          children: [
            AeemgCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.darkTeal,
                    child: isAuthenticated
                        ? Text(
                            _initials(displayName),
                            style: AppTypography.h2.copyWith(
                              color: AppColors.lightEmerald,
                            ),
                          )
                        : const Icon(
                            Icons.person_outline,
                            color: AppColors.lightEmerald,
                            size: 28,
                          ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: AppTypography.h3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isAuthenticated
                              ? userContact ?? ''
                              : 'Connectez-vous pour accéder à votre espace membre.',
                          style: AppTypography.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isAuthenticated) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _RoleBadge(
                            label: profile?.roleLabel ?? 'Membre',
                            staff: isStaff,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            if (isAuthenticated) ...[
              const _GroupLabel('Mon compte'),
              _MenuGroup(
                items: [
                  _MenuItem(
                    Icons.person_outline,
                    'Modifier mon profil',
                    () => context.push('/profile/edit'),
                  ),
                  _MenuItem(
                    Icons.lock_outline,
                    'Mot de passe',
                    () => context.push('/profile/password'),
                  ),
                  _MenuItem(
                    Icons.notifications_none,
                    'Préférences de notification',
                    () => context.push('/notifications/settings'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const _GroupLabel('Communauté'),
              _MenuGroup(
                items: [
                  _MenuItem(
                    Icons.people_outline,
                    'Annuaire des membres',
                    () => context.push('/members'),
                  ),
                  _MenuItem(
                    Icons.volunteer_activism_outlined,
                    'Faire un don',
                    () => context.push('/donations'),
                  ),
                  _MenuItem(
                    Icons.account_balance_outlined,
                    'Bilans financiers',
                    () => context.push('/finance'),
                  ),
                  if (isStaff)
                    _MenuItem(
                      Icons.admin_panel_settings_outlined,
                      'Administration',
                      () => context.push('/admin'),
                      accent: true,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            const _GroupLabel('Application'),
            _MenuGroup(
              items: [
                if (isAuthenticated)
                  _MenuItem(
                    Icons.inbox_outlined,
                    'Notifications',
                    () => context.push('/notifications'),
                  ),
                _MenuItem(
                  Icons.settings_outlined,
                  'Paramètres',
                  () => context.push('/settings'),
                ),
                if (isAuthenticated)
                  _MenuItem(
                    Icons.rate_review_outlined,
                    'Donner mon avis',
                    () => context.push('/feedback'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Diagnostic réservé aux environnements de développement et de recette.
            if (Env.appEnv != 'prod') ...[
              const _GroupLabel('Diagnostic'),
              _MenuGroup(
                items: [
                  _MenuItem.status(
                    Icons.cloud_outlined,
                    'Supabase',
                    Env.isConfigured ? 'Configuré' : 'Non configuré',
                    ok: Env.isConfigured,
                  ),
                  _MenuItem.status(
                    Icons.verified_user_outlined,
                    'Session',
                    isAuthenticated ? 'Connecté' : 'Non connecté',
                    ok: isAuthenticated,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            if (isAuthenticated)
              AeemgSecondaryButton(
                label: 'Se déconnecter',
                icon: Icons.logout,
                onPressed: () => ref.read(authRepositoryProvider).signOut(),
              )
            else
              AeemgPrimaryButton(
                label: 'Se connecter',
                icon: Icons.login,
                onPressed: () => context.push('/login'),
              ),
          ],
        ).animate().fadeIn(duration: 250.ms),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label, required this.staff});

  final String label;
  final bool staff;

  @override
  Widget build(BuildContext context) {
    final color = staff ? AppColors.gold : AppColors.brightGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.sm,
      ),
      child: Text(title.toUpperCase(), style: AppTypography.overline),
    );
  }
}

class _MenuItem {
  const _MenuItem(this.icon, this.title, this.onTap, {this.accent = false})
    : status = null,
      ok = false;

  const _MenuItem.status(this.icon, this.title, this.status, {required this.ok})
    : onTap = null,
      accent = false;

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final String? status;
  final bool ok;
  final bool accent;
}

/// Liste groupée dans une seule carte, séparateurs alignés sur le texte.
class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.items});

  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return AeemgCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(indent: 56),
            _MenuRow(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item});

  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    final iconColor = item.accent ? AppColors.gold : AppColors.textSecondary;
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 14,
      ),
      child: Row(
        children: [
          Icon(item.icon, color: iconColor, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              item.title,
              style: AppTypography.body.copyWith(
                color: item.accent ? AppColors.gold : AppColors.white,
              ),
            ),
          ),
          if (item.status != null) ...[
            Text(item.status!, style: AppTypography.bodySmall),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              item.ok ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16,
              color: item.ok ? AppColors.emerald : AppColors.textTertiary,
            ),
          ] else
            const Icon(
              Icons.chevron_right,
              color: AppColors.textTertiary,
              size: 20,
            ),
        ],
      ),
    );
    if (item.onTap == null) return row;
    return InkWell(onTap: item.onTap, child: row);
  }
}

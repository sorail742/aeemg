import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(myProfileProvider);
    final isAuthenticated = user != null;
    final userContact = user?.email ?? user?.phone;
    final displayName = profileAsync.maybeWhen(
      data: (p) => p?.fullName ?? userContact ?? 'Membre AEEMG',
      orElse: () => userContact ?? 'Visiteur',
    );
    final isStaff = profileAsync.maybeWhen(
      data: (p) => p?.isStaff ?? false,
      orElse: () => false,
    );
    final initials = displayName.isNotEmpty
        ? displayName.trim().split(' ').take(2).map((s) => s.isEmpty ? '' : s[0].toUpperCase()).join()
        : '?';

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text('Profil', style: AppTypography.h2.copyWith(color: AppColors.white)),
      ),
      body: IslamicBackground(
        withPattern: true,
        child: ListView(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.xl,
          ),
          physics: const BouncingScrollPhysics(),
          children: [
            // Profile Hero Card
            AeemgCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.emerald, AppColors.gold],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emerald.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: AppTypography.h1.copyWith(color: AppColors.white, fontSize: 32),
                      ),
                    ),
                  ).animate().scale(curve: Curves.easeOutBack),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    displayName,
                    textAlign: TextAlign.center,
                    style: AppTypography.h2.copyWith(color: AppColors.white),
                  ).animate(delay: 100.ms).fade(),
                  const SizedBox(height: 4),
                  Text(
                    isAuthenticated
                        ? userContact ?? 'Membre'
                        : 'Connectez-vous pour accéder à votre profil',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ).animate(delay: 150.ms).fade(),
                  if (isAuthenticated) ...[
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.emerald.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified, color: AppColors.emerald, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                isStaff ? 'Staff AEEMG' : 'Membre AEEMG',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.emerald,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ).animate(delay: 200.ms).fade(),
                  ],
                ],
              ),
            ).animate().fade().slideY(begin: -0.1),
            const SizedBox(height: AppSpacing.lg),

            if (isAuthenticated) ...[
              _SectionHeader(title: 'Mon Compte'),
              _MenuTile(icon: Icons.edit, title: 'Modifier mon profil', onTap: () => context.push('/profile/edit')),
              _MenuTile(icon: Icons.lock_outline, title: 'Définir un mot de passe', onTap: () => context.push('/profile/password')),
              _MenuTile(icon: Icons.tune, title: 'Préférences alertes', onTap: () => context.push('/notifications/settings')),
              const SizedBox(height: AppSpacing.lg),

              _SectionHeader(title: 'Communauté'),
              _MenuTile(icon: Icons.people, title: 'Annuaire des membres', onTap: () => context.push('/members')),
              _MenuTile(icon: Icons.favorite, title: 'Faire un don', onTap: () => context.push('/donations')),
              _MenuTile(icon: Icons.account_balance, title: 'Bilans financiers', onTap: () => context.push('/finance')),
              if (isStaff)
                _MenuTile(
                  icon: Icons.admin_panel_settings,
                  title: 'Administration',
                  highlight: true,
                  onTap: () => context.push('/admin'),
                ),
              const SizedBox(height: AppSpacing.lg),

              _SectionHeader(title: 'Application'),
              _MenuTile(icon: Icons.notifications, title: 'Notifications', onTap: () => context.push('/notifications')),
              _MenuTile(icon: Icons.settings_outlined, title: 'Paramètres', onTap: () => context.push('/settings')),
              _MenuTile(icon: Icons.feedback_outlined, title: 'Retour beta', onTap: () => context.push('/feedback')),
              const SizedBox(height: AppSpacing.xl),
            ],

            _SectionHeader(title: 'Système'),
            _StatusTile(
              icon: Icons.cloud,
              title: 'Supabase',
              status: Env.isConfigured ? 'Configuré' : 'En attente de configuration',
              isOk: Env.isConfigured,
            ),
            const SizedBox(height: AppSpacing.sm),
            _StatusTile(
              icon: Icons.login,
              title: 'Authentification',
              status: isAuthenticated ? 'Connecté' : 'Non connecté',
              isOk: isAuthenticated,
            ),
            const SizedBox(height: AppSpacing.xl),

            if (isAuthenticated)
              AeemgSecondaryButton(
                label: 'Se déconnecter',
                icon: Icons.logout,
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                },
              )
            else
              AeemgPrimaryButton(
                label: 'Se connecter',
                icon: Icons.email_outlined,
                onPressed: () => context.push('/login'),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: AppSpacing.xs, top: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: AppColors.gold,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.badge,
    this.highlight = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? badge;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final iconColor = highlight ? AppColors.gold : AppColors.emerald;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AeemgCard(
        onTap: onTap,
        variant: highlight ? AeemgCardVariant.active : AeemgCardVariant.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.smMd,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(title, style: AppTypography.body)),
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(right: AppSpacing.smMd),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.icon,
    required this.title,
    required this.status,
    required this.isOk,
  });

  final IconData icon;
  final String title;
  final String status;
  final bool isOk;

  @override
  Widget build(BuildContext context) {
    final statusColor = isOk ? AppColors.emerald : AppColors.gold;
    return AeemgCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: statusColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.h3.copyWith(fontSize: 14)),
                Text(status, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOk ? Icons.check_circle : Icons.schedule,
              color: statusColor,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

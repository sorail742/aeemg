import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/supabase_errors.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/ds/aeemg_card.dart';
import '../../../shared/widgets/ds/aeemg_motion.dart';
import '../../../shared/widgets/ds/aeemg_pill_tab_bar.dart';
import '../../../shared/widgets/ds/aeemg_section.dart';
import '../../../shared/widgets/ds/islamic_background.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'providers/donations_providers.dart';
import 'widgets/donation_widgets.dart';

class DonationsScreen extends ConsumerWidget {
  const DonationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = NumberFormat.currency(
      locale: 'fr_GN',
      symbol: 'GNF ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IslamicBackground(
        withPattern: true,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm + MediaQuery.paddingOf(context).top,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AeemgRoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Retour',
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/home'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('Faire un don', style: AppTypography.h1),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Paiement sécurisé par Orange Money.',
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const AeemgPillTabBar(labels: ['Campagnes', 'Mes dons']),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _CampaignsTab(
                      currency: currency,
                      onDonated: () => ref.invalidate(myDonationsProvider),
                    ),
                    _MyDonationsTab(currency: currency),
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

class _CampaignsTab extends ConsumerWidget {
  const _CampaignsTab({required this.currency, required this.onDonated});

  final NumberFormat currency;
  final VoidCallback onDonated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    void donate(double amount, {String? campaignId, String? category}) =>
        _donate(
          context,
          ref,
          user!.id,
          amount,
          campaignId: campaignId,
          category: category ?? 'general',
          onDonated: onDonated,
        );

    final List<Widget> campaigns = ref
        .watch(donationCampaignsProvider)
        .when(
          loading: () => const [
            AeemgSkeletonTile(),
            SizedBox(height: AppSpacing.sm),
            AeemgSkeletonTile(),
          ],
          error: (error, _) => [
            AeemgEmptyState(
              compact: true,
              icon: Icons.cloud_off_outlined,
              title: 'Campagnes indisponibles',
              message: friendlySupabaseError(error),
            ),
          ],
          data: (list) => list.isEmpty
              ? const [
                  AeemgEmptyState(
                    compact: true,
                    icon: Icons.campaign_outlined,
                    title: 'Aucune campagne active',
                    message: 'Les prochaines campagnes apparaîtront ici.',
                  ),
                ]
              : [
                  for (final campaign in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: CampaignCard(
                        campaign: campaign,
                        currency: currency,
                        onContribute: user == null
                            ? null
                            : () => donate(
                                10000,
                                campaignId: campaign.id,
                                category: campaign.category,
                              ),
                      ),
                    ),
                ],
        );

    final children = [
      QuickDonateCard(
        currency: currency,
        onAmount: user == null ? null : (amount) => donate(amount.toDouble()),
        onLogin: () => context.push('/login'),
      ),
      const SizedBox(height: AppSpacing.lg),
      const AeemgSectionHeader(title: 'Campagnes en cours'),
      ...campaigns,
    ];

    return RefreshIndicator(
      color: AppColors.emerald,
      backgroundColor: AppColors.cardSurface,
      onRefresh: () async => ref.invalidate(donationCampaignsProvider),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        children: [
          for (var i = 0; i < children.length; i++)
            children[i].reveal(context, index: i),
        ],
      ),
    );
  }

  Future<void> _donate(
    BuildContext context,
    WidgetRef ref,
    String userId,
    double amount, {
    String? campaignId,
    String category = 'general',
    required VoidCallback onDonated,
  }) async {
    final phone = await _askOrangeMoneyPhone(context);
    if (phone == null) return;

    try {
      final repo = ref.read(donationsRepositoryProvider);
      final donationId = await repo.createDonation(
        userId: userId,
        amount: amount,
        category: category,
        campaignId: campaignId,
      );
      final result = await repo.initiateOrangeMoney(
        donationId: donationId,
        amount: amount,
        phone: phone,
      );
      onDonated();
      if (!context.mounted) return;
      final hint = result['ussd_hint'] as String?;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            [
              result['message'] as String? ?? 'Paiement Orange Money initié.',
              ?hint,
            ].join('\n'),
          ),
          backgroundColor: AppColors.emerald,
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Paiement impossible : ${friendlySupabaseError(e)}',
              style: const TextStyle(color: AppColors.white),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<String?> _askOrangeMoneyPhone(BuildContext context) async {
    final controller = TextEditingController(text: '+224');
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone_android, color: AppColors.warning),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text(
              'Orange Money',
              style: TextStyle(color: AppColors.white),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: AppColors.white),
          decoration: InputDecoration(
            labelText: 'Numéro Orange (Guinée)',
            labelStyle: TextStyle(color: AppColors.textSecondary),
            hintText: '+224 6XX XX XX XX',
            hintStyle: TextStyle(color: AppColors.textTertiary),
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: AppColors.deepNavy,
            ),
            onPressed: () {
              final phone = controller.text.trim();
              if (phone.length >= 8) Navigator.pop(dialogContext, phone);
            },
            child: const Text(
              'Payer',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyDonationsTab extends ConsumerWidget {
  const _MyDonationsTab({required this.currency});

  final NumberFormat currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final donationsAsync = ref.watch(myDonationsProvider);

    if (user == null) {
      return Center(
        child: Text(
          'Connectez-vous pour voir votre historique de dons.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.emerald,
      backgroundColor: AppColors.cardSurface,
      onRefresh: () async => ref.invalidate(myDonationsProvider),
      child: AsyncValueWidget(
        value: donationsAsync,
        empty: ListView(
          children: const [
            SizedBox(height: 120),
            Center(
              child: Text(
                'Aucun don enregistré pour le moment.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        data: (donations) => ListView.separated(
          padding: const EdgeInsets.only(
            top: AppSpacing.md,
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.xl,
          ),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          itemCount: donations.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final d = donations[index];
            final date = DateFormat('d MMM yyyy', 'fr').format(d.createdAt);
            return AeemgCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: AppColors.emerald,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currency.format(d.amount),
                              style: AppTypography.h3.copyWith(
                                color: AppColors.emerald,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              d.campaignTitle ?? 'Don général',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            date,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              d.statusLabel,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
                .animate(delay: Duration(milliseconds: 50 * index))
                .fade()
                .slideX(begin: 0.05);
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/ds/aeemg_card.dart';
import '../../../shared/widgets/ds/islamic_background.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/donations_repository.dart';

final donationsRepositoryProvider = Provider<DonationsRepository>((ref) {
  return DonationsRepository(ref.watch(supabaseClientProvider));
});

final donationCampaignsProvider = FutureProvider((ref) async {
  return ref.read(donationsRepositoryProvider).fetchCampaigns();
});

final myDonationsProvider = FutureProvider((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return <DonationRecord>[];
  return ref.read(donationsRepositoryProvider).fetchMyDonations(user.id);
});

class DonationsScreen extends ConsumerStatefulWidget {
  const DonationsScreen({super.key});

  @override
  ConsumerState<DonationsScreen> createState() => _DonationsScreenState();
}

class _DonationsScreenState extends ConsumerState<DonationsScreen>
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
    final user = ref.watch(currentUserProvider);
    final currency =
        NumberFormat.currency(locale: 'fr_GN', symbol: 'GNF ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.8),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text('Faire un don', style: AppTypography.h2.copyWith(color: AppColors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Campagnes'),
            Tab(text: 'Mes dons'),
          ],
        ),
      ),
      body: IslamicBackground(
        withPattern: true,
        child: TabBarView(
          controller: _tabController,
          children: [
            _CampaignsTab(
              user: user,
              currency: currency,
              onDonated: () => ref.invalidate(myDonationsProvider),
            ),
            _MyDonationsTab(currency: currency),
          ],
        ),
      ),
    );
  }
}

class _CampaignsTab extends ConsumerWidget {
  const _CampaignsTab({
    required this.user,
    required this.currency,
    required this.onDonated,
  });

  final User? user;
  final NumberFormat currency;
  final VoidCallback onDonated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignsAsync = ref.watch(donationCampaignsProvider);

    return AsyncValueWidget(
      value: campaignsAsync,
      empty: Center(child: Text('Aucune campagne active.', style: TextStyle(color: AppColors.textSecondary))),
      data: (campaigns) => ListView(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + kToolbarHeight + 64,
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: AppSpacing.xl,
        ),
        physics: const BouncingScrollPhysics(),
        children: [
          AeemgCard(
            variant: AeemgCardVariant.active,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.volunteer_activism, color: AppColors.gold, size: 28),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Faire un don rapide', style: AppTypography.h2.copyWith(color: AppColors.gold)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Soutenez les actions de l\'AEEMG.',
                  style: AppTypography.body.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [5000, 10000, 25000].map((amount) {
                    return InkWell(
                      onTap: user == null
                          ? null
                          : () => _donate(
                                context,
                                ref,
                                user!.id,
                                amount.toDouble(),
                                onDonated: onDonated,
                              ),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withValues(alpha: 0.15),
                          border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          currency.format(amount),
                          style: AppTypography.h4.copyWith(color: AppColors.emerald),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ).animate().fade().slideY(begin: -0.1),
          const SizedBox(height: AppSpacing.xl),
          
          Text('Campagnes en cours', style: AppTypography.h2.copyWith(color: AppColors.white))
              .animate(delay: 100.ms).fade(),
          const SizedBox(height: AppSpacing.md),
          
          ...campaigns.asMap().entries.map((entry) {
            final index = entry.key;
            final campaign = entry.value;
            final progress = campaign.progress.clamp(0.0, 1.0);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AeemgCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(campaign.title, style: AppTypography.h3),
                    if (campaign.description != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(campaign.description!, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Objectif', style: AppTypography.caption),
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: AppTypography.caption.copyWith(color: AppColors.emerald, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppColors.cardSurfaceLight,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.emerald),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(currency.format(campaign.raisedAmount), style: AppTypography.caption.copyWith(color: AppColors.emerald)),
                        Text(currency.format(campaign.goalAmount), style: AppTypography.caption),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.lg),
                    if (user != null)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.emerald,
                            foregroundColor: AppColors.deepNavy,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => _donate(
                            context,
                            ref,
                            user!.id,
                            10000,
                            campaignId: campaign.id,
                            category: campaign.category,
                            onDonated: onDonated,
                          ),
                          icon: const Icon(Icons.favorite),
                          label: const Text('Contribuer (10 000 GNF)', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      )
                    else
                      Center(
                        child: Text(
                          'Connectez-vous pour contribuer.',
                          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                  ],
                ),
              ).animate(delay: Duration(milliseconds: 200 + (index * 100))).fade().slideY(begin: 0.1),
            );
          }),
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
            content: Text('Erreur paiement : $e', style: const TextStyle(color: AppColors.white)),
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
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: const Icon(Icons.phone_android, color: Colors.orange),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text('Orange Money', style: TextStyle(color: AppColors.white)),
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
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.emerald.withValues(alpha: 0.5))),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.emerald)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.emerald, foregroundColor: AppColors.deepNavy),
            onPressed: () {
              final phone = controller.text.trim();
              if (phone.length >= 8) Navigator.pop(dialogContext, phone);
            },
            child: const Text('Payer', style: TextStyle(fontWeight: FontWeight.bold)),
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
        child: Text('Connectez-vous pour voir votre historique de dons.', style: TextStyle(color: AppColors.textSecondary)),
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
            Center(child: Text('Aucun don enregistré pour le moment.', style: TextStyle(color: AppColors.textSecondary))),
          ],
        ),
        data: (donations) => ListView.separated(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 64,
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.xl,
          ),
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
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
                    child: const Icon(Icons.favorite, color: AppColors.emerald),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currency.format(d.amount),
                          style: AppTypography.h3.copyWith(color: AppColors.emerald),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          d.campaignTitle ?? 'Don général',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.white),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(date, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          d.statusLabel,
                          style: AppTypography.caption.copyWith(color: AppColors.gold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate(delay: Duration(milliseconds: 50 * index)).fade().slideX(begin: 0.05);
          },
        ),
      ),
    );
  }
}

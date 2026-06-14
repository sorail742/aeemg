import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/ds/aeemg_card.dart';
import '../../../shared/widgets/ds/islamic_background.dart';
import 'providers/members_provider.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  final _searchController = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Color based on initial letter for avatar variety
  Color _avatarColor(String name) {
    final colors = [
      AppColors.emerald,
      AppColors.gold,
      const Color(0xFF7C3AED),
      const Color(0xFF0EA5E9),
      const Color(0xFFEC4899),
    ];
    return colors[name.isEmpty ? 0 : name.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersListProvider(_filter));

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.9),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text('Annuaire des membres', style: AppTypography.h2.copyWith(color: AppColors.white)),
      ),
      body: IslamicBackground(
        withPattern: true,
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight + 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  hintText: 'Filtrer par section, spécialité…',
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
                  suffixIcon: _filter.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _filter = '');
                          },
                        )
                      : null,
                ),
                onSubmitted: (v) => setState(() => _filter = v.trim()),
                onChanged: (v) {
                  if (v.isEmpty) setState(() => _filter = '');
                },
              ).animate().fade().slideY(begin: -0.2),
            ),
            Expanded(
              child: AsyncValueWidget(
                value: membersAsync,
                empty: Center(child: Text('Aucun membre trouvé.', style: TextStyle(color: AppColors.textSecondary))),
                data: (members) => ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  physics: const BouncingScrollPhysics(),
                  itemCount: members.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final initials = member.fullName.trim().split(' ').take(2)
                        .map((s) => s.isEmpty ? '' : s[0].toUpperCase()).join();
                    final avatarColor = _avatarColor(member.fullName);
                    final subtitle = [
                      if (member.section != null) member.section,
                      if (member.specialty != null) member.specialty,
                    ].join(' · ');

                    return AeemgCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: avatarColor.withValues(alpha: 0.2),
                              border: Border.all(color: avatarColor.withValues(alpha: 0.4), width: 2),
                            ),
                            child: Center(
                              child: Text(
                                initials.isEmpty ? '?' : initials,
                                style: AppTypography.h3.copyWith(color: avatarColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.fullName,
                                  style: AppTypography.h3,
                                ),
                                if (subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
                                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              member.roleLabel,
                              style: AppTypography.caption.copyWith(color: AppColors.gold, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ).animate(delay: Duration(milliseconds: 40 * index)).fade().slideX(begin: 0.05);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

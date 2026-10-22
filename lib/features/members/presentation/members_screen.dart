import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/supabase_errors.dart';
import '../../../shared/models/profile.dart';
import '../../../shared/widgets/ds/aeemg_avatar.dart';
import '../../../shared/widgets/ds/aeemg_card.dart';
import '../../../shared/widgets/ds/aeemg_motion.dart';
import '../../../shared/widgets/ds/aeemg_page.dart';
import '../../../shared/widgets/ds/aeemg_section.dart';
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

  void _search(String value) => setState(() => _filter = value.trim());

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersListProvider(_filter));
    final members = membersAsync.value ?? const <MemberProfile>[];

    final search = TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Filtrer par section, spécialité…',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _filter.isEmpty
            ? null
            : IconButton(
                tooltip: 'Effacer',
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _searchController.clear();
                  _search('');
                },
              ),
      ),
      onSubmitted: _search,
      onChanged: (v) {
        if (v.isEmpty) _search('');
      },
    );

    final List<Widget> status = membersAsync.when(
      loading: () => const [
        AeemgSkeletonTile(),
        SizedBox(height: AppSpacing.sm),
        AeemgSkeletonTile(),
      ],
      error: (error, _) => [
        AeemgEmptyState(
          compact: true,
          icon: Icons.cloud_off_outlined,
          title: 'Annuaire indisponible',
          message: friendlySupabaseError(error),
        ),
      ],
      data: (list) => [
        if (list.isEmpty)
          AeemgEmptyState(
            compact: true,
            icon: Icons.group_off_outlined,
            title: 'Aucun membre trouvé',
            message: _filter.isEmpty
                ? 'Les profils publics apparaîtront ici.'
                : 'Aucun résultat pour « $_filter ».',
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              list.length == 1 ? '1 membre' : '${list.length} membres',
              style: AppTypography.caption,
            ),
          ),
      ],
    );

    return AeemgPage(
      title: 'Annuaire des membres',
      subtitle: 'Les profils publics de la communauté.',
      onRefresh: () async => ref.invalidate(membersListProvider(_filter)),
      itemCount: membersAsync.hasValue ? members.length : 0,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: _MemberCard(member: members[index]),
      ),
      children: [
        search,
        const SizedBox(height: AppSpacing.md),
        ...status,
      ],
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member});

  final MemberProfile member;

  @override
  Widget build(BuildContext context) {
    final details = [
      ?member.section,
      ?member.specialty,
    ].where((s) => s.isNotEmpty).join(' · ');
    final isMember = member.roleLabel == 'Membre';
    final tint = isMember ? AppColors.textSecondary : AppColors.gold;

    return AeemgCard(
      padding: const EdgeInsets.all(AppSpacing.smMd),
      child: Row(
        children: [
          AeemgAvatar(
            name: member.fullName,
            imageUrl: member.avatarUrl,
            size: 48,
          ),
          const SizedBox(width: AppSpacing.smMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.fullName, style: AppTypography.h4),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(details, style: AppTypography.bodySmall),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: AppRadius.pillBorder,
              border: Border.all(color: tint.withValues(alpha: 0.3)),
            ),
            child: Text(
              member.roleLabel,
              style: AppTypography.caption.copyWith(
                color: tint,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

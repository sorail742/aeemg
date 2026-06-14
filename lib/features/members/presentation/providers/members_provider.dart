import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../../../shared/models/profile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/members_repository.dart';

final membersRepositoryProvider = Provider<MembersRepository>((ref) {
  return MembersRepository(ref.watch(supabaseClientProvider));
});

final membersListProvider = FutureProvider.family<List<MemberProfile>, String>(
  (ref, sectionFilter) async {
    return ref.read(membersRepositoryProvider).fetchMembers(
          sectionQuery: sectionFilter.isEmpty ? null : sectionFilter,
        );
  },
);

final myProfileProvider = FutureProvider<MemberProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.read(membersRepositoryProvider).fetchProfile(user.id);
});

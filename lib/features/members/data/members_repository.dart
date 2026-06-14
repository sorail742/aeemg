import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/profile.dart';

class MembersRepository {
  MembersRepository(this._client);

  final SupabaseClient? _client;

  Future<List<MemberProfile>> fetchMembers({String? sectionQuery}) async {
    final client = _client;
    if (client == null) return [];

    var query = client.from('profiles').select().eq('is_profile_public', true);
    if (sectionQuery != null && sectionQuery.isNotEmpty) {
      query = query.ilike('section', '%$sectionQuery%');
    }
    final rows = await query.order('full_name');
    return (rows as List)
        .map((e) => MemberProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MemberProfile?> fetchProfile(String userId) async {
    final client = _client;
    if (client == null) return null;

    final row = await client.from('profiles').select().eq('id', userId).maybeSingle();
    if (row == null) return null;
    return MemberProfile.fromJson(row);
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await _client?.from('profiles').update(data).eq('id', userId);
  }
}

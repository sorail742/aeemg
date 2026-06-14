import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../data/messages_repository.dart';
import '../../data/models/chat_models.dart';

final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  return MessagesRepository(ref.watch(supabaseClientProvider));
});

final chatGroupsProvider = FutureProvider<List<ChatGroup>>((ref) async {
  return ref.read(messagesRepositoryProvider).fetchGroups();
});

final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  return ref.read(messagesRepositoryProvider).fetchAnnouncements();
});

final messagesStreamProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, groupId) {
  return ref.read(messagesRepositoryProvider).watchMessages(groupId);
});

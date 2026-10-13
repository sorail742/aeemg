import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../data/chat_media.dart';
import '../../data/messages_repository.dart';
import '../../data/models/chat_models.dart';

final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  return MessagesRepository(ref.watch(supabaseClientProvider));
});

final chatGroupsProvider = FutureProvider<List<ChatGroup>>((ref) async {
  return ref.read(messagesRepositoryProvider).fetchGroups();
});

final canManageGroupProvider = FutureProvider.autoDispose.family<bool, String>((
  ref,
  groupId,
) {
  return ref.read(messagesRepositoryProvider).canManageGroup(groupId);
});

/// URL d'affichage d'un média de message : URL signée à partir de
/// `media_path`, ou ancienne URL si le message n'a pas de chemin (SEC-006).
final chatMediaUrlProvider = FutureProvider.autoDispose
    .family<String?, ({ChatMediaKind kind, String? path, String? legacyUrl})>((
      ref,
      media,
    ) async {
      final path = media.path;
      if (path == null) return media.legacyUrl;
      return ref
          .read(messagesRepositoryProvider)
          .signedChatMediaUrl(media.kind, path);
    });

final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  return ref.read(messagesRepositoryProvider).fetchAnnouncements();
});

final messagesStreamProvider = StreamProvider.family<List<ChatMessage>, String>(
  (ref, groupId) {
    return ref.read(messagesRepositoryProvider).watchMessages(groupId);
  },
);

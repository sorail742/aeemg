import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/chat_models.dart';

class MessagesRepository {
  MessagesRepository(this._client);

  final SupabaseClient? _client;

  Future<List<ChatGroup>> fetchGroups() async {
    final client = _client;
    if (client == null) return [];

    final rows = await client.from('chat_groups').select().order('name');
    return (rows as List)
        .map((e) => ChatGroup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Inscription opportuniste à l'ouverture d'une conversation. Le serveur ne
  /// l'accepte que pour les groupes publics (SEC-003) : un refus (groupe privé,
  /// conversation directe, déjà membre) n'est pas une erreur pour l'utilisateur.
  Future<void> joinGroup(String groupId, String userId) async {
    try {
      await _client?.from('chat_group_members').upsert({
        'group_id': groupId,
        'user_id': userId,
      }, ignoreDuplicates: true);
    } on PostgrestException {
      // Groupe non public : l'accès passe par un admin du groupe.
    }
  }

  /// L'utilisateur courant peut-il gérer les membres du groupe (owner/admin du
  /// groupe ou staff) ? Calculé côté serveur par `is_group_admin`.
  Future<bool> canManageGroup(String groupId) async {
    final client = _client;
    if (client == null) return false;
    final result = await client.rpc('is_group_admin', params: {'g': groupId});
    return result == true;
  }

  Stream<List<ChatMessage>> watchMessages(String groupId) {
    final client = _client;
    if (client == null) return Stream.value([]);

    return client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .order('created_at')
        .map((rows) => rows.map(ChatMessage.fromJson).toList());
  }

  Future<void> sendMessage({
    required String groupId,
    required String senderId,
    required String content,
    String messageType = 'text',
    String? mediaUrl,
    String? replyToId,
  }) async {
    await _client?.from('messages').insert({
      'group_id': groupId,
      'sender_id': senderId,
      'content': content,
      'message_type': messageType,
      'media_url': ?mediaUrl,
      'reply_to_id': ?replyToId,
    });
  }

  Stream<List<MessageReceipt>> watchMessageReceipts(String groupId) {
    final client = _client;
    if (client == null) return Stream.value([]);
    // We only watch receipts for messages in this group.
    // This is a bit complex in Supabase stream, so we'll just watch all receipts and filter in UI, or wait for realtime.
    return client
        .from('message_receipts')
        .stream(primaryKey: ['message_id', 'user_id'])
        .map((rows) => rows.map(MessageReceipt.fromJson).toList());
  }

  Future<void> markMessageRead(String messageId, String userId) async {
    await _client?.from('message_receipts').upsert({
      'message_id': messageId,
      'user_id': userId,
      'status': 'read',
      'read_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> markMessageDelivered(String messageId, String userId) async {
    await _client?.from('message_receipts').upsert({
      'message_id': messageId,
      'user_id': userId,
      'status': 'delivered',
      'read_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Announcement>> fetchAnnouncements() async {
    final client = _client;
    if (client == null) return [];

    final rows = await client
        .from('announcements')
        .select()
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAnnouncementRead(
    String announcementId,
    String userId,
  ) async {
    await _client?.from('announcement_reads').upsert({
      'announcement_id': announcementId,
      'user_id': userId,
    });
  }

  /// Soft-delete a message (sets is_deleted = true)
  Future<void> deleteMessage(String messageId) async {
    await _client
        ?.from('messages')
        .update({'is_deleted': true, 'content': 'Ce message a été supprimé'})
        .eq('id', messageId);
  }

  /// Add or toggle an emoji reaction on a message
  Future<void> addReaction({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    // Check if reaction already exists
    final existing = await _client
        ?.from('message_reactions')
        .select()
        .eq('message_id', messageId)
        .eq('user_id', userId)
        .eq('emoji', emoji)
        .maybeSingle();

    if (existing != null) {
      // Toggle off
      await _client
          ?.from('message_reactions')
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', userId)
          .eq('emoji', emoji);
    } else {
      await _client?.from('message_reactions').upsert({
        'message_id': messageId,
        'user_id': userId,
        'emoji': emoji,
      });
    }
  }

  /// Add an existing user to the group
  Future<void> addMemberToGroup(String groupId, String userId) async {
    await _client?.from('chat_group_members').insert({
      'group_id': groupId,
      'user_id': userId,
    });
  }

  /// Invite a phone number to the group (if they don't have the app yet).
  ///
  /// [phoneNumber] doit être au format E.164 (voir `normalizeE164`). Seuls les
  /// admins du groupe et le staff peuvent inviter ; `invited_by` est renseigné
  /// par la base (SEC-004).
  Future<void> invitePhoneNumber(String groupId, String phoneNumber) async {
    // L'envoi du SMS d'invitation (Edge Function) n'est pas encore branché :
    // on enregistre seulement l'invitation.
    await _client?.from('group_invitations').insert({
      'group_id': groupId,
      'phone_number': phoneNumber,
    });
  }
}

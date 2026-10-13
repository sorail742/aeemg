class ChatGroup {
  const ChatGroup({
    required this.id,
    this.name,
    this.description,
    required this.isOfficial,
    required this.isGroup,
    required this.createdAt,
  });

  final String id;
  final String? name;
  final String? description;
  final bool isOfficial;
  final bool isGroup;
  final DateTime createdAt;

  factory ChatGroup.fromJson(Map<String, dynamic> json) => ChatGroup(
    id: json['id'] as String,
    name: json['name'] as String?,
    description: json['description'] as String?,
    isOfficial: json['is_official'] as bool? ?? false,
    isGroup: json['is_group'] as bool? ?? true,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.content,
    required this.messageType,
    this.mediaUrl,
    this.replyToId,
    required this.isDeleted,
    required this.isPinned,
    required this.createdAt,
    this.senderName,
  });

  final String id;
  final String groupId;
  final String senderId;
  final String content;
  final String messageType;
  final String? mediaUrl;
  final String? replyToId;
  final bool isDeleted;
  final bool isPinned;
  final DateTime createdAt;
  final String? senderName;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    groupId: json['group_id'] as String,
    senderId: json['sender_id'] as String,
    content: json['content'] as String,
    messageType: json['message_type'] as String? ?? 'text',
    mediaUrl: json['media_url'] as String?,
    replyToId: json['reply_to_id'] as String?,
    isDeleted: json['is_deleted'] as bool? ?? false,
    isPinned: json['is_pinned'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
    senderName:
        (json['profiles'] as Map<String, dynamic>?)?['full_name'] as String?,
  );
}

class MessageReceipt {
  const MessageReceipt({
    required this.messageId,
    required this.userId,
    required this.status,
    required this.readAt,
  });

  final String messageId;
  final String userId;
  final String status;
  final DateTime readAt;

  factory MessageReceipt.fromJson(Map<String, dynamic> json) => MessageReceipt(
    messageId: json['message_id'] as String,
    userId: json['user_id'] as String,
    status: json['status'] as String,
    readAt: DateTime.parse(json['read_at'] as String),
  );
}

class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.isImportant,
    required this.createdAt,
    this.authorName,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String content;
  final bool isImportant;
  final DateTime createdAt;
  final String? authorName;
  final bool isRead;

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
    id: json['id'] as String,
    title: json['title'] as String,
    content: json['content'] as String,
    isImportant: json['is_important'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
    authorName:
        (json['profiles'] as Map<String, dynamic>?)?['full_name'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'is_important': isImportant,
    'created_at': createdAt.toIso8601String(),
  };
}

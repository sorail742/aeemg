import '../../../../shared/models/profile.dart';

class PostModel {
  final String id;
  final String authorId;
  final String content;
  final String? imageUrl;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Relations
  final MemberProfile? author;
  final bool isLikedByMe;

  const PostModel({
    required this.id,
    required this.authorId,
    required this.content,
    this.imageUrl,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
    required this.updatedAt,
    this.author,
    this.isLikedByMe = false,
  });

  factory PostModel.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    // Check if the current user liked it based on joined post_likes
    bool liked = false;
    if (currentUserId != null && json['post_likes'] != null) {
      final likes = json['post_likes'] as List;
      liked = likes.any((like) => like['user_id'] == currentUserId);
    }

    return PostModel(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      content: json['content'] as String,
      imageUrl: json['image_url'] as String?,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      author: json['profiles'] != null ? MemberProfile.fromJson(json['profiles']) : null,
      isLikedByMe: liked,
    );
  }

  PostModel copyWith({
    String? id,
    String? authorId,
    String? content,
    String? imageUrl,
    int? likesCount,
    int? commentsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    MemberProfile? author,
    bool? isLikedByMe,
  }) {
    return PostModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      author: author ?? this.author,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
    );
  }
}

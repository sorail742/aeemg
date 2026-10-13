import 'dart:math';

/// Types de médias de la messagerie et règles de dépôt (SEC-006).
///
/// Les limites et types MIME reprennent ceux des buckets Supabase (ADR-0018,
/// migration `20261013110000_sec006_medias_prives.sql`) : la vérification
/// locale sert à afficher un message clair avant l'envoi, le serveur reste
/// la référence.
enum ChatMediaKind {
  image(
    bucket: 'chat_images',
    maxBytes: 5 * 1024 * 1024,
    contentTypes: {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'webp': 'image/webp',
    },
  ),
  audio(
    bucket: 'chat_audio',
    maxBytes: 10 * 1024 * 1024,
    contentTypes: {
      'm4a': 'audio/mp4',
      'ogg': 'audio/ogg',
      'webm': 'audio/webm',
    },
  );

  const ChatMediaKind({
    required this.bucket,
    required this.maxBytes,
    required this.contentTypes,
  });

  final String bucket;
  final int maxBytes;

  /// Extension (minuscules, sans point) → type MIME autorisé.
  final Map<String, String> contentTypes;

  /// Type de média d'un message (`message_type`), ou `null` pour un texte.
  static ChatMediaKind? fromMessageType(String messageType) =>
      switch (messageType) {
        'image' => ChatMediaKind.image,
        'audio' => ChatMediaKind.audio,
        _ => null,
      };
}

/// Refus d'un média avant envoi, avec un message destiné à l'utilisateur.
class ChatMediaRejected implements Exception {
  const ChatMediaRejected(this.message);

  final String message;

  @override
  String toString() => message;
}

String _extension(String fileName) {
  final dot = fileName.lastIndexOf('.');
  return dot < 0 ? '' : fileName.substring(dot + 1).toLowerCase();
}

/// Vérifie qu'un fichier peut être envoyé et retourne son type MIME.
///
/// Lève [ChatMediaRejected] si le type n'est pas autorisé ou si le fichier
/// dépasse la limite du bucket.
String checkChatMedia(ChatMediaKind kind, String fileName, int sizeBytes) {
  final contentType = kind.contentTypes[_extension(fileName)];
  if (contentType == null) {
    final allowed = kind.contentTypes.keys.join(', ');
    throw ChatMediaRejected(
      'Type de fichier non autorisé. Formats acceptés : $allowed.',
    );
  }
  if (sizeBytes > kind.maxBytes) {
    final maxMb = kind.maxBytes ~/ (1024 * 1024);
    throw ChatMediaRejected('Fichier trop volumineux (maximum $maxMb Mo).');
  }
  return contentType;
}

/// Chemin de l'objet dans le bucket : `<group_id>/<identifiant aléatoire>.<ext>`.
///
/// Le premier segment doit être l'identifiant du groupe : c'est lui que les
/// policies Storage vérifient.
String newChatMediaPath(String groupId, String fileName, {Random? random}) {
  final rng = random ?? Random.secure();
  final id = List.generate(
    16,
    (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  return '$groupId/$id.${_extension(fileName)}';
}

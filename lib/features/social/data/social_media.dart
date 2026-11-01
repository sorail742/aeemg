import 'dart:math';

/// Configuration et règles de téléversement du bucket social_images (SEC-007).
///
/// Les limites et types MIME reprennent ceux du bucket Supabase (ADR-0018,
/// migration `20261014110000_sec007_social_images.sql`) : la vérification
/// locale permet d'afficher un message clair à l'utilisateur avant le transfert.
const String socialImagesBucket = 'social_images';

/// Limite maximale d'une image du fil social : 5 Mo.
const int socialImageMaxBytes = 5 * 1024 * 1024;

/// Extensions autorisées et correspondances MIME (ADR-0018).
const Map<String, String> socialImageContentTypes = {
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'webp': 'image/webp',
};

/// Exception levée lorsqu'un fichier sélectionné enfreint les règles du bucket.
class SocialMediaRejected implements Exception {
  const SocialMediaRejected(this.message);

  final String message;

  @override
  String toString() => message;
}

String _extension(String fileName) {
  final dot = fileName.lastIndexOf('.');
  return dot < 0 ? '' : fileName.substring(dot + 1).toLowerCase();
}

/// Vérifie qu'une image respecte les contraintes du bucket social_images.
///
/// Lève [SocialMediaRejected] si le format n'est pas autorisé ou si la
/// taille dépasse 5 Mo. Retourne le type MIME en cas de succès.
String checkSocialImage(String fileName, int sizeBytes) {
  final ext = _extension(fileName);
  final contentType = socialImageContentTypes[ext];
  if (contentType == null) {
    final allowed = socialImageContentTypes.keys.join(', ');
    throw SocialMediaRejected(
      'Type de fichier non autorisé. Formats acceptés : $allowed.',
    );
  }
  if (sizeBytes > socialImageMaxBytes) {
    throw const SocialMediaRejected('Fichier trop volumineux (maximum 5 Mo).');
  }
  return contentType;
}

/// Génère le chemin de destination dans le bucket : `<userId>/<id>.<ext>`.
///
/// Les policies Storage de SEC-007 exigent que le premier segment du chemin
/// soit l'identifiant de l'utilisateur connecté (`auth.uid()`).
String newSocialImagePath(String userId, String fileName, {Random? random}) {
  final rng = random ?? Random.secure();
  final id = List.generate(
    16,
    (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  return '$userId/$id.${_extension(fileName)}';
}

/// Extrait le chemin de l'objet dans le bucket depuis son URL publique.
///
/// Renvoie `null` si l'URL ne pointe pas vers le bucket `social_images`.
String? extractSocialImagePath(String imageUrl) {
  final uri = Uri.tryParse(imageUrl);
  if (uri == null) return null;
  final match = RegExp(
    r'/storage/v1/object/public/social_images/([^?#]+)',
  ).firstMatch(uri.path);
  return match?.group(1);
}

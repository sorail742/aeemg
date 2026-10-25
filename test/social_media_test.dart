import 'dart:math';

import 'package:aeemg/features/social/data/social_media.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('checkSocialImage (SEC-007)', () {
    test('retourne le type MIME des formats d\'image autorisés', () {
      expect(checkSocialImage('photo.JPG', 1024), 'image/jpeg');
      expect(checkSocialImage('image.jpeg', 2048), 'image/jpeg');
      expect(checkSocialImage('graph.png', 4096), 'image/png');
      expect(checkSocialImage('banner.webp', 8192), 'image/webp');
    });

    test('refuse les formats de fichiers non autorisés', () {
      expect(
        () => checkSocialImage('script.html', 1024),
        throwsA(
          isA<SocialMediaRejected>().having(
            (e) => e.message,
            'message',
            contains('Type de fichier non autorisé'),
          ),
        ),
      );
      expect(
        () => checkSocialImage('document.pdf', 1024),
        throwsA(isA<SocialMediaRejected>()),
      );
      expect(
        () => checkSocialImage('archive.zip', 1024),
        throwsA(isA<SocialMediaRejected>()),
      );
    });

    test('refuse un fichier dépassant la limite de 5 Mo', () {
      const fiveMb = 5 * 1024 * 1024;
      // 5 Mo exacts : autorisé
      expect(checkSocialImage('photo.jpg', fiveMb), 'image/jpeg');
      // 5 Mo + 1 octet : refusé
      expect(
        () => checkSocialImage('photo.jpg', fiveMb + 1),
        throwsA(
          isA<SocialMediaRejected>().having(
            (e) => e.message,
            'message',
            contains('trop volumineux'),
          ),
        ),
      );
    });
  });

  group('newSocialImagePath (SEC-007)', () {
    test('range le média sous <userId>/...', () {
      final path = newSocialImagePath(
        'user-42',
        'photo.PNG',
        random: Random(1),
      );
      expect(path, matches(RegExp(r'^user-42/[0-9a-f]{32}\.png$')));
      expect(newSocialImagePath('user-42', 'photo.png'), isNot(path));
    });
  });

  group('extractSocialImagePath (SEC-007)', () {
    test('extrait le chemin de l\'objet depuis une URL publique', () {
      expect(
        extractSocialImagePath(
          'https://xyz.supabase.co/storage/v1/object/public/social_images/u-1/123.jpg',
        ),
        'u-1/123.jpg',
      );
      expect(
        extractSocialImagePath(
          'https://xyz.supabase.co/storage/v1/object/public/social_images/u-2/sub/photo.png?v=1',
        ),
        'u-2/sub/photo.png',
      );
    });

    test('renvoie null pour une URL étrangère', () {
      expect(extractSocialImagePath('https://exemple.org/image.png'), isNull);
      expect(
        extractSocialImagePath(
          'https://xyz.supabase.co/storage/v1/object/public/chat_images/g-1/1.jpg',
        ),
        isNull,
      );
    });
  });
}

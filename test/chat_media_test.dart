import 'dart:math';

import 'package:aeemg/core/utils/supabase_errors.dart';
import 'package:aeemg/features/messages/data/chat_media.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('checkChatMedia', () {
    test('retourne le type MIME d\'une image autorisée', () {
      expect(
        checkChatMedia(ChatMediaKind.image, 'photo.JPG', 1000),
        'image/jpeg',
      );
      expect(
        checkChatMedia(ChatMediaKind.audio, 'vocal.m4a', 1000),
        'audio/mp4',
      );
    });

    test('refuse un type non autorisé avec un message clair', () {
      expect(
        () => checkChatMedia(ChatMediaKind.image, 'page.html', 10),
        throwsA(
          isA<ChatMediaRejected>().having(
            (e) => e.message,
            'message',
            contains('Type de fichier non autorisé'),
          ),
        ),
      );
      expect(
        () => checkChatMedia(ChatMediaKind.audio, 'photo.jpg', 10),
        throwsA(isA<ChatMediaRejected>()),
      );
    });

    test('refuse un fichier au-delà de la limite du bucket', () {
      expect(
        checkChatMedia(ChatMediaKind.image, 'a.png', 5 * 1024 * 1024),
        'image/png',
      );
      expect(
        () => checkChatMedia(ChatMediaKind.image, 'a.png', 5 * 1024 * 1024 + 1),
        throwsA(
          isA<ChatMediaRejected>().having(
            (e) => e.message,
            'message',
            'Fichier trop volumineux (maximum 5 Mo).',
          ),
        ),
      );
      expect(
        () =>
            checkChatMedia(ChatMediaKind.audio, 'a.m4a', 10 * 1024 * 1024 + 1),
        throwsA(isA<ChatMediaRejected>()),
      );
    });
  });

  test('newChatMediaPath range le média dans le dossier du groupe', () {
    final path = newChatMediaPath('g-1', 'photo.Jpeg', random: Random(1));
    expect(path, matches(RegExp(r'^g-1/[0-9a-f]{32}\.jpeg$')));
    expect(newChatMediaPath('g-1', 'photo.jpeg'), isNot(path));
  });

  test('fromMessageType associe le type de message au bucket', () {
    expect(ChatMediaKind.fromMessageType('image')?.bucket, 'chat_images');
    expect(ChatMediaKind.fromMessageType('audio')?.bucket, 'chat_audio');
    expect(ChatMediaKind.fromMessageType('text'), isNull);
  });

  group('friendlySupabaseError (Storage)', () {
    test('taille dépassée', () {
      expect(
        friendlySupabaseError(
          const StorageException(
            'The object exceeded the maximum allowed size',
            statusCode: '413',
          ),
        ),
        'Fichier trop volumineux pour être envoyé.',
      );
    });

    test('type MIME refusé', () {
      expect(
        friendlySupabaseError(
          const StorageException('mime type text/html is not supported'),
        ),
        'Type de fichier non autorisé.',
      );
    });

    test('refus RLS', () {
      expect(
        friendlySupabaseError(
          const StorageException(
            'new row violates row-level security policy',
            statusCode: '403',
          ),
        ),
        contains('pas membre'),
      );
    });

    test('refus local avant envoi', () {
      expect(
        friendlySupabaseError(const ChatMediaRejected('Trop gros.')),
        'Trop gros.',
      );
    });
  });
}

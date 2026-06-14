import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_typography.dart';
import '../../features/messages/data/models/chat_models.dart';

/// Affiche le détail d'une annonce sans fermer la navigation principale.
Future<void> showAnnouncementDetail(
  BuildContext context,
  Announcement announcement,
) {
  final dateFormat = DateFormat('d MMMM yyyy · HH:mm', 'fr');

  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(announcement.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dateFormat.format(announcement.createdAt),
                style: AppTypography.caption,
              ),
              const SizedBox(height: 12),
              Text(announcement.content, style: AppTypography.body),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fermer'),
          ),
        ],
      );
    },
  );
}

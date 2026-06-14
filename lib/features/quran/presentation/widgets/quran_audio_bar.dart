import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/quran_audio_service.dart';
import '../providers/quran_provider.dart';

class QuranAudioBar extends ConsumerWidget {
  const QuranAudioBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(quranAudioServiceProvider);
    final target = audio.currentTarget;
    if (target == null) return const SizedBox.shrink();

    return Material(
      elevation: 8,
      color: AppColors.cardSurface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: StreamBuilder(
            stream: audio.playerStateStream,
            builder: (context, snapshot) {
              final playing = audio.isPlaying;
              return Row(
                children: [
                  IconButton(
                    icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                    color: AppColors.brightGreen,
                    onPressed: () => audio.togglePlayPause(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Récitation', style: AppTypography.h4),
                        Text(target.label, style: AppTypography.caption, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.fast_rewind, size: 20, color: AppColors.textSecondary),
                    onPressed: () => audio.seekBackward(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.fast_forward, size: 20, color: AppColors.textSecondary),
                    onPressed: () => audio.seekForward(),
                  ),
                  PopupMenuButton<double>(
                    icon: const Icon(Icons.speed, size: 20, color: AppColors.textSecondary),
                    color: AppColors.cardSurfaceLight,
                    onSelected: (speed) => audio.setSpeed(speed),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 0.5, child: Text('0.5x', style: TextStyle(color: AppColors.white))),
                      const PopupMenuItem(value: 1.0, child: Text('1.0x (Normal)', style: TextStyle(color: AppColors.white))),
                      const PopupMenuItem(value: 1.5, child: Text('1.5x', style: TextStyle(color: AppColors.white))),
                      const PopupMenuItem(value: 2.0, child: Text('2.0x', style: TextStyle(color: AppColors.white))),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.stop, color: AppColors.error),
                    onPressed: () => audio.stop(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

Future<void> showReciterPicker(BuildContext context, WidgetRef ref) async {
  final current = ref.read(quranReciterProvider);
  await showModalBottomSheet<void>(
    context: context,
    builder: (context) => ListView(
      shrinkWrap: true,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text('Choisir un récitateur', style: AppTypography.h2),
        ),
        ...QuranAudioService.reciters.map((reciter) {
          final selected = reciter.id == current;
          return ListTile(
            title: Text(reciter.label),
            trailing: selected
                ? const Icon(Icons.check, color: AppColors.brightGreen)
                : null,
            onTap: () async {
              ref.read(quranReciterProvider.notifier).state = reciter.id;
              await ref
                  .read(quranBookmarksRepositoryProvider)
                  .setReciterId(reciter.id);
              if (context.mounted) Navigator.pop(context);
            },
          );
        }),
      ],
    ),
  );
}

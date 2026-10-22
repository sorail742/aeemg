import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/phone_number.dart';
import '../../../core/utils/supabase_errors.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/chat_media.dart';
import '../data/models/chat_models.dart';
import 'providers/messages_provider.dart';

// ─────────────────────────────────────────────────────────────
//  CALL SCREEN
// ─────────────────────────────────────────────────────────────
class _CallScreen extends StatefulWidget {
  const _CallScreen({required this.groupName, required this.isVideo});

  final String groupName;
  final bool isVideo;

  @override
  State<_CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<_CallScreen> {
  Timer? _timer;
  int _seconds = 0;
  bool _muted = false;
  bool _speakerOn = true;
  bool _cameraOff = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isVideo ? '📹 Appel vidéo' : '📞 Appel audio',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _formattedTime,
                    style: const TextStyle(
                      color: AppColors.brightGreen,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Avatar
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.emerald, AppColors.brightGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emerald.withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(Icons.group, size: 60, color: AppColors.white),
            ),
            const SizedBox(height: 24),
            Text(
              widget.groupName,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Appel en cours...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            const Spacer(),
            // Controls
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CallButton(
                    icon: _muted ? Icons.mic_off : Icons.mic,
                    label: _muted ? 'Activé' : 'Muet',
                    color: _muted ? AppColors.error : AppColors.textTertiary,
                    onTap: () => setState(() => _muted = !_muted),
                  ),
                  // End call button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.error,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error,
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.call_end,
                        color: AppColors.white,
                        size: 34,
                      ),
                    ),
                  ),
                  if (widget.isVideo)
                    _CallButton(
                      icon: _cameraOff ? Icons.videocam_off : Icons.videocam,
                      label: _cameraOff ? 'Caméra off' : 'Caméra',
                      color: _cameraOff
                          ? AppColors.error
                          : AppColors.textTertiary,
                      onTap: () => setState(() => _cameraOff = !_cameraOff),
                    )
                  else
                    _CallButton(
                      icon: _speakerOn ? Icons.volume_up : Icons.volume_off,
                      label: 'Haut-parleur',
                      color: _speakerOn
                          ? AppColors.brightGreen
                          : AppColors.textTertiary,
                      onTap: () => setState(() => _speakerOn = !_speakerOn),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.2),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MÉDIA PRIVÉ (URL signée, SEC-006)
// ─────────────────────────────────────────────────────────────
class _ChatMedia extends ConsumerWidget {
  const _ChatMedia({required this.message, required this.builder});

  final ChatMessage message;
  final Widget Function(String url) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kind = ChatMediaKind.fromMessageType(message.messageType)!;
    final url = ref.watch(
      chatMediaUrlProvider((
        kind: kind,
        path: message.mediaPath,
        legacyUrl: message.mediaUrl,
      )),
    );
    return url.when(
      data: (url) => url == null ? const _MediaUnavailable() : builder(url),
      loading: () => const SizedBox(
        width: 200,
        height: 48,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.white,
          ),
        ),
      ),
      error: (_, _) => const _MediaUnavailable(),
    );
  }
}

class _MediaUnavailable extends StatelessWidget {
  const _MediaUnavailable();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.broken_image_outlined,
          color: AppColors.textTertiary,
          size: 18,
        ),
        SizedBox(width: 6),
        Text(
          'Média indisponible',
          style: TextStyle(color: AppColors.textTertiary),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  AUDIO MESSAGE PLAYER
// ─────────────────────────────────────────────────────────────
class _AudioMessagePlayer extends StatefulWidget {
  const _AudioMessagePlayer({required this.url, required this.isMine});

  final String url;
  final bool isMine;

  @override
  State<_AudioMessagePlayer> createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<_AudioMessagePlayer> {
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playing = state == PlayerState.playing);
    });
    _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _player.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playing = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    final activeColor = widget.isMine ? AppColors.white : AppColors.brightGreen;
    final trackColor = widget.isMine ? AppColors.border : AppColors.border;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () async {
            if (_playing) {
              await _player.pause();
            } else {
              if (_position > Duration.zero) {
                await _player.resume();
              } else {
                await _player.play(UrlSource(widget.url));
              }
            }
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isMine
                  ? AppColors.border
                  : AppColors.emerald.withValues(alpha: 0.3),
            ),
            child: Icon(
              _playing ? Icons.pause : Icons.play_arrow,
              color: activeColor,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: progress.toDouble(),
                backgroundColor: trackColor,
                valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                minHeight: 3,
                borderRadius: BorderRadius.circular(2),
              ),
              const SizedBox(height: 4),
              Text(
                _playing ? _fmt(_position) : _fmt(_duration),
                style: TextStyle(
                  color: activeColor.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          Icons.graphic_eq,
          color: activeColor.withValues(alpha: 0.5),
          size: 18,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MAIN CHAT SCREEN
// ─────────────────────────────────────────────────────────────
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.groupId, required this.groupName});

  final String groupId;
  final String groupName;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _audioRecorder = AudioRecorder();
  final _imagePicker = ImagePicker();
  final _scrollController = ScrollController();

  bool _joinAttempted = false;
  bool _isRecording = false;
  bool _showEmojiPicker = false;
  String? _recordingPath;
  ChatMessage? _replyingTo;

  // Reactions quick bar
  static const _quickReactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

  @override
  void dispose() {
    _controller.dispose();
    _audioRecorder.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final user = ref.read(currentUserProvider);
    final text = _controller.text.trim();
    if (user == null || text.isEmpty) return;

    final replyId = _replyingTo?.id;
    setState(() => _replyingTo = null);

    await ref
        .read(messagesRepositoryProvider)
        .sendMessage(
          groupId: widget.groupId,
          senderId: user.id,
          content: text,
          messageType: 'text',
          replyToId: replyId,
        );
    _controller.clear();
  }

  Future<void> _sendImage() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final xFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (xFile == null) return;

    await _sendMedia(
      kind: ChatMediaKind.image,
      fileName: xFile.name,
      readBytes: xFile.readAsBytes,
      content: '📸 Image',
      senderId: user.id,
    );
  }

  /// Dépose le média dans le dossier privé du groupe puis envoie le message
  /// avec son chemin (SEC-006).
  Future<void> _sendMedia({
    required ChatMediaKind kind,
    required String fileName,
    required Future<Uint8List> Function() readBytes,
    required String content,
    required String senderId,
  }) async {
    final repo = ref.read(messagesRepositoryProvider);
    try {
      final path = await repo.uploadChatMedia(
        groupId: widget.groupId,
        kind: kind,
        fileName: fileName,
        bytes: await readBytes(),
      );
      await repo.sendMessage(
        groupId: widget.groupId,
        senderId: senderId,
        content: content,
        messageType: kind.name,
        mediaPath: path,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlySupabaseError(e))));
      }
    }
  }

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final dir = await getTemporaryDirectory();
      _recordingPath =
          '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(const RecordConfig(), path: _recordingPath!);
      setState(() => _isRecording = true);
    }
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    setState(() => _isRecording = false);
    if (path == null) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await _sendMedia(
      kind: ChatMediaKind.audio,
      fileName: 'vocal.m4a',
      readBytes: () => File(path).readAsBytes(),
      content: '🎤 Message vocal',
      senderId: user.id,
    );
  }

  void _replyToMessage(ChatMessage message) {
    setState(() => _replyingTo = message);
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardSurfaceLight,
        title: const Text(
          'Supprimer le message',
          style: TextStyle(color: AppColors.white),
        ),
        content: const Text(
          'Ce message sera supprimé pour tout le monde.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(messagesRepositoryProvider).deleteMessage(message.id);
    }
  }

  void _showMessageOptions(
    BuildContext context,
    ChatMessage message,
    bool isMine,
  ) {
    final userId = ref.read(currentUserProvider)?.id;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cardSurfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quick reactions bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _quickReactions.map((emoji) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        if (userId != null) {
                          ref
                              .read(messagesRepositoryProvider)
                              .addReaction(
                                messageId: message.id,
                                userId: userId,
                                emoji: emoji,
                              );
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(color: AppColors.border, height: 1),
              _OptionTile(
                icon: Icons.reply,
                label: 'Répondre',
                onTap: () {
                  Navigator.pop(context);
                  _replyToMessage(message);
                },
              ),
              _OptionTile(
                icon: Icons.copy,
                label: 'Copier',
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: message.content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Message copié'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              if (isMine)
                _OptionTile(
                  icon: Icons.delete_outline,
                  label: 'Supprimer',
                  color: AppColors.error,
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessage(message);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddMemberDialog() {
    final phoneController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: AppColors.cardSurfaceLight,
            title: const Text(
              'Ajouter un membre',
              style: TextStyle(color: AppColors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Entrez le numéro de téléphone pour l\'ajouter ou l\'inviter :',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    hintText: '+224...',
                    hintStyle: const TextStyle(color: AppColors.textTertiary),
                    filled: true,
                    fillColor: AppColors.scrim.withValues(alpha: 0.26),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Annuler',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brightGreen,
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        if (phoneController.text.trim().isEmpty) return;
                        final messenger = ScaffoldMessenger.of(context);
                        final phone = normalizeE164(phoneController.text);
                        if (phone == null) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Numéro invalide : saisissez-le avec '
                                'l\'indicatif pays, par exemple +224 620 00 00 00.',
                              ),
                            ),
                          );
                          return;
                        }

                        setStateDialog(() => isLoading = true);
                        try {
                          // TODO: Dans une vraie app, on chercherait l'ID de l'utilisateur par son téléphone.
                          // Si l'utilisateur n'existe pas, on l'invite via invitePhoneNumber.
                          // Pour simuler cela, on appelle l'invitation.
                          await ref
                              .read(messagesRepositoryProvider)
                              .invitePhoneNumber(widget.groupId, phone);

                          if (ctx.mounted) Navigator.pop(ctx);
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Invitation envoyée au numéro.'),
                            ),
                          );
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(friendlySupabaseError(e))),
                          );
                        } finally {
                          setStateDialog(() => isLoading = false);
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text(
                        'Ajouter',
                        style: TextStyle(color: AppColors.white),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showGroupOptions() {
    final canManage =
        ref.read(canManageGroupProvider(widget.groupId)).value ?? false;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cardSurfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.groupName,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const Divider(color: AppColors.border, height: 1),
              // Réservé aux admins du groupe et au staff (SEC-003).
              if (canManage)
                _OptionTile(
                  icon: Icons.person_add,
                  label: 'Ajouter un membre/numéro',
                  onTap: () {
                    Navigator.pop(context);
                    _showAddMemberDialog();
                  },
                ),
              _OptionTile(
                icon: Icons.group,
                label: 'Voir les membres',
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.cardSurfaceLight,
                      title: const Text(
                        'Membres du groupe',
                        style: TextStyle(color: AppColors.white),
                      ),
                      content: const Text(
                        'La liste des membres sera affichée ici prochainement.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Fermer'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              _OptionTile(
                icon: Icons.notifications_off,
                label: 'Désactiver les notifications',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Notifications désactivées pour ce groupe.',
                      ),
                    ),
                  );
                },
              ),
              _OptionTile(
                icon: Icons.search,
                label: 'Rechercher dans la discussion',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Recherche activée. Tapez votre recherche...',
                      ),
                    ),
                  );
                },
              ),
              _OptionTile(
                icon: Icons.delete_sweep_outlined,
                label: 'Effacer la discussion',
                color: AppColors.error,
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.cardSurfaceLight,
                      title: const Text(
                        'Effacer la discussion',
                        style: TextStyle(color: AppColors.white),
                      ),
                      content: const Text(
                        'Voulez-vous vraiment vider cette discussion ? (Action locale uniquement)',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Discussion effacée de votre appareil.',
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'Effacer',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build date label ──────────────────────────────────────
  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDay = DateTime(dt.year, dt.month, dt.day);

    if (msgDay == today) return "Aujourd'hui";
    if (msgDay == yesterday) return 'Hier';
    return DateFormat('d MMMM yyyy', 'fr').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesStreamProvider(widget.groupId));
    final user = ref.watch(currentUserProvider);
    // Précharge le droit de gestion pour le menu des options du groupe.
    ref.watch(canManageGroupProvider(widget.groupId));

    if (user != null && !_joinAttempted) {
      _joinAttempted = true;
      Future.microtask(() {
        ref.read(messagesRepositoryProvider).joinGroup(widget.groupId, user.id);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy.withValues(alpha: 0.95),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.emerald, AppColors.emeraldHover],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emerald.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.group, color: AppColors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.groupName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.emerald,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'En ligne',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.emerald,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam, color: AppColors.emerald),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    _CallScreen(groupName: widget.groupName, isVideo: true),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.call, color: AppColors.emerald),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    _CallScreen(groupName: widget.groupName, isVideo: false),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.white),
            onPressed: _showGroupOptions,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const NetworkImage(
              'https://i.pinimg.com/originals/8f/ba/cb/8fbacbd464e996966eb9d4a6b7a9c21e.jpg',
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              AppColors.scrim.withValues(alpha: 0.82),
              BlendMode.darken,
            ),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: AsyncValueWidget(
                value: messagesAsync,
                empty: const Center(
                  child: Text(
                    'Aucun message. Lancez la discussion !',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                data: (messages) {
                  final sorted = messages.toList()
                    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

                  // Build list with date separators (oldest to newest)
                  final items = <_ChatItem>[];
                  String? lastDateLabel;
                  for (final msg in sorted) {
                    final label = _dateLabel(msg.createdAt);
                    if (label != lastDateLabel) {
                      items.add(_ChatItem.dateSeparator(label));
                      lastDateLabel = label;
                    }
                    items.add(_ChatItem.message(msg));
                  }

                  // Reverse for the reverse ListView
                  final reversedItems = items.reversed.toList();

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    reverse: true,
                    itemCount: reversedItems.length,
                    itemBuilder: (context, index) {
                      final item = reversedItems[index];
                      if (item.isDateSeparator) {
                        return _DateSeparatorWidget(label: item.dateLabel!);
                      }
                      final msg = item.message!;
                      final isMine = msg.senderId == user?.id;
                      return _MessageBubble(
                        message: msg,
                        isMine: isMine,
                        onSwipe: () => _replyToMessage(msg),
                        onLongPress: () =>
                            _showMessageOptions(context, msg, isMine),
                      );
                    },
                  );
                },
              ),
            ),
            // Reply preview
            if (_replyingTo != null)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  border: Border(
                    top: BorderSide(
                      color: AppColors.emerald.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.emerald,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _replyingTo!.senderName ?? 'Utilisateur',
                            style: const TextStyle(
                              color: AppColors.emerald,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _replyingTo!.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textTertiary,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _replyingTo = null),
                    ),
                  ],
                ),
              ),
            // Input bar
            if (user != null)
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.cardSurfaceLight,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      _showEmojiPicker
                                          ? Icons.keyboard
                                          : Icons.emoji_emotions_outlined,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: () {
                                      if (!_showEmojiPicker) {
                                        FocusScope.of(context).unfocus();
                                      }
                                      setState(
                                        () => _showEmojiPicker =
                                            !_showEmojiPicker,
                                      );
                                    },
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _controller,
                                      minLines: 1,
                                      maxLines: 6,
                                      style: const TextStyle(
                                        color: AppColors.white,
                                      ),
                                      onTap: () {
                                        if (_showEmojiPicker) {
                                          setState(
                                            () => _showEmojiPicker = false,
                                          );
                                        }
                                      },
                                      decoration: const InputDecoration(
                                        hintText: 'Message',
                                        border: InputBorder.none,
                                        hintStyle: TextStyle(
                                          color: AppColors.textTertiary,
                                        ),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.attach_file,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: _sendImage,
                                  ),
                                  if (_controller.text.isEmpty)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.camera_alt,
                                        color: AppColors.textSecondary,
                                      ),
                                      onPressed: _sendImage,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onLongPressStart: (_) => _startRecording(),
                            onLongPressEnd: (_) => _stopRecording(),
                            onTap: () {
                              if (_controller.text.isNotEmpty) _sendText();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isRecording
                                    ? AppColors.error
                                    : AppColors.emerald,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (_isRecording
                                                ? AppColors.error
                                                : AppColors.emerald)
                                            .withValues(alpha: 0.4),
                                    blurRadius: _isRecording ? 15 : 6,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _controller.text.isNotEmpty
                                    ? Icons.send
                                    : (_isRecording
                                          ? Icons.mic
                                          : Icons.mic_none),
                                color: AppColors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_showEmojiPicker)
                      SizedBox(
                        height: 250,
                        child: EmojiPicker(
                          textEditingController: _controller,
                          onEmojiSelected: (_, _) => setState(() {}),
                          config: const Config(
                            emojiViewConfig: EmojiViewConfig(
                              backgroundColor: AppColors.cardSurfaceLight,
                            ),
                            categoryViewConfig: CategoryViewConfig(
                              backgroundColor: AppColors.cardSurfaceLight,
                              iconColorSelected: AppColors.brightGreen,
                              indicatorColor: AppColors.brightGreen,
                            ),
                            bottomActionBarConfig: BottomActionBarConfig(
                              backgroundColor: AppColors.cardSurfaceLight,
                              buttonColor: AppColors.cardSurfaceLight,
                              buttonIconColor: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────────────────────
class _ChatItem {
  final ChatMessage? message;
  final String? dateLabel;

  bool get isDateSeparator => dateLabel != null;

  const _ChatItem.message(this.message) : dateLabel = null;
  const _ChatItem.dateSeparator(this.dateLabel) : message = null;
}

class _DateSeparatorWidget extends StatelessWidget {
  const _DateSeparatorWidget({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: AppColors.white.withValues(alpha: 0.1)),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.cardSurfaceLight.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(color: AppColors.white.withValues(alpha: 0.1)),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.white;
    return ListTile(
      leading: Icon(icon, color: c),
      title: Text(label, style: TextStyle(color: c)),
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MESSAGE BUBBLE
// ─────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.onSwipe,
    required this.onLongPress,
  });

  final ChatMessage message;
  final bool isMine;
  final VoidCallback onSwipe;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat.Hm('fr');

    return Dismissible(
      key: ValueKey(message.id),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        onSwipe();
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: const Icon(Icons.reply, color: AppColors.textSecondary),
      ),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.78,
            ),
            decoration: BoxDecoration(
              color: message.isDeleted
                  ? AppColors.white.withValues(alpha: 0.05)
                  : (isMine ? AppColors.heroStart : AppColors.cardSurfaceLight),
              // v3 : bulles plus rondes, coin du locuteur discret.
              border: isMine ? null : Border.all(color: AppColors.border),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppRadius.large + 2),
                topRight: const Radius.circular(AppRadius.large + 2),
                bottomLeft: Radius.circular(
                  isMine ? AppRadius.large + 2 : AppRadius.small - 2,
                ),
                bottomRight: Radius.circular(
                  isMine ? AppRadius.small - 2 : AppRadius.large + 2,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.scrim.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sender name (groups)
                if (!isMine && message.senderName != null && !message.isDeleted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      message.senderName!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color:
                            AppColors.avatarPalette[message.senderId.hashCode %
                                AppColors.avatarPalette.length],
                      ),
                    ),
                  ),
                // Reply preview
                if (message.replyToId != null && !message.isDeleted)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.scrim.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: const Border(
                        left: BorderSide(
                          color: AppColors.brightGreen,
                          width: 3,
                        ),
                      ),
                    ),
                    child: const Text(
                      '↩ Réponse à un message',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                // Content
                if (message.isDeleted)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.block,
                        color: AppColors.textTertiary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        message.content,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )
                else if (message.messageType == 'image' &&
                    (message.mediaPath ?? message.mediaUrl) != null)
                  _ChatMedia(
                    message: message,
                    builder: (url) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(url, fit: BoxFit.cover, width: 200),
                    ),
                  )
                else if (message.messageType == 'audio' &&
                    (message.mediaPath ?? message.mediaUrl) != null)
                  _ChatMedia(
                    message: message,
                    builder: (url) =>
                        _AudioMessagePlayer(url: url, isMine: isMine),
                  )
                else
                  Text(message.content, style: AppTypography.body),
                // Timestamp + ticks
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeFormat.format(message.createdAt),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        if (isMine && !message.isDeleted) ...[
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.done_all,
                            size: 13,
                            color: AppColors.info,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

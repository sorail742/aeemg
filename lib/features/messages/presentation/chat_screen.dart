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
      backgroundColor: const Color(0xFF0B1120),
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
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
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
              child: const Icon(Icons.group, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              widget.groupName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Appel en cours...',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const Spacer(),
            // Controls
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CallButton(
                    icon: _muted ? Icons.mic_off : Icons.mic,
                    label: _muted ? 'Activé' : 'Muet',
                    color: _muted ? Colors.redAccent : Colors.white30,
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
                        color: Colors.red,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red,
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.call_end,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                  if (widget.isVideo)
                    _CallButton(
                      icon: _cameraOff ? Icons.videocam_off : Icons.videocam,
                      label: _cameraOff ? 'Caméra off' : 'Caméra',
                      color: _cameraOff ? Colors.redAccent : Colors.white30,
                      onTap: () => setState(() => _cameraOff = !_cameraOff),
                    )
                  else
                    _CallButton(
                      icon: _speakerOn ? Icons.volume_up : Icons.volume_off,
                      label: 'Haut-parleur',
                      color: _speakerOn
                          ? AppColors.brightGreen
                          : Colors.white30,
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
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
        Icon(Icons.broken_image_outlined, color: Colors.white38, size: 18),
        SizedBox(width: 6),
        Text('Média indisponible', style: TextStyle(color: Colors.white38)),
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

    final activeColor = widget.isMine ? Colors.white : AppColors.brightGreen;
    final trackColor = widget.isMine ? Colors.white24 : Colors.white24;

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
                  ? Colors.white24
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
        backgroundColor: const Color(0xFF1F2C34),
        title: const Text(
          'Supprimer le message',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Ce message sera supprimé pour tout le monde.',
          style: TextStyle(color: Colors.white70),
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
              style: TextStyle(color: Colors.redAccent),
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
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1F2C34),
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
                          color: Colors.white.withValues(alpha: 0.08),
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
              const Divider(color: Colors.white12, height: 1),
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
                  color: Colors.redAccent,
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
            backgroundColor: const Color(0xFF1F2C34),
            title: const Text(
              'Ajouter un membre',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Entrez le numéro de téléphone pour l\'ajouter ou l\'inviter :',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '+224...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.black26,
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
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brightGreen,
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        final phone = phoneController.text.trim();
                        if (phone.isEmpty) return;

                        setStateDialog(() => isLoading = true);
                        final messenger = ScaffoldMessenger.of(context);
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
                            SnackBar(content: Text('Erreur: $e')),
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
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Ajouter',
                        style: TextStyle(color: Colors.white),
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
        ref.read(canManageGroupProvider(widget.groupId)).valueOrNull ?? false;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1F2C34),
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
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
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
                      backgroundColor: const Color(0xFF1F2C34),
                      title: const Text(
                        'Membres du groupe',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        'La liste des membres sera affichée ici prochainement.',
                        style: TextStyle(color: Colors.white70),
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
                color: Colors.redAccent,
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF1F2C34),
                      title: const Text(
                        'Effacer la discussion',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        'Voulez-vous vraiment vider cette discussion ? (Action locale uniquement)',
                        style: TextStyle(color: Colors.white70),
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
                            style: TextStyle(color: Colors.redAccent),
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
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A).withValues(alpha: 0.95),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                  colors: [AppColors.emerald, Color(0xFF00A86B)],
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
              child: const Icon(Icons.group, color: Colors.white, size: 24),
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
                      color: Colors.white,
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
            icon: const Icon(Icons.more_vert, color: Colors.white),
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
              Colors.black.withValues(alpha: 0.82),
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
                    style: TextStyle(color: Colors.white54),
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
                  color: const Color(0xFF1A2833),
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
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white38,
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
                                color: const Color(0xFF1F2C34),
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
                                      color: Colors.white54,
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
                                        color: Colors.white,
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
                                          color: Colors.white38,
                                        ),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.attach_file,
                                      color: Colors.white54,
                                    ),
                                    onPressed: _sendImage,
                                  ),
                                  if (_controller.text.isEmpty)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white54,
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
                                    ? Colors.redAccent
                                    : AppColors.emerald,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (_isRecording
                                                ? Colors.redAccent
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
                                color: Colors.white,
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
                              backgroundColor: Color(0xFF1F2C34),
                            ),
                            categoryViewConfig: CategoryViewConfig(
                              backgroundColor: Color(0xFF1F2C34),
                              iconColorSelected: AppColors.brightGreen,
                              indicatorColor: AppColors.brightGreen,
                            ),
                            bottomActionBarConfig: BottomActionBarConfig(
                              backgroundColor: Color(0xFF1F2C34),
                              buttonColor: Color(0xFF1F2C34),
                              buttonIconColor: Colors.white54,
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
          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2C34).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
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
    final c = color ?? Colors.white;
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
        child: const Icon(Icons.reply, color: Colors.white70),
      ),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.78,
            ),
            decoration: BoxDecoration(
              color: message.isDeleted
                  ? Colors.white.withValues(alpha: 0.05)
                  : (isMine
                        ? const Color(0xFF005C4B)
                        : const Color(0xFF202C33)),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: isMine ? const Radius.circular(14) : Radius.zero,
                bottomRight: isMine ? Radius.zero : const Radius.circular(14),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
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
                        color: Colors
                            .primaries[message.senderId.hashCode %
                                Colors.primaries.length]
                            .shade300,
                      ),
                    ),
                  ),
                // Reply preview
                if (message.replyToId != null && !message.isDeleted)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
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
                      style: TextStyle(fontSize: 11, color: Colors.white60),
                    ),
                  ),
                // Content
                if (message.isDeleted)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.block, color: Colors.white38, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        message.content,
                        style: const TextStyle(
                          color: Colors.white38,
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
                  Text(
                    message.content,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
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
                            color: Colors.white38,
                          ),
                        ),
                        if (isMine && !message.isDeleted) ...[
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.done_all,
                            size: 13,
                            color: Colors.lightBlue,
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

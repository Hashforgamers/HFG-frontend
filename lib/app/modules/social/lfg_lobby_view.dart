import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'lfg_service.dart';

class LfgLobbyView extends StatefulWidget {
  const LfgLobbyView({super.key, required this.post});

  final LfgPost post;

  @override
  State<LfgLobbyView> createState() => _LfgLobbyViewState();
}

class _LfgLobbyViewState extends State<LfgLobbyView> {
  static const _green = Color(0xFF00DC00);
  final LfgService _service = LfgService();
  final AudioRecorder _recorder = AudioRecorder();
  final TextEditingController _messageController = TextEditingController();
  final Map<String, AudioPlayer> _players = <String, AudioPlayer>{};

  bool _isRecording = false;
  bool _isSending = false;
  DateTime? _recordingStartedAt;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    unawaited(_join());
  }

  Future<void> _join() async {
    try {
      await _service.joinLobby(widget.post.uid);
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    unawaited(_recorder.dispose());
    _messageController.dispose();
    for (final player in _players.values) {
      unawaited(player.dispose());
    }
    super.dispose();
  }

  void _showError(Object error) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          error
              .toString()
              .replaceFirst('Exception: ', '')
              .replaceFirst('Bad state: ', ''),
        ),
      ),
    );
  }

  Future<void> _sendText() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    try {
      await _service.sendText(lobbyId: widget.post.uid, text: text);
      _messageController.clear();
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _toggleRecording() async {
    if (_isSending) return;
    if (_isRecording) {
      await _stopAndSendVoice();
      return;
    }
    final allowed = await _recorder.hasPermission();
    if (!allowed) {
      if (mounted) {
        _showError('Mic permission is needed to drop a voice note.');
      }
      return;
    }
    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/lfg_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 44100,
      ),
      path: path,
    );
    _recordingStartedAt = DateTime.now();
    _recordingDuration = Duration.zero;
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _recordingStartedAt == null) return;
      setState(() {
        _recordingDuration = DateTime.now().difference(_recordingStartedAt!);
      });
    });
    if (mounted) setState(() => _isRecording = true);
  }

  Future<void> _stopAndSendVoice() async {
    _recordingTimer?.cancel();
    final duration = _recordingStartedAt == null
        ? _recordingDuration
        : DateTime.now().difference(_recordingStartedAt!);
    final path = await _recorder.stop();
    if (mounted) {
      setState(() {
        _isRecording = false;
        _isSending = true;
      });
    }
    if (path == null || duration.inMilliseconds < 700) {
      if (path != null) unawaited(File(path).delete());
      if (mounted) {
        setState(() => _isSending = false);
        _showError('Hold the thought a little longer before sending.');
      }
      return;
    }
    try {
      final uid = _service.currentUid;
      if (uid == null) throw StateError('Sign in to send voice notes.');
      final objectPath =
          'lfg_voice/${widget.post.uid}/$uid/'
          '${DateTime.now().millisecondsSinceEpoch}.m4a';
      final snapshot = await _uploadVoiceFile(File(path), objectPath);
      final url = await _downloadUrlAfterUpload(snapshot.ref);
      await _service.sendVoice(
        lobbyId: widget.post.uid,
        audioUrl: url,
        durationMs: duration.inMilliseconds,
      );
      unawaited(File(path).delete());
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        '[LFG][voice-upload] FirebaseException plugin=${error.plugin} '
        'code=${error.code} message=${error.message}',
      );
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        _showError(
          error.code == 'object-not-found'
              ? 'Voice upload could not be found. Please record it again.'
              : 'Voice upload failed (${error.code}).',
        );
      }
    } catch (error, stackTrace) {
      debugPrint('[LFG][voice-upload] $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<TaskSnapshot> _uploadVoiceFile(File file, String objectPath) async {
    final references = <Reference>[
      FirebaseStorage.instance.ref(objectPath),
      FirebaseStorage.instanceFor(
        bucket: 'gs://hash-ee6fc.appspot.com',
      ).ref(objectPath),
    ];
    FirebaseException? lastStorageError;
    for (final ref in references) {
      debugPrint(
        '[LFG][voice-upload] start bucket=${ref.bucket} path=${ref.fullPath}',
      );
      try {
        final snapshot = await ref.putFile(
          file,
          SettableMetadata(contentType: 'audio/mp4'),
        );
        if (snapshot.state != TaskState.success) {
          throw StateError('Voice upload did not complete: ${snapshot.state}');
        }
        debugPrint(
          '[LFG][voice-upload] success bytes=${snapshot.totalBytes} '
          'bucket=${snapshot.ref.bucket} path=${snapshot.ref.fullPath}',
        );
        return snapshot;
      } on FirebaseException catch (error) {
        lastStorageError = error;
        debugPrint(
          '[LFG][voice-upload] bucket=${ref.bucket} code=${error.code} '
          'message=${error.message}',
        );
        if (error.code != 'object-not-found') rethrow;
      }
    }
    throw lastStorageError ?? StateError('No Firebase Storage bucket worked.');
  }

  Future<String> _downloadUrlAfterUpload(Reference ref) async {
    Object? lastError;
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        return await ref.getDownloadURL();
      } on FirebaseException catch (error) {
        lastError = error;
        debugPrint(
          '[LFG][voice-url] attempt=$attempt bucket=${ref.bucket} '
          'path=${ref.fullPath} code=${error.code} message=${error.message}',
        );
        if (error.code != 'object-not-found' || attempt == 3) rethrow;
        await Future<void>.delayed(Duration(milliseconds: attempt * 250));
      }
    }
    throw StateError('Could not resolve voice URL: $lastError');
  }

  Future<void> _togglePlayback(LfgLobbyMessage message) async {
    final player = _players.putIfAbsent(message.id, AudioPlayer.new);
    try {
      if (player.playing) {
        await player.pause();
      } else {
        if (player.audioSource == null) {
          await player.setUrl(message.audioUrl);
        }
        if (player.processingState == ProcessingState.completed) {
          await player.seek(Duration.zero);
        }
        await player.play();
      }
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) _showError('Could not play this voice drop.');
    }
  }

  String _clock(DateTime time) {
    final hour = time.hour == 0
        ? 12
        : time.hour > 12
        ? time.hour - 12
        : time.hour;
    return '$hour:${time.minute.toString().padLeft(2, '0')} '
        '${time.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _duration(int milliseconds) {
    final seconds = Duration(milliseconds: milliseconds).inSeconds;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090909),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF252525),
              backgroundImage: widget.post.photoUrl.isEmpty
                  ? null
                  : CachedNetworkImageProvider(widget.post.photoUrl),
              child: widget.post.photoUrl.isEmpty
                  ? const Icon(Icons.groups_rounded, color: Colors.white54)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.post.game} LOBBY',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${widget.post.mode} · async squad chat',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildLobbyBanner(),
          Expanded(
            child: StreamBuilder<List<LfgLobbyMessage>>(
              stream: _service.watchLobbyMessages(widget.post.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Lobby comms are having a lag spike.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }
                final messages = snapshot.data ?? const <LfgLobbyMessage>[];
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.graphic_eq_rounded,
                            color: _green,
                            size: 42,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'BREAK THE SILENCE',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Drop a message or voice note. No live call needed.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                  itemCount: messages.length,
                  itemBuilder: (_, index) => _buildMessage(messages[index]),
                );
              },
            ),
          ),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildLobbyBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _green.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: _green),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              widget.post.note.isEmpty
                  ? '${widget.post.displayName} is building a squad.'
                  : widget.post.note,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
            ),
          ),
          if (widget.post.micOn)
            const Icon(Icons.mic_rounded, color: Colors.white54, size: 18),
        ],
      ),
    );
  }

  Widget _buildMessage(LfgLobbyMessage message) {
    final mine = message.senderId == _service.currentUid;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 7),
        decoration: BoxDecoration(
          color: mine ? _green : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
          border: mine ? null : Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine)
              Text(
                message.senderName,
                style: GoogleFonts.inter(
                  color: _green,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            if (message.type == 'voice')
              _buildVoiceMessage(message, mine)
            else
              Text(
                message.text,
                style: GoogleFonts.inter(
                  color: mine ? Colors.black : Colors.white,
                  fontSize: 14,
                ),
              ),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                _clock(message.createdAt),
                style: GoogleFonts.inter(
                  color: mine ? Colors.black54 : Colors.white38,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceMessage(LfgLobbyMessage message, bool mine) {
    final player = _players[message.id];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => _togglePlayback(message),
          icon: Icon(
            player?.playing == true
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            color: mine ? Colors.black : _green,
          ),
        ),
        const SizedBox(width: 2),
        Icon(
          Icons.graphic_eq_rounded,
          color: mine ? Colors.black54 : Colors.white54,
          size: 54,
        ),
        const SizedBox(width: 7),
        Text(
          _duration(message.durationMs),
          style: GoogleFonts.inter(
            color: mine ? Colors.black87 : Colors.white70,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildComposer() {
    final seconds = _recordingDuration.inSeconds;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _isRecording
                  ? Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A1111),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const _RecordingDot(),
                          const SizedBox(width: 10),
                          Text(
                            'VOICE DROP  ${seconds ~/ 60}:'
                            '${(seconds % 60).toString().padLeft(2, '0')}',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'Tap mic to send',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    )
                  : TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendText(),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Drop a message...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF1A1A1A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _toggleRecording,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _isRecording ? Colors.redAccent : Colors.white10,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                ),
              ),
            ),
            if (!_isRecording) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: _isSending ? null : _sendText,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _isSending
                      ? const Padding(
                          padding: EdgeInsets.all(13),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.black),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecordingDot extends StatefulWidget {
  const _RecordingDot();

  @override
  State<_RecordingDot> createState() => _RecordingDotState();
}

class _RecordingDotState extends State<_RecordingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: const CircleAvatar(radius: 5, backgroundColor: Colors.redAccent),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/firestore_service.dart';
import '../sync_session_controller.dart';

// ─── Watch Together Screen ────────────────────────────────────────────────────
// Phase Z-3 — YouTube Watch Together
// Both partners load the same YouTube video; SyncSessionController keeps
// position and play/pause in sync. Reactions stored in Firestore.

class WatchTogetherScreen extends StatefulWidget {
  final String coupleId;
  const WatchTogetherScreen({super.key, required this.coupleId});
  @override State<WatchTogetherScreen> createState() => _WatchTogetherScreenState();
}

class _WatchTogetherScreenState extends State<WatchTogetherScreen> {
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  late final SyncSessionController _sync;
  YoutubePlayerController? _ytCtrl;
  StreamSubscription<YoutubePlayerValue>? _ytSub;

  final _urlCtrl = TextEditingController();
  String? _currentVideoId;
  Timer? _posTimer;

  // Reactions
  List<_Reaction> _reactions = [];
  StreamSubscription? _reactionSub;
  Timer? _reactionCleaner;

  // Watch list
  List<_WatchItem> _watchList = [];
  StreamSubscription? _watchListSub;

  @override
  void initState() {
    super.initState();
    _sync = SyncSessionController(coupleId: widget.coupleId, myUid: _uid);
    _sync.addListener(_onSyncChanged);
    _sync.listen();
    _loadWatchList();
    _listenReactions();
  }

  void _loadWatchList() {
    _watchListSub = FirestoreService()
        .sub(widget.coupleId, 'watchList')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .listen((snap) {
          if (!mounted) return;
          setState(() {
            _watchList = snap.docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              return _WatchItem(
                id: d.id,
                videoId: data['videoId'] ?? '',
                title: data['title'] ?? 'Untitled',
                addedBy: data['addedBy'] ?? '',
              );
            }).toList();
          });
        });
  }

  void _listenReactions() {
    _reactionSub = FirestoreService()
        .sub(widget.coupleId, 'watchReactions')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .listen((snap) {
          if (!mounted) return;
          final now = DateTime.now();
          final fresh = snap.docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final ts = (data['sentAt'] as Timestamp?)?.toDate();
            return ts != null && now.difference(ts).inSeconds < 5;
          }).map((d) {
            final data = d.data() as Map<String, dynamic>;
            return _Reaction(emoji: data['emoji'] ?? '❤️', fromUid: data['fromUid'] ?? '');
          }).toList();
          setState(() => _reactions = fresh);
          // Auto-clear after 5s
          _reactionCleaner?.cancel();
          if (fresh.isNotEmpty) {
            _reactionCleaner = Timer(const Duration(seconds: 5), () {
              if (mounted) setState(() => _reactions = []);
            });
          }
        });
  }

  // Called when syncSession changes (listener-side sync)
  void _onSyncChanged() {
    if (!mounted) return;
    final s = _sync.session;
    if (s == null || s.type != SyncType.youtube || !s.isActive) return;
    if (_sync.isConductor) return;

    // Load new video if changed
    if (s.contentId != _currentVideoId) {
      _loadVideo(s.contentId, autoplay: s.state == SyncState.playing, startMs: s.positionMs);
      return;
    }

    if (_ytCtrl == null) return;

    // Sync state
    if (s.state == SyncState.playing) {
      _ytCtrl!.playVideo();
    } else if (s.state == SyncState.paused) {
      _ytCtrl!.pauseVideo();
    }

    // Drift check
    _ytCtrl!.currentTime.then((pos) {
      final localMs = (pos * 1000).round();
      if (_sync.needsSeek(localMs)) {
        _ytCtrl!.seekTo(seconds: s.positionMs / 1000.0, allowSeekAhead: true);
      }
    });
  }

  void _loadVideo(String videoId, {bool autoplay = false, int startMs = 0}) {
    _ytSub?.cancel();
    _ytCtrl?.close();

    setState(() => _currentVideoId = videoId);

    _ytCtrl = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      startSeconds: startMs / 1000.0,
      autoPlay: autoplay,
      params: YoutubePlayerParams(
        showControls: _sync.isConductor,
        showFullscreenButton: true,
        mute: false,
        loop: false,
      ),
    );

    // Listen to player state changes
    _ytSub = _ytCtrl!.stream.listen((value) {
      if (!mounted) return;
      // Conductor: when player becomes playing, write to sync
      if (_sync.isConductor) {
        if (value.playerState == PlayerState.playing) {
          _ytCtrl!.currentTime.then((t) => _sync.play(positionMs: (t * 1000).round()));
        } else if (value.playerState == PlayerState.paused) {
          _ytCtrl!.currentTime.then((t) => _sync.pause(positionMs: (t * 1000).round()));
        }
      }
    });

    _startPositionSync();
    setState(() {});
  }

  void _startPositionSync() {
    _posTimer?.cancel();
    _posTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!_sync.isConductor || _ytCtrl == null) return;
      final pos = await _ytCtrl!.currentTime;
      await _sync.updatePosition((pos * 1000).round());
    });
  }

  Future<void> _startVideo(String videoId, {String title = ''}) async {
    // Save to watch list — use videoId as fallback title so pasted URLs always persist
    final existing = _watchList.any((w) => w.videoId == videoId);
    if (!existing) {
      final resolvedTitle = title.isNotEmpty ? title : 'Video $videoId';
      await FirestoreService().sub(widget.coupleId, 'watchList').add({
        'videoId': videoId,
        'title': resolvedTitle,
        'addedBy': _uid,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
    await _sync.startSession(SyncType.youtube, videoId);
    await _sync.play(positionMs: 0);
    _loadVideo(videoId, autoplay: true);
  }

  Future<void> _sendReaction(String emoji) async {
    await FirestoreService().sub(widget.coupleId, 'watchReactions').add({
      'emoji': emoji,
      'fromUid': _uid,
      'sentAt': FieldValue.serverTimestamp(),
    });
  }

  String? _extractVideoId(String input) {
    final uri = Uri.tryParse(input);
    if (uri == null) {
      if (input.length == 11 && !input.contains(' ')) return input;
      return null;
    }
    if (uri.host.contains('youtu.be')) return uri.pathSegments.firstOrNull;
    return uri.queryParameters['v'];
  }

  @override
  void dispose() {
    _posTimer?.cancel();
    _reactionCleaner?.cancel();
    _reactionSub?.cancel();
    _watchListSub?.cancel();
    _urlCtrl.dispose();
    _ytSub?.cancel();
    _ytCtrl?.close();
    _sync.removeListener(_onSyncChanged);
    _sync.endSession();
    _sync.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final td = context.watch<ThemeProvider>().data;

    return Scaffold(
      backgroundColor: td.background,
      appBar: AppBar(
        backgroundColor: td.background,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Watch Together 🎬', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: td.textOnSurface)),
          Text('YouTube only', style: TextStyle(fontSize: 11, color: td.textOnSurface.withValues(alpha: 0.45))),
        ]),
      ),
      body: Column(children: [
        // ── Player ──────────────────────────────────────────────────────
        if (_currentVideoId != null && _ytCtrl != null)
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(children: [
              YoutubePlayer(controller: _ytCtrl!),
              if (_reactions.isNotEmpty)
                Positioned.fill(child: IgnorePointer(child: _ReactionsOverlay(reactions: _reactions))),
            ]),
          )
        else
          Container(
            height: 200,
            color: Colors.black,
            child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('▶', style: TextStyle(fontSize: 48, color: Colors.white24)),
              const SizedBox(height: 12),
              Text('Paste a YouTube link below', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
            ])),
          ),

        // ── Reactions row ────────────────────────────────────────────────
        if (_currentVideoId != null)
          Container(
            color: td.surface,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (final emoji in ['❤️', '😂', '😭', '😮'])
                GestureDetector(
                  onTap: () => _sendReaction(emoji),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                ),
            ]),
          ),

        // ── URL input ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(child: Container(
              decoration: BoxDecoration(
                color: td.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: td.border),
              ),
              child: TextField(
                controller: _urlCtrl,
                style: TextStyle(color: td.textOnSurface, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Paste YouTube link or video ID…',
                  hintStyle: TextStyle(color: td.textOnSurface.withValues(alpha: 0.35), fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            )),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                final id = _extractVideoId(_urlCtrl.text.trim());
                if (id != null) {
                  _urlCtrl.clear();
                  _startVideo(id);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Paste a valid YouTube link')),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [td.primary, td.secondary]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('Watch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),

        // ── Watch List ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(children: [
            Text('Watch List', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: td.textOnSurface.withValues(alpha: 0.5))),
          ]),
        ),
        if (_watchList.isNotEmpty)
          Expanded(child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _watchList.length,
            itemBuilder: (_, i) {
              final item = _watchList[i];
              return ListTile(
                dense: true,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    'https://img.youtube.com/vi/${item.videoId}/default.jpg',
                    width: 56, height: 36, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 56, height: 36, color: td.surface2, child: const Icon(Icons.play_circle_outline, size: 20)),
                  ),
                ),
                title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: td.textOnSurface, fontWeight: FontWeight.w500)),
                onTap: () => _startVideo(item.videoId, title: item.title),
                trailing: Icon(Icons.play_arrow_rounded, color: td.primary, size: 20),
              );
            },
          ))
        else
          Expanded(child: Center(child: Text(
            'Your watch list is empty\nPaste a YouTube link to start',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: td.textOnSurface.withValues(alpha: 0.35), height: 1.5),
          ))),
      ]),
    );
  }
}

// ─── Reaction Overlay ─────────────────────────────────────────────────────────

class _Reaction { final String emoji, fromUid; const _Reaction({required this.emoji, required this.fromUid}); }

class _ReactionsOverlay extends StatelessWidget {
  final List<_Reaction> reactions;
  const _ReactionsOverlay({required this.reactions});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: reactions.asMap().entries.map((e) {
        final i = e.key;
        final r = e.value;
        final left = (0.1 + (i * 0.2) % 0.7) * MediaQuery.of(context).size.width;
        return Positioned(
          bottom: 20 + i * 30.0,
          left: left,
          child: Text(r.emoji, style: const TextStyle(fontSize: 32)),
        );
      }).toList(),
    );
  }
}

// ─── Watch Item ───────────────────────────────────────────────────────────────

class _WatchItem {
  final String id, videoId, title, addedBy;
  const _WatchItem({required this.id, required this.videoId, required this.title, required this.addedBy});
}

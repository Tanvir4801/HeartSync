import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/firestore_service.dart';
import '../sync_session_controller.dart';
import '../models/radio_track_model.dart';

// ─── Radio Room Screen ────────────────────────────────────────────────────────
// Phase Z-1 — Couple Radio
// Self-contained: no third-party APIs. Both partners upload songs they own;
// the SyncSessionController keeps playback position in sync.

class RadioRoomScreen extends StatefulWidget {
  final String coupleId;
  const RadioRoomScreen({super.key, required this.coupleId});
  @override State<RadioRoomScreen> createState() => _RadioRoomScreenState();
}

class _RadioRoomScreenState extends State<RadioRoomScreen> with TickerProviderStateMixin {
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _player = AudioPlayer();
  late final SyncSessionController _sync;
  late final AnimationController _discCtrl;
  late final AnimationController _pulseCtrl;

  // Tracks queue
  List<RadioTrack> _tracks = [];
  int _currentIndex = 0;
  StreamSubscription? _tracksSub;

  // Player state
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _uploading = false;
  Timer? _positionSyncTimer;

  // Partner info
  String _partnerName = '♡';
  String _partnerInitial = '♡';

  @override
  void initState() {
    super.initState();
    _sync = SyncSessionController(coupleId: widget.coupleId, myUid: _uid);
    _discCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);

    _sync.addListener(_onSyncChanged);
    _sync.listen();
    _loadTracks();
    _loadPartner();
    _wirePlayer();
  }

  Future<void> _loadPartner() async {
    try {
      final doc = await FirestoreService().coupleDoc(widget.coupleId).get();
      final data = doc.data() as Map<String, dynamic>?;
      final emails = List<String>.from(data?['memberEmails'] ?? []);
      final myEmail = FirebaseAuth.instance.currentUser?.email ?? '';
      final pEmail = emails.firstWhere((e) => e != myEmail, orElse: () => '');
      if (pEmail.isNotEmpty && mounted) {
        final name = pEmail.split('@')[0].split(RegExp(r'[._]'))
            .map((s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '')
            .join(' ');
        setState(() { _partnerName = name; _partnerInitial = name.isNotEmpty ? name[0].toUpperCase() : '♡'; });
      }
    } catch (e) { debugPrint('[RadioRoom] loadPartner: $e'); }
  }

  void _loadTracks() {
    _tracksSub = FirestoreService()
        .sub(widget.coupleId, 'radioTracks')
        .orderBy('createdAt')
        .snapshots()
        .listen((snap) {
          if (!mounted) return;
          setState(() => _tracks = snap.docs.map(RadioTrack.fromDoc).toList());
        });
  }

  void _wirePlayer() {
    _player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      setState(() => _isPlaying = s == PlayerState.playing);
      if (!_isPlaying) _discCtrl.stop();
      else _discCtrl.repeat();
    });
    _player.onPositionChanged.listen((pos) {
      if (!mounted) return;
      setState(() => _position = pos);
      // Conductor writes position every 5s — tracked via a periodic timer
    });
    _player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _duration = d);
    });
    _player.onPlayerComplete.listen((_) { if (mounted) _skipNext(); });

    // Conductor: write position every 5s (retained for proper disposal)
    _positionSyncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      if (_sync.isConductor && _isPlaying) {
        _sync.updatePosition(_position.inMilliseconds);
      }
    });
  }

  // Called whenever syncSession doc changes
  void _onSyncChanged() {
    if (!mounted) return;
    final s = _sync.session;
    if (s == null || !s.isActive) return;
    if (_sync.isConductor) return; // conductor drives their own player

    // Listener: sync content
    final trackId = s.contentId;
    final idx = _tracks.indexWhere((t) => t.id == trackId);
    if (idx != -1 && idx != _currentIndex) {
      setState(() => _currentIndex = idx);
      _player.setSourceUrl(_tracks[idx].storageUrl).then((_) {
        if (s.state == SyncState.playing) _player.resume();
      });
    }

    // Sync state
    if (s.state == SyncState.playing && !_isPlaying) {
      _player.resume();
    } else if (s.state == SyncState.paused && _isPlaying) {
      _player.pause();
    }

    // Drift check
    if (_sync.needsSeek(_position.inMilliseconds)) {
      _player.seek(Duration(milliseconds: s.positionMs));
    }
  }

  // ── Conductor controls ────────────────────────────────────────────────────

  Future<void> _play(RadioTrack track) async {
    if (!_sync.isConductor) {
      await _sync.claimConductor();
    }
    final idx = _tracks.indexOf(track);
    setState(() => _currentIndex = idx);
    await _player.setSourceUrl(track.storageUrl);
    await _player.resume();
    await _sync.startSession(SyncType.radio, track.id);
    await _sync.play(positionMs: 0);
  }

  Future<void> _togglePlayPause() async {
    if (!_sync.isConductor) {
      await _sync.claimConductor();
    }
    if (_isPlaying) {
      await _player.pause();
      await _sync.pause(positionMs: _position.inMilliseconds);
    } else {
      await _player.resume();
      await _sync.play(positionMs: _position.inMilliseconds);
    }
  }

  Future<void> _skipNext() async {
    if (_tracks.isEmpty) return;
    final next = (_currentIndex + 1) % _tracks.length;
    await _play(_tracks[next]);
  }

  Future<void> _skipPrev() async {
    if (_tracks.isEmpty) return;
    final prev = (_currentIndex - 1 + _tracks.length) % _tracks.length;
    await _play(_tracks[prev]);
  }

  // ── Upload audio track ────────────────────────────────────────────────────

  Future<void> _uploadTrack() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _uploading = true);
    try {
      final id = '${_uid}_${DateTime.now().millisecondsSinceEpoch}';
      final ref = FirebaseStorage.instance
          .ref()
          .child('couples/${widget.coupleId}/radio/$id.${file.extension ?? 'mp3'}');
      await ref.putData(file.bytes!);
      final url = await ref.getDownloadURL();

      // Parse title from filename
      final rawName = (file.name).replaceAll(RegExp(r'\.\w+$'), '');
      final parts = rawName.split(RegExp(r'[\s\-_]+')).where((s) => s.isNotEmpty).toList();
      final title = parts.isNotEmpty ? parts.join(' ') : 'Untitled';

      final track = RadioTrack(
        id: '', title: title, artistName: '♡',
        uploadedBy: _uid, storageUrl: url, durationMs: 0,
        createdAt: DateTime.now(),
      );
      await FirestoreService().sub(widget.coupleId, 'radioTracks').add(track.toMap());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Song added to your radio ♡'),
          backgroundColor: Color(0xFFE05C7E),
        ));
      }
    } catch (e) {
      debugPrint('[RadioRoom] upload error: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  void dispose() {
    _tracksSub?.cancel();
    _positionSyncTimer?.cancel();
    _sync.removeListener(_onSyncChanged);
    _sync.endSession();
    _sync.dispose();
    _player.dispose();
    _discCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final td = context.watch<ThemeProvider>().data;
    final track = _tracks.isNotEmpty ? _tracks[_currentIndex] : null;
    final myInitial = (FirebaseAuth.instance.currentUser?.email ?? 'Y')[0].toUpperCase();

    return Scaffold(
      backgroundColor: td.background,
      appBar: AppBar(
        backgroundColor: td.background,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Couple Radio 📻', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: td.textOnSurface)),
          Text('Your private station', style: TextStyle(fontSize: 11, color: td.textOnSurface.withValues(alpha: 0.5))),
        ]),
        actions: [
          if (_uploading)
            const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE05C7E))))
          else
            IconButton(
              icon: const Icon(Icons.add_rounded),
              color: td.primary,
              tooltip: 'Add a song',
              onPressed: _uploadTrack,
            ),
        ],
      ),
      body: Column(children: [
        // ── Player area ───────────────────────────────────────────────────
        Expanded(child: _tracks.isEmpty
          ? _EmptyRadio(onAdd: _uploadTrack, td: td)
          : Column(children: [
              const SizedBox(height: 24),
              // Partner avatars
              _AvatarRow(myInitial: myInitial, partnerInitial: _partnerInitial, td: td, pulseCtrl: _pulseCtrl),
              const SizedBox(height: 32),
              // Spinning disc
              _SpinningDisc(ctrl: _discCtrl, isPlaying: _isPlaying, track: track, td: td),
              const SizedBox(height: 24),
              // Track title
              if (track != null) ...[
                Text(track.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: td.textOnSurface), textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(track.artistName.isEmpty ? '♡' : track.artistName, style: TextStyle(fontSize: 13, color: td.textOnSurface.withValues(alpha: 0.5))),
              ],
              const SizedBox(height: 20),
              // Conductor badge
              if (_sync.isConductor)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: td.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: td.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text('You are DJ 🎧', style: TextStyle(fontSize: 11, color: td.primary, fontWeight: FontWeight.w600)),
                )
              else if (_sync.session?.isActive == true)
                Text('Following ${_partnerName}\'s playlist ♡', style: TextStyle(fontSize: 11, color: td.textOnSurface.withValues(alpha: 0.4))),
              const SizedBox(height: 24),
              // Progress bar
              if (_duration.inMilliseconds > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _position.inMilliseconds / _duration.inMilliseconds,
                        backgroundColor: td.border,
                        valueColor: AlwaysStoppedAnimation(td.primary),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(_formatDuration(_position), style: TextStyle(fontSize: 10, color: td.textOnSurface.withValues(alpha: 0.4))),
                      Text(_formatDuration(_duration), style: TextStyle(fontSize: 10, color: td.textOnSurface.withValues(alpha: 0.4))),
                    ]),
                  ]),
                ),
              const SizedBox(height: 24),
              // Controls
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _CtrlButton(icon: Icons.skip_previous_rounded, size: 32, color: td.textOnSurface.withValues(alpha: 0.6), onTap: _skipPrev),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: track != null ? () {
                    if (!_isPlaying && _sync.session == null) _play(track);
                    else _togglePlayPause();
                  } : null,
                  child: Container(
                    width: 68, height: 68,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [td.primary, td.secondary]),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: td.primary.withValues(alpha: 0.4), blurRadius: 20)],
                    ),
                    child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 36),
                  ),
                ),
                const SizedBox(width: 24),
                _CtrlButton(icon: Icons.skip_next_rounded, size: 32, color: td.textOnSurface.withValues(alpha: 0.6), onTap: _skipNext),
              ]),
            ]),
        ),
        // ── Track queue ───────────────────────────────────────────────────
        if (_tracks.isNotEmpty)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: td.surface,
              border: Border(top: BorderSide(color: td.border)),
            ),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Queue', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: td.textOnSurface.withValues(alpha: 0.5))),
                  Text('${_tracks.length} songs', style: TextStyle(fontSize: 11, color: td.textOnSurface.withValues(alpha: 0.4))),
                ]),
              ),
              Expanded(child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _tracks.length,
                itemBuilder: (_, i) {
                  final t = _tracks[i];
                  final isCurrent = i == _currentIndex && _sync.session?.isActive == true;
                  return ListTile(
                    dense: true,
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: isCurrent ? td.primary : td.surface2,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isCurrent && _isPlaying ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
                        color: isCurrent ? Colors.white : td.textOnSurface.withValues(alpha: 0.4),
                        size: 18,
                      ),
                    ),
                    title: Text(t.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isCurrent ? td.primary : td.textOnSurface)),
                    subtitle: t.artistName.isNotEmpty ? Text(t.artistName, style: TextStyle(fontSize: 11, color: td.textOnSurface.withValues(alpha: 0.4))) : null,
                    onTap: () => _play(t),
                  );
                },
              )),
            ]),
          ),
      ]),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

// ─── Partner Avatars ──────────────────────────────────────────────────────────

class _AvatarRow extends StatelessWidget {
  final String myInitial, partnerInitial;
  final HeartSyncThemeData td;
  final AnimationController pulseCtrl;
  const _AvatarRow({required this.myInitial, required this.partnerInitial, required this.td, required this.pulseCtrl});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _Avatar(initial: myInitial, color: td.primary),
      const SizedBox(width: 12),
      AnimatedBuilder(
        animation: pulseCtrl,
        builder: (_, __) => Container(
          width: 10 + pulseCtrl.value * 4, height: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [td.primary, td.secondary]),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
      const Text('  ♫  ', style: TextStyle(fontSize: 14, color: Color(0xFFE05C7E))),
      AnimatedBuilder(
        animation: pulseCtrl,
        builder: (_, __) => Container(
          width: 10 + pulseCtrl.value * 4, height: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [td.secondary, td.primary]),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
      const SizedBox(width: 12),
      _Avatar(initial: partnerInitial, color: td.secondary),
    ]);
  }
}

class _Avatar extends StatelessWidget {
  final String initial;
  final Color color;
  const _Avatar({required this.initial, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: 44, height: 44,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      shape: BoxShape.circle,
      border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
    ),
    child: Center(child: Text(initial, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18))),
  );
}

// ─── Spinning Vinyl Disc ──────────────────────────────────────────────────────

class _SpinningDisc extends StatelessWidget {
  final AnimationController ctrl;
  final bool isPlaying;
  final RadioTrack? track;
  final HeartSyncThemeData td;
  const _SpinningDisc({required this.ctrl, required this.isPlaying, required this.track, required this.td});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) => Transform.rotate(
        angle: isPlaying ? ctrl.value * 2 * math.pi : 0,
        child: Container(
          width: 160, height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: td.surface,
            border: Border.all(color: td.primary.withValues(alpha: 0.3), width: 3),
            boxShadow: [BoxShadow(color: td.primary.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 5)],
          ),
          child: CustomPaint(painter: _DiscPainter(td.primary, td.secondary)),
        ),
      ),
    );
  }
}

class _DiscPainter extends CustomPainter {
  final Color primary, secondary;
  _DiscPainter(this.primary, this.secondary);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final c = Offset(cx, cy);

    // Grooves
    for (int i = 3; i <= 7; i++) {
      canvas.drawCircle(c, cx * i / 8, Paint()
        ..color = primary.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
    }
    // Label circle
    canvas.drawCircle(c, cx * 0.28, Paint()
      ..shader = RadialGradient(colors: [primary, secondary]).createShader(Rect.fromCircle(center: c, radius: cx * 0.28)));
    // Center hole
    canvas.drawCircle(c, 6, Paint()..color = primary.withValues(alpha: 0.8));
    // Music note
    const style = TextStyle(fontSize: 20, color: Colors.white);
    final tp = TextPainter(text: const TextSpan(text: '♪', style: style), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override bool shouldRepaint(_DiscPainter old) => false;
}

// ─── Control Button ───────────────────────────────────────────────────────────

class _CtrlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback onTap;
  const _CtrlButton({required this.icon, required this.size, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Icon(icon, size: size, color: color),
  );
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyRadio extends StatelessWidget {
  final VoidCallback onAdd;
  final HeartSyncThemeData td;
  const _EmptyRadio({required this.onAdd, required this.td});

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('📻', style: const TextStyle(fontSize: 64)),
        const SizedBox(height: 24),
        Text(
          'Add a song that reminds you of each other',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: td.textOnSurface, height: 1.4),
        ),
        const SizedBox(height: 10),
        Text(
          'Your private shared radio station — only the two of you can hear it.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: td.textOnSurface.withValues(alpha: 0.45), height: 1.5),
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [td.primary, td.secondary]),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: td.primary.withValues(alpha: 0.3), blurRadius: 16)],
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Add first song', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            ]),
          ),
        ),
      ]),
    ));
  }
}

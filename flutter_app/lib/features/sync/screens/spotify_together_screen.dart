import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme.dart';
import '../../../core/firestore_service.dart';
import '../sync_session_controller.dart';
import '../spotify_api.dart';

// ─── Spotify Together Screen ──────────────────────────────────────────────────
// Phase Z-2 — Full Spotify sync implementation
//
// Flow:
//   1. Both partners connect their Spotify accounts via OAuth
//   2. One becomes conductor (controls playback)
//   3. Conductor polls Spotify every 3s → writes SyncSession to Firestore
//   4. Listener reads SyncSession → syncs their Spotify if drift > 3s

class SpotifyTogetherScreen extends StatefulWidget {
  final String coupleId;
  const SpotifyTogetherScreen({super.key, required this.coupleId});
  @override State<SpotifyTogetherScreen> createState() => _SpotifyTogetherScreenState();
}

class _SpotifyTogetherScreenState extends State<SpotifyTogetherScreen> {
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  late final SyncSessionController _sync;

  // ── Spotify connection status ──────────────────────────────────────────────
  SpotifyStatus? _myStatus;
  SpotifyStatus? _partnerStatus;
  String _partnerUid = '';
  bool _loadingStatus = true;
  Timer? _statusPoller;

  // ── Playback state ─────────────────────────────────────────────────────────
  SpotifyTrack? _currentTrack;
  Timer? _conductorPollTimer;
  Timer? _listenerSyncTimer;
  bool _actionBusy = false;
  String? _errorMsg;

  // ── Partner info from couple doc ───────────────────────────────────────────
  StreamSubscription? _sessionSub;

  @override
  void initState() {
    super.initState();
    _sync = SyncSessionController(coupleId: widget.coupleId, myUid: _uid);
    _sync.addListener(_onSyncChanged);
    _sync.listen();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadPartnerUid();
    await _refreshStatuses();
    // After loading statuses, if both connected and we have a session, start loops
    if (_myStatus?.connected == true) _startConductorPoll();
    if (!_sync.isConductor) _startListenerSync();
  }

  Future<void> _loadPartnerUid() async {
    try {
      final doc = await FirestoreService().coupleDoc(widget.coupleId).get();
      final data = doc.data() as Map<String, dynamic>?;
      final members = List<String>.from(data?['memberIds'] ?? data?['members'] ?? []);
      setState(() => _partnerUid = members.firstWhere((m) => m != _uid, orElse: () => ''));
    } catch (e) { debugPrint('[Spotify] loadPartnerUid: $e'); }
  }

  Future<void> _refreshStatuses() async {
    setState(() => _loadingStatus = true);
    final myF = SpotifyApi.getStatus(_uid);
    final partnerF = _partnerUid.isNotEmpty ? SpotifyApi.getStatus(_partnerUid) : Future.value(null);
    final results = await Future.wait([myF, partnerF]);
    if (!mounted) return;
    setState(() {
      _myStatus = results[0];
      _partnerStatus = results[1];
      _loadingStatus = false;
    });
    // Poll status while waiting for partner to connect
    if (_myStatus?.connected == true && _partnerStatus?.connected != true) {
      _startStatusPolling();
    } else {
      _statusPoller?.cancel();
    }
  }

  void _startStatusPolling() {
    _statusPoller?.cancel();
    _statusPoller = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      // Always refresh BOTH statuses on each tick so we catch both sides
      final myF = SpotifyApi.getStatus(_uid);
      final partnerF = _partnerUid.isNotEmpty
          ? SpotifyApi.getStatus(_partnerUid)
          : Future.value(null as SpotifyStatus?);
      final results = await Future.wait([myF, partnerF]);
      if (!mounted) return;
      setState(() {
        _myStatus = results[0];
        _partnerStatus = results[1];
      });
      // Only stop polling once BOTH partners are connected
      if (_myStatus?.connected == true && _partnerStatus?.connected == true) {
        _statusPoller?.cancel();
        if (_sync.isConductor) _startConductorPoll();
        else _startListenerSync();
      }
    });
  }

  // ── Conductor loop: poll current track every 3s → write to SyncSession ────

  void _startConductorPoll() {
    _conductorPollTimer?.cancel();
    if (!_sync.isConductor) return;
    _conductorPollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted || !_sync.isConductor) return;
      final track = await SpotifyApi.getCurrentTrack(_uid);
      if (!mounted) return;
      setState(() => _currentTrack = track);
      if (track == null) return;

      // Write state to Firestore SyncSession so listener can sync
      if (track.trackUri != _sync.session?.contentId) {
        await _sync.startSession(SyncType.music, track.trackUri);
      }
      if (track.isPlaying) {
        await _sync.play(positionMs: track.positionMs);
      } else {
        await _sync.pause(positionMs: track.positionMs);
      }
      // Write track metadata to Firestore for listener UI
      await _writeTrackMetadata(track);
    });
  }

  // ── Listener loop: read SyncSession → sync Spotify if drift > 3s ──────────

  void _startListenerSync() {
    _listenerSyncTimer?.cancel();
    _listenerSyncTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted || _sync.isConductor || _partnerUid.isEmpty) return;
      final session = _sync.session;
      if (session == null || !session.isActive || session.type != SyncType.music) return;

      // Read track metadata (for UI)
      final meta = await _readTrackMetadata();
      if (!mounted) return;
      if (meta != null) setState(() => _currentTrack = meta);

      // Drift check
      if (_currentTrack == null) return;
      final localMs = _currentTrack!.positionMs;
      final remoteMs = session.positionMs;
      final drift = (localMs - remoteMs).abs();

      if (drift > 3000 || _currentTrack!.trackUri != session.contentId) {
        await SpotifyApi.syncToListener(
          listenerUid: _uid,
          trackUri: session.contentId,
          positionMs: remoteMs,
          isPlaying: session.state == SyncState.playing,
        );
      }
    });
  }

  void _onSyncChanged() {
    if (!mounted) return;
    final session = _sync.session;
    setState(() {});

    // If we just became conductor or listener, restart the loops
    if (_sync.isConductor) {
      _listenerSyncTimer?.cancel();
      _startConductorPoll();
    } else {
      _conductorPollTimer?.cancel();
      _startListenerSync();
    }
  }

  Future<void> _writeTrackMetadata(SpotifyTrack track) async {
    try {
      await FirebaseFirestore.instance
          .collection('couples').doc(widget.coupleId)
          .collection('syncSession').doc('trackMeta')
          .set({
            'trackUri': track.trackUri,
            'trackName': track.trackName,
            'artistName': track.artistName,
            'albumArtUrl': track.albumArtUrl,
            'positionMs': track.positionMs,
            'durationMs': track.durationMs,
            'isPlaying': track.isPlaying,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (_) {}
  }

  Future<SpotifyTrack?> _readTrackMetadata() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('couples').doc(widget.coupleId)
          .collection('syncSession').doc('trackMeta')
          .get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      return SpotifyTrack(
        trackUri: data['trackUri'] ?? '',
        trackId: '',
        trackName: data['trackName'] ?? 'Unknown',
        artistName: data['artistName'] ?? '',
        albumName: '',
        albumArtUrl: data['albumArtUrl'] ?? '',
        positionMs: (data['positionMs'] as num?)?.toInt() ?? 0,
        durationMs: (data['durationMs'] as num?)?.toInt() ?? 1,
        isPlaying: data['isPlaying'] as bool? ?? false,
      );
    } catch (_) { return null; }
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _connectSpotify() async {
    final url = SpotifyApi.authUrl(_uid, widget.coupleId);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      // Poll for connection after returning from browser
      _startStatusPolling();
    } else {
      setState(() => _errorMsg = 'Could not open browser. Try: $url');
    }
  }

  Future<void> _claimConductor() async {
    await _sync.claimConductor();
    _startConductorPoll();
  }

  Future<void> _disconnect() async {
    setState(() => _actionBusy = true);
    await SpotifyApi.disconnect(widget.coupleId);
    await _sync.endSession();
    setState(() { _myStatus = null; _currentTrack = null; _actionBusy = false; });
  }

  Future<void> _tapPlay() async {
    if (_actionBusy || !_sync.isConductor) return;
    setState(() { _actionBusy = true; _errorMsg = null; });
    bool ok;
    if (_currentTrack?.isPlaying == true) {
      ok = await SpotifyApi.pause();
    } else {
      ok = await SpotifyApi.play(trackUri: _currentTrack?.trackUri);
    }
    if (!ok && mounted) setState(() => _errorMsg = 'Spotify Premium required for playback control.');
    setState(() => _actionBusy = false);
  }

  @override
  void dispose() {
    _statusPoller?.cancel();
    _conductorPollTimer?.cancel();
    _listenerSyncTimer?.cancel();
    _sessionSub?.cancel();
    _sync.removeListener(_onSyncChanged);
    _sync.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final td = context.watch<ThemeProvider>().data;
    final bothConnected = _myStatus?.connected == true && _partnerStatus?.connected == true;

    return Scaffold(
      backgroundColor: td.background,
      appBar: AppBar(
        backgroundColor: td.background,
        title: Row(children: [
          const Text('🎧', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Spotify Together', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: td.textOnSurface)),
            Text(bothConnected ? 'Both connected ✓' : 'Connect Spotify to start', style: TextStyle(fontSize: 11, color: bothConnected ? const Color(0xFF1DB954) : td.textOnSurface.withValues(alpha: 0.45))),
          ]),
        ]),
        actions: [
          if (_myStatus?.connected == true)
            IconButton(
              icon: Icon(Icons.link_off, color: td.textOnSurface.withValues(alpha: 0.4), size: 20),
              tooltip: 'Disconnect Spotify',
              onPressed: _actionBusy ? null : _disconnect,
            ),
        ],
      ),
      body: _loadingStatus
          ? Center(child: CircularProgressIndicator(color: const Color(0xFF1DB954), strokeWidth: 2))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                // ── Connection cards ─────────────────────────────────────
                _ConnectionCards(
                  myStatus: _myStatus,
                  partnerStatus: _partnerStatus,
                  onConnectTap: _connectSpotify,
                  td: td,
                ),
                const SizedBox(height: 20),

                // ── Error banner ─────────────────────────────────────────
                if (_errorMsg != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      const Text('⚠️'),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_errorMsg!, style: const TextStyle(fontSize: 12, color: Colors.redAccent))),
                      IconButton(onPressed: () => setState(() => _errorMsg = null), icon: const Icon(Icons.close, size: 16, color: Colors.redAccent)),
                    ]),
                  ),

                // ── Player area ──────────────────────────────────────────
                if (bothConnected) ...[
                  _PlayerCard(
                    track: _currentTrack,
                    isConductor: _sync.isConductor,
                    isActionBusy: _actionBusy,
                    onPlayPause: _tapPlay,
                    onClaimConductor: _claimConductor,
                    td: td,
                  ),
                  const SizedBox(height: 16),
                  _SyncStatusCard(sync: _sync, td: td),
                  const SizedBox(height: 16),
                  _HowItWorksCard(td: td),
                ] else ...[
                  _WaitingCard(
                    myConnected: _myStatus?.connected == true,
                    partnerConnected: _partnerStatus?.connected == true,
                    td: td,
                  ),
                ],
                const SizedBox(height: 40),
              ]),
            ),
    );
  }
}

// ─── Connection Cards ─────────────────────────────────────────────────────────

class _ConnectionCards extends StatelessWidget {
  final SpotifyStatus? myStatus, partnerStatus;
  final VoidCallback onConnectTap;
  final HeartSyncThemeData td;

  const _ConnectionCards({
    required this.myStatus, required this.partnerStatus,
    required this.onConnectTap, required this.td,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _ConnCard(label: 'You', status: myStatus, onConnect: onConnectTap, td: td)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text('♥', style: TextStyle(fontSize: 18, color: td.primary.withValues(alpha: 0.5))),
      ),
      Expanded(child: _ConnCard(label: 'Partner', status: partnerStatus, onConnect: null, td: td)),
    ]);
  }
}

class _ConnCard extends StatelessWidget {
  final String label;
  final SpotifyStatus? status;
  final VoidCallback? onConnect;
  final HeartSyncThemeData td;
  const _ConnCard({required this.label, required this.status, required this.onConnect, required this.td});

  @override
  Widget build(BuildContext context) {
    final connected = status?.connected == true;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: connected ? const Color(0xFF1DB954).withValues(alpha: 0.08) : td.surface,
        borderRadius: BorderRadius.circular(td.cardRadius),
        border: Border.all(
          color: connected ? const Color(0xFF1DB954).withValues(alpha: 0.4) : td.border,
          width: connected ? 1.5 : 1,
        ),
      ),
      child: Column(children: [
        Text(label, style: TextStyle(fontSize: 11, color: td.textOnSurface.withValues(alpha: 0.45), fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: connected ? const Color(0xFF1DB954).withValues(alpha: 0.15) : td.surface2,
            shape: BoxShape.circle,
          ),
          child: Center(child: Text(
            connected ? '✓' : '♫',
            style: TextStyle(fontSize: 18, color: connected ? const Color(0xFF1DB954) : td.textOnSurface.withValues(alpha: 0.3)),
          )),
        ),
        const SizedBox(height: 8),
        if (connected)
          Text(
            status!.displayName.isNotEmpty ? status!.displayName : 'Connected',
            style: const TextStyle(fontSize: 11, color: Color(0xFF1DB954), fontWeight: FontWeight.w600),
            maxLines: 1, overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          )
        else if (onConnect != null)
          GestureDetector(
            onTap: onConnect,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1DB954),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Connect', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          )
        else
          Text('Waiting…', style: TextStyle(fontSize: 11, color: td.textOnSurface.withValues(alpha: 0.3))),
      ]),
    );
  }
}

// ─── Player Card ──────────────────────────────────────────────────────────────

class _PlayerCard extends StatelessWidget {
  final SpotifyTrack? track;
  final bool isConductor, isActionBusy;
  final VoidCallback onPlayPause, onClaimConductor;
  final HeartSyncThemeData td;

  const _PlayerCard({
    required this.track, required this.isConductor,
    required this.isActionBusy, required this.onPlayPause,
    required this.onClaimConductor, required this.td,
  });

  @override
  Widget build(BuildContext context) {
    if (track == null) return _NoTrackCard(isConductor: isConductor, td: td);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1DB954).withValues(alpha: 0.08), td.surface],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(td.cardRadius),
        border: Border.all(color: const Color(0xFF1DB954).withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Album art + info
        Row(children: [
          // Album art
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: track!.albumArtUrl.isNotEmpty
                ? Image.network(track!.albumArtUrl, width: 64, height: 64, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _AlbumArtPlaceholder(td: td))
                : _AlbumArtPlaceholder(td: td),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(track!.trackName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: td.textOnSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(track!.artistName, style: TextStyle(fontSize: 12, color: td.textOnSurface.withValues(alpha: 0.55)), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(track!.albumName, style: TextStyle(fontSize: 11, color: td.textOnSurface.withValues(alpha: 0.35)), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          // Spotify logo
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text('🎧', style: TextStyle(fontSize: 22, color: const Color(0xFF1DB954).withValues(alpha: 0.7))),
          ),
        ]),
        const SizedBox(height: 16),

        // Progress bar
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: track!.progress.clamp(0.0, 1.0),
              backgroundColor: td.border,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF1DB954)),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(track!.formattedPosition, style: TextStyle(fontSize: 10, color: td.textOnSurface.withValues(alpha: 0.4))),
            Text(track!.formattedDuration, style: TextStyle(fontSize: 10, color: td.textOnSurface.withValues(alpha: 0.4))),
          ]),
        ]),

        // Controls (conductor only)
        if (isConductor) ...[
          const SizedBox(height: 14),
          Center(child: GestureDetector(
            onTap: isActionBusy ? null : onPlayPause,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: isActionBusy ? const Color(0xFF1DB954).withValues(alpha: 0.4) : const Color(0xFF1DB954),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFF1DB954).withValues(alpha: 0.3), blurRadius: 16)],
              ),
              child: isActionBusy
                  ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                  : Icon(
                      track!.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white, size: 28,
                    ),
            ),
          )),
        ] else ...[
          // Listener view: show sync status and "take control" option
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: td.surface2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              _PulseDot(color: const Color(0xFF1DB954)),
              const SizedBox(width: 8),
              Expanded(child: Text('Partner is controlling the music', style: TextStyle(fontSize: 12, color: td.textOnSurface.withValues(alpha: 0.55)))),
              GestureDetector(
                onTap: onClaimConductor,
                child: Text('Take control', style: TextStyle(fontSize: 11, color: const Color(0xFF1DB954), fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _AlbumArtPlaceholder extends StatelessWidget {
  final HeartSyncThemeData td;
  const _AlbumArtPlaceholder({required this.td});
  @override
  Widget build(BuildContext context) => Container(
    width: 64, height: 64,
    decoration: BoxDecoration(color: td.surface2, borderRadius: BorderRadius.circular(10)),
    child: const Center(child: Text('♫', style: TextStyle(fontSize: 28, color: Color(0xFF1DB954)))),
  );
}

class _NoTrackCard extends StatelessWidget {
  final bool isConductor;
  final HeartSyncThemeData td;
  const _NoTrackCard({required this.isConductor, required this.td});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: td.surface,
      borderRadius: BorderRadius.circular(td.cardRadius),
      border: Border.all(color: td.border),
    ),
    child: Column(children: [
      Text('♫', style: TextStyle(fontSize: 40, color: td.textOnSurface.withValues(alpha: 0.2))),
      const SizedBox(height: 12),
      Text(
        isConductor ? 'Play anything on Spotify to start syncing' : 'Waiting for partner to start playing…',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: td.textOnSurface.withValues(alpha: 0.45), height: 1.5),
      ),
    ]),
  );
}

// ─── Sync Status Card ─────────────────────────────────────────────────────────

class _SyncStatusCard extends StatelessWidget {
  final SyncSessionController sync;
  final HeartSyncThemeData td;
  const _SyncStatusCard({required this.sync, required this.td});

  @override
  Widget build(BuildContext context) {
    final session = sync.session;
    final active = session?.isActive == true && session?.type == SyncType.music;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: td.surface,
        borderRadius: BorderRadius.circular(td.cardRadius),
        border: Border.all(color: td.border),
      ),
      child: Row(children: [
        _PulseDot(color: active ? const Color(0xFF1DB954) : td.textOnSurface.withValues(alpha: 0.2)),
        const SizedBox(width: 10),
        Expanded(child: Text(
          active
              ? sync.isConductor ? 'You\'re conducting — partner is synced to you' : 'Syncing to partner\'s Spotify'
              : 'No active session',
          style: TextStyle(fontSize: 12, color: td.textOnSurface.withValues(alpha: 0.55)),
        )),
      ]),
    );
  }
}

// ─── Pulsing Dot ──────────────────────────────────────────────────────────────

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});
  @override State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Container(
      width: 8, height: 8,
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.4 + _c.value * 0.6),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.3), blurRadius: 4 + _c.value * 4)],
      ),
    ),
  );
}

// ─── Waiting Card ─────────────────────────────────────────────────────────────

class _WaitingCard extends StatelessWidget {
  final bool myConnected, partnerConnected;
  final HeartSyncThemeData td;
  const _WaitingCard({required this.myConnected, required this.partnerConnected, required this.td});

  @override
  Widget build(BuildContext context) {
    final String msg;
    if (!myConnected) {
      msg = 'Connect your Spotify account above to get started.\n\nBoth partners need to connect — it only takes a few seconds.';
    } else if (!partnerConnected) {
      msg = '✓ You\'re connected!\n\nWaiting for your partner to connect their Spotify. They\'ll see a "Connect" button when they open this screen.';
    } else {
      msg = 'Both connected! Start playing any song on Spotify and it will appear here.';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: td.surface,
        borderRadius: BorderRadius.circular(td.cardRadius),
        border: Border.all(color: td.border),
      ),
      child: Column(children: [
        Text('🎧', style: TextStyle(fontSize: 36, color: const Color(0xFF1DB954).withValues(alpha: 0.6))),
        const SizedBox(height: 12),
        Text(msg,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: td.textOnSurface.withValues(alpha: 0.5), height: 1.6),
        ),
      ]),
    );
  }
}

// ─── How it Works Card ────────────────────────────────────────────────────────

class _HowItWorksCard extends StatelessWidget {
  final HeartSyncThemeData td;
  const _HowItWorksCard({required this.td});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: td.surface,
      borderRadius: BorderRadius.circular(td.cardRadius),
      border: Border.all(color: td.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('How Spotify Together works', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: td.textOnSurface.withValues(alpha: 0.4))),
      const SizedBox(height: 8),
      Text(
        '• Both partners need a Spotify account (Premium required for playback control)\n'
        '• The conductor controls play, pause, and track — partner syncs automatically\n'
        '• HeartSync syncs position within 3 seconds — no matter the distance\n'
        '• Tap "Take control" to become the conductor at any time',
        style: TextStyle(fontSize: 12, color: td.textOnSurface.withValues(alpha: 0.4), height: 1.55),
      ),
    ]),
  );
}

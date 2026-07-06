import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ─── Sync Session Types & States ──────────────────────────────────────────────

enum SyncType { music, youtube, radio }
enum SyncState { idle, playing, paused, ended }

// ─── SyncSession Model ────────────────────────────────────────────────────────

class SyncSession {
  final SyncType type;
  final String contentId;
  final SyncState state;
  final int positionMs;
  final String conductorId;
  final DateTime updatedAt;

  const SyncSession({
    required this.type,
    required this.contentId,
    required this.state,
    required this.positionMs,
    required this.conductorId,
    required this.updatedAt,
  });

  factory SyncSession.fromMap(Map<String, dynamic> d) {
    return SyncSession(
      type: SyncType.values.firstWhere(
        (e) => e.name == (d['type'] ?? 'radio'),
        orElse: () => SyncType.radio,
      ),
      contentId: d['contentId'] ?? '',
      state: SyncState.values.firstWhere(
        (e) => e.name == (d['state'] ?? 'idle'),
        orElse: () => SyncState.idle,
      ),
      positionMs: (d['positionMs'] as num?)?.toInt() ?? 0,
      conductorId: d['conductorId'] ?? '',
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'contentId': contentId,
    'state': state.name,
    'positionMs': positionMs,
    'conductorId': conductorId,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  bool get isActive => state == SyncState.playing || state == SyncState.paused;

  SyncSession copyWith({
    SyncType? type,
    String? contentId,
    SyncState? state,
    int? positionMs,
    String? conductorId,
  }) => SyncSession(
    type: type ?? this.type,
    contentId: contentId ?? this.contentId,
    state: state ?? this.state,
    positionMs: positionMs ?? this.positionMs,
    conductorId: conductorId ?? this.conductorId,
    updatedAt: DateTime.now(),
  );
}

// ─── SyncSessionController ────────────────────────────────────────────────────
// One controller per couple. Create it in the screen's initState, dispose in dispose().
// The conductor writes; the listener reads and syncs locally.
//
// Usage:
//   _ctrl = SyncSessionController(coupleId: '...', myUid: '...');
//   await _ctrl.listen();                        // start streaming
//   await _ctrl.startSession(SyncType.radio, id); // become conductor
//   _ctrl.updatePosition(ms);                    // call every 5s from conductor
//   await _ctrl.endSession();                    // clean up on screen exit

class SyncSessionController extends ChangeNotifier {
  final String coupleId;
  final String myUid;

  SyncSession? _session;
  SyncSession? get session => _session;

  bool get isConductor => _session?.conductorId == myUid;
  bool get isIdle => _session == null || _session!.state == SyncState.idle;
  bool get isPlaying => _session?.state == SyncState.playing;

  StreamSubscription<DocumentSnapshot>? _sub;
  Timer? _positionTimer;

  SyncSessionController({required this.coupleId, required this.myUid});

  DocumentReference get _doc =>
      FirebaseFirestore.instance.collection('couples').doc(coupleId).collection('syncSession').doc('active');

  // ── Start listening to changes ────────────────────────────────────────────

  void listen() {
    _sub?.cancel();
    _sub = _doc.snapshots().listen((snap) {
      if (!snap.exists) {
        if (_session != null) {
          _session = null;
          notifyListeners();
        }
        return;
      }
      final data = snap.data() as Map<String, dynamic>?;
      if (data == null) return;
      final prev = _session;
      _session = SyncSession.fromMap(data);
      // Only notify if something meaningful changed
      if (prev?.state != _session!.state ||
          prev?.contentId != _session!.contentId ||
          prev?.conductorId != _session!.conductorId ||
          (prev?.positionMs != _session!.positionMs && !isConductor)) {
        notifyListeners();
      }
    }, onError: (e) => debugPrint('[SyncSessionController] stream error: $e'));
  }

  // ── Start a new session (caller becomes conductor) ────────────────────────
  // Optimistically updates local _session before Firestore snapshot arrives,
  // so subsequent play/pause calls work without waiting for propagation.

  Future<void> startSession(SyncType type, String contentId) async {
    final s = SyncSession(
      type: type,
      contentId: contentId,
      state: SyncState.idle,
      positionMs: 0,
      conductorId: myUid,
      updatedAt: DateTime.now(),
    );
    // Optimistic local update — ensures isConductor == true immediately
    _session = s;
    notifyListeners();
    try {
      await _doc.set(s.toMap());
    } catch (e) { debugPrint('[SyncSessionController] startSession error: $e'); }
  }

  // ── Claim conductor role ──────────────────────────────────────────────────

  Future<void> claimConductor() async {
    // Optimistic local update
    if (_session != null) {
      _session = _session!.copyWith(conductorId: myUid);
      notifyListeners();
    }
    try {
      await _doc.update({'conductorId': myUid, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) { debugPrint('[SyncSessionController] claimConductor error: $e'); }
  }

  // ── Play ──────────────────────────────────────────────────────────────────

  Future<void> play({int? positionMs}) async {
    if (!isConductor) return;
    // Optimistic local update
    _session = _session?.copyWith(state: SyncState.playing, positionMs: positionMs ?? _session!.positionMs);
    notifyListeners();
    try {
      await _doc.update({
        'state': SyncState.playing.name,
        if (positionMs != null) 'positionMs': positionMs,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) { debugPrint('[SyncSessionController] play error: $e'); }
  }

  // ── Pause ─────────────────────────────────────────────────────────────────

  Future<void> pause({int? positionMs}) async {
    if (!isConductor) return;
    // Optimistic local update
    _session = _session?.copyWith(state: SyncState.paused, positionMs: positionMs ?? _session!.positionMs);
    notifyListeners();
    try {
      _positionTimer?.cancel();
      await _doc.update({
        'state': SyncState.paused.name,
        if (positionMs != null) 'positionMs': positionMs,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) { debugPrint('[SyncSessionController] pause error: $e'); }
  }

  // ── Seek ──────────────────────────────────────────────────────────────────

  Future<void> seek(int positionMs) async {
    if (!isConductor) return;
    try {
      await _doc.update({
        'positionMs': positionMs,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) { debugPrint('[SyncSessionController] seek error: $e'); }
  }

  // ── Update content (e.g. next track in radio) ─────────────────────────────

  Future<void> setContent(String contentId, {int positionMs = 0}) async {
    if (!isConductor) return;
    try {
      await _doc.update({
        'contentId': contentId,
        'positionMs': positionMs,
        'state': SyncState.playing.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) { debugPrint('[SyncSessionController] setContent error: $e'); }
  }

  // ── Update position (called every 5s by conductor while playing) ──────────

  Future<void> updatePosition(int positionMs) async {
    if (!isConductor) return;
    try {
      await _doc.update({'positionMs': positionMs, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) { debugPrint('[SyncSessionController] updatePosition error: $e'); }
  }

  // ── End session ───────────────────────────────────────────────────────────

  Future<void> endSession() async {
    _positionTimer?.cancel();
    try {
      await _doc.set({'state': SyncState.idle.name, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    } catch (e) { debugPrint('[SyncSessionController] endSession error: $e'); }
  }

  // ── Internal: periodic position write every 5s ────────────────────────────

  void _startPositionTimer() {
    _positionTimer?.cancel();
    // Caller must call updatePosition(currentMs) regularly; this timer is a reminder hook
    // Actual call is made by the conductor screen which knows the player's position
  }

  // ── Listener-side drift check ─────────────────────────────────────────────
  // Call with your local player's current position.
  // Returns true if you need to seek (drift > 3000ms).

  bool needsSeek(int localPositionMs) {
    if (_session == null || isConductor) return false;
    final drift = (_session!.positionMs - localPositionMs).abs();
    return drift > 3000;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _positionTimer?.cancel();
    super.dispose();
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../../core/api_client.dart';

/// Thin wrapper around the HeartSync server's Spotify endpoints.
/// Read-only endpoints (status, current-track) call the server directly.
/// All write endpoints (play, pause, seek, sync, disconnect) use api_client.dart
/// so Firebase ID-token auth is attached automatically — the server resolves
/// the UID from the token, never trusts a caller-supplied UID.
class SpotifyApi {
  SpotifyApi._();

  /// Server base URL — derived from the current page URL in web, localhost on native.
  static String get base {
    if (kIsWeb) {
      try {
        final uri = Uri.base;
        final host = uri.host.contains(':') ? uri.host.split(':').first : uri.host;
        return 'https://$host:3001';
      } catch (_) {}
    }
    return 'http://localhost:3001';
  }

  // ── OAuth ─────────────────────────────────────────────────────────────────

  /// URL the user opens in a browser to connect their Spotify account.
  static String authUrl(String uid, String coupleId) =>
      '$base/api/spotify/auth?uid=${Uri.encodeComponent(uid)}&coupleId=${Uri.encodeComponent(coupleId)}';

  // ── Unauthenticated read helpers (UID in path, no secret token needed) ────

  static Future<Map<String, dynamic>?> _readGet(String path) async {
    try {
      final res = await http.get(Uri.parse('$base$path'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  static Future<SpotifyStatus?> getStatus(String uid) async {
    final data = await _readGet('/api/spotify/status/$uid');
    if (data == null) return null;
    return SpotifyStatus(
      connected: data['connected'] == true,
      displayName: data['displayName'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String? ?? '',
    );
  }

  static Future<SpotifyTrack?> getCurrentTrack(String uid) async {
    final data = await _readGet('/api/spotify/current-track/$uid');
    if (data == null || data['playing'] != true) return null;
    return SpotifyTrack.fromMap(data);
  }

  // ── Authenticated write endpoints — UID comes from Firebase token on server ─

  static Future<bool> play({String? trackUri, int positionMs = 0}) async {
    final result = await backendPost('/api/spotify/play', {
      if (trackUri != null) 'trackUri': trackUri,
      'positionMs': positionMs,
    });
    return result['ok'] == true || result['error'] == null;
  }

  static Future<bool> pause() async {
    final result = await backendPut('/api/spotify/pause', {});
    return result['ok'] == true;
  }

  static Future<bool> seek(int positionMs) async {
    final result = await backendPut('/api/spotify/seek', {'positionMs': positionMs});
    return result['ok'] == true;
  }

  /// Conductor calls this to sync the listener. conductorUid is verified
  /// server-side from the Firebase token; only listenerUid + track info go in body.
  static Future<bool> syncToListener({
    required String listenerUid,
    required String trackUri,
    required int positionMs,
    required bool isPlaying,
  }) async {
    final result = await backendPost('/api/spotify/sync', {
      'listenerUid': listenerUid,
      'trackUri': trackUri,
      'positionMs': positionMs,
      'isPlaying': isPlaying,
    });
    return result['ok'] == true;
  }

  static Future<bool> disconnect(String coupleId) async {
    final result = await backendDelete('/api/spotify/disconnect?coupleId=${Uri.encodeComponent(coupleId)}');
    return result['ok'] == true;
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

class SpotifyStatus {
  final bool connected;
  final String displayName;
  final String avatarUrl;
  const SpotifyStatus({required this.connected, required this.displayName, required this.avatarUrl});
}

class SpotifyTrack {
  final String trackUri;
  final String trackId;
  final String trackName;
  final String artistName;
  final String albumName;
  final String albumArtUrl;
  final int positionMs;
  final int durationMs;
  final bool isPlaying;

  const SpotifyTrack({
    required this.trackUri, required this.trackId, required this.trackName,
    required this.artistName, required this.albumName, required this.albumArtUrl,
    required this.positionMs, required this.durationMs, required this.isPlaying,
  });

  factory SpotifyTrack.fromMap(Map<String, dynamic> d) => SpotifyTrack(
    trackUri: d['trackUri'] as String? ?? '',
    trackId: d['trackId'] as String? ?? '',
    trackName: d['trackName'] as String? ?? 'Unknown track',
    artistName: d['artistName'] as String? ?? '',
    albumName: d['albumName'] as String? ?? '',
    albumArtUrl: d['albumArtUrl'] as String? ?? '',
    positionMs: (d['positionMs'] as num?)?.toInt() ?? 0,
    durationMs: (d['durationMs'] as num?)?.toInt() ?? 1,
    isPlaying: d['playing'] as bool? ?? false,
  );

  double get progress => durationMs > 0 ? positionMs / durationMs : 0.0;
  String get formattedPosition => _fmt(positionMs);
  String get formattedDuration => _fmt(durationMs);
  static String _fmt(int ms) {
    final s = ms ~/ 1000; final m = s ~/ 60; final sec = s % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }
}

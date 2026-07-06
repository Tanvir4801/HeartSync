import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Thin wrapper around the HeartSync server's Spotify endpoints.
/// The server handles OAuth tokens, token refresh, and Spotify API calls.
class SpotifyApi {
  SpotifyApi._();

  /// Server base URL — derived from the current page URL in web, localhost on
  /// native. In Replit, the Flutter app (port 8080) and the API (port 3001)
  /// share the same hostname, so we just swap the port.
  static String get base {
    if (kIsWeb) {
      final uri = Uri.base;
      final host = uri.host.contains(':') ? uri.host.split(':').first : uri.host;
      return 'https://$host:3001';
    }
    return 'http://localhost:3001';
  }

  // ── OAuth ────────────────────────────────────────────────────────────────

  /// The URL the user must open in a browser to connect their Spotify account.
  static String authUrl(String uid, String coupleId) =>
      '$base/api/spotify/auth?uid=${Uri.encodeComponent(uid)}&coupleId=${Uri.encodeComponent(coupleId)}';

  // ── REST helpers ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> _get(String path) async {
    try {
      final res = await http.get(Uri.parse('$base$path'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
      return null;
    } catch (_) { return null; }
  }

  static Future<Map<String, dynamic>?> _post(String path, Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse('$base$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
      return null;
    } catch (_) { return null; }
  }

  static Future<Map<String, dynamic>?> _put(String path, Map<String, dynamic> body) async {
    try {
      final res = await http.put(
        Uri.parse('$base$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
      return null;
    } catch (_) { return null; }
  }

  // ── Public API ────────────────────────────────────────────────────────────

  static Future<SpotifyStatus?> getStatus(String uid) async {
    final data = await _get('/api/spotify/status/$uid');
    if (data == null) return null;
    return SpotifyStatus(
      connected: data['connected'] == true,
      displayName: data['displayName'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String? ?? '',
    );
  }

  static Future<SpotifyTrack?> getCurrentTrack(String uid) async {
    final data = await _get('/api/spotify/current-track/$uid');
    if (data == null || data['playing'] != true) return null;
    return SpotifyTrack.fromMap(data);
  }

  static Future<bool> play(String uid, {String? trackUri, int positionMs = 0}) async {
    final result = await _post('/api/spotify/play', {
      'uid': uid,
      if (trackUri != null) 'trackUri': trackUri,
      'positionMs': positionMs,
    });
    return result?['ok'] == true;
  }

  static Future<bool> pause(String uid) async {
    final result = await _put('/api/spotify/pause', {'uid': uid});
    return result?['ok'] == true;
  }

  static Future<bool> seek(String uid, int positionMs) async {
    final result = await _put('/api/spotify/seek', {'uid': uid, 'positionMs': positionMs});
    return result?['ok'] == true;
  }

  static Future<bool> syncToListener({
    required String conductorUid,
    required String listenerUid,
    required String trackUri,
    required int positionMs,
    required bool isPlaying,
  }) async {
    final result = await _post('/api/spotify/sync', {
      'conductorUid': conductorUid,
      'listenerUid': listenerUid,
      'trackUri': trackUri,
      'positionMs': positionMs,
      'isPlaying': isPlaying,
    });
    return result?['ok'] == true;
  }

  static Future<bool> disconnect(String uid, String coupleId) async {
    try {
      final res = await http.delete(
        Uri.parse('$base/api/spotify/disconnect/$uid?coupleId=${Uri.encodeComponent(coupleId)}'),
      ).timeout(const Duration(seconds: 6));
      return res.statusCode == 200;
    } catch (_) { return false; }
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
    required this.trackUri,
    required this.trackId,
    required this.trackName,
    required this.artistName,
    required this.albumName,
    required this.albumArtUrl,
    required this.positionMs,
    required this.durationMs,
    required this.isPlaying,
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

  String get formattedPosition => _formatMs(positionMs);
  String get formattedDuration => _formatMs(durationMs);

  static String _formatMs(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    final sec = s % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }
}

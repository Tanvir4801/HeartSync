import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';

// ─── Spotify Together Screen ──────────────────────────────────────────────────
// Phase Z-2 — Spotify Together
//
// Architecture (to be wired once Spotify OAuth is set up on the backend):
//
//  1. "Connect Spotify" button → Firebase Auth link with Spotify OAuth.
//     Tokens stored server-side in /users/{uid} (not readable by partner).
//
//  2. Backend routes needed (server/routes/spotify.js):
//     GET  /api/spotify/current-track?uid=   → current playing track
//     POST /api/spotify/sync                 → {conductorUid, listenerUid, action, positionMs}
//
//  3. Flutter polls /api/spotify/current-track every 5s (conductor only),
//     writes to couples/{id}/syncSession with type='music',
//     backend applies the same state to listener's Spotify account via their token.
//
//  4. Home screen shows "Listening Together" card when session is active.
//
// Until the backend routes are live this screen shows a clear setup guide.

class SpotifyTogetherScreen extends StatelessWidget {
  const SpotifyTogetherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final td = context.watch<ThemeProvider>().data;

    return Scaffold(
      backgroundColor: td.background,
      appBar: AppBar(
        backgroundColor: td.background,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Spotify Together 🎧', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: td.textOnSurface)),
          Text('Listen in perfect sync', style: TextStyle(fontSize: 11, color: td.textOnSurface.withValues(alpha: 0.45))),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF1DB954).withValues(alpha: 0.12), td.surface],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(td.cardRadius),
              border: Border.all(color: const Color(0xFF1DB954).withValues(alpha: 0.25)),
            ),
            child: Column(children: [
              const Text('🎵', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text(
                'Listen Together via Spotify',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: td.textOnSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Both partners connect their own Spotify accounts. HeartSync keeps your playback in sync — Spotify streams the music, we coordinate the timing.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: td.textOnSurface.withValues(alpha: 0.5), height: 1.5),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // How it works
          Text('How it works', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: td.textOnSurface)),
          const SizedBox(height: 12),
          ..._steps(td),
          const SizedBox(height: 24),

          // Setup required banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: td.surface,
              borderRadius: BorderRadius.circular(td.cardRadius),
              border: Border.all(color: td.border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('⚙️', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text('Backend setup needed', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: td.primary)),
              ]),
              const SizedBox(height: 8),
              Text(
                'To enable Spotify sync, the HeartSync server needs:\n'
                '• A Spotify Developer app at developer.spotify.com\n'
                '• SPOTIFY_CLIENT_ID and SPOTIFY_CLIENT_SECRET environment secrets\n'
                '• Routes: GET /api/spotify/current-track and POST /api/spotify/sync\n\n'
                'Once those are set up, the "Connect Spotify" button will appear here.',
                style: TextStyle(fontSize: 12, color: td.textOnSurface.withValues(alpha: 0.55), height: 1.6),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // What you need
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: td.surface,
              borderRadius: BorderRadius.circular(td.cardRadius),
              border: Border.all(color: td.border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('📋', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text('What you both need', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: td.textOnSurface)),
              ]),
              const SizedBox(height: 8),
              Text(
                '✓ Each partner needs their own Spotify account (free or premium)\n'
                '✓ Spotify Premium recommended for uninterrupted sync\n'
                '✓ Spotify app installed on each device\n\n'
                'HeartSync does not stream audio — it coordinates playback state between your two Spotify accounts so you hear the same moment of the same song.',
                style: TextStyle(fontSize: 12, color: td.textOnSurface.withValues(alpha: 0.55), height: 1.6),
              ),
            ]),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  List<Widget> _steps(HeartSyncThemeData td) {
    final steps = [
      ('1', '🔗', 'Connect Spotify', 'Both partners tap "Connect Spotify" and log in with their own Spotify account.'),
      ('2', '🎵', 'One partner plays a song', 'The "conductor" plays any track in their Spotify app.'),
      ('3', '⚡', 'HeartSync syncs instantly', 'Your backend detects what\'s playing and starts the same track on your partner\'s Spotify at the same moment.'),
      ('4', '💕', 'Listen together', 'Both partners hear the same song in sync — even across any distance.'),
    ];
    return steps.map((s) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: td.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: td.primary.withValues(alpha: 0.3)),
          ),
          child: Center(child: Text(s.$1, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: td.primary))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${s.$2}  ${s.$3}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: td.textOnSurface)),
          const SizedBox(height: 2),
          Text(s.$4, style: TextStyle(fontSize: 12, color: td.textOnSurface.withValues(alpha: 0.45), height: 1.4)),
        ])),
      ]),
    )).toList();
  }
}

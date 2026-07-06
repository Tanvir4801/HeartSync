---
name: Sync Zone architecture
description: How the Sync Zone feature (Phase Y/Z) is structured and key pitfalls
---

## SyncSessionController pattern
- `couples/{coupleId}/syncSession/active` is the single Firestore doc
- Only the conductor writes; listener reads via stream subscription
- **Critical**: `startSession()` and `claimConductor()` do optimistic local state updates so `isConductor` is true before Firestore snapshot propagates — otherwise `play()`/`pause()` no-ops
- Conductor writes position every 5s via retained `_positionSyncTimer` (must be canceled in dispose)
- Listener drift tolerance: 3000ms before seeking

## Package versions (installed)
- `audioplayers: ^6.0.0` — API: `AudioPlayer()`, `setSourceUrl()`, `resume/pause/seek()`, `onPlayerStateChanged`, `onPositionChanged`
- `youtube_player_iframe: 5.2.2` — API: `YoutubePlayerController.fromVideoId()`, `controller.stream` (not `onPlayerReady`), `PlayerState` enum (not `YoutubePlayerState`), `controller.currentTime` → `Future<double>`
- `file_picker: ^8.0.0` — for audio upload in Couple Radio

## Firestore data model
- `couples/{id}/syncSession/active` — type, contentId, state, positionMs, conductorId, updatedAt
- `couples/{id}/radioTracks/{id}` — title, artistName, uploadedBy, storageUrl, durationMs, createdAt
- `couples/{id}/watchList/{id}` — videoId, title, addedBy, addedAt
- `couples/{id}/watchReactions/{id}` — emoji, fromUid, sentAt (client-filtered after 5s, no server TTL yet)

## Feature locations
- SyncSessionController: `lib/features/sync/sync_session_controller.dart`
- Radio Room: `lib/features/sync/screens/radio_room_screen.dart`
- Watch Together: `lib/features/sync/screens/watch_together_screen.dart`
- Spotify Together: `lib/features/sync/screens/spotify_together_screen.dart` (UI only, needs backend)
- Sync Zone hub: `lib/features/sync/screens/sync_zone_screen.dart`
- Carousel entry: `home_screen.dart` FeatureCardCarousel, count=8, uses `td.accent` color

## Phase S (chat additions)
- Wishing Star: `_wishingStarVisible` bool, random Timer (15–135s), once per session; tap opens `_WishDialog`, saves as Note with openDate +24h
- Butterfly: `_butterflyFired` bool; checks `lower.contains('i love you') || lower.contains('i miss you')` in _send(); 3s animation via `_ButterflyOverlay` CustomPainter

## Phase R (already done at import)
- LoveSkyBackground has `isAnniversary` flag driving golden gradient + _AnniversaryParticles
- Chat has `_AnniversaryBanner` widget
- NEW: `_AnniversaryMemoryCard` above input bar shows earliest isFavorite memory on anniversary day

## What's NOT done (Phase Z-2 Spotify)
- Needs SPOTIFY_CLIENT_ID + SPOTIFY_CLIENT_SECRET env secrets
- Needs server/routes/spotify.js with /api/spotify/current-track and /api/spotify/sync
- Flutter UI placeholder is in spotify_together_screen.dart

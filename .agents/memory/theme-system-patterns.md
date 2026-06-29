---
name: Theme system patterns
description: Critical patterns for the HeartSync theme system — provider import, light/dark generation, sweetheart tokens, and new home screen features
---

## Provider import in theme.dart
`theme.dart` defines widgets (`ThemedCard`, `ShimmerBox`) that use `context.watch<ThemeProvider>()`. It **must** import `package:provider/provider.dart` — missing this import causes a compile error `The method 'watch' isn't defined for the class 'BuildContext'`.

**Why:** Dart requires explicit imports for extension methods; provider's `context.watch` is an extension on `BuildContext` defined in provider.dart.

## AppTheme.forThemeData() — light vs dark
`main.dart` calls `AppTheme.forThemeData(td)` to build the MaterialApp ThemeData. The method checks `td.isLight` and builds either `ColorScheme.light()` (Sweetheart) or `ColorScheme.dark()` (all others). Scaffolds, inputs, buttons, and card shapes all vary.

**Why:** Flutter's Material 3 light/dark brightness affects many default colors; can't just swap background colors without setting Brightness.

## Sweetheart token values
- background: `#F3EFFF`, surface: `#FFFBFE`, surface2: `#F0EBFF`, border: `#E2D9FF`
- primary: `#9B87F5` (Lavender Pop), secondary: `#FF9EB5` (Coral Blush), accent: `#FFD66B` (Sunshine)
- textOnSurface: `#4A3B6B` (Plum Ink) — replaces white for readability on light bg
- shimmerBase: `#E8E0FF`, shimmerHighlight: `#F3EFFF`
- cardRadius: 26 (vs 16 for dark themes)
- isLight: true

## LoveSky Sweetheart mode
When `td.isLight`, `LoveSkyBackground` calls `sweetheartSkyPhase()` instead of `currentSkyPhase()`. `sweetheartSkyPhase()` caps at `SkyPhase.evening` — night phase is never used with Sweetheart because the star field/constellation looks wrong on a pastel background. Particle colors for petals switch to `[#FF9EB5, #9B87F5, #FFD66B]`.

## Home Screen Architecture — new romance features
`home_screen.dart` has these sections in column order:
1. `_PresenceWriter` — invisible widget, pings `couples/{id}` with `presence.{uid}.lastSeen` every 3 min using SetOptions(merge:true)
2. `GreetingHeroCard(coupleId, uid)` — reads presence map from same couple doc stream, shows pulsing green dot if partner seen < 5 min
3. `StatCardRow` — 4 independent badges
4. `_HeartbeatSection` — virtual heartbeat tap; streams `couples/{id}/heartbeats`, sends heartbeat on tap, ripple animation on receive
5. `_DailySurprise` — daily message reveal
6. `_ClockRow` — dual timezone clock
7. `_MoodSection` — emoji picker, writes to `couples/{id}/moods`
8. `_DuoVibeSection` — streams today's moods from BOTH partners; shows combined vibe from `_vibeMap` lookup (17 combo entries); waits if partner hasn't picked
9. `_LoveJarSection` — shake jar for sweet message; loads `couples/{id}/lovejar` filtered by `toUid == uid`; "Drop Note" writes `{message, fromUid, toUid, addedAt}` to partner's jar
10. `_HugButtons`, `_QuickActions`, `FeatureCardCarousel`

## Firestore paths used by romance features
- `couples/{id}/heartbeats` — `{fromUid, sentAt, type:'heartbeat'}`
- `couples/{id}/lovejar` — `{message, fromUid, toUid, addedAt}`
- `couples/{id}/moods` — `{userId, mood, timestamp}` (already existed)
- `couples/{id}` main doc — `presence.{uid}.lastSeen` (Timestamp field merged in)

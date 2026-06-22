---
name: ThemeProvider wiring
description: How the ThemeProvider ChangeNotifier is wired into the HeartSync Flutter app
---

## Pattern
`ThemeProvider` is a `ChangeNotifier` defined in `lib/core/theme.dart`.

Wired in `main.dart`:
```dart
ChangeNotifierProvider(create: (_) => ThemeProvider(), child: const HeartSyncApp())
```

Used in `shell/main_shell.dart` and theme_picker_screen.dart via:
```dart
final themeData = context.watch<ThemeProvider>().data;
provider.setTheme(RomanticTheme.midnightBloom);
```

## Available themes (RomanticTheme enum)
- `horizon` — amber/rose (default)
- `midnightBloom` — rose/purple
- `goldenHour` — gold/orange
- `northernLights` — cyan/purple

## Why
Dynamic theme switching without restart. Each `HeartSyncThemeData` has: background, surface, surface2, border, primary, secondary, accent, gradient, heartColors.

## How to apply
When adding new screens that need theme-aware colors, use `context.watch<ThemeProvider>().data` and access `.primary`, `.secondary`, `.accent` etc. Don't hardcode `AppTheme.dawnAmber` in new screens — use the theme token instead.

---
name: IndexedStack screen caching
description: MainShell must cache Widget instances in initState, not recreate them in build() — fixes blank home screen on shell rebuild
---

## Rule
In `_MainShellState`, build each screen widget once in `initState()` and store in `late final List<Widget> _screens`. Use `_screens` in the `IndexedStack`. Never call `e.builder()` inside `build()`.

**Why:** Calling `_items.map((e) => e.builder()).toList()` inside `build()` creates fresh widget instances on every shell repaint (e.g. when ThemeProvider notifies listeners). Flutter reconciles the new instances against the old element tree, but animation controllers and StatefulWidget state inside those screens can get confused, and in debug-mode Flutter Web the mismatch causes the IndexedStack child to render blank.

**How to apply:** Any time you add screens to MainShell, append to `_items` in `initState` AND rebuild `_screens` (or just re-derive it after `_items` is set). Do not lazily evaluate builders in `build()`.

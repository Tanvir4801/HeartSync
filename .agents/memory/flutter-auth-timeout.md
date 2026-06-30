---
name: Flutter auth timeout
description: Firebase authStateChanges() hangs in Replit preview — _AuthGate needs a fallback timer
---

In the Replit web preview, `FirebaseAuth.instance.authStateChanges()` never emits a value — the stream stays in `ConnectionState.waiting` forever. This is because Firebase Auth requires a real network round-trip that the Replit sandboxed preview can't complete.

**Fix:** Convert `_AuthGate` from `StatelessWidget` to `StatefulWidget` and add a `Future.delayed(6 seconds)` in `initState` that sets `_timedOut = true`. In the `StreamBuilder` builder: if `waiting && !_timedOut`, show splash; otherwise treat as logged-out and show LoginScreen.

**Why:** Without the timeout the user sees the splash screen forever. With it, the Flutter app advances to the login screen after 6 seconds.

**How to apply:** Whenever `_AuthGate` is modified, preserve this `_timedOut` flag pattern. Do NOT convert back to StatelessWidget. The timeout also acts as a safe fallback in production if Firebase is slow.

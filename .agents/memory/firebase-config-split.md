---
name: Firebase config split
description: Two separate Firebase web app registrations for this project
---

Both the admin console and the Flutter app share Firebase project `heartsync-b4e9f`, but they are registered as different web apps.

**Admin console (React):**
- appId: `1:324450946196:web:cc0d6675befd6a712eb881`
- measurementId: `G-KELNLQ2YKY`
- Config lives in `VITE_FIREBASE_*` env vars → served via `/api/config`

**Flutter app:**
- appId: `1:324450946196:web:7b1bd408e54a58ea2eb881`
- measurementId: `G-MFX0PDLDLN`
- Config hardcoded in `flutter_app/lib/firebase_options.dart` (web + android + ios stubs)

**Why:** Each app registration has its own analytics stream and SDK credentials. The Flutter appId must match the one registered in Firebase console for that app type.

**How to apply:** Don't mix up the two appIds. The Flutter firebase_options.dart should always use `7b1bd4...`, not `cc0d66...`.

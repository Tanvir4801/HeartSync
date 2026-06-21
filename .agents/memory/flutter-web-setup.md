---
name: Flutter web setup
description: How Flutter is installed and run in this Replit project
---

Flutter 3.32.0 is installed via Nix (`installSystemDependencies({ packages: ["flutter"] })`).

The Flutter mobile app lives in `flutter_app/` inside the repo root. The admin console (React/Vite + Express) lives at the repo root.

**Ports:**
- Admin console (React/Vite): port 5000 (webview)
- Flutter web dev server: port 8080 (console workflow: "Run Flutter Web")

**Run command (Flutter web):**
```
cd flutter_app && flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0 --no-pub
```

**Why:** Port 5000 is reserved for the webview/admin console. Flutter web uses port 8080 as a console-type workflow.

**How to apply:** When adding a new Flutter workflow, always use port 8080 with outputType "console". Never use port 5000 for the Flutter app.

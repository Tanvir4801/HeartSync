---
name: Spotify sync architecture
description: How Spotify Together is wired — Flutter API client, server auth, polling logic
---

## Flutter → Server communication pattern
- **Read endpoints** (status, current-track): SpotifyApi._readGet() — raw HTTP, UID in path, no auth needed
- **Write endpoints** (play, pause, seek, sync, disconnect): use backendPost/backendPut/backendDelete from api_client.dart, which attaches Firebase ID token as Bearer header
- Server extracts UID from the verified token (req.user.uid) — never from request body, prevents IDOR

## Server route auth
- verifyToken: checks Authorization: Bearer <token>, sets req.user.uid. Mock mode: passes through.
- getCouple: resolves coupleId — tries 'members' field first, then 'memberIds' fallback
- Spotify sync requires verifyToken + getCouple; validates listenerUid is in the couple's member array

## Polling logic rule
- _startStatusPolling() must refresh BOTH user statuses each tick
- Stop only when BOTH are connected (not either) — otherwise stops prematurely when only one partner connects

## Firestore paths
- Active session: couples/{coupleId}/syncSession/active
- Track metadata for listener UI: couples/{coupleId}/syncSession/trackMeta

**Why:** Earlier impl trusted caller-supplied UIDs enabling IDOR; build-cache corruption caused Matrix4 cascade errors (fix: flutter clean + pub get).

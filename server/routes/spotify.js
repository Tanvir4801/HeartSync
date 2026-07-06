/**
 * Spotify integration routes for HeartSync
 *
 * Endpoints (no admin auth — these are user-facing via Firebase UID):
 *   GET  /api/spotify/auth?uid=&coupleId=       → redirect to Spotify OAuth
 *   GET  /api/spotify/callback                  → handle OAuth callback
 *   GET  /api/spotify/status/:uid               → check connection status
 *   GET  /api/spotify/current-track/:uid        → get currently playing track
 *   POST /api/spotify/play                      → play (or seek + resume) a track
 *   PUT  /api/spotify/pause                     → pause
 *   PUT  /api/spotify/seek                      → seek to position
 *   POST /api/spotify/sync                      → sync listener to conductor state
 *   DELETE /api/spotify/disconnect/:uid         → remove stored tokens
 */

const express = require('express');
const router = express.Router();
const { getFirestore } = require('../firebase');

// ── Env ────────────────────────────────────────────────────────────────────────
const CLIENT_ID = process.env.SPOTIFY_CLIENT_ID;
const CLIENT_SECRET = process.env.SPOTIFY_CLIENT_SECRET;

function getRedirectUri() {
  const domain = process.env.REPLIT_DEV_DOMAIN;
  if (domain) return `https://${domain}/api/spotify/callback`;
  return process.env.SPOTIFY_REDIRECT_URI || `http://localhost:${process.env.PORT || 3001}/api/spotify/callback`;
}

const SCOPES = [
  'user-read-playback-state',
  'user-modify-playback-state',
  'user-read-currently-playing',
  'user-read-email',
  'user-read-private',
].join(' ');

// ── Token storage ─────────────────────────────────────────────────────────────
// Primary: Firestore users/{uid}/private/spotifyTokens
// Fallback: in-memory cache (works in mock mode; lost on server restart)
const _cache = new Map();

async function loadTokens(uid) {
  try {
    const db = getFirestore();
    if (db) {
      const snap = await db
        .collection('users').doc(uid)
        .collection('private').doc('spotifyTokens')
        .get();
      if (snap.exists) return snap.data();
    }
  } catch (e) { console.error('[Spotify] loadTokens Firestore error:', e.message); }
  return _cache.get(uid) || null;
}

async function storeTokens(uid, data) {
  _cache.set(uid, data);
  try {
    const db = getFirestore();
    if (db) {
      await db
        .collection('users').doc(uid)
        .collection('private').doc('spotifyTokens')
        .set(data);
    }
  } catch (e) { console.error('[Spotify] storeTokens Firestore error:', e.message); }
}

async function deleteTokens(uid) {
  _cache.delete(uid);
  try {
    const db = getFirestore();
    if (db) {
      await db
        .collection('users').doc(uid)
        .collection('private').doc('spotifyTokens')
        .delete();
    }
  } catch (e) { console.error('[Spotify] deleteTokens Firestore error:', e.message); }
}

// ── Token refresh ─────────────────────────────────────────────────────────────

async function refreshTokens(refreshToken) {
  const creds = Buffer.from(`${CLIENT_ID}:${CLIENT_SECRET}`).toString('base64');
  const res = await fetch('https://accounts.spotify.com/api/token', {
    method: 'POST',
    headers: {
      Authorization: `Basic ${creds}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      grant_type: 'refresh_token',
      refresh_token: refreshToken,
    }),
  });
  if (!res.ok) {
    const txt = await res.text();
    throw new Error(`Refresh failed (${res.status}): ${txt}`);
  }
  const json = await res.json();
  return {
    accessToken: json.access_token,
    refreshToken: json.refresh_token || refreshToken, // Spotify may omit new refresh token
    expiresAt: Date.now() + json.expires_in * 1000,
  };
}

/** Returns a valid access token, refreshing if needed. Returns null if not connected. */
async function getAccessToken(uid) {
  const data = await loadTokens(uid);
  if (!data) return null;

  // Refresh if within 60s of expiry
  if (Date.now() >= data.expiresAt - 60_000) {
    try {
      const fresh = await refreshTokens(data.refreshToken);
      const updated = { ...data, ...fresh };
      await storeTokens(uid, updated);
      return updated.accessToken;
    } catch (e) {
      console.error('[Spotify] token refresh error:', e.message);
      return null;
    }
  }

  return data.accessToken;
}

// ── Spotify API helpers ───────────────────────────────────────────────────────

async function spotifyFetch(accessToken, path, { method = 'GET', body } = {}) {
  const res = await fetch(`https://api.spotify.com/v1${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${accessToken}`,
      ...(body ? { 'Content-Type': 'application/json' } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  return res;
}

// ── Routes ────────────────────────────────────────────────────────────────────

// GET /api/spotify/auth?uid=&coupleId=
router.get('/auth', (req, res) => {
  if (!CLIENT_ID) {
    return res.status(503).send(`
      <html><body style="font-family:sans-serif;text-align:center;padding:40px;background:#1B1836;color:#fff">
      <h2>⚠️ Spotify not configured</h2>
      <p style="color:#aaa">Add SPOTIFY_CLIENT_ID and SPOTIFY_CLIENT_SECRET to Replit Secrets.</p>
      </body></html>
    `);
  }
  const { uid, coupleId = '' } = req.query;
  if (!uid) return res.status(400).json({ error: 'uid is required' });

  const state = Buffer.from(JSON.stringify({ uid, coupleId, ts: Date.now() })).toString('base64url');
  const params = new URLSearchParams({
    response_type: 'code',
    client_id: CLIENT_ID,
    scope: SCOPES,
    redirect_uri: getRedirectUri(),
    state,
    show_dialog: 'false',
  });
  res.redirect(`https://accounts.spotify.com/authorize?${params}`);
});

// GET /api/spotify/callback
router.get('/callback', async (req, res) => {
  const { code, state, error } = req.query;
  const HTML = (icon, title, subtitle, color = '#1DB954') => `
    <html>
    <head><meta charset="utf-8"><title>HeartSync × Spotify</title></head>
    <body style="margin:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;
      background:linear-gradient(135deg,#1B1836 0%,#2E2C4A 100%);color:#fff;min-height:100vh;
      display:flex;flex-direction:column;align-items:center;justify-content:center">
      <div style="text-align:center;padding:40px">
        <div style="font-size:64px;margin-bottom:20px">${icon}</div>
        <h2 style="margin:0 0 8px;color:${color};font-size:24px">${title}</h2>
        <p style="color:#aaa;margin:0 0 24px;font-size:15px">${subtitle}</p>
        <p style="color:#555;font-size:12px">This tab will close automatically…</p>
      </div>
      <script>setTimeout(() => { try { window.close(); } catch(e) {} }, 2500);</script>
    </body></html>
  `;

  if (error) {
    return res.send(HTML('❌', 'Cancelled', 'You can close this tab and return to HeartSync.', '#E05C7E'));
  }

  let uid, coupleId;
  try {
    const decoded = JSON.parse(Buffer.from(state, 'base64url').toString());
    uid = decoded.uid;
    coupleId = decoded.coupleId;
  } catch {
    return res.status(400).send(HTML('❌', 'Invalid state', 'Something went wrong. Please try again.', '#E05C7E'));
  }

  try {
    const creds = Buffer.from(`${CLIENT_ID}:${CLIENT_SECRET}`).toString('base64');
    const tokenRes = await fetch('https://accounts.spotify.com/api/token', {
      method: 'POST',
      headers: {
        Authorization: `Basic ${creds}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        grant_type: 'authorization_code',
        code,
        redirect_uri: getRedirectUri(),
      }),
    });

    if (!tokenRes.ok) {
      const txt = await tokenRes.text();
      console.error('[Spotify] token exchange failed:', txt);
      return res.status(500).send(HTML('❌', 'Token exchange failed', 'Please try connecting again.', '#E05C7E'));
    }

    const tokens = await tokenRes.json();

    // Fetch user profile
    const profileRes = await fetch('https://api.spotify.com/v1/me', {
      headers: { Authorization: `Bearer ${tokens.access_token}` },
    });
    const profile = profileRes.ok ? await profileRes.json() : {};

    await storeTokens(uid, {
      accessToken: tokens.access_token,
      refreshToken: tokens.refresh_token,
      expiresAt: Date.now() + tokens.expires_in * 1000,
      spotifyUserId: profile.id || '',
      displayName: profile.display_name || profile.id || 'Spotify user',
      avatarUrl: profile.images?.[0]?.url || '',
      connectedAt: Date.now(),
    });

    // Also update couple's Firestore doc to mark member as spotify-connected
    if (coupleId) {
      try {
        const db = getFirestore();
        if (db) {
          await db.collection('couples').doc(coupleId)
            .collection('spotifyStatus').doc(uid)
            .set({ connected: true, displayName: profile.display_name || '', updatedAt: new Date() });
        }
      } catch (e) { console.error('[Spotify] couple status write error:', e.message); }
    }

    return res.send(HTML(
      '✅',
      `${profile.display_name || 'Spotify'} connected!`,
      'You can close this tab and return to HeartSync.',
      '#1DB954',
    ));
  } catch (err) {
    console.error('[Spotify] callback error:', err);
    return res.status(500).send(HTML('❌', 'Authentication error', 'Please try connecting again.', '#E05C7E'));
  }
});

// GET /api/spotify/status/:uid
router.get('/status/:uid', async (req, res) => {
  const data = await loadTokens(req.params.uid);
  if (!data) return res.json({ connected: false });
  res.json({
    connected: true,
    displayName: data.displayName || '',
    avatarUrl: data.avatarUrl || '',
    connectedAt: data.connectedAt || null,
  });
});

// GET /api/spotify/current-track/:uid
// Returns the user's currently playing Spotify track.
router.get('/current-track/:uid', async (req, res) => {
  const token = await getAccessToken(req.params.uid);
  if (!token) return res.status(401).json({ error: 'not_connected' });

  try {
    const r = await spotifyFetch(token, '/me/player/currently-playing');
    if (r.status === 204) return res.json({ playing: false, idle: true });
    if (!r.ok) return res.json({ playing: false, error: r.status });

    const data = await r.json();
    if (!data || !data.item) return res.json({ playing: false });

    res.json({
      playing: data.is_playing,
      trackUri: data.item.uri,
      trackId: data.item.id,
      trackName: data.item.name,
      artistName: data.item.artists?.map(a => a.name).join(', ') ?? '',
      albumName: data.item.album?.name ?? '',
      albumArtUrl: data.item.album?.images?.[0]?.url ?? '',
      positionMs: data.progress_ms ?? 0,
      durationMs: data.item.duration_ms ?? 0,
    });
  } catch (e) {
    console.error('[Spotify] current-track error:', e.message);
    res.status(500).json({ error: 'fetch_failed' });
  }
});

// POST /api/spotify/play  { uid, trackUri?, positionMs? }
router.post('/play', async (req, res) => {
  const { uid, trackUri, positionMs = 0 } = req.body || {};
  if (!uid) return res.status(400).json({ error: 'uid required' });

  const token = await getAccessToken(uid);
  if (!token) return res.status(401).json({ error: 'not_connected' });

  try {
    const body = {};
    if (trackUri) body.uris = [trackUri];
    if (positionMs > 0) body.position_ms = positionMs;

    const r = await spotifyFetch(token, '/me/player/play', { method: 'PUT', body });
    if (!r.ok && r.status !== 204) {
      const txt = await r.text();
      console.error('[Spotify] play error:', txt);
      // 403 = Premium required, 404 = no active device
      if (r.status === 403) return res.status(403).json({ error: 'premium_required' });
      if (r.status === 404) return res.status(404).json({ error: 'no_active_device' });
      return res.status(r.status).json({ error: 'play_failed' });
    }
    res.json({ ok: true });
  } catch (e) {
    console.error('[Spotify] play error:', e.message);
    res.status(500).json({ error: 'play_failed' });
  }
});

// PUT /api/spotify/pause  { uid }
router.put('/pause', async (req, res) => {
  const { uid } = req.body || {};
  if (!uid) return res.status(400).json({ error: 'uid required' });

  const token = await getAccessToken(uid);
  if (!token) return res.status(401).json({ error: 'not_connected' });

  try {
    const r = await spotifyFetch(token, '/me/player/pause', { method: 'PUT' });
    if (!r.ok && r.status !== 204) return res.status(r.status).json({ error: 'pause_failed' });
    res.json({ ok: true });
  } catch (e) {
    console.error('[Spotify] pause error:', e.message);
    res.status(500).json({ error: 'pause_failed' });
  }
});

// PUT /api/spotify/seek  { uid, positionMs }
router.put('/seek', async (req, res) => {
  const { uid, positionMs } = req.body || {};
  if (!uid) return res.status(400).json({ error: 'uid required' });

  const token = await getAccessToken(uid);
  if (!token) return res.status(401).json({ error: 'not_connected' });

  try {
    const r = await spotifyFetch(token, `/me/player/seek?position_ms=${positionMs ?? 0}`, { method: 'PUT' });
    if (!r.ok && r.status !== 204) return res.status(r.status).json({ error: 'seek_failed' });
    res.json({ ok: true });
  } catch (e) {
    console.error('[Spotify] seek error:', e.message);
    res.status(500).json({ error: 'seek_failed' });
  }
});

/**
 * POST /api/spotify/sync  { conductorUid, listenerUid, trackUri, positionMs, isPlaying }
 * Applies the conductor's current Spotify state to the listener's account.
 * Called by the listener's Flutter app when drift > 3s.
 */
router.post('/sync', async (req, res) => {
  const { conductorUid, listenerUid, trackUri, positionMs = 0, isPlaying = true } = req.body || {};
  if (!listenerUid || !trackUri) {
    return res.status(400).json({ error: 'listenerUid and trackUri required' });
  }

  const token = await getAccessToken(listenerUid);
  if (!token) return res.status(401).json({ error: 'listener_not_connected' });

  try {
    // First, play the track at the right position
    const playBody = { uris: [trackUri], position_ms: positionMs };
    const playRes = await spotifyFetch(token, '/me/player/play', { method: 'PUT', body: playBody });

    if (!playRes.ok && playRes.status !== 204) {
      const txt = await playRes.text();
      console.error('[Spotify] sync play error:', txt);
      if (playRes.status === 403) return res.status(403).json({ error: 'premium_required' });
      if (playRes.status === 404) return res.status(404).json({ error: 'no_active_device' });
      return res.status(playRes.status).json({ error: 'sync_failed' });
    }

    // If conductor is paused, pause the listener too
    if (!isPlaying) {
      // Small delay to let the play command take effect before pausing
      await new Promise(r => setTimeout(r, 300));
      await spotifyFetch(token, '/me/player/pause', { method: 'PUT' });
    }

    res.json({ ok: true });
  } catch (e) {
    console.error('[Spotify] sync error:', e.message);
    res.status(500).json({ error: 'sync_failed' });
  }
});

// DELETE /api/spotify/disconnect/:uid
router.delete('/disconnect/:uid', async (req, res) => {
  const { uid } = req.params;
  await deleteTokens(uid);

  // Remove from couple's status collection
  const { coupleId } = req.query;
  if (coupleId) {
    try {
      const db = getFirestore();
      if (db) {
        await db.collection('couples').doc(coupleId)
          .collection('spotifyStatus').doc(uid).delete();
      }
    } catch (e) { console.error('[Spotify] disconnect status error:', e.message); }
  }

  res.json({ ok: true });
});

// GET /api/spotify/config — returns setup info so Flutter can build the OAuth URL
router.get('/config', (req, res) => {
  res.json({
    configured: !!CLIENT_ID,
    redirectUri: getRedirectUri(),
    authBase: `${getRedirectUri().replace('/callback', '/auth')}`,
  });
});

module.exports = router;

/**
 * sync.js — Sync session management for all three sync types:
 *   radio | youtube | music (Spotify)
 *
 * Routes:
 *   POST   /api/sync/session          start or update a session
 *   DELETE /api/sync/session          end a session
 *   POST   /api/sync/radio/track      add track to couple radio
 *   GET    /api/sync/radio/tracks     list couple radio tracks
 *   DELETE /api/sync/radio/track/:id  delete a radio track
 *   POST   /api/sync/watchlist        add video to watch list
 *   GET    /api/sync/watchlist        list watch list
 *   POST   /api/sync/reaction         send emoji reaction (watch together)
 */

const express = require('express');
const router = express.Router();
const { getFirestore, getMessaging, admin } = require('../firebase');
const verifyToken = require('../middleware/verifyToken');
const getCouple = require('../middleware/getCouple');

// ── Helper: get FieldValue safely ─────────────────────────────────────────────
function serverTimestamp() {
  try { return admin.firestore.FieldValue.serverTimestamp(); } catch { return new Date(); }
}

// ── POST /api/sync/session ─────────────────────────────────────────────────────
router.post('/session', verifyToken, getCouple, async (req, res) => {
  const { type, contentId, state, positionMs = 0 } = req.body;
  const db = getFirestore();
  if (!db) return res.json({ success: true, mock: true });

  try {
    await db
      .collection('couples').doc(req.coupleId)
      .collection('syncSession').doc('active')
      .set({
        type: type || 'radio',
        contentId: contentId || '',
        state: state || 'idle',
        positionMs,
        conductorId: req.user.uid,
        updatedAt: serverTimestamp(),
      }, { merge: true });

    // Notify partner via FCM if session is starting
    if (state === 'playing') {
      const members = req.coupleData?.members || req.coupleData?.memberIds || [];
      const partnerUid = members.find(m => m !== req.user.uid);
      if (partnerUid) {
        _notifyPartner(partnerUid, type).catch(() => {});
      }
    }

    res.json({ success: true });
  } catch (err) {
    console.error('[Sync] session update error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

async function _notifyPartner(partnerUid, sessionType) {
  const db = getFirestore();
  const messaging = getMessaging();
  if (!db || !messaging) return;
  try {
    const doc = await db.collection('users').doc(partnerUid).get();
    const fcmToken = doc.data()?.fcmToken;
    if (!fcmToken) return;
    const labels = { radio: 'Couple Radio 📻', youtube: 'Watch Together 🎬', music: 'Spotify Together 🎧' };
    await messaging.send({
      token: fcmToken,
      notification: {
        title: '🎵 Sync Zone',
        body: `Your partner started ${labels[sessionType] || 'a session'} — join them!`,
      },
      data: { type: 'sync_invite', sessionType: sessionType || 'radio' },
    });
  } catch (e) {
    console.log('[Sync] FCM error:', e.message);
  }
}

// ── DELETE /api/sync/session ───────────────────────────────────────────────────
router.delete('/session', verifyToken, getCouple, async (req, res) => {
  const db = getFirestore();
  if (!db) return res.json({ success: true, mock: true });
  try {
    await db
      .collection('couples').doc(req.coupleId)
      .collection('syncSession').doc('active')
      .set({ state: 'idle', updatedAt: serverTimestamp() }, { merge: true });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── POST /api/sync/radio/track ─────────────────────────────────────────────────
router.post('/radio/track', verifyToken, getCouple, async (req, res) => {
  const { title, artistName, storageUrl, durationMs } = req.body;
  if (!storageUrl) return res.status(400).json({ error: 'storageUrl required' });

  const db = getFirestore();
  if (!db) return res.json({ id: 'mock-track-' + Date.now(), mock: true });

  try {
    const ref = await db
      .collection('couples').doc(req.coupleId)
      .collection('radioTracks')
      .add({
        title: title || 'Untitled',
        artistName: artistName || '',
        storageUrl,
        durationMs: durationMs || 0,
        uploadedBy: req.user.uid,
        createdAt: serverTimestamp(),
        playCount: 0,
      });
    res.json({ id: ref.id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── GET /api/sync/radio/tracks ─────────────────────────────────────────────────
router.get('/radio/tracks', verifyToken, getCouple, async (req, res) => {
  const db = getFirestore();
  if (!db) return res.json({ tracks: [] });

  try {
    const snap = await db
      .collection('couples').doc(req.coupleId)
      .collection('radioTracks')
      .orderBy('createdAt', 'asc')
      .get();
    const tracks = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    res.json({ tracks });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── DELETE /api/sync/radio/track/:id ──────────────────────────────────────────
router.delete('/radio/track/:id', verifyToken, getCouple, async (req, res) => {
  const db = getFirestore();
  if (!db) return res.json({ success: true, mock: true });

  try {
    await db
      .collection('couples').doc(req.coupleId)
      .collection('radioTracks').doc(req.params.id)
      .delete();
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── POST /api/sync/watchlist ───────────────────────────────────────────────────
router.post('/watchlist', verifyToken, getCouple, async (req, res) => {
  const { videoId, title, thumbnail } = req.body;
  if (!videoId) return res.status(400).json({ error: 'videoId required' });

  const db = getFirestore();
  if (!db) return res.json({ id: 'mock-' + Date.now() });

  try {
    const ref = await db
      .collection('couples').doc(req.coupleId)
      .collection('watchList')
      .add({
        videoId,
        title: title || 'YouTube video',
        thumbnail: thumbnail || `https://img.youtube.com/vi/${videoId}/mqdefault.jpg`,
        addedBy: req.user.uid,
        addedAt: serverTimestamp(),
        watched: false,
      });
    res.json({ id: ref.id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── GET /api/sync/watchlist ────────────────────────────────────────────────────
router.get('/watchlist', verifyToken, getCouple, async (req, res) => {
  const db = getFirestore();
  if (!db) return res.json({ items: [] });

  try {
    const snap = await db
      .collection('couples').doc(req.coupleId)
      .collection('watchList')
      .orderBy('addedAt', 'desc')
      .get();
    const items = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    res.json({ items });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── POST /api/sync/reaction ────────────────────────────────────────────────────
router.post('/reaction', verifyToken, getCouple, async (req, res) => {
  const { emoji } = req.body;
  if (!emoji) return res.status(400).json({ error: 'emoji required' });

  const db = getFirestore();
  if (!db) return res.json({ success: true, mock: true });

  try {
    await db
      .collection('couples').doc(req.coupleId)
      .collection('watchReactions')
      .add({
        emoji,
        fromUid: req.user.uid,
        sentAt: serverTimestamp(),
      });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

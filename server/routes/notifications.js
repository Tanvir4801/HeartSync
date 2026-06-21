const express = require('express');
const router = express.Router();
const { getMessaging, getFirestore } = require('../firebase');

function db() { return getFirestore(); }

router.post('/broadcast', async (req, res) => {
  const { title, body, tier, inactiveDays, sendAt } = req.body;
  if (!title || !body) return res.status(400).json({ error: 'title and body required' });

  if (sendAt && new Date(sendAt) > new Date()) {
    const scheduled = { title, body, tier: tier || 'all', inactiveDays: inactiveDays || null, sendAt, status: 'pending', createdAt: new Date().toISOString(), createdBy: req.user?.email };
    try {
      if (db()) {
        const ref = await db().collection('admin').doc('scheduled_notifications').collection('items').add(scheduled);
        return res.json({ success: true, scheduled: true, id: ref.id, sendAt });
      }
    } catch {}
    return res.json({ success: true, scheduled: true, mock: true, sendAt });
  }

  const messaging = getMessaging();
  if (!messaging) {
    console.log(`[MOCK] Broadcast to ${tier || 'all'}: "${title}" — ${body}${inactiveDays ? ` (inactive>${inactiveDays}d)` : ''}`);
    if (db()) {
      await _logSend({ title, body, tier, inactiveDays, sentAt: new Date().toISOString(), createdBy: req.user?.email, mock: true });
    }
    return res.json({ success: true, mock: true, messageId: 'mock-msg-id', targeting: { tier, inactiveDays } });
  }

  try {
    let topic = 'all-users';
    if (tier === 'premium') topic = 'premium-users';
    else if (tier === 'free') topic = 'free-users';

    const messageId = await messaging.send({ topic, notification: { title, body } });
    if (db()) await _logSend({ title, body, tier, inactiveDays, sentAt: new Date().toISOString(), createdBy: req.user?.email, messageId });
    res.json({ success: true, messageId, targeting: { tier, topic } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/scheduled', async (req, res) => {
  try {
    if (!db()) return res.json([]);
    const snap = await db().collection('admin').doc('scheduled_notifications').collection('items')
      .where('status', '==', 'pending').orderBy('sendAt').get();
    res.json(snap.docs.map(d => ({ id: d.id, ...d.data() })));
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.delete('/scheduled/:id', async (req, res) => {
  try {
    if (db()) await db().collection('admin').doc('scheduled_notifications').collection('items').doc(req.params.id).update({ status: 'cancelled' });
    res.json({ ok: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/history', async (req, res) => {
  try {
    if (!db()) return res.json([]);
    const snap = await db().collection('admin').doc('notification_log').collection('entries')
      .orderBy('sentAt', 'desc').limit(50).get();
    res.json(snap.docs.map(d => ({ id: d.id, ...d.data() })));
  } catch (e) { res.status(500).json({ error: e.message }); }
});

async function _logSend(data) {
  try { if (db()) await db().collection('admin').doc('notification_log').collection('entries').add(data); } catch {}
}

module.exports = router;

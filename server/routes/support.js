const express = require('express');
const router = express.Router();
const { getFirestore, getAdmin } = require('../firebase');

function db() { return getFirestore(); }

const MOCK_TICKETS = [
  { id: 'tk1', coupleId: 'couple-abc', userEmail: 'alice@example.com', message: 'My partner cannot join with the invite code', status: 'open', createdAt: new Date(Date.now() - 3600000 * 5).toISOString() },
  { id: 'tk2', coupleId: 'couple-def', userEmail: 'bob@example.com', message: 'Cannot upload photos — getting a storage error', status: 'open', createdAt: new Date(Date.now() - 3600000 * 12).toISOString() },
  { id: 'tk3', coupleId: 'couple-ghi', userEmail: 'carol@example.com', message: 'Streak reset incorrectly after timezone change', status: 'resolved', createdAt: new Date(Date.now() - 3600000 * 48).toISOString() },
];

router.get('/tickets', async (req, res) => {
  const { status } = req.query;
  try {
    if (!db()) {
      const filtered = status ? MOCK_TICKETS.filter(t => t.status === status) : MOCK_TICKETS;
      return res.json(filtered);
    }
    let q = db().collection('support_tickets').orderBy('createdAt', 'desc');
    if (status) q = q.where('status', '==', status);
    const snap = await q.limit(100).get();
    const tickets = await Promise.all(snap.docs.map(async d => {
      const replies = await d.ref.collection('replies').orderBy('createdAt').get();
      return { id: d.id, ...d.data(), replies: replies.docs.map(r => ({ id: r.id, ...r.data() })) };
    }));
    res.json(tickets);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/tickets/:id/reply', async (req, res) => {
  const { message } = req.body;
  if (!message) return res.status(400).json({ error: 'message required' });
  const reply = { message, from: 'admin', adminEmail: req.user?.email, createdAt: new Date().toISOString() };
  try {
    if (db()) {
      await db().collection('support_tickets').doc(req.params.id).collection('replies').add(reply);
      await db().collection('support_tickets').doc(req.params.id).update({ status: 'replied', updatedAt: new Date().toISOString() });
    }
    res.json({ ok: true, reply });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.patch('/tickets/:id/status', async (req, res) => {
  const { status } = req.body;
  if (!['open', 'replied', 'resolved'].includes(status)) return res.status(400).json({ error: 'invalid status' });
  try {
    if (db()) await db().collection('support_tickets').doc(req.params.id).update({ status, updatedAt: new Date().toISOString() });
    res.json({ ok: true, status });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = router;

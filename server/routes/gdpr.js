const express = require('express');
const router = express.Router();
const { getFirestore, getAdmin } = require('../firebase');
const { appendAuditLog } = require('./audit');

function db() { return getFirestore(); }

const MOCK_REQUESTS = [
  { id: 'gr1', coupleId: 'couple-abc', type: 'export', status: 'pending', requestedAt: new Date(Date.now() - 3600000 * 6).toISOString() },
  { id: 'gr2', coupleId: 'couple-xyz', type: 'deletion', status: 'pending', requestedAt: new Date(Date.now() - 3600000 * 24).toISOString() },
  { id: 'gr3', coupleId: 'couple-def', type: 'export', status: 'completed', requestedAt: new Date(Date.now() - 86400000 * 3).toISOString(), completedAt: new Date(Date.now() - 86400000 * 2).toISOString() },
];

router.get('/requests', async (req, res) => {
  const { status } = req.query;
  try {
    if (!db()) {
      const filtered = status ? MOCK_REQUESTS.filter(r => r.status === status) : MOCK_REQUESTS;
      return res.json(filtered);
    }
    let q = db().collection('admin').doc('data_requests').collection('items').orderBy('requestedAt', 'desc');
    if (status) q = q.where('status', '==', status);
    const snap = await q.limit(100).get();
    res.json(snap.docs.map(d => ({ id: d.id, ...d.data() })));
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/requests/:id/export', async (req, res) => {
  const { id } = req.params;
  try {
    let coupleId = null;
    if (db()) {
      const docSnap = await db().collection('admin').doc('data_requests').collection('items').doc(id).get();
      if (!docSnap.exists) return res.status(404).json({ error: 'Request not found' });
      coupleId = docSnap.data().coupleId;
    } else {
      const mock = MOCK_REQUESTS.find(r => r.id === id);
      coupleId = mock?.coupleId || 'unknown';
    }
    const exportData = { coupleId, exportedAt: new Date().toISOString(), by: req.user?.email };
    if (db()) {
      const [memories, messages, notes] = await Promise.all([
        db().collection('couples').doc(coupleId).collection('memories').get(),
        db().collection('couples').doc(coupleId).collection('messages').get(),
        db().collection('couples').doc(coupleId).collection('notes').get(),
      ]);
      exportData.memories = memories.docs.map(d => d.data()).length;
      exportData.messages = messages.docs.map(d => d.data()).length;
      exportData.notes = notes.docs.map(d => d.data()).length;
      await db().collection('admin').doc('data_requests').collection('items').doc(id).update({ status: 'completed', completedAt: new Date().toISOString() });
    }
    await appendAuditLog('data_export', coupleId, req.user?.email, req.user?.role || 'admin', `Data export completed for ${coupleId}`);
    res.json({ ok: true, exportData });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/requests/:id/delete', async (req, res) => {
  const { id } = req.params;
  try {
    let coupleId = null;
    if (db()) {
      const docSnap = await db().collection('admin').doc('data_requests').collection('items').doc(id).get();
      if (!docSnap.exists) return res.status(404).json({ error: 'Request not found' });
      coupleId = docSnap.data().coupleId;
      await _deleteAllCoupleData(coupleId);
      await db().collection('admin').doc('data_requests').collection('items').doc(id).update({ status: 'completed', completedAt: new Date().toISOString() });
    } else {
      coupleId = MOCK_REQUESTS.find(r => r.id === id)?.coupleId || 'unknown';
    }
    await appendAuditLog('data_deletion', coupleId, req.user?.email, req.user?.role || 'admin', `Full data deletion executed for ${coupleId}`);
    res.json({ ok: true, deleted: coupleId });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

async function _deleteAllCoupleData(coupleId) {
  const firestore = db();
  if (!firestore) return;
  const subcollections = ['memories', 'messages', 'notes', 'moods', 'hugs', 'battery', 'challenges', 'typing', 'milestones'];
  for (const col of subcollections) {
    const snap = await firestore.collection('couples').doc(coupleId).collection(col).get();
    const batch = firestore.batch();
    snap.docs.forEach(d => batch.delete(d.ref));
    if (snap.docs.length) await batch.commit();
  }
  await firestore.collection('couples').doc(coupleId).delete();
}

module.exports = router;

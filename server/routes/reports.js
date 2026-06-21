const express = require('express');
const router = express.Router();
const { getFirestore } = require('../firebase');

const mockReports = [
  { id: 'r001', coupleId: 'c002', contentType: 'memory', contentId: 'm123', reason: 'Inappropriate content', reportedAt: '2024-06-18T10:00:00Z', status: 'pending' },
  { id: 'r002', coupleId: 'c004', contentType: 'message', contentId: 'msg456', reason: 'Spam', reportedAt: '2024-06-17T14:30:00Z', status: 'pending' },
  { id: 'r003', coupleId: 'c001', contentType: 'note', contentId: 'n789', reason: 'Harassment', reportedAt: '2024-06-15T09:00:00Z', status: 'dismissed' },
];

router.get('/', async (req, res) => {
  const db = getFirestore();
  if (!db) return res.json(mockReports);
  try {
    const snap = await db.collection('reports').orderBy('reportedAt', 'desc').limit(50).get();
    res.json(snap.docs.map(d => ({ id: d.id, ...d.data() })));
  } catch (err) {
    res.json(mockReports);
  }
});

router.patch('/:id', async (req, res) => {
  const { status } = req.body;
  const db = getFirestore();
  if (!db) return res.json({ success: true, status });
  try {
    await db.collection('reports').doc(req.params.id).update({ status, resolvedAt: new Date().toISOString(), resolvedBy: req.user.uid });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

const express = require('express');
const router = express.Router();
const { getFirestore } = require('../firebase');

const mockCouples = [
  { id: 'c001', inviteCode: 'LOVE42', members: ['alice@test.com', 'bob@test.com'], anniversaryDate: '2022-06-15', tier: 'Premium', memoryCount: 47, messageCount: 1203, lastActive: '2024-06-20', status: 'active' },
  { id: 'c002', inviteCode: 'HEART7', members: ['priya@test.com', 'arjun@test.com'], anniversaryDate: '2023-01-10', tier: 'Free', memoryCount: 12, messageCount: 340, lastActive: '2024-06-19', status: 'active' },
  { id: 'c003', inviteCode: 'STAR99', members: ['mei@test.com', 'leo@test.com'], anniversaryDate: '2021-11-20', tier: 'Lifetime', memoryCount: 210, messageCount: 5600, lastActive: '2024-06-20', status: 'active' },
  { id: 'c004', inviteCode: 'MOON11', members: ['sara@test.com', 'john@test.com'], anniversaryDate: '2023-08-05', tier: 'Free', memoryCount: 3, messageCount: 45, lastActive: '2024-05-01', status: 'unlinked' },
  { id: 'c005', inviteCode: 'ROSE55', members: ['nina@test.com', 'sam@test.com'], anniversaryDate: '2022-02-14', tier: 'Premium', memoryCount: 89, messageCount: 2100, lastActive: '2024-06-18', status: 'suspended' },
];

router.get('/', async (req, res) => {
  const { q } = req.query;
  const db = getFirestore();
  if (!db) {
    const filtered = q
      ? mockCouples.filter(c =>
          c.inviteCode.includes(q.toUpperCase()) ||
          c.id.includes(q) ||
          c.members.some(m => m.includes(q))
        )
      : mockCouples;
    return res.json(filtered);
  }

  try {
    const snap = await db.collection('couples').limit(50).get();
    const couples = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    res.json(couples);
  } catch (err) {
    console.error(err);
    res.json(mockCouples);
  }
});

router.get('/:id', async (req, res) => {
  const db = getFirestore();
  if (!db) {
    const couple = mockCouples.find(c => c.id === req.params.id);
    return couple ? res.json(couple) : res.status(404).json({ error: 'Not found' });
  }
  try {
    const doc = await db.collection('couples').doc(req.params.id).get();
    if (!doc.exists) return res.status(404).json({ error: 'Not found' });
    res.json({ id: doc.id, ...doc.data() });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

router.patch('/:id/subscription', async (req, res) => {
  const { tier } = req.body;
  const db = getFirestore();
  if (!db) return res.json({ success: true, tier });
  try {
    await db.collection('couples').doc(req.params.id).collection('subscription').doc('current').set({ tier, grantedAt: new Date().toISOString(), grantedBy: req.user.uid }, { merge: true });
    res.json({ success: true, tier });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.patch('/:id/status', async (req, res) => {
  const { status } = req.body;
  const db = getFirestore();
  if (!db) return res.json({ success: true, status });
  try {
    await db.collection('couples').doc(req.params.id).update({ status });
    res.json({ success: true, status });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

const express = require('express');
const router = express.Router();
const { getFirestore } = require('../firebase');

const mockUsage = Array.from({ length: 30 }, (_, i) => {
  const d = new Date();
  d.setDate(d.getDate() - (29 - i));
  return {
    date: d.toISOString().split('T')[0],
    endpoint: ['love-letter', 'caption', 'monthly-recap'][i % 3],
    tokensUsed: Math.floor(Math.random() * 2000) + 500,
    costEstimate: parseFloat((Math.random() * 0.05 + 0.005).toFixed(4)),
    coupleId: `c00${(i % 5) + 1}`,
  };
});

router.get('/', async (req, res) => {
  const db = getFirestore();
  if (!db) return res.json(mockUsage);
  try {
    const snap = await db.collection('admin').doc('ai_usage').collection('logs').orderBy('timestamp', 'desc').limit(100).get();
    if (snap.empty) return res.json(mockUsage);
    res.json(snap.docs.map(d => ({ id: d.id, ...d.data() })));
  } catch (err) {
    res.json(mockUsage);
  }
});

router.post('/log', async (req, res) => {
  const { endpoint, coupleId, tokensUsed, costEstimate } = req.body;
  const db = getFirestore();
  if (!db) return res.json({ success: true, mock: true });
  try {
    await db.collection('admin').doc('ai_usage').collection('logs').add({
      endpoint, coupleId, tokensUsed, costEstimate,
      timestamp: new Date().toISOString(),
    });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

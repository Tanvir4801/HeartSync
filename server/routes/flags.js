const express = require('express');
const router = express.Router();
const { getFirestore } = require('../firebase');

const mockFlags = [
  { id: 'couple_polls', enabled: false, rolloutPercent: 0, description: 'Daily polls feature for couples' },
  { id: 'ai_captions', enabled: true, rolloutPercent: 100, description: 'AI-generated memory captions' },
  { id: 'love_journey_map', enabled: true, rolloutPercent: 50, description: 'Interactive journey map' },
  { id: 'voice_notes', enabled: true, rolloutPercent: 100, description: 'Voice note recording in chat' },
  { id: 'monthly_recap', enabled: false, rolloutPercent: 10, description: 'AI monthly relationship recap' },
];

router.get('/', async (req, res) => {
  const db = getFirestore();
  if (!db) return res.json(mockFlags);
  try {
    const snap = await db.collection('admin').doc('feature_flags').collection('flags').get();
    if (snap.empty) return res.json(mockFlags);
    res.json(snap.docs.map(d => ({ id: d.id, ...d.data() })));
  } catch (err) {
    res.json(mockFlags);
  }
});

router.put('/:id', async (req, res) => {
  const { enabled, rolloutPercent } = req.body;
  const db = getFirestore();
  if (!db) return res.json({ success: true, id: req.params.id, enabled, rolloutPercent });
  try {
    await db.collection('admin').doc('feature_flags').collection('flags').doc(req.params.id).set({ enabled, rolloutPercent, updatedAt: new Date().toISOString(), updatedBy: req.user.uid }, { merge: true });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

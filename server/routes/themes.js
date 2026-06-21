const express = require('express');
const router = express.Router();
const { getFirestore } = require('../firebase');

function db() { return getFirestore(); }

const MOCK_THEMES = [
  { id: 'horizon', name: 'Horizon', isPremium: false, colors: { primary: '#F2A65A', secondary: '#E8927C', accent: '#9B8AC4', bg: '#1C1B33' }, createdAt: new Date().toISOString() },
  { id: 'midnight-bloom', name: 'Midnight Bloom', isPremium: true, colors: { primary: '#9B8AC4', secondary: '#E05C7E', accent: '#4ADE80', bg: '#0D0D1A' }, createdAt: new Date().toISOString() },
  { id: 'golden-hour', name: 'Golden Hour', isPremium: true, colors: { primary: '#F2A65A', secondary: '#FACC15', accent: '#E8927C', bg: '#1A1208' }, createdAt: new Date().toISOString() },
  { id: 'northern-lights', name: 'Northern Lights', isPremium: true, colors: { primary: '#4ADE80', secondary: '#9B8AC4', accent: '#38BDF8', bg: '#0D1A17' }, createdAt: new Date().toISOString() },
];

const MOCK_BADGES = [
  { id: 'streak-7', name: '7-Day Streak', icon: '🔥', unlockCondition: '7-day consecutive activity streak', xpThreshold: 0, streakThreshold: 7 },
  { id: 'streak-30', name: '30-Day Streak', icon: '❤️‍🔥', unlockCondition: '30-day consecutive activity streak', xpThreshold: 0, streakThreshold: 30 },
  { id: 'memories-10', name: 'Memory Keeper', icon: '📸', unlockCondition: '10 memories added', xpThreshold: 100, streakThreshold: 0 },
  { id: 'memories-100', name: '100 Memories', icon: '🏆', unlockCondition: '100 memories added', xpThreshold: 500, streakThreshold: 0 },
  { id: 'xp-500', name: 'Power Couple', icon: '⚡', unlockCondition: '500 XP earned', xpThreshold: 500, streakThreshold: 0 },
  { id: 'premium', name: 'Premium', icon: '💎', unlockCondition: 'Active premium subscription', xpThreshold: 0, streakThreshold: 0 },
];

router.get('/themes', async (req, res) => {
  try {
    if (!db()) return res.json(MOCK_THEMES);
    const snap = await db().collection('admin').doc('themes').collection('items').get();
    if (snap.empty) return res.json(MOCK_THEMES);
    res.json(snap.docs.map(d => ({ id: d.id, ...d.data() })));
  } catch { res.json(MOCK_THEMES); }
});

router.post('/themes', async (req, res) => {
  const { id, name, isPremium, colors } = req.body;
  if (!id || !name || !colors) return res.status(400).json({ error: 'id, name, colors required' });
  const doc = { name, isPremium: !!isPremium, colors, updatedAt: new Date().toISOString(), updatedBy: req.user?.email };
  try {
    if (db()) await db().collection('admin').doc('themes').collection('items').doc(id).set(doc, { merge: true });
    res.json({ id, ...doc });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.delete('/themes/:id', async (req, res) => {
  try {
    if (db()) await db().collection('admin').doc('themes').collection('items').doc(req.params.id).delete();
    res.json({ deleted: req.params.id });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.get('/badges', async (req, res) => {
  try {
    if (!db()) return res.json(MOCK_BADGES);
    const snap = await db().collection('admin').doc('badges').collection('items').get();
    if (snap.empty) return res.json(MOCK_BADGES);
    res.json(snap.docs.map(d => ({ id: d.id, ...d.data() })));
  } catch { res.json(MOCK_BADGES); }
});

router.post('/badges', async (req, res) => {
  const { id, name, icon, unlockCondition, xpThreshold, streakThreshold } = req.body;
  if (!id || !name) return res.status(400).json({ error: 'id and name required' });
  const doc = { name, icon: icon || '🏅', unlockCondition, xpThreshold: xpThreshold || 0, streakThreshold: streakThreshold || 0, updatedAt: new Date().toISOString(), updatedBy: req.user?.email };
  try {
    if (db()) await db().collection('admin').doc('badges').collection('items').doc(id).set(doc, { merge: true });
    res.json({ id, ...doc });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.delete('/badges/:id', async (req, res) => {
  try {
    if (db()) await db().collection('admin').doc('badges').collection('items').doc(req.params.id).delete();
    res.json({ deleted: req.params.id });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = router;

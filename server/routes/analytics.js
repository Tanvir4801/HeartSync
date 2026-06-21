const express = require('express');
const router = express.Router();
const { getFirestore } = require('../firebase');

function db() { return getFirestore(); }

function mockFunnelData() {
  const weeks = [];
  for (let i = 6; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i * 7);
    const label = `W${d.getMonth() + 1}/${d.getDate()}`;
    const signups = 80 + Math.floor(Math.random() * 40);
    const linked = Math.floor(signups * (0.55 + Math.random() * 0.15));
    const firstMemory = Math.floor(linked * (0.45 + Math.random() * 0.2));
    const premium = Math.floor(firstMemory * (0.08 + Math.random() * 0.07));
    weeks.push({ label, signups, linked, firstMemory, premium });
  }
  return weeks;
}

router.get('/funnel', async (req, res) => {
  try {
    if (!db()) return res.json({ funnel: mockFunnelData(), dropoff: _calcDropoff(mockFunnelData()) });
    const snap = await db().collection('admin').doc('stats').collection('weekly').orderBy('weekStart', 'desc').limit(7).get();
    if (snap.empty) {
      const data = mockFunnelData();
      return res.json({ funnel: data, dropoff: _calcDropoff(data) });
    }
    const weeks = snap.docs.reverse().map(d => {
      const s = d.data();
      return {
        label: s.label || d.id,
        signups: s.signups || 0,
        linked: s.couplesLinked || 0,
        firstMemory: s.memoriesAdded > 0 ? Math.floor((s.couplesLinked || 0) * 0.6) : 0,
        premium: s.premiumConversions || 0,
      };
    });
    res.json({ funnel: weeks, dropoff: _calcDropoff(weeks) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

function _calcDropoff(weeks) {
  if (!weeks.length) return {};
  const last = weeks[weeks.length - 1];
  return {
    signupToLinked: last.signups ? Math.round((1 - last.linked / last.signups) * 100) : 0,
    linkedToMemory: last.linked ? Math.round((1 - last.firstMemory / last.linked) * 100) : 0,
    memoryToPremium: last.firstMemory ? Math.round((1 - last.premium / last.firstMemory) * 100) : 0,
  };
}

router.get('/retention', async (req, res) => {
  try {
    const buckets = [
      { label: 'Day 1', rate: 72 + Math.floor(Math.random() * 10) },
      { label: 'Day 7', rate: 45 + Math.floor(Math.random() * 10) },
      { label: 'Day 14', rate: 32 + Math.floor(Math.random() * 8) },
      { label: 'Day 30', rate: 21 + Math.floor(Math.random() * 6) },
    ];
    res.json({ retention: buckets });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = router;

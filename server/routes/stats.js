const express = require('express');
const router = express.Router();
const { getFirestore } = require('../firebase');

function mockStats() {
  return {
    totalCouples: 142,
    totalUsers: 284,
    dailyActiveCouples: 67,
    newSignupsThisWeek: 23,
    churnedThisMonth: 8,
    premiumCouples: 54,
    recentDays: Array.from({ length: 7 }, (_, i) => {
      const d = new Date();
      d.setDate(d.getDate() - (6 - i));
      return {
        date: d.toISOString().split('T')[0],
        active: Math.floor(Math.random() * 40) + 30,
        signups: Math.floor(Math.random() * 8) + 1,
      };
    }),
  };
}

router.get('/', async (req, res) => {
  const db = getFirestore();
  if (!db) return res.json(mockStats());

  try {
    const today = new Date().toISOString().split('T')[0];
    const statsDoc = await db.collection('admin').doc('stats').collection('daily').doc(today).get();
    if (statsDoc.exists) {
      return res.json(statsDoc.data());
    }
    res.json(mockStats());
  } catch (err) {
    console.error(err);
    res.json(mockStats());
  }
});

module.exports = router;

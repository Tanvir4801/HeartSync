const express = require('express');
const router = express.Router();
const { getFirestore } = require('../firebase');

const MOCK_EVENTS = [
  { type: 'INITIAL_PURCHASE', coupleId: 'c001', amount: 99,  product: 'Premium Monthly',   date: '2025-05-20' },
  { type: 'RENEWAL',          coupleId: 'c003', amount: 999, product: 'Lifetime',           date: '2025-05-19' },
  { type: 'RENEWAL',          coupleId: 'c001', amount: 99,  product: 'Premium Monthly',   date: '2025-05-15' },
  { type: 'CANCELLATION',     coupleId: 'c005', amount: 0,   product: 'Premium Monthly',   date: '2025-04-14' },
  { type: 'INITIAL_PURCHASE', coupleId: 'c002', amount: 99,  product: 'Premium Monthly',   date: '2025-04-12' },
  { type: 'RENEWAL',          coupleId: 'c004', amount: 299, product: 'Premium Quarterly', date: '2025-03-01' },
  { type: 'INITIAL_PURCHASE', coupleId: 'c006', amount: 99,  product: 'Premium Monthly',   date: '2025-02-10' },
  { type: 'RENEWAL',          coupleId: 'c002', amount: 99,  product: 'Premium Monthly',   date: '2025-01-12' },
];

router.get('/events', async (req, res) => {
  const db = getFirestore();
  if (!db) return res.json({ events: MOCK_EVENTS });
  try {
    const snap = await db
      .collection('admin').doc('revenuecat_events').collection('events')
      .orderBy('receivedAt', 'desc').limit(50).get();
    if (snap.empty) return res.json({ events: MOCK_EVENTS });
    const events = snap.docs.map(d => {
      const raw = d.data();
      const ev  = raw.event || {};
      return {
        type:     ev.type || raw.type || 'UNKNOWN',
        coupleId: ev.app_user_id || raw.coupleId || '—',
        amount:   ev.price || ev.price_in_purchased_currency || 0,
        product:  ev.product_id || raw.product || '—',
        date:     (ev.purchased_at_ms
          ? new Date(ev.purchased_at_ms).toISOString().split('T')[0]
          : (raw.receivedAt || '').split('T')[0]) || '—',
      };
    });
    res.json({ events });
  } catch (e) {
    console.error('[revenue] events error:', e.message);
    res.json({ events: MOCK_EVENTS });
  }
});

module.exports = router;

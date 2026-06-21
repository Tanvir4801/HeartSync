const express = require('express');
const router = express.Router();
const { getFirestore } = require('../firebase');

function verifyRevenueCatSignature(req) {
  const secret = process.env.REVENUECAT_WEBHOOK_SECRET;
  if (!secret) return true;
  const authHeader = req.headers.authorization;
  return authHeader === secret;
}

router.post('/', async (req, res) => {
  if (!verifyRevenueCatSignature(req)) {
    return res.status(401).json({ error: 'Unauthorized webhook' });
  }

  const event = req.body;
  const db = getFirestore();

  if (db) {
    try {
      await db.collection('admin').doc('revenuecat_events').collection('events').add({
        ...event,
        receivedAt: new Date().toISOString(),
      });

      if (event.event?.app_user_id) {
        const coupleId = event.event.app_user_id;
        const type = event.event.type;
        const tier = ['INITIAL_PURCHASE', 'RENEWAL', 'PRODUCT_CHANGE'].includes(type) ? 'Premium' : 'Free';
        await db.collection('couples').doc(coupleId).collection('subscription').doc('current').set({
          tier,
          revenueCatEventType: type,
          updatedAt: new Date().toISOString(),
        }, { merge: true });
      }
    } catch (err) {
      console.error('RevenueCat webhook error:', err.message);
    }
  }

  res.status(200).json({ received: true });
});

module.exports = router;

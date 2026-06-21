const express = require('express');
const router = express.Router();
const { getAuth } = require('../firebase');

router.post('/verify', async (req, res) => {
  const { idToken } = req.body;
  if (!idToken) return res.status(400).json({ error: 'idToken required' });

  if (!process.env.FIREBASE_SERVICE_ACCOUNT) {
    return res.json({
      uid: 'mock-admin',
      email: 'admin@heartsync.app',
      isAdmin: true,
      mock: true,
    });
  }

  try {
    const auth = getAuth();
    const decoded = await auth.verifyIdToken(idToken);
    if (!decoded.isAdmin) {
      return res.status(403).json({ error: 'Not authorized — admin access required' });
    }
    res.json({ uid: decoded.uid, email: decoded.email, isAdmin: true });
  } catch (err) {
    res.status(401).json({ error: 'Invalid token' });
  }
});

module.exports = router;

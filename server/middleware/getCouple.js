/**
 * getCouple.js
 * Resolves the coupleId for the current Firebase user and attaches it to req.
 * Use after verifyToken on couple-scoped routes.
 */
const { getFirestore } = require('../firebase');

module.exports = async (req, res, next) => {
  const db = getFirestore();

  // Mock mode — use query/body coupleId if present
  if (!db) {
    req.coupleId = req.body?.coupleId || req.query?.coupleId || 'mock-couple';
    req.coupleData = { members: [req.user?.uid || 'mock-user', 'mock-partner'] };
    return next();
  }

  try {
    const snap = await db
      .collection('couples')
      .where('members', 'array-contains', req.user.uid)
      .where('status', '==', 'active')
      .limit(1)
      .get();

    if (snap.empty) {
      // Fallback: try 'memberIds' field
      const snap2 = await db
        .collection('couples')
        .where('memberIds', 'array-contains', req.user.uid)
        .limit(1)
        .get();

      if (snap2.empty) {
        return res.status(404).json({ error: 'No couple found for this user' });
      }
      req.coupleId = snap2.docs[0].id;
      req.coupleData = snap2.docs[0].data();
    } else {
      req.coupleId = snap.docs[0].id;
      req.coupleData = snap.docs[0].data();
    }
    next();
  } catch (err) {
    return res.status(500).json({ error: 'Could not resolve couple', detail: err.message });
  }
};

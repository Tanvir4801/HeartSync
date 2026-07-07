/**
 * verifyToken.js
 * Verifies Firebase ID token from Authorization: Bearer <token> header.
 * In mock mode (no Firebase), passes through with req.user = { uid: 'mock-user' }.
 */
const { getAuth } = require('../firebase');

module.exports = async (req, res, next) => {
  const auth = getAuth();

  // Mock mode — no Firebase Admin, skip verification
  if (!auth) {
    req.user = { uid: req.headers['x-mock-uid'] || 'mock-user' };
    return next();
  }

  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing Authorization header' });
  }

  try {
    const token = header.split('Bearer ')[1];
    req.user = await auth.verifyIdToken(token);
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid token', detail: err.message });
  }
};

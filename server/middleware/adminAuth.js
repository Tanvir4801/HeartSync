const { getAuth } = require('../firebase');

async function adminMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing authorization token' });
  }

  const idToken = authHeader.split('Bearer ')[1];

  if (!process.env.FIREBASE_SERVICE_ACCOUNT) {
    req.user = { uid: 'mock-admin', email: 'admin@heartsync.app', isAdmin: true };
    return next();
  }

  try {
    const auth = getAuth();
    if (!auth) {
      return res.status(503).json({ error: 'Auth service unavailable' });
    }
    const decodedToken = await auth.verifyIdToken(idToken);
    if (!decodedToken.isAdmin) {
      return res.status(403).json({ error: 'Not authorized — admin access required' });
    }
    req.user = decodedToken;
    next();
  } catch (err) {
    console.error('Token verification failed:', err.message);
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

module.exports = adminMiddleware;

const { getAuth } = require('../firebase');

const ROLE_PERMISSIONS = {
  admin: ['*'],
  support: ['couples', 'reports', 'support', 'audit'],
};

function hasPermission(role, route) {
  if (!role) return false;
  const perms = ROLE_PERMISSIONS[role] || [];
  return perms.includes('*') || perms.some(p => route.includes(p));
}

async function adminMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing authorization token' });
  }

  const idToken = authHeader.split('Bearer ')[1];

  if (!process.env.FIREBASE_SERVICE_ACCOUNT) {
    req.user = { uid: 'mock-admin', email: 'admin@heartsync.app', isAdmin: true, role: 'admin' };
    return next();
  }

  try {
    const auth = getAuth();
    if (!auth) return res.status(503).json({ error: 'Auth service unavailable' });
    const decodedToken = await auth.verifyIdToken(idToken);
    if (!decodedToken.isAdmin && !decodedToken.role) {
      return res.status(403).json({ error: 'Not authorized — admin access required' });
    }
    req.user = { ...decodedToken, role: decodedToken.role || 'admin' };
    next();
  } catch (err) {
    console.error('Token verification failed:', err.message);
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

function requireRole(...roles) {
  return (req, res, next) => {
    const userRole = req.user?.role || 'admin';
    if (!roles.includes(userRole) && userRole !== 'admin') {
      return res.status(403).json({ error: `Role '${userRole}' cannot access this resource` });
    }
    next();
  };
}

module.exports = adminMiddleware;
module.exports.requireRole = requireRole;

const express = require('express');
const router = express.Router();
const { getFirestore } = require('../firebase');

function db() { return getFirestore(); }

const MOCK_LOG = [
  { id: 'al1', action: 'grant_premium', targetCoupleId: 'couple-abc', adminEmail: 'admin@heartsync.app', adminRole: 'admin', detail: 'Manually granted premium — comp for support ticket', createdAt: new Date(Date.now() - 3600000 * 2).toISOString() },
  { id: 'al2', action: 'suspend_couple', targetCoupleId: 'couple-xyz', adminEmail: 'admin@heartsync.app', adminRole: 'admin', detail: 'Suspended for ToS violation — graphic content', createdAt: new Date(Date.now() - 3600000 * 8).toISOString() },
  { id: 'al3', action: 'remove_content', targetCoupleId: 'couple-def', adminEmail: 'support@heartsync.app', adminRole: 'support', detail: 'Removed reported memory image', createdAt: new Date(Date.now() - 3600000 * 24).toISOString() },
  { id: 'al4', action: 'toggle_flag', targetCoupleId: null, adminEmail: 'admin@heartsync.app', adminRole: 'admin', detail: 'Enabled feature flag: ai_monthly_recap (rollout 20%)', createdAt: new Date(Date.now() - 3600000 * 36).toISOString() },
  { id: 'al5', action: 'dismiss_report', targetCoupleId: 'couple-ghi', adminEmail: 'support@heartsync.app', adminRole: 'support', detail: 'Dismissed content report — false positive', createdAt: new Date(Date.now() - 3600000 * 48).toISOString() },
];

async function appendAuditLog(action, targetCoupleId, adminEmail, adminRole, detail) {
  const entry = { action, targetCoupleId: targetCoupleId || null, adminEmail, adminRole, detail, createdAt: new Date().toISOString() };
  try {
    if (db()) await db().collection('admin').doc('audit_log').collection('entries').add(entry);
  } catch {}
  return entry;
}

router.get('/', async (req, res) => {
  const { action, adminEmail, limit = 50 } = req.query;
  try {
    if (!db()) {
      let filtered = MOCK_LOG;
      if (action) filtered = filtered.filter(l => l.action === action);
      if (adminEmail) filtered = filtered.filter(l => l.adminEmail === adminEmail);
      return res.json(filtered.slice(0, Number(limit)));
    }
    let q = db().collection('admin').doc('audit_log').collection('entries').orderBy('createdAt', 'desc');
    if (action) q = q.where('action', '==', action);
    if (adminEmail) q = q.where('adminEmail', '==', adminEmail);
    const snap = await q.limit(Number(limit)).get();
    res.json(snap.docs.map(d => ({ id: d.id, ...d.data() })));
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.post('/', async (req, res) => {
  const { action, targetCoupleId, detail } = req.body;
  if (!action) return res.status(400).json({ error: 'action required' });
  const entry = await appendAuditLog(action, targetCoupleId, req.user?.email, req.user?.role || 'admin', detail);
  res.json(entry);
});

module.exports = router;
module.exports.appendAuditLog = appendAuditLog;

import React, { useState, useEffect } from 'react';
import { api } from '../lib/api';

export default function GDPR() {
  const [requests, setRequests] = useState([]);
  const [statusFilter, setStatusFilter] = useState('pending');
  const [loading, setLoading] = useState(true);
  const [processing, setProcessing] = useState({});
  const [result, setResult] = useState({});

  useEffect(() => {
    setLoading(true);
    const q = statusFilter !== 'all' ? `?status=${statusFilter}` : '';
    api(`/gdpr/requests${q}`).then(setRequests).finally(() => setLoading(false));
  }, [statusFilter]);

  async function handleExport(id) {
    setProcessing(p => ({ ...p, [id]: true }));
    try {
      const r = await api(`/gdpr/requests/${id}/export`, { method: 'POST' });
      setResult(res => ({ ...res, [id]: `Exported: ${JSON.stringify(r.exportData)}` }));
      setRequests(reqs => reqs.map(x => x.id === id ? { ...x, status: 'completed' } : x));
    } catch (e) { setResult(res => ({ ...res, [id]: 'Error: ' + e.message })); }
    setProcessing(p => ({ ...p, [id]: false }));
  }

  async function handleDelete(id, coupleId) {
    if (!confirm(`Permanently delete ALL data for couple ${coupleId}? This cannot be undone.`)) return;
    setProcessing(p => ({ ...p, [id]: true }));
    try {
      await api(`/gdpr/requests/${id}/delete`, { method: 'POST' });
      setResult(res => ({ ...res, [id]: 'All couple data permanently deleted.' }));
      setRequests(reqs => reqs.map(x => x.id === id ? { ...x, status: 'completed' } : x));
    } catch (e) { setResult(res => ({ ...res, [id]: 'Error: ' + e.message })); }
    setProcessing(p => ({ ...p, [id]: false }));
  }

  const s = styles;
  return (
    <div>
      <h1 style={s.h1}>GDPR / Data Requests</h1>
      <p style={s.sub}>Couples request data export or account deletion from the app settings screen. Fulfill and close out each request here.</p>

      <div style={{ background: 'rgba(248, 113, 113, 0.08)', border: '1px solid rgba(248,113,113,0.3)', borderRadius: 10, padding: '10px 16px', fontSize: 13, color: 'var(--color-danger)', marginBottom: 20 }}>
        ⚠️ Deletion is irreversible. It removes all Firestore documents and Storage files for the couple permanently via firebase-admin, not just setting status=suspended.
      </div>

      <div style={{ display: 'flex', gap: 8, marginBottom: 20 }}>
        {['pending', 'completed', 'all'].map(f => (
          <button key={f} onClick={() => setStatusFilter(f)} style={{ ...s.tabBtn, ...(statusFilter === f ? s.tabActive : {}) }}>{f.charAt(0).toUpperCase() + f.slice(1)}</button>
        ))}
      </div>

      <div style={s.card}>
        {loading ? (
          <div style={s.empty}>Loading…</div>
        ) : requests.length === 0 ? (
          <div style={s.empty}>No {statusFilter} requests</div>
        ) : (
          requests.map(req => (
            <div key={req.id} style={s.reqRow}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: 12 }}>
                <div>
                  <div style={{ display: 'flex', gap: 8, alignItems: 'center', marginBottom: 4 }}>
                    <span style={{ fontSize: 14, fontWeight: 700, fontFamily: 'monospace' }}>{req.coupleId}</span>
                    <span style={{ fontSize: 12, fontWeight: 700, padding: '2px 8px', borderRadius: 4, background: req.type === 'deletion' ? 'rgba(248,113,113,0.15)' : 'rgba(130,130,255,0.15)', color: req.type === 'deletion' ? 'var(--color-danger)' : '#818CF8' }}>
                      {req.type === 'deletion' ? '🗑 DELETION' : '📦 EXPORT'}
                    </span>
                    <span style={{ fontSize: 12, padding: '2px 8px', borderRadius: 4, background: req.status === 'completed' ? 'rgba(74,222,128,0.1)' : 'rgba(250,204,21,0.1)', color: req.status === 'completed' ? 'var(--color-success)' : 'var(--color-warning)' }}>
                      {req.status}
                    </span>
                  </div>
                  <div style={{ fontSize: 12, color: 'var(--color-text-muted)' }}>
                    Requested: {new Date(req.requestedAt).toLocaleString()}
                    {req.completedAt && ` · Completed: ${new Date(req.completedAt).toLocaleString()}`}
                  </div>
                </div>

                {req.status === 'pending' && (
                  <div style={{ display: 'flex', gap: 8 }}>
                    {req.type === 'export' && (
                      <button onClick={() => handleExport(req.id)} disabled={processing[req.id]} style={s.btn}>
                        {processing[req.id] ? 'Exporting…' : '📦 Export Data'}
                      </button>
                    )}
                    {req.type === 'deletion' && (
                      <button onClick={() => handleDelete(req.id, req.coupleId)} disabled={processing[req.id]} style={{ ...s.btn, background: 'var(--color-danger)' }}>
                        {processing[req.id] ? 'Deleting…' : '🗑 Delete All Data'}
                      </button>
                    )}
                  </div>
                )}
              </div>
              {result[req.id] && <div style={{ marginTop: 10, fontSize: 12, color: 'var(--color-text-muted)', background: 'var(--color-bg)', borderRadius: 6, padding: '8px 12px' }}>{result[req.id]}</div>}
            </div>
          ))
        )}
      </div>
    </div>
  );
}

const styles = {
  h1: { fontSize: 22, fontWeight: 700, marginBottom: 4 },
  sub: { color: 'var(--color-text-muted)', fontSize: 13, marginBottom: 16 },
  card: { background: 'var(--color-surface)', border: '1px solid var(--color-border)', borderRadius: 12, padding: 4 },
  reqRow: { padding: '16px 20px', borderBottom: '1px solid var(--color-border)' },
  btn: { background: 'var(--color-primary)', color: '#fff', border: 'none', borderRadius: 8, padding: '8px 16px', fontSize: 13, fontWeight: 600, cursor: 'pointer' },
  tabBtn: { background: 'var(--color-bg)', border: '1px solid var(--color-border)', borderRadius: 8, padding: '6px 14px', fontSize: 12, cursor: 'pointer', color: 'var(--color-text-muted)' },
  tabActive: { background: 'var(--color-primary-soft)', border: '1px solid var(--color-primary)', color: 'var(--color-primary)', fontWeight: 600 },
  empty: { padding: 40, textAlign: 'center', color: 'var(--color-text-muted)', fontSize: 13 },
};

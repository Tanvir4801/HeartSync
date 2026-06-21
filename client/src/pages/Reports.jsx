import React, { useEffect, useState } from 'react';
import { api } from '../lib/api';
import Card, { Badge } from '../components/Card';
import { Check, X } from 'lucide-react';

export default function Reports() {
  const [reports, setReports] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.reports.list().then(setReports).catch(console.error).finally(() => setLoading(false));
  }, []);

  async function handle(id, status) {
    try {
      await api.reports.update(id, status);
      setReports(r => r.map(rep => rep.id === id ? { ...rep, status } : rep));
    } catch (err) {
      alert(err.message);
    }
  }

  const pending = reports.filter(r => r.status === 'pending');
  const resolved = reports.filter(r => r.status !== 'pending');

  return (
    <div>
      <div style={{ marginBottom: 24 }}>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>Content Moderation</h1>
        <p style={{ fontSize: 14, color: 'var(--color-text-muted)' }}>Review and action reported content</p>
      </div>

      <div style={{ display: 'flex', gap: 12, marginBottom: 20 }}>
        <div style={{ padding: '8px 16px', background: 'rgba(248,113,113,0.1)', border: '1px solid rgba(248,113,113,0.3)', borderRadius: 'var(--radius)', fontSize: 13 }}>
          <span style={{ color: 'var(--color-danger)', fontWeight: 700 }}>{pending.length}</span>
          <span style={{ color: 'var(--color-text-muted)', marginLeft: 6 }}>pending</span>
        </div>
        <div style={{ padding: '8px 16px', background: 'var(--color-surface-2)', border: '1px solid var(--color-border)', borderRadius: 'var(--radius)', fontSize: 13 }}>
          <span style={{ color: 'var(--color-text)', fontWeight: 700 }}>{resolved.length}</span>
          <span style={{ color: 'var(--color-text-muted)', marginLeft: 6 }}>resolved</span>
        </div>
      </div>

      <Card>
        {loading ? (
          <div style={{ color: 'var(--color-text-muted)', fontSize: 14 }}>Loading reports…</div>
        ) : reports.length === 0 ? (
          <div style={{ textAlign: 'center', padding: 32, color: 'var(--color-text-muted)' }}>No reports found</div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            {reports.map(r => (
              <div key={r.id} style={{
                display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 16,
                padding: 16,
                background: 'var(--color-bg)',
                borderRadius: 'var(--radius)',
                border: `1px solid ${r.status === 'pending' ? 'rgba(248,113,113,0.3)' : 'var(--color-border)'}`,
              }}>
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', gap: 8, marginBottom: 6, alignItems: 'center', flexWrap: 'wrap' }}>
                    <Badge variant={r.status === 'pending' ? 'danger' : r.status === 'dismissed' ? 'default' : 'success'}>{r.status}</Badge>
                    <Badge variant="info">{r.contentType}</Badge>
                    <span style={{ fontSize: 12, color: 'var(--color-text-muted)' }}>Couple: {r.coupleId}</span>
                  </div>
                  <p style={{ fontSize: 14, color: 'var(--color-text)', marginBottom: 4 }}>{r.reason}</p>
                  <p style={{ fontSize: 12, color: 'var(--color-text-muted)' }}>Content ID: {r.contentId} · {new Date(r.reportedAt).toLocaleString()}</p>
                </div>
                {r.status === 'pending' && (
                  <div style={{ display: 'flex', gap: 8, flexShrink: 0 }}>
                    <button onClick={() => handle(r.id, 'removed')} style={{ padding: '6px 12px', background: 'rgba(248,113,113,0.15)', border: 'none', borderRadius: 6, color: 'var(--color-danger)', cursor: 'pointer', fontSize: 12, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 4 }}>
                      <X size={12} /> Remove
                    </button>
                    <button onClick={() => handle(r.id, 'dismissed')} style={{ padding: '6px 12px', background: 'var(--color-surface-2)', border: 'none', borderRadius: 6, color: 'var(--color-text-muted)', cursor: 'pointer', fontSize: 12, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 4 }}>
                      <Check size={12} /> Dismiss
                    </button>
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </Card>
    </div>
  );
}

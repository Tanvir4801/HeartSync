import React, { useState, useEffect } from 'react';
import { api } from '../lib/api';

const ACTION_LABELS = {
  grant_premium: { label: 'Grant Premium', color: 'var(--color-success)' },
  suspend_couple: { label: 'Suspend', color: 'var(--color-danger)' },
  remove_content: { label: 'Remove Content', color: 'var(--color-warning)' },
  toggle_flag: { label: 'Toggle Flag', color: 'var(--color-primary)' },
  dismiss_report: { label: 'Dismiss Report', color: 'var(--color-text-muted)' },
  data_export: { label: 'Data Export', color: '#818CF8' },
  data_deletion: { label: 'Data Deletion', color: 'var(--color-danger)' },
};

export default function AuditLog() {
  const [logs, setLogs] = useState([]);
  const [filter, setFilter] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    const q = filter ? `?action=${filter}` : '';
    api(`/audit${q}`).then(setLogs).finally(() => setLoading(false));
  }, [filter]);

  const s = styles;
  return (
    <div>
      <h1 style={s.h1}>Audit Log</h1>
      <p style={s.sub}>Every privileged action on the console — who, what, when, on which couple.</p>

      <div style={{ display: 'flex', gap: 8, marginBottom: 20, flexWrap: 'wrap' }}>
        <button onClick={() => setFilter('')} style={{ ...s.tabBtn, ...(filter === '' ? s.tabActive : {}) }}>All</button>
        {Object.keys(ACTION_LABELS).map(a => (
          <button key={a} onClick={() => setFilter(a)} style={{ ...s.tabBtn, ...(filter === a ? s.tabActive : {}), fontSize: 11 }}>
            {ACTION_LABELS[a].label}
          </button>
        ))}
      </div>

      <div style={s.card}>
        {loading ? (
          <div style={s.empty}>Loading…</div>
        ) : logs.length === 0 ? (
          <div style={s.empty}>No audit entries found</div>
        ) : (
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ borderBottom: '1px solid var(--color-border)' }}>
                {['Time', 'Admin', 'Role', 'Action', 'Couple', 'Detail'].map(h => (
                  <th key={h} style={s.th}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {logs.map(l => {
                const actionMeta = ACTION_LABELS[l.action] || { label: l.action, color: 'var(--color-text-muted)' };
                return (
                  <tr key={l.id} style={{ borderBottom: '1px solid var(--color-border)' }}>
                    <td style={s.td}><span style={{ fontSize: 11, color: 'var(--color-text-muted)' }}>{new Date(l.createdAt).toLocaleString()}</span></td>
                    <td style={s.td}><span style={{ fontSize: 13 }}>{l.adminEmail}</span></td>
                    <td style={s.td}><span style={{ fontSize: 11, background: l.adminRole === 'admin' ? 'var(--color-primary-soft)' : 'var(--color-bg)', color: l.adminRole === 'admin' ? 'var(--color-primary)' : 'var(--color-text-muted)', borderRadius: 4, padding: '2px 7px' }}>{l.adminRole}</span></td>
                    <td style={s.td}><span style={{ fontSize: 12, fontWeight: 600, color: actionMeta.color }}>{actionMeta.label}</span></td>
                    <td style={s.td}><span style={{ fontSize: 11, fontFamily: 'monospace', color: 'var(--color-text-muted)' }}>{l.targetCoupleId ? l.targetCoupleId.substring(0, 10) + '…' : '—'}</span></td>
                    <td style={{ ...s.td, maxWidth: 260 }}><span style={{ fontSize: 12, color: 'var(--color-text-muted)' }}>{l.detail}</span></td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}

const styles = {
  h1: { fontSize: 22, fontWeight: 700, marginBottom: 4 },
  sub: { color: 'var(--color-text-muted)', fontSize: 13, marginBottom: 20 },
  card: { background: 'var(--color-surface)', border: '1px solid var(--color-border)', borderRadius: 12, padding: 20 },
  th: { textAlign: 'left', fontSize: 11, color: 'var(--color-text-muted)', padding: '8px 12px', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.06em' },
  td: { padding: '12px 12px', verticalAlign: 'top' },
  tabBtn: { background: 'var(--color-bg)', border: '1px solid var(--color-border)', borderRadius: 8, padding: '6px 12px', fontSize: 12, cursor: 'pointer', color: 'var(--color-text-muted)' },
  tabActive: { background: 'var(--color-primary-soft)', border: '1px solid var(--color-primary)', color: 'var(--color-primary)', fontWeight: 600 },
  empty: { padding: 40, textAlign: 'center', color: 'var(--color-text-muted)', fontSize: 13 },
};

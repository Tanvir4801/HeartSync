import React, { useState, useEffect } from 'react';
import { api } from '../lib/api';

export default function Support() {
  const [tickets, setTickets] = useState([]);
  const [statusFilter, setStatusFilter] = useState('open');
  const [selected, setSelected] = useState(null);
  const [replyText, setReplyText] = useState('');
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);

  useEffect(() => {
    setLoading(true);
    api.support.tickets(statusFilter)
      .then(data => { setTickets(data); setSelected(null); })
      .finally(() => setLoading(false));
  }, [statusFilter]);

  async function sendReply(id) {
    if (!replyText.trim()) return;
    setSending(true);
    try {
      await api.support.reply(id, replyText);
      setReplyText('');
      setTickets(t => t.map(x => x.id === id ? { ...x, status: 'replied' } : x));
      if (selected?.id === id) setSelected(s => ({ ...s, status: 'replied' }));
    } catch (e) { alert(e.message); }
    setSending(false);
  }

  async function setStatus(id, status) {
    await api.support.setStatus(id, status);
    setTickets(t => t.map(x => x.id === id ? { ...x, status } : x));
    if (selected?.id === id) setSelected(s => ({ ...s, status }));
  }

  const statusColor = { open: 'var(--color-warning)', replied: 'var(--color-primary)', resolved: 'var(--color-success)' };
  const s = styles;

  return (
    <div>
      <h1 style={s.h1}>Support Inbox</h1>
      <p style={s.sub}>User-submitted tickets from the Flutter app settings screen.</p>

      <div style={{ display: 'flex', gap: 8, marginBottom: 20 }}>
        {['open', 'replied', 'resolved', 'all'].map(f => (
          <button key={f} onClick={() => setStatusFilter(f)} style={{ ...s.tabBtn, ...(statusFilter === f ? s.tabActive : {}) }}>{f.charAt(0).toUpperCase() + f.slice(1)}</button>
        ))}
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '320px 1fr', gap: 20, height: 'calc(100vh - 260px)' }}>
        <div style={{ ...s.card, overflow: 'auto', padding: 0 }}>
          {loading ? <div style={s.empty}>Loading…</div> : tickets.length === 0 ? <div style={s.empty}>No {statusFilter} tickets</div> : (
            tickets.map(t => (
              <div key={t.id} onClick={() => setSelected(t)} style={{ ...s.ticketRow, background: selected?.id === t.id ? 'var(--color-primary-soft)' : 'transparent', borderLeft: selected?.id === t.id ? '3px solid var(--color-primary)' : '3px solid transparent' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
                  <span style={{ fontSize: 12, fontWeight: 600, color: statusColor[t.status] || 'var(--color-text-muted)', textTransform: 'uppercase' }}>{t.status}</span>
                  <span style={{ fontSize: 11, color: 'var(--color-text-muted)' }}>{new Date(t.createdAt).toLocaleDateString()}</span>
                </div>
                <div style={{ fontSize: 13, fontWeight: 500, marginBottom: 2 }}>{t.userEmail || t.coupleId}</div>
                <div style={{ fontSize: 12, color: 'var(--color-text-muted)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{t.message}</div>
              </div>
            ))
          )}
        </div>

        <div style={s.card}>
          {!selected ? (
            <div style={s.empty}>← Select a ticket</div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
              <div style={{ marginBottom: 16, paddingBottom: 16, borderBottom: '1px solid var(--color-border)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <div>
                    <div style={{ fontWeight: 700, fontSize: 15 }}>{selected.userEmail}</div>
                    <div style={{ fontSize: 12, color: 'var(--color-text-muted)' }}>Couple: {selected.coupleId} · {new Date(selected.createdAt).toLocaleString()}</div>
                  </div>
                  <div style={{ display: 'flex', gap: 6 }}>
                    {selected.status !== 'resolved' && <button onClick={() => setStatus(selected.id, 'resolved')} style={{ ...s.btn, background: 'var(--color-success)' }}>✓ Resolve</button>}
                    {selected.status === 'resolved' && <button onClick={() => setStatus(selected.id, 'open')} style={{ ...s.btn, background: 'var(--color-bg)', color: 'var(--color-text-muted)', border: '1px solid var(--color-border)' }}>Reopen</button>}
                  </div>
                </div>
              </div>

              <div style={{ flex: 1, overflow: 'auto' }}>
                <div style={{ ...s.bubble, background: 'var(--color-bg)', marginBottom: 12 }}>
                  <div style={{ fontSize: 11, color: 'var(--color-text-muted)', marginBottom: 4 }}>User</div>
                  <div style={{ fontSize: 14, lineHeight: 1.6 }}>{selected.message}</div>
                </div>
                {(selected.replies || []).map((r, i) => (
                  <div key={i} style={{ ...s.bubble, background: 'var(--color-primary-soft)', border: '1px solid var(--color-primary)', marginBottom: 8 }}>
                    <div style={{ fontSize: 11, color: 'var(--color-primary)', marginBottom: 4 }}>Admin ({r.adminEmail}) · {new Date(r.createdAt).toLocaleString()}</div>
                    <div style={{ fontSize: 14 }}>{r.message}</div>
                  </div>
                ))}
              </div>

              {selected.status !== 'resolved' && (
                <div style={{ marginTop: 12, display: 'flex', gap: 8 }}>
                  <textarea value={replyText} onChange={e => setReplyText(e.target.value)} placeholder="Type a reply…" rows={3} style={{ ...s.input, flex: 1, resize: 'none' }} />
                  <button onClick={() => sendReply(selected.id)} disabled={sending || !replyText.trim()} style={s.btn}>{sending ? '…' : 'Send'}</button>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

const styles = {
  h1: { fontSize: 22, fontWeight: 700, marginBottom: 4 },
  sub: { color: 'var(--color-text-muted)', fontSize: 13, marginBottom: 20 },
  card: { background: 'var(--color-surface)', border: '1px solid var(--color-border)', borderRadius: 12, padding: 20 },
  ticketRow: { padding: '12px 16px', cursor: 'pointer', borderBottom: '1px solid var(--color-border)', transition: 'background 0.15s' },
  input: { background: 'var(--color-bg)', border: '1px solid var(--color-border)', borderRadius: 8, padding: '8px 12px', color: 'var(--color-text)', fontSize: 13, width: '100%', boxSizing: 'border-box' },
  btn: { background: 'var(--color-primary)', color: '#fff', border: 'none', borderRadius: 8, padding: '8px 16px', fontSize: 13, fontWeight: 600, cursor: 'pointer', whiteSpace: 'nowrap' },
  tabBtn: { background: 'var(--color-bg)', border: '1px solid var(--color-border)', borderRadius: 8, padding: '6px 14px', fontSize: 12, cursor: 'pointer', color: 'var(--color-text-muted)' },
  tabActive: { background: 'var(--color-primary-soft)', border: '1px solid var(--color-primary)', color: 'var(--color-primary)', fontWeight: 600 },
  empty: { display: 'flex', alignItems: 'center', justifyContent: 'center', height: 200, color: 'var(--color-text-muted)', fontSize: 13 },
  bubble: { borderRadius: 10, padding: '10px 14px', border: '1px solid var(--color-border)' },
};

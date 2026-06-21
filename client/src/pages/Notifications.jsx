import React, { useState, useEffect } from 'react';
import { api } from '../lib/api';
import { Send, Bell } from 'lucide-react';
import Card from '../components/Card';

export default function Notifications() {
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [tier, setTier] = useState('all');
  const [inactiveDays, setInactiveDays] = useState('');
  const [sendAt, setSendAt] = useState('');
  const [sending, setSending] = useState(false);
  const [result, setResult] = useState(null);
  const [history, setHistory] = useState([]);
  const [scheduled, setScheduled] = useState([]);
  const [tab, setTab] = useState('send');

  useEffect(() => {
    api.notifications.history().then(setHistory).catch(() => {});
    api.notifications.scheduled().then(setScheduled).catch(() => {});
  }, []);

  async function handleSend(e) {
    e.preventDefault();
    if (!title.trim() || !body.trim()) return;
    setSending(true);
    setResult(null);
    try {
      const opts = {};
      if (tier !== 'all') opts.tier = tier;
      if (inactiveDays) opts.inactiveDays = +inactiveDays;
      if (sendAt) opts.sendAt = sendAt;
      const res = await api.notifications.broadcast(title.trim(), body.trim(), opts);
      if (res.scheduled) {
        setResult({ success: true, message: `Scheduled for ${new Date(res.sendAt).toLocaleString()}` });
        setScheduled(s => [...s, { title: title.trim(), body: body.trim(), tier, sendAt, status: 'pending' }]);
      } else {
        setResult({ success: true, message: `Sent! ${res.mock ? '[demo mode] ' : ''}ID: ${res.messageId}` });
        setHistory(h => [{ title: title.trim(), body: body.trim(), tier, sentAt: new Date().toISOString(), mock: res.mock }, ...h]);
      }
      setTitle(''); setBody(''); setSendAt('');
    } catch (err) {
      setResult({ success: false, message: err.message });
    } finally {
      setSending(false);
    }
  }

  async function cancelScheduled(id) {
    await api.notifications.cancelScheduled(id);
    setScheduled(s => s.filter(x => x.id !== id));
  }

  const st = styles;

  return (
    <div>
      <div style={{ marginBottom: 24 }}>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>Push Notifications</h1>
        <p style={{ fontSize: 14, color: 'var(--color-text-muted)' }}>Broadcast with targeting by tier, inactivity, or schedule.</p>
      </div>

      <div style={{ display: 'flex', gap: 8, marginBottom: 20 }}>
        {[['send', '📤 Send'], ['scheduled', `⏰ Scheduled (${scheduled.length})`], ['history', '📋 History']].map(([k, label]) => (
          <button key={k} onClick={() => setTab(k)} style={{ ...st.tabBtn, ...(tab === k ? st.tabActive : {}) }}>{label}</button>
        ))}
      </div>

      {tab === 'send' && (
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20 }}>
          <Card>
            <h2 style={{ fontSize: 15, fontWeight: 600, marginBottom: 16, display: 'flex', alignItems: 'center', gap: 8 }}><Bell size={16} /> New Broadcast</h2>
            <form onSubmit={handleSend} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
              <div>
                <label style={st.label}>Title</label>
                <input value={title} onChange={e => setTitle(e.target.value)} placeholder="e.g. New feature: Love Journey Map!" maxLength={100} style={st.input} />
              </div>
              <div>
                <label style={st.label}>Message body</label>
                <textarea value={body} onChange={e => setBody(e.target.value)} placeholder="What do you want to tell your users?" rows={4} maxLength={300} style={{ ...st.input, resize: 'vertical' }} />
                <div style={{ fontSize: 12, color: 'var(--color-text-muted)', textAlign: 'right', marginTop: 4 }}>{body.length}/300</div>
              </div>

              <div style={{ background: 'var(--color-bg)', borderRadius: 10, padding: 14, border: '1px solid var(--color-border)' }}>
                <div style={{ fontSize: 11, fontWeight: 700, color: 'var(--color-text-muted)', marginBottom: 10, textTransform: 'uppercase', letterSpacing: '0.06em' }}>Targeting</div>
                <div style={{ marginBottom: 10 }}>
                  <label style={st.label}>User Tier</label>
                  <select value={tier} onChange={e => setTier(e.target.value)} style={st.input}>
                    <option value="all">All users</option>
                    <option value="free">Free tier only</option>
                    <option value="premium">Premium only</option>
                  </select>
                </div>
                <div>
                  <label style={st.label}>Inactive for N+ days (optional)</label>
                  <input type="number" value={inactiveDays} onChange={e => setInactiveDays(e.target.value)} placeholder="e.g. 7" style={st.input} min={1} />
                </div>
              </div>

              <div>
                <label style={st.label}>Schedule send (optional — blank = now)</label>
                <input type="datetime-local" value={sendAt} onChange={e => setSendAt(e.target.value)} style={st.input} />
              </div>

              {result && (
                <div style={{ padding: '10px 14px', borderRadius: 8, fontSize: 13, background: result.success ? 'rgba(74,222,128,0.1)' : 'rgba(248,113,113,0.1)', color: result.success ? 'var(--color-success)' : 'var(--color-danger)', border: `1px solid ${result.success ? 'rgba(74,222,128,0.3)' : 'rgba(248,113,113,0.3)'}` }}>
                  {result.message}
                </div>
              )}

              <button type="submit" disabled={sending || !title.trim() || !body.trim()} style={{ padding: 11, background: 'var(--color-primary)', color: '#fff', border: 'none', borderRadius: 8, fontWeight: 600, fontSize: 14, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, opacity: sending || !title.trim() || !body.trim() ? 0.6 : 1 }}>
                <Send size={15} />
                {sending ? 'Sending…' : sendAt ? '⏰ Schedule' : '📤 Send Now'}
              </button>
            </form>
          </Card>

          <Card>
            <h2 style={{ fontSize: 15, fontWeight: 600, marginBottom: 12 }}>Targeting Preview</h2>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginBottom: 20 }}>
              {[
                ['Topic', tier === 'all' ? 'all-users' : `${tier}-users`],
                ['Inactivity filter', inactiveDays ? `≥ ${inactiveDays} days` : 'None'],
                ['Send time', sendAt ? new Date(sendAt).toLocaleString() : 'Immediately'],
              ].map(([k, v]) => (
                <div key={k} style={{ display: 'flex', justifyContent: 'space-between', fontSize: 13, padding: '8px 0', borderBottom: '1px solid var(--color-border)' }}>
                  <span style={{ color: 'var(--color-text-muted)' }}>{k}</span>
                  <span style={{ fontWeight: 500, fontFamily: k === 'Topic' ? 'monospace' : undefined }}>{v}</span>
                </div>
              ))}
            </div>
            <h2 style={{ fontSize: 14, fontWeight: 600, marginBottom: 10 }}>Guidelines</h2>
            {[
              ['Use sparingly', 'Broadcast notifications are for announcements only. Over-sending damages retention.'],
              ['Irreversible', 'You cannot unsend a push notification once sent. Schedule to review before send.'],
            ].map(([title, desc]) => (
              <div key={title} style={{ padding: '10px 12px', background: 'var(--color-bg)', borderRadius: 8, border: '1px solid var(--color-border)', marginBottom: 8 }}>
                <div style={{ fontSize: 13, fontWeight: 600, marginBottom: 3 }}>{title}</div>
                <div style={{ fontSize: 12, color: 'var(--color-text-muted)', lineHeight: 1.5 }}>{desc}</div>
              </div>
            ))}
          </Card>
        </div>
      )}

      {tab === 'scheduled' && (
        <Card>
          <h3 style={{ fontSize: 14, fontWeight: 700, marginBottom: 16 }}>Pending Scheduled Sends</h3>
          {scheduled.length === 0 ? <div style={st.empty}>No scheduled notifications</div> : scheduled.map((n, i) => (
            <div key={n.id || i} style={st.notifRow}>
              <div>
                <div style={{ fontWeight: 600 }}>{n.title}</div>
                <div style={{ fontSize: 12, color: 'var(--color-text-muted)' }}>{n.body}</div>
                <div style={{ fontSize: 11, color: 'var(--color-warning)', marginTop: 4 }}>📅 {n.sendAt ? new Date(n.sendAt).toLocaleString() : ''} · {n.tier || 'all'}</div>
              </div>
              {n.id && <button onClick={() => cancelScheduled(n.id)} style={{ ...st.miniBtn, color: 'var(--color-danger)' }}>Cancel</button>}
            </div>
          ))}
        </Card>
      )}

      {tab === 'history' && (
        <Card>
          <h3 style={{ fontSize: 14, fontWeight: 700, marginBottom: 16 }}>Send History</h3>
          {history.length === 0 ? <div style={st.empty}>No sends yet</div> : history.map((n, i) => (
            <div key={i} style={st.notifRow}>
              <div>
                <div style={{ fontWeight: 600 }}>{n.title} {n.mock && <span style={{ fontSize: 10, background: 'var(--color-warning)', color: '#000', borderRadius: 3, padding: '1px 5px', marginLeft: 6 }}>DEMO</span>}</div>
                <div style={{ fontSize: 12, color: 'var(--color-text-muted)' }}>{n.body}</div>
                <div style={{ fontSize: 11, color: 'var(--color-text-muted)', marginTop: 4 }}>{n.sentAt ? new Date(n.sentAt).toLocaleString() : ''}</div>
              </div>
            </div>
          ))}
        </Card>
      )}
    </div>
  );
}

const styles = {
  input: { width: '100%', padding: '10px 12px', background: 'var(--color-bg)', border: '1px solid var(--color-border)', borderRadius: 8, color: 'var(--color-text)', fontSize: 14, outline: 'none', boxSizing: 'border-box' },
  label: { display: 'block', fontSize: 13, fontWeight: 500, marginBottom: 6, color: 'var(--color-text-muted)' },
  tabBtn: { background: 'var(--color-bg)', border: '1px solid var(--color-border)', borderRadius: 8, padding: '6px 14px', fontSize: 12, cursor: 'pointer', color: 'var(--color-text-muted)' },
  tabActive: { background: 'var(--color-primary-soft)', border: '1px solid var(--color-primary)', color: 'var(--color-primary)', fontWeight: 600 },
  notifRow: { display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px 0', borderBottom: '1px solid var(--color-border)' },
  miniBtn: { background: 'var(--color-bg)', border: '1px solid var(--color-border)', borderRadius: 6, padding: '4px 10px', fontSize: 12, cursor: 'pointer', color: 'var(--color-text-muted)' },
  empty: { padding: 32, textAlign: 'center', color: 'var(--color-text-muted)', fontSize: 13 },
};

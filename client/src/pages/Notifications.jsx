import React, { useState } from 'react';
import { api } from '../lib/api';
import Card from '../components/Card';
import { Send, Bell } from 'lucide-react';

export default function Notifications() {
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [sending, setSending] = useState(false);
  const [result, setResult] = useState(null);

  async function handleSend(e) {
    e.preventDefault();
    if (!title.trim() || !body.trim()) return;
    setSending(true);
    setResult(null);
    try {
      const res = await api.notifications.broadcast(title.trim(), body.trim());
      setResult({ success: true, message: `Sent! Message ID: ${res.messageId}${res.mock ? ' (demo mode)' : ''}` });
      setTitle('');
      setBody('');
    } catch (err) {
      setResult({ success: false, message: err.message });
    } finally {
      setSending(false);
    }
  }

  return (
    <div>
      <div style={{ marginBottom: 24 }}>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>Push Notifications</h1>
        <p style={{ fontSize: 14, color: 'var(--color-text-muted)' }}>Broadcast to all users via FCM topic</p>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20 }}>
        <Card>
          <h2 style={{ fontSize: 15, fontWeight: 600, marginBottom: 16, display: 'flex', alignItems: 'center', gap: 8 }}>
            <Bell size={16} />
            New Broadcast
          </h2>
          <form onSubmit={handleSend} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            <div>
              <label style={{ display: 'block', fontSize: 13, fontWeight: 500, marginBottom: 6, color: 'var(--color-text-muted)' }}>Title</label>
              <input
                value={title}
                onChange={e => setTitle(e.target.value)}
                placeholder="e.g. New feature: Love Journey Map!"
                maxLength={100}
                style={{ width: '100%', padding: '10px 12px', background: 'var(--color-bg)', border: '1px solid var(--color-border)', borderRadius: 'var(--radius)', color: 'var(--color-text)', fontSize: 14, outline: 'none' }}
              />
            </div>
            <div>
              <label style={{ display: 'block', fontSize: 13, fontWeight: 500, marginBottom: 6, color: 'var(--color-text-muted)' }}>Message body</label>
              <textarea
                value={body}
                onChange={e => setBody(e.target.value)}
                placeholder="What do you want to tell your users?"
                rows={4}
                maxLength={300}
                style={{ width: '100%', padding: '10px 12px', background: 'var(--color-bg)', border: '1px solid var(--color-border)', borderRadius: 'var(--radius)', color: 'var(--color-text)', fontSize: 14, outline: 'none', resize: 'vertical' }}
              />
              <div style={{ fontSize: 12, color: 'var(--color-text-muted)', textAlign: 'right', marginTop: 4 }}>{body.length}/300</div>
            </div>

            {result && (
              <div style={{ padding: '10px 14px', borderRadius: 'var(--radius)', fontSize: 13, background: result.success ? 'rgba(74,222,128,0.1)' : 'rgba(248,113,113,0.1)', color: result.success ? 'var(--color-success)' : 'var(--color-danger)', border: `1px solid ${result.success ? 'rgba(74,222,128,0.3)' : 'rgba(248,113,113,0.3)'}` }}>
                {result.message}
              </div>
            )}

            <button type="submit" disabled={sending || !title.trim() || !body.trim()} style={{ padding: '11px', background: 'var(--color-primary)', color: '#fff', border: 'none', borderRadius: 'var(--radius)', fontWeight: 600, fontSize: 14, opacity: sending || !title.trim() || !body.trim() ? 0.6 : 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}>
              <Send size={15} />
              {sending ? 'Sending…' : 'Broadcast to all users'}
            </button>
          </form>
        </Card>

        <Card>
          <h2 style={{ fontSize: 15, fontWeight: 600, marginBottom: 12 }}>Guidelines</h2>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {[
              ['Use sparingly', 'Broadcast notifications are for announcements only. Over-sending damages retention.'],
              ['Per-couple notifications', 'Hugs, note unlocks, and messages fire automatically via Cloud Functions — do not use this for those.'],
              ['Topic subscription', 'Every device subscribes to the all-users FCM topic on launch. This send reaches all.'],
              ['Irreversible', 'You cannot unsend a push notification once sent.'],
            ].map(([title, desc]) => (
              <div key={title} style={{ padding: '10px 12px', background: 'var(--color-bg)', borderRadius: 'var(--radius)', border: '1px solid var(--color-border)' }}>
                <div style={{ fontSize: 13, fontWeight: 600, marginBottom: 3 }}>{title}</div>
                <div style={{ fontSize: 13, color: 'var(--color-text-muted)', lineHeight: 1.5 }}>{desc}</div>
              </div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  );
}

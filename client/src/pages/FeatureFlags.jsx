import React, { useEffect, useState } from 'react';
import { api } from '../lib/api';
import Card from '../components/Card';

export default function FeatureFlags() {
  const [flags, setFlags] = useState([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState({});
  const [msg, setMsg] = useState('');

  useEffect(() => {
    api.flags.list().then(setFlags).catch(console.error).finally(() => setLoading(false));
  }, []);

  async function update(id, field, value) {
    const flag = flags.find(f => f.id === id);
    if (!flag) return;
    const updated = { ...flag, [field]: value };
    setFlags(f => f.map(fl => fl.id === id ? updated : fl));
    setSaving(s => ({ ...s, [id]: true }));
    try {
      await api.flags.update(id, updated.enabled, updated.rolloutPercent);
      setMsg(`Flag "${id}" updated`);
    } catch (err) {
      setMsg(`Error: ${err.message}`);
    } finally {
      setSaving(s => ({ ...s, [id]: false }));
    }
  }

  return (
    <div>
      <div style={{ marginBottom: 24 }}>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>Feature Flags</h1>
        <p style={{ fontSize: 14, color: 'var(--color-text-muted)' }}>Toggle features and control rollout percentages</p>
      </div>

      {msg && (
        <div style={{ marginBottom: 16, padding: '10px 14px', background: 'var(--color-primary-soft)', border: '1px solid var(--color-primary)', borderRadius: 'var(--radius)', fontSize: 13, color: 'var(--color-primary)' }}>
          {msg}
        </div>
      )}

      <Card style={{ padding: 0, overflow: 'hidden' }}>
        {loading ? (
          <div style={{ padding: 24, color: 'var(--color-text-muted)', fontSize: 14 }}>Loading…</div>
        ) : (
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ borderBottom: '1px solid var(--color-border)' }}>
                {['Flag', 'Description', 'Enabled', 'Rollout %', 'Status'].map(h => (
                  <th key={h} style={{ padding: '12px 20px', textAlign: 'left', fontSize: 12, fontWeight: 600, color: 'var(--color-text-muted)' }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {flags.map(flag => (
                <tr key={flag.id} style={{ borderBottom: '1px solid var(--color-border)' }}>
                  <td style={{ padding: '14px 20px', fontFamily: 'monospace', fontSize: 13, fontWeight: 600 }}>{flag.id}</td>
                  <td style={{ padding: '14px 20px', fontSize: 13, color: 'var(--color-text-muted)' }}>{flag.description}</td>
                  <td style={{ padding: '14px 20px' }}>
                    <button
                      onClick={() => update(flag.id, 'enabled', !flag.enabled)}
                      disabled={saving[flag.id]}
                      style={{
                        width: 44, height: 24, borderRadius: 12, border: 'none', cursor: 'pointer',
                        background: flag.enabled ? 'var(--color-success)' : 'var(--color-border)',
                        position: 'relative', transition: 'background 0.2s',
                      }}
                    >
                      <div style={{
                        width: 18, height: 18, borderRadius: '50%', background: '#fff',
                        position: 'absolute', top: 3,
                        left: flag.enabled ? 23 : 3,
                        transition: 'left 0.2s',
                        boxShadow: '0 1px 3px rgba(0,0,0,0.3)',
                      }} />
                    </button>
                  </td>
                  <td style={{ padding: '14px 20px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                      <input
                        type="range" min={0} max={100} value={flag.rolloutPercent}
                        onChange={e => update(flag.id, 'rolloutPercent', parseInt(e.target.value))}
                        disabled={!flag.enabled}
                        style={{ width: 100, accentColor: 'var(--color-primary)', opacity: flag.enabled ? 1 : 0.4 }}
                      />
                      <span style={{ fontSize: 13, fontWeight: 600, minWidth: 36 }}>{flag.rolloutPercent}%</span>
                    </div>
                  </td>
                  <td style={{ padding: '14px 20px' }}>
                    <span style={{
                      display: 'inline-block', padding: '2px 8px', borderRadius: 20, fontSize: 11, fontWeight: 600, textTransform: 'uppercase',
                      background: !flag.enabled ? 'var(--color-surface-2)' : flag.rolloutPercent === 100 ? 'rgba(74,222,128,0.15)' : 'rgba(250,204,21,0.15)',
                      color: !flag.enabled ? 'var(--color-text-muted)' : flag.rolloutPercent === 100 ? 'var(--color-success)' : 'var(--color-warning)',
                    }}>
                      {!flag.enabled ? 'Off' : flag.rolloutPercent === 100 ? 'Full rollout' : `${flag.rolloutPercent}% rollout`}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </Card>

      <div style={{ marginTop: 16, padding: '12px 16px', background: 'var(--color-surface-2)', borderRadius: 'var(--radius)', fontSize: 13, color: 'var(--color-text-muted)' }}>
        The Flutter app reads <code style={{ background: 'var(--color-bg)', padding: '1px 4px', borderRadius: 4 }}>admin/feature_flags/</code> on launch to decide which features to show.
        Changes here take effect on the next app launch (no app store update needed).
      </div>
    </div>
  );
}

import React, { useState, useEffect } from 'react';
import { api } from '../lib/api';

const defaultTheme = { id: '', name: '', isPremium: false, colors: { primary: '#F2A65A', secondary: '#E8927C', accent: '#9B8AC4', bg: '#1C1B33' } };

export default function Themes() {
  const [themes, setThemes] = useState([]);
  const [badges, setBadges] = useState([]);
  const [themeForm, setThemeForm] = useState(defaultTheme);
  const [badgeForm, setBadgeForm] = useState({ id: '', name: '', icon: '🏅', unlockCondition: '', xpThreshold: 0, streakThreshold: 0 });
  const [tab, setTab] = useState('themes');
  const [saving, setSaving] = useState(false);
  const [msg, setMsg] = useState('');

  useEffect(() => {
    api('/themes/themes').then(setThemes).catch(() => {});
    api('/themes/badges').then(setBadges).catch(() => {});
  }, []);

  async function saveTheme(e) {
    e.preventDefault();
    if (!themeForm.id || !themeForm.name) return;
    setSaving(true);
    try {
      const saved = await api('/themes/themes', { method: 'POST', body: JSON.stringify(themeForm) });
      setThemes(t => { const i = t.findIndex(x => x.id === saved.id); return i >= 0 ? t.map((x, j) => j === i ? saved : x) : [...t, saved]; });
      setThemeForm(defaultTheme);
      setMsg('Theme saved.');
    } catch (e) { setMsg('Error: ' + e.message); }
    setSaving(false);
  }

  async function deleteTheme(id) {
    await api(`/themes/themes/${id}`, { method: 'DELETE' });
    setThemes(t => t.filter(x => x.id !== id));
  }

  async function saveBadge(e) {
    e.preventDefault();
    if (!badgeForm.id || !badgeForm.name) return;
    setSaving(true);
    try {
      const saved = await api('/themes/badges', { method: 'POST', body: JSON.stringify(badgeForm) });
      setBadges(b => { const i = b.findIndex(x => x.id === saved.id); return i >= 0 ? b.map((x, j) => j === i ? saved : x) : [...b, saved]; });
      setBadgeForm({ id: '', name: '', icon: '🏅', unlockCondition: '', xpThreshold: 0, streakThreshold: 0 });
      setMsg('Badge saved.');
    } catch (e) { setMsg('Error: ' + e.message); }
    setSaving(false);
  }

  async function deleteBadge(id) {
    await api(`/themes/badges/${id}`, { method: 'DELETE' });
    setBadges(b => b.filter(x => x.id !== id));
  }

  const s = styles;
  return (
    <div>
      <h1 style={s.h1}>Themes & Badges</h1>
      <p style={s.sub}>Manage couple themes and achievement badges. Flutter reads these collections directly — no app update needed.</p>

      <div style={{ display: 'flex', gap: 8, marginBottom: 24 }}>
        {['themes', 'badges'].map(t => (
          <button key={t} onClick={() => setTab(t)} style={{ ...s.tabBtn, ...(tab === t ? s.tabActive : {}) }}>{t === 'themes' ? '🎨 Themes' : '🏅 Badges'}</button>
        ))}
      </div>

      {msg && <div style={s.toast}>{msg}</div>}

      {tab === 'themes' && (
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24 }}>
          <div style={s.card}>
            <h3 style={s.cardTitle}>{themeForm.id && themes.find(t => t.id === themeForm.id) ? 'Edit Theme' : 'New Theme'}</h3>
            <form onSubmit={saveTheme} style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              <input placeholder="Theme ID (e.g. horizon)" value={themeForm.id} onChange={e => setThemeForm(f => ({ ...f, id: e.target.value }))} style={s.input} />
              <input placeholder="Display Name" value={themeForm.name} onChange={e => setThemeForm(f => ({ ...f, name: e.target.value }))} style={s.input} />
              <label style={s.check}><input type="checkbox" checked={themeForm.isPremium} onChange={e => setThemeForm(f => ({ ...f, isPremium: e.target.checked }))} /> Premium only</label>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
                {['primary', 'secondary', 'accent', 'bg'].map(k => (
                  <div key={k}>
                    <label style={s.label}>{k}</label>
                    <input type="color" value={themeForm.colors[k]} onChange={e => setThemeForm(f => ({ ...f, colors: { ...f.colors, [k]: e.target.value } }))} style={{ ...s.input, height: 36, padding: 4 }} />
                  </div>
                ))}
              </div>
              <button type="submit" disabled={saving} style={s.btn}>{saving ? 'Saving…' : 'Save Theme'}</button>
            </form>
          </div>

          <div style={s.card}>
            <h3 style={s.cardTitle}>All Themes ({themes.length})</h3>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {themes.map(t => (
                <div key={t.id} style={s.row}>
                  <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
                    {['primary', 'secondary', 'accent', 'bg'].map(k => (
                      <div key={k} style={{ width: 16, height: 16, borderRadius: 4, background: t.colors?.[k] || '#888', border: '1px solid rgba(255,255,255,0.1)' }} />
                    ))}
                    <span style={{ fontWeight: 600, fontSize: 13 }}>{t.name}</span>
                    {t.isPremium && <span style={s.badge}>PREMIUM</span>}
                  </div>
                  <div style={{ display: 'flex', gap: 6 }}>
                    <button onClick={() => setThemeForm(t)} style={s.miniBtn}>Edit</button>
                    <button onClick={() => deleteTheme(t.id)} style={{ ...s.miniBtn, color: 'var(--color-danger)' }}>Delete</button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {tab === 'badges' && (
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24 }}>
          <div style={s.card}>
            <h3 style={s.cardTitle}>New / Edit Badge</h3>
            <form onSubmit={saveBadge} style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              <input placeholder="Badge ID (e.g. streak-30)" value={badgeForm.id} onChange={e => setBadgeForm(f => ({ ...f, id: e.target.value }))} style={s.input} />
              <input placeholder="Display Name" value={badgeForm.name} onChange={e => setBadgeForm(f => ({ ...f, name: e.target.value }))} style={s.input} />
              <input placeholder="Icon emoji (e.g. 🏆)" value={badgeForm.icon} onChange={e => setBadgeForm(f => ({ ...f, icon: e.target.value }))} style={s.input} />
              <input placeholder="Unlock condition description" value={badgeForm.unlockCondition} onChange={e => setBadgeForm(f => ({ ...f, unlockCondition: e.target.value }))} style={s.input} />
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
                <div><label style={s.label}>XP Threshold</label><input type="number" value={badgeForm.xpThreshold} onChange={e => setBadgeForm(f => ({ ...f, xpThreshold: +e.target.value }))} style={s.input} /></div>
                <div><label style={s.label}>Streak Threshold</label><input type="number" value={badgeForm.streakThreshold} onChange={e => setBadgeForm(f => ({ ...f, streakThreshold: +e.target.value }))} style={s.input} /></div>
              </div>
              <button type="submit" disabled={saving} style={s.btn}>{saving ? 'Saving…' : 'Save Badge'}</button>
            </form>
          </div>

          <div style={s.card}>
            <h3 style={s.cardTitle}>All Badges ({badges.length})</h3>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {badges.map(b => (
                <div key={b.id} style={s.row}>
                  <div>
                    <span style={{ fontSize: 20, marginRight: 8 }}>{b.icon}</span>
                    <span style={{ fontWeight: 600, fontSize: 13 }}>{b.name}</span>
                    <div style={{ fontSize: 11, color: 'var(--color-text-muted)', marginTop: 2 }}>{b.unlockCondition}</div>
                  </div>
                  <div style={{ display: 'flex', gap: 6 }}>
                    <button onClick={() => setBadgeForm(b)} style={s.miniBtn}>Edit</button>
                    <button onClick={() => deleteBadge(b.id)} style={{ ...s.miniBtn, color: 'var(--color-danger)' }}>Delete</button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

const styles = {
  h1: { fontSize: 22, fontWeight: 700, marginBottom: 4 },
  sub: { color: 'var(--color-text-muted)', fontSize: 13, marginBottom: 24 },
  card: { background: 'var(--color-surface)', border: '1px solid var(--color-border)', borderRadius: 12, padding: 20 },
  cardTitle: { fontSize: 14, fontWeight: 700, marginBottom: 16 },
  input: { background: 'var(--color-bg)', border: '1px solid var(--color-border)', borderRadius: 8, padding: '8px 12px', color: 'var(--color-text)', fontSize: 13, width: '100%', boxSizing: 'border-box' },
  label: { fontSize: 11, color: 'var(--color-text-muted)', marginBottom: 4, display: 'block' },
  btn: { background: 'var(--color-primary)', color: '#fff', border: 'none', borderRadius: 8, padding: '10px 20px', fontSize: 13, fontWeight: 600, cursor: 'pointer' },
  miniBtn: { background: 'var(--color-bg)', border: '1px solid var(--color-border)', borderRadius: 6, padding: '4px 10px', fontSize: 12, cursor: 'pointer', color: 'var(--color-text-muted)' },
  row: { display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '10px 12px', background: 'var(--color-bg)', borderRadius: 8, border: '1px solid var(--color-border)' },
  badge: { background: 'var(--color-warning)', color: '#000', borderRadius: 4, padding: '1px 6px', fontSize: 10, fontWeight: 700 },
  tabBtn: { background: 'var(--color-bg)', border: '1px solid var(--color-border)', borderRadius: 8, padding: '7px 16px', fontSize: 13, cursor: 'pointer', color: 'var(--color-text-muted)' },
  tabActive: { background: 'var(--color-primary-soft)', border: '1px solid var(--color-primary)', color: 'var(--color-primary)', fontWeight: 600 },
  check: { display: 'flex', alignItems: 'center', gap: 8, fontSize: 13, color: 'var(--color-text-muted)', cursor: 'pointer' },
  toast: { background: 'var(--color-primary-soft)', border: '1px solid var(--color-primary)', borderRadius: 8, padding: '8px 14px', fontSize: 13, color: 'var(--color-primary)', marginBottom: 16 },
};

import React, { useState, useEffect } from 'react';
import { api } from '../lib/api';

function FunnelBar({ label, count, max, color }) {
  const pct = max ? Math.round(count / max * 100) : 0;
  return (
    <div style={{ marginBottom: 14 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 5 }}>
        <span style={{ fontSize: 13, fontWeight: 500 }}>{label}</span>
        <span style={{ fontSize: 13, color: 'var(--color-text-muted)' }}>{count.toLocaleString()} <span style={{ color, fontWeight: 600 }}>({pct}%)</span></span>
      </div>
      <div style={{ height: 10, background: 'var(--color-bg)', borderRadius: 6, overflow: 'hidden' }}>
        <div style={{ height: '100%', width: `${pct}%`, background: color, borderRadius: 6, transition: 'width 0.6s ease' }} />
      </div>
    </div>
  );
}

function MiniChart({ weeks, field, color }) {
  const vals = weeks.map(w => w[field]);
  const max = Math.max(...vals, 1);
  return (
    <div style={{ display: 'flex', alignItems: 'flex-end', gap: 3, height: 48 }}>
      {vals.map((v, i) => (
        <div key={i} title={`${weeks[i].label}: ${v}`} style={{ flex: 1, height: `${v / max * 100}%`, minHeight: 2, background: color, borderRadius: '2px 2px 0 0', opacity: 0.8 }} />
      ))}
    </div>
  );
}

export default function Analytics() {
  const [funnel, setFunnel] = useState([]);
  const [dropoff, setDropoff] = useState({});
  const [retention, setRetention] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedWeek, setSelectedWeek] = useState(null);

  useEffect(() => {
    Promise.all([api.analytics.funnel(), api.analytics.retention()])
      .then(([f, r]) => { setFunnel(f.funnel || []); setDropoff(f.dropoff || {}); setRetention(r.retention || []); })
      .finally(() => setLoading(false));
  }, []);

  const lastWeek = funnel[funnel.length - 1] || {};
  const s = styles;

  if (loading) return <div style={s.loading}>Loading analytics…</div>;

  return (
    <div>
      <h1 style={s.h1}>Funnel & Retention</h1>
      <p style={s.sub}>Where couples drop off, week over week.</p>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 16, marginBottom: 24 }}>
        {[
          { label: 'Signup → Linked', value: dropoff.signupToLinked, color: 'var(--color-warning)' },
          { label: 'Linked → First Memory', value: dropoff.linkedToMemory, color: 'var(--color-primary)' },
          { label: 'Memory → Premium', value: dropoff.memoryToPremium, color: 'var(--color-success)' },
        ].map(d => (
          <div key={d.label} style={s.statCard}>
            <div style={{ fontSize: 11, color: 'var(--color-text-muted)', marginBottom: 4 }}>Drop-off</div>
            <div style={{ fontSize: 32, fontWeight: 800, color: d.color }}>{d.value ?? '—'}%</div>
            <div style={{ fontSize: 13, color: 'var(--color-text-muted)' }}>{d.label}</div>
          </div>
        ))}
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20, marginBottom: 24 }}>
        <div style={s.card}>
          <h3 style={s.cardTitle}>This Week's Funnel</h3>
          <FunnelBar label="Signups" count={lastWeek.signups || 0} max={lastWeek.signups || 1} color="var(--color-primary)" />
          <FunnelBar label="Couple Linked" count={lastWeek.linked || 0} max={lastWeek.signups || 1} color="var(--color-warning)" />
          <FunnelBar label="First Memory Added" count={lastWeek.firstMemory || 0} max={lastWeek.signups || 1} color="#818CF8" />
          <FunnelBar label="Premium Conversion" count={lastWeek.premium || 0} max={lastWeek.signups || 1} color="var(--color-success)" />
        </div>

        <div style={s.card}>
          <h3 style={s.cardTitle}>Retention Rates</h3>
          {retention.map(r => (
            <div key={r.label} style={{ marginBottom: 14 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 5 }}>
                <span style={{ fontSize: 13, fontWeight: 500 }}>{r.label}</span>
                <span style={{ fontSize: 13, fontWeight: 700, color: r.rate > 50 ? 'var(--color-success)' : r.rate > 25 ? 'var(--color-warning)' : 'var(--color-danger)' }}>{r.rate}%</span>
              </div>
              <div style={{ height: 8, background: 'var(--color-bg)', borderRadius: 4, overflow: 'hidden' }}>
                <div style={{ height: '100%', width: `${r.rate}%`, background: r.rate > 50 ? 'var(--color-success)' : r.rate > 25 ? 'var(--color-warning)' : 'var(--color-danger)', borderRadius: 4 }} />
              </div>
            </div>
          ))}
        </div>
      </div>

      <div style={s.card}>
        <h3 style={s.cardTitle}>Week-over-Week Trend</h3>
        {funnel.length > 0 && (
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr 1fr', gap: 20 }}>
            {[
              { label: 'Signups', field: 'signups', color: 'var(--color-primary)' },
              { label: 'Linked', field: 'linked', color: 'var(--color-warning)' },
              { label: 'First Memory', field: 'firstMemory', color: '#818CF8' },
              { label: 'Premium', field: 'premium', color: 'var(--color-success)' },
            ].map(m => (
              <div key={m.field}>
                <div style={{ fontSize: 11, color: 'var(--color-text-muted)', marginBottom: 8 }}>{m.label}</div>
                <MiniChart weeks={funnel} field={m.field} color={m.color} />
                <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6 }}>
                  {funnel.map((w, i) => <span key={i} style={{ fontSize: 9, color: 'var(--color-text-muted)' }}>{w.label}</span>)}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

const styles = {
  h1: { fontSize: 22, fontWeight: 700, marginBottom: 4 },
  sub: { color: 'var(--color-text-muted)', fontSize: 13, marginBottom: 24 },
  card: { background: 'var(--color-surface)', border: '1px solid var(--color-border)', borderRadius: 12, padding: 20 },
  statCard: { background: 'var(--color-surface)', border: '1px solid var(--color-border)', borderRadius: 12, padding: 20 },
  cardTitle: { fontSize: 14, fontWeight: 700, marginBottom: 16 },
  loading: { padding: 40, textAlign: 'center', color: 'var(--color-text-muted)' },
};

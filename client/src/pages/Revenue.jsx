import React, { useEffect, useState } from 'react';
import { api } from '../lib/api';
import Card from '../components/Card';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts';

const typeColors = {
  INITIAL_PURCHASE: 'var(--color-success)',
  RENEWAL:          'var(--color-info)',
  CANCELLATION:     'var(--color-danger)',
  PRODUCT_CHANGE:   'var(--color-warning)',
};

function buildChartData(events) {
  const byMonth = {};
  events.forEach(e => {
    if (!e.date || e.amount <= 0) return;
    const [year, month] = e.date.split('-');
    const key = `${year}-${month}`;
    const label = new Date(`${year}-${month}-01`).toLocaleString('default', { month: 'short' });
    if (!byMonth[key]) byMonth[key] = { month: label, revenue: 0 };
    byMonth[key].revenue += Number(e.amount);
  });
  return Object.entries(byMonth)
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([, v]) => ({ ...v, revenue: parseFloat(v.revenue.toFixed(2)) }));
}

export default function Revenue() {
  const [events, setEvents] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.revenue.events()
      .then(r => setEvents(r.events || []))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  const chartData   = buildChartData(events);
  const totalRev    = events.filter(e => e.amount > 0).reduce((s, e) => s + Number(e.amount), 0);
  const purchases   = events.filter(e => e.type === 'INITIAL_PURCHASE').length;
  const renewals    = events.filter(e => e.type === 'RENEWAL').length;
  const churned     = events.filter(e => e.type === 'CANCELLATION').length;

  return (
    <div>
      <div style={{ marginBottom: 24 }}>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>Subscription & Revenue</h1>
        <p style={{ fontSize: 14, color: 'var(--color-text-muted)' }}>RevenueCat events and revenue overview</p>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(160px, 1fr))', gap: 16, marginBottom: 24 }}>
        {[
          { label: 'Total Revenue',  value: `₹${totalRev.toFixed(0)}`, color: '#4ade80' },
          { label: 'New Purchases',  value: purchases,                  color: '#e05c7e' },
          { label: 'Renewals',       value: renewals,                   color: '#60a5fa' },
          { label: 'Cancellations',  value: churned,                    color: '#f87171' },
        ].map(s => (
          <div key={s.label} className="stat-card">
            <div style={{ position: 'absolute', top: -16, right: -16, width: 60, height: 60, borderRadius: '50%', background: s.color, opacity: 0.08, filter: 'blur(16px)', pointerEvents: 'none' }} />
            <div style={{ fontSize: 12, color: 'var(--color-text-muted)', marginBottom: 10, position: 'relative' }}>{s.label}</div>
            <div style={{ fontSize: 28, fontWeight: 800, color: s.color, lineHeight: 1, position: 'relative', letterSpacing: '-0.02em' }}>{s.value}</div>
          </div>
        ))}
      </div>

      <Card style={{ marginBottom: 20 }}>
        <h2 style={{ fontSize: 15, fontWeight: 600, marginBottom: 16 }}>Revenue (₹) — by Month</h2>
        {loading ? (
          <div style={{ color: 'var(--color-text-muted)', fontSize: 14 }}>Loading…</div>
        ) : chartData.length === 0 ? (
          <div style={{ color: 'var(--color-text-muted)', fontSize: 14, padding: 24, textAlign: 'center' }}>No revenue data yet</div>
        ) : (
          <ResponsiveContainer width="100%" height={220}>
            <BarChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" stroke="var(--color-border)" />
              <XAxis dataKey="month" tick={{ fill: 'var(--color-text-muted)', fontSize: 12 }} tickLine={false} axisLine={false} />
              <YAxis tick={{ fill: 'var(--color-text-muted)', fontSize: 12 }} tickLine={false} axisLine={false} />
              <Tooltip
                contentStyle={{ background: 'var(--color-surface-2)', border: '1px solid var(--color-border)', borderRadius: 8 }}
                formatter={(v) => [`₹${v}`, 'Revenue']}
              />
              <Bar dataKey="revenue" fill="var(--color-primary)" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        )}
      </Card>

      <Card>
        <h2 style={{ fontSize: 15, fontWeight: 600, marginBottom: 16 }}>Recent RevenueCat Events</h2>
        {loading ? (
          <div style={{ color: 'var(--color-text-muted)', fontSize: 14 }}>Loading…</div>
        ) : events.length === 0 ? (
          <div style={{ textAlign: 'center', padding: 32, color: 'var(--color-text-muted)', fontSize: 13 }}>No events yet. Connect RevenueCat webhook to start streaming data.</div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column' }}>
            {events.map((e, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 0', borderBottom: i < events.length - 1 ? '1px solid var(--color-border)' : 'none' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                  <span style={{ display: 'inline-block', padding: '2px 8px', borderRadius: 20, fontSize: 11, fontWeight: 600, background: (typeColors[e.type] || 'var(--color-text-muted)') + '22', color: typeColors[e.type] || 'var(--color-text-muted)', textTransform: 'uppercase', whiteSpace: 'nowrap' }}>
                    {(e.type || '').replace(/_/g, ' ')}
                  </span>
                  <span style={{ fontSize: 13, color: 'var(--color-text-muted)' }}>{e.coupleId} · {e.product}</span>
                </div>
                <div style={{ textAlign: 'right', flexShrink: 0 }}>
                  <div style={{ fontSize: 14, fontWeight: 600, color: e.amount > 0 ? 'var(--color-success)' : 'var(--color-text-muted)' }}>
                    {e.amount > 0 ? `₹${e.amount}` : '—'}
                  </div>
                  <div style={{ fontSize: 12, color: 'var(--color-text-muted)' }}>{e.date}</div>
                </div>
              </div>
            ))}
          </div>
        )}
        <p style={{ fontSize: 12, color: 'var(--color-text-muted)', marginTop: 16 }}>
          Live events require <code style={{ background: 'var(--color-bg)', padding: '1px 4px', borderRadius: 4 }}>REVENUECAT_WEBHOOK_SECRET</code> to be configured.
        </p>
      </Card>
    </div>
  );
}

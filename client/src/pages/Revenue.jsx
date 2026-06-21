import React from 'react';
import Card from '../components/Card';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts';

const mockEvents = [
  { type: 'INITIAL_PURCHASE', coupleId: 'c001', amount: 99, product: 'Premium Monthly', date: '2024-06-20' },
  { type: 'RENEWAL', coupleId: 'c003', amount: 999, product: 'Lifetime', date: '2024-06-19' },
  { type: 'RENEWAL', coupleId: 'c001', amount: 99, product: 'Premium Monthly', date: '2024-06-15' },
  { type: 'CANCELLATION', coupleId: 'c005', amount: 0, product: 'Premium Monthly', date: '2024-06-14' },
  { type: 'INITIAL_PURCHASE', coupleId: 'c002', amount: 99, product: 'Premium Monthly', date: '2024-06-12' },
];

const chartData = [
  { month: 'Jan', revenue: 1287 },
  { month: 'Feb', revenue: 1890 },
  { month: 'Mar', revenue: 2341 },
  { month: 'Apr', revenue: 2100 },
  { month: 'May', revenue: 3200 },
  { month: 'Jun', revenue: 4120 },
];

const typeColors = {
  INITIAL_PURCHASE: 'var(--color-success)',
  RENEWAL: 'var(--color-info)',
  CANCELLATION: 'var(--color-danger)',
  PRODUCT_CHANGE: 'var(--color-warning)',
};

export default function Revenue() {
  return (
    <div>
      <div style={{ marginBottom: 24 }}>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>Subscription & Revenue</h1>
        <p style={{ fontSize: 14, color: 'var(--color-text-muted)' }}>RevenueCat events and revenue overview</p>
      </div>

      <Card style={{ marginBottom: 20 }}>
        <h2 style={{ fontSize: 15, fontWeight: 600, marginBottom: 16 }}>Revenue (₹) — 2024</h2>
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
      </Card>

      <Card>
        <h2 style={{ fontSize: 15, fontWeight: 600, marginBottom: 16 }}>Recent RevenueCat Events</h2>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {mockEvents.map((e, i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 0', borderBottom: i < mockEvents.length - 1 ? '1px solid var(--color-border)' : 'none' }}>
              <div>
                <span style={{ display: 'inline-block', padding: '2px 8px', borderRadius: 20, fontSize: 11, fontWeight: 600, background: typeColors[e.type] + '20', color: typeColors[e.type], marginRight: 10, textTransform: 'uppercase' }}>
                  {e.type.replace('_', ' ')}
                </span>
                <span style={{ fontSize: 13, color: 'var(--color-text-muted)' }}>{e.coupleId} · {e.product}</span>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div style={{ fontSize: 14, fontWeight: 600, color: e.amount > 0 ? 'var(--color-success)' : 'var(--color-text-muted)' }}>
                  {e.amount > 0 ? `₹${e.amount}` : '—'}
                </div>
                <div style={{ fontSize: 12, color: 'var(--color-text-muted)' }}>{e.date}</div>
              </div>
            </div>
          ))}
        </div>
        <p style={{ fontSize: 12, color: 'var(--color-text-muted)', marginTop: 12 }}>
          Live data requires <code style={{ background: 'var(--color-bg)', padding: '1px 4px', borderRadius: 4 }}>REVENUECAT_WEBHOOK_SECRET</code> to be set
        </p>
      </Card>
    </div>
  );
}

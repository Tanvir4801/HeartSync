import React, { useEffect, useState } from 'react';
import { api } from '../lib/api';
import Card from '../components/Card';
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts';

export default function AIUsage() {
  const [usage, setUsage] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.aiUsage.list().then(setUsage).catch(console.error).finally(() => setLoading(false));
  }, []);

  const totalCost = usage.reduce((s, u) => s + (u.costEstimate || 0), 0);
  const totalTokens = usage.reduce((s, u) => s + (u.tokensUsed || 0), 0);

  const byDate = {};
  usage.forEach(u => {
    const d = u.date || u.timestamp?.split('T')[0] || 'unknown';
    byDate[d] = (byDate[d] || 0) + (u.costEstimate || 0);
  });
  const chartData = Object.entries(byDate).sort(([a], [b]) => a.localeCompare(b)).map(([date, cost]) => ({ date, cost: parseFloat(cost.toFixed(4)) }));

  const byCoupleRaw = {};
  usage.forEach(u => {
    byCoupleRaw[u.coupleId] = (byCoupleRaw[u.coupleId] || 0) + (u.costEstimate || 0);
  });
  const byCouple = Object.entries(byCoupleRaw).sort(([, a], [, b]) => b - a);

  return (
    <div>
      <div style={{ marginBottom: 24 }}>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>AI Usage & Cost</h1>
        <p style={{ fontSize: 14, color: 'var(--color-text-muted)' }}>Monitor AI API costs before they exceed ₹99/mo</p>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(180px, 1fr))', gap: 16, marginBottom: 24 }}>
        <div style={{ background: 'var(--color-surface)', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-lg)', padding: 20 }}>
          <div style={{ fontSize: 13, color: 'var(--color-text-muted)', marginBottom: 8 }}>Total Cost (logged)</div>
          <div style={{ fontSize: 26, fontWeight: 700, color: totalCost > 0.5 ? 'var(--color-danger)' : 'var(--color-success)' }}>${totalCost.toFixed(3)}</div>
        </div>
        <div style={{ background: 'var(--color-surface)', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-lg)', padding: 20 }}>
          <div style={{ fontSize: 13, color: 'var(--color-text-muted)', marginBottom: 8 }}>Total Tokens</div>
          <div style={{ fontSize: 26, fontWeight: 700 }}>{totalTokens.toLocaleString()}</div>
        </div>
        <div style={{ background: 'var(--color-surface)', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-lg)', padding: 20 }}>
          <div style={{ fontSize: 13, color: 'var(--color-text-muted)', marginBottom: 8 }}>AI Requests</div>
          <div style={{ fontSize: 26, fontWeight: 700 }}>{usage.length}</div>
        </div>
      </div>

      <Card style={{ marginBottom: 20 }}>
        <h2 style={{ fontSize: 15, fontWeight: 600, marginBottom: 16 }}>Cost per Day ($)</h2>
        {loading ? <div style={{ color: 'var(--color-text-muted)', fontSize: 14 }}>Loading…</div> : (
          <ResponsiveContainer width="100%" height={200}>
            <LineChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" stroke="var(--color-border)" />
              <XAxis dataKey="date" tick={{ fill: 'var(--color-text-muted)', fontSize: 11 }} tickLine={false} axisLine={false} />
              <YAxis tick={{ fill: 'var(--color-text-muted)', fontSize: 11 }} tickLine={false} axisLine={false} />
              <Tooltip contentStyle={{ background: 'var(--color-surface-2)', border: '1px solid var(--color-border)', borderRadius: 8 }} formatter={(v) => [`$${v}`, 'Cost']} />
              <Line type="monotone" dataKey="cost" stroke="var(--color-warning)" strokeWidth={2} dot={false} />
            </LineChart>
          </ResponsiveContainer>
        )}
      </Card>

      <Card>
        <h2 style={{ fontSize: 15, fontWeight: 600, marginBottom: 16 }}>Cost by Couple</h2>
        {byCouple.length === 0 ? (
          <div style={{ color: 'var(--color-text-muted)', fontSize: 14 }}>No data</div>
        ) : (
          <div>
            {byCouple.map(([coupleId, cost]) => (
              <div key={coupleId} style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 10 }}>
                <div style={{ width: 70, fontSize: 13, fontWeight: 600 }}>{coupleId}</div>
                <div style={{ flex: 1, height: 8, background: 'var(--color-bg)', borderRadius: 4, overflow: 'hidden' }}>
                  <div style={{ height: '100%', borderRadius: 4, background: 'var(--color-primary)', width: `${Math.min((cost / byCouple[0][1]) * 100, 100)}%` }} />
                </div>
                <div style={{ width: 60, textAlign: 'right', fontSize: 13, color: 'var(--color-text-muted)' }}>${cost.toFixed(3)}</div>
              </div>
            ))}
          </div>
        )}
      </Card>
    </div>
  );
}

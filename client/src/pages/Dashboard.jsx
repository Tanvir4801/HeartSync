import React, { useEffect, useState } from 'react';
import { api } from '../lib/api';
import Card, { StatCard } from '../components/Card';
import { Users, Heart, TrendingUp, UserMinus, Crown, Activity } from 'lucide-react';
import { AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts';

export default function Dashboard() {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.stats.get().then(setStats).catch(console.error).finally(() => setLoading(false));
  }, []);

  if (loading) return <div style={{ color: 'var(--color-text-muted)', fontSize: 14 }}>Loading stats…</div>;
  if (!stats) return <div style={{ color: 'var(--color-danger)' }}>Failed to load stats</div>;

  return (
    <div>
      <div style={{ marginBottom: 24 }}>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>Dashboard</h1>
        <p style={{ fontSize: 14, color: 'var(--color-text-muted)' }}>HeartSync platform overview</p>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(180px, 1fr))', gap: 16, marginBottom: 24 }}>
        <StatCard label="Total Couples" value={stats.totalCouples} icon={Heart} sub="Registered couple spaces" />
        <StatCard label="Total Users" value={stats.totalUsers} icon={Users} sub="Across all couples" />
        <StatCard label="Daily Active" value={stats.dailyActiveCouples} icon={Activity} sub="Last 24 hours" />
        <StatCard label="New This Week" value={stats.newSignupsThisWeek} icon={TrendingUp} sub="New couple signups" />
        <StatCard label="Churned / Month" value={stats.churnedThisMonth} icon={UserMinus} sub="Status = unlinked" />
        <StatCard label="Premium" value={stats.premiumCouples ?? '—'} icon={Crown} sub="Paid subscribers" />
      </div>

      {stats.recentDays && (
        <Card>
          <h2 style={{ fontSize: 15, fontWeight: 600, marginBottom: 16 }}>Activity — Last 7 Days</h2>
          <ResponsiveContainer width="100%" height={220}>
            <AreaChart data={stats.recentDays}>
              <defs>
                <linearGradient id="activeGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#e05c7e" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#e05c7e" stopOpacity={0} />
                </linearGradient>
                <linearGradient id="signupGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#60a5fa" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#60a5fa" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="var(--color-border)" />
              <XAxis dataKey="date" tick={{ fill: 'var(--color-text-muted)', fontSize: 12 }} tickLine={false} axisLine={false} />
              <YAxis tick={{ fill: 'var(--color-text-muted)', fontSize: 12 }} tickLine={false} axisLine={false} />
              <Tooltip
                contentStyle={{ background: 'var(--color-surface-2)', border: '1px solid var(--color-border)', borderRadius: 8 }}
                labelStyle={{ color: 'var(--color-text)' }}
                itemStyle={{ color: 'var(--color-text-muted)' }}
              />
              <Area type="monotone" dataKey="active" stroke="#e05c7e" fill="url(#activeGrad)" name="Active couples" strokeWidth={2} dot={false} />
              <Area type="monotone" dataKey="signups" stroke="#60a5fa" fill="url(#signupGrad)" name="New signups" strokeWidth={2} dot={false} />
            </AreaChart>
          </ResponsiveContainer>
        </Card>
      )}
    </div>
  );
}

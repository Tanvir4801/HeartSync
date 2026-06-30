import React, { useEffect, useState } from 'react';
import { api } from '../lib/api';
import Card, { StatCard } from '../components/Card';
import { Users, Heart, TrendingUp, UserMinus, Crown, Activity } from 'lucide-react';
import { AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts';

const STAT_CARDS = (stats) => [
  { label: 'Total Couples',  value: stats.totalCouples,          icon: Heart,      accent: '#e05c7e', sub: 'Registered couple spaces' },
  { label: 'Total Users',    value: stats.totalUsers,             icon: Users,      accent: '#60a5fa', sub: 'Across all couples'        },
  { label: 'Daily Active',   value: stats.dailyActiveCouples,    icon: Activity,   accent: '#4ade80', sub: 'Last 24 hours'             },
  { label: 'New This Week',  value: stats.newSignupsThisWeek,    icon: TrendingUp, accent: '#b44fde', sub: 'New couple sign-ups'       },
  { label: 'Churned / Mo',   value: stats.churnedThisMonth,      icon: UserMinus,  accent: '#f87171', sub: 'Status → unlinked'         },
  { label: 'Premium',        value: stats.premiumCouples ?? '—', icon: Crown,      accent: '#facc15', sub: 'Paid subscribers'          },
];

function CustomTooltip({ active, payload, label }) {
  if (!active || !payload?.length) return null;
  return (
    <div style={{
      background: 'rgba(7,7,28,0.92)', backdropFilter: 'blur(12px)',
      border: '1px solid rgba(255,255,255,0.1)', borderRadius: 10, padding: '10px 14px',
    }}>
      <p style={{ fontSize: 12, color: 'var(--color-text-muted)', marginBottom: 6 }}>{label}</p>
      {payload.map(p => (
        <p key={p.name} style={{ fontSize: 13, color: p.color, fontWeight: 600 }}>
          {p.name}: <span style={{ color: 'var(--color-text)' }}>{p.value}</span>
        </p>
      ))}
    </div>
  );
}

export default function Dashboard() {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.stats.get().then(setStats).catch(console.error).finally(() => setLoading(false));
  }, []);

  if (loading) return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 10, color: 'var(--color-text-muted)', fontSize: 14 }}>
      <div style={{ width: 18, height: 18, border: '2px solid rgba(224,92,126,0.3)', borderTopColor: 'var(--color-primary)', borderRadius: '50%', animation: 'spin 0.8s linear infinite' }} />
      Loading…
    </div>
  );
  if (!stats) return <div style={{ color: 'var(--color-danger)', fontSize: 14 }}>Failed to load stats</div>;

  return (
    <div className="anim-fade-in">
      {/* Page header */}
      <div style={{ marginBottom: 28 }}>
        <h1 style={{ fontSize: 26, fontWeight: 800, marginBottom: 4, letterSpacing: '-0.02em' }}>
          <span className="grad-text">Dashboard</span>
        </h1>
        <p style={{ fontSize: 14, color: 'var(--color-text-muted)' }}>
          HeartSync platform overview · real-time metrics
        </p>
      </div>

      {/* Stat cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(185px, 1fr))', gap: 16, marginBottom: 28 }}>
        {STAT_CARDS(stats).map((s, i) => (
          <div key={s.label} className={`anim-slide-up anim-delay-${(i + 1) * 100}`}>
            <StatCard label={s.label} value={s.value} icon={s.icon} accent={s.accent} sub={s.sub} />
          </div>
        ))}
      </div>

      {/* Activity chart */}
      {stats.recentDays && (
        <Card>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 20 }}>
            <div>
              <h2 style={{ fontSize: 16, fontWeight: 700, marginBottom: 2 }}>Activity — Last 7 Days</h2>
              <p style={{ fontSize: 12, color: 'var(--color-text-muted)' }}>Active couples & new sign-ups</p>
            </div>
            <div style={{ display: 'flex', gap: 16 }}>
              {[
                { color: '#e05c7e', label: 'Active couples' },
                { color: '#60a5fa', label: 'New sign-ups'   },
              ].map(l => (
                <div key={l.label} style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                  <div style={{ width: 10, height: 10, borderRadius: '50%', background: l.color, boxShadow: `0 0 8px ${l.color}` }} />
                  <span style={{ fontSize: 12, color: 'var(--color-text-muted)' }}>{l.label}</span>
                </div>
              ))}
            </div>
          </div>
          <ResponsiveContainer width="100%" height={230}>
            <AreaChart data={stats.recentDays} margin={{ top: 4, right: 4, left: -20, bottom: 0 }}>
              <defs>
                <linearGradient id="activeGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#e05c7e" stopOpacity={0.35} />
                  <stop offset="95%" stopColor="#e05c7e" stopOpacity={0} />
                </linearGradient>
                <linearGradient id="signupGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#60a5fa" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#60a5fa" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
              <XAxis dataKey="date" tick={{ fill: 'var(--color-text-muted)', fontSize: 11 }} tickLine={false} axisLine={false} />
              <YAxis tick={{ fill: 'var(--color-text-muted)', fontSize: 11 }} tickLine={false} axisLine={false} />
              <Tooltip content={<CustomTooltip />} />
              <Area type="monotone" dataKey="active"  stroke="#e05c7e" strokeWidth={2.5} fill="url(#activeGrad)"  dot={false} name="Active couples" />
              <Area type="monotone" dataKey="signups" stroke="#60a5fa" strokeWidth={2.5} fill="url(#signupGrad)" dot={false} name="New sign-ups"    />
            </AreaChart>
          </ResponsiveContainer>
        </Card>
      )}

      <style>{`
        @keyframes spin { to { transform: rotate(360deg); } }
      `}</style>
    </div>
  );
}

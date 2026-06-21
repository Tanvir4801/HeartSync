import React from 'react';

export default function Card({ children, style }) {
  return (
    <div style={{
      background: 'var(--color-surface)',
      border: '1px solid var(--color-border)',
      borderRadius: 'var(--radius-lg)',
      padding: 20,
      ...style,
    }}>
      {children}
    </div>
  );
}

export function StatCard({ label, value, icon: Icon, color, sub }) {
  return (
    <div style={{
      background: 'var(--color-surface)',
      border: '1px solid var(--color-border)',
      borderRadius: 'var(--radius-lg)',
      padding: 20,
      display: 'flex',
      flexDirection: 'column',
      gap: 8,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <span style={{ fontSize: 13, color: 'var(--color-text-muted)', fontWeight: 500 }}>{label}</span>
        {Icon && (
          <div style={{ width: 36, height: 36, borderRadius: 10, background: color || 'var(--color-primary-soft)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Icon size={18} color={color ? '#fff' : 'var(--color-primary)'} />
          </div>
        )}
      </div>
      <div style={{ fontSize: 28, fontWeight: 700, color: 'var(--color-text)', lineHeight: 1 }}>{value}</div>
      {sub && <div style={{ fontSize: 12, color: 'var(--color-text-muted)' }}>{sub}</div>}
    </div>
  );
}

export function Badge({ children, variant = 'default' }) {
  const colors = {
    default: { bg: 'var(--color-surface-2)', color: 'var(--color-text-muted)' },
    success: { bg: 'rgba(74, 222, 128, 0.15)', color: 'var(--color-success)' },
    warning: { bg: 'rgba(250, 204, 21, 0.15)', color: 'var(--color-warning)' },
    danger: { bg: 'rgba(248, 113, 113, 0.15)', color: 'var(--color-danger)' },
    info: { bg: 'rgba(96, 165, 250, 0.15)', color: 'var(--color-info)' },
    primary: { bg: 'var(--color-primary-soft)', color: 'var(--color-primary)' },
  };
  const c = colors[variant] || colors.default;
  return (
    <span style={{
      display: 'inline-block',
      padding: '2px 8px',
      borderRadius: 20,
      fontSize: 11,
      fontWeight: 600,
      background: c.bg,
      color: c.color,
      textTransform: 'uppercase',
      letterSpacing: '0.05em',
    }}>
      {children}
    </span>
  );
}

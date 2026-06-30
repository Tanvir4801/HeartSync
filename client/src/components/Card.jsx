import React, { useState } from 'react';

export default function Card({ children, style, className = '' }) {
  return (
    <div className={`glass-card ${className}`} style={style}>
      {children}
    </div>
  );
}

export function StatCard({ label, value, icon: Icon, color, sub, accent }) {
  const [hovered, setHovered] = useState(false);
  const accentColor = accent || color || 'var(--color-primary)';

  return (
    <div
      className="stat-card"
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
    >
      {/* Ambient glow orb */}
      <div style={{
        position: 'absolute', top: -20, right: -20,
        width: 80, height: 80, borderRadius: '50%',
        background: accentColor,
        opacity: hovered ? 0.12 : 0.07,
        filter: 'blur(20px)',
        transition: 'opacity 0.3s ease',
        pointerEvents: 'none',
      }} />

      <div style={{ position: 'relative', zIndex: 1 }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
          <span style={{ fontSize: 12, color: 'var(--color-text-muted)', fontWeight: 500, letterSpacing: '0.02em' }}>
            {label}
          </span>
          {Icon && (
            <div style={{
              width: 36, height: 36, borderRadius: 10,
              background: `${accentColor}20`,
              border: `1px solid ${accentColor}40`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: hovered ? `0 0 16px ${accentColor}40` : 'none',
              transition: 'box-shadow 0.3s ease',
            }}>
              <Icon size={17} color={accentColor} />
            </div>
          )}
        </div>
        <div style={{
          fontSize: 30, fontWeight: 800,
          color: 'var(--color-text)',
          lineHeight: 1, marginBottom: sub ? 6 : 0,
          letterSpacing: '-0.02em',
        }}>
          {value}
        </div>
        {sub && (
          <div style={{ fontSize: 11.5, color: 'var(--color-text-muted)', marginTop: 4 }}>
            {sub}
          </div>
        )}
      </div>
    </div>
  );
}

export function Badge({ children, variant = 'default' }) {
  const colors = {
    default: { bg: 'rgba(255,255,255,0.07)', color: 'var(--color-text-muted)', border: 'rgba(255,255,255,0.08)' },
    success: { bg: 'rgba(74,222,128,0.1)',   color: 'var(--color-success)',     border: 'rgba(74,222,128,0.2)'  },
    warning: { bg: 'rgba(250,204,21,0.1)',   color: 'var(--color-warning)',     border: 'rgba(250,204,21,0.2)'  },
    danger:  { bg: 'rgba(248,113,113,0.1)',  color: 'var(--color-danger)',      border: 'rgba(248,113,113,0.2)' },
    info:    { bg: 'rgba(96,165,250,0.1)',   color: 'var(--color-info)',        border: 'rgba(96,165,250,0.2)'  },
    primary: { bg: 'rgba(224,92,126,0.12)',  color: 'var(--color-primary)',     border: 'rgba(224,92,126,0.25)' },
  };
  const c = colors[variant] || colors.default;
  return (
    <span style={{
      display: 'inline-block',
      padding: '2px 9px',
      borderRadius: 20,
      fontSize: 10.5,
      fontWeight: 700,
      background: c.bg,
      color: c.color,
      border: `1px solid ${c.border}`,
      textTransform: 'uppercase',
      letterSpacing: '0.06em',
    }}>
      {children}
    </span>
  );
}

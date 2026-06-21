import React, { useState } from 'react';
import { Outlet, NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '../lib/auth';
import {
  LayoutDashboard, Users, Flag, Bell, BarChart2,
  ShieldAlert, Cpu, LogOut, Menu, X, Heart
} from 'lucide-react';

const navItems = [
  { to: '/dashboard', icon: LayoutDashboard, label: 'Dashboard' },
  { to: '/couples', icon: Users, label: 'Couples' },
  { to: '/reports', icon: ShieldAlert, label: 'Moderation' },
  { to: '/revenue', icon: BarChart2, label: 'Revenue' },
  { to: '/ai-usage', icon: Cpu, label: 'AI Usage' },
  { to: '/notifications', icon: Bell, label: 'Notifications' },
  { to: '/flags', icon: Flag, label: 'Feature Flags' },
];

export default function Layout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [sidebarOpen, setSidebarOpen] = useState(true);

  function handleLogout() {
    logout();
    navigate('/login');
  }

  return (
    <div style={{ display: 'flex', height: '100vh', overflow: 'hidden' }}>
      <aside style={{
        width: sidebarOpen ? 220 : 64,
        background: 'var(--color-surface)',
        borderRight: '1px solid var(--color-border)',
        display: 'flex',
        flexDirection: 'column',
        transition: 'width 0.2s ease',
        flexShrink: 0,
        overflow: 'hidden',
      }}>
        <div style={{ padding: '18px 16px', display: 'flex', alignItems: 'center', gap: 10, borderBottom: '1px solid var(--color-border)' }}>
          <div style={{ width: 32, height: 32, borderRadius: 8, background: 'var(--color-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
            <Heart size={16} color="#fff" fill="#fff" />
          </div>
          {sidebarOpen && <span style={{ fontWeight: 700, fontSize: 15, whiteSpace: 'nowrap', color: 'var(--color-text)' }}>HeartSync Console</span>}
        </div>

        <nav style={{ flex: 1, padding: '12px 8px', display: 'flex', flexDirection: 'column', gap: 2 }}>
          {navItems.map(({ to, icon: Icon, label }) => (
            <NavLink key={to} to={to} style={({ isActive }) => ({
              display: 'flex', alignItems: 'center', gap: 10,
              padding: '9px 10px', borderRadius: 8,
              color: isActive ? 'var(--color-primary)' : 'var(--color-text-muted)',
              background: isActive ? 'var(--color-primary-soft)' : 'transparent',
              fontWeight: isActive ? 600 : 400,
              fontSize: 14,
              transition: 'all 0.15s',
              whiteSpace: 'nowrap',
              overflow: 'hidden',
            })}>
              <Icon size={18} style={{ flexShrink: 0 }} />
              {sidebarOpen && label}
            </NavLink>
          ))}
        </nav>

        <div style={{ padding: '12px 8px', borderTop: '1px solid var(--color-border)' }}>
          {sidebarOpen && (
            <div style={{ padding: '6px 10px', fontSize: 12, color: 'var(--color-text-muted)', marginBottom: 6, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
              {user?.email}
              {user?.mock && <span style={{ marginLeft: 6, background: 'var(--color-warning)', color: '#000', borderRadius: 4, padding: '1px 5px', fontSize: 10 }}>DEMO</span>}
            </div>
          )}
          <button onClick={handleLogout} style={{
            display: 'flex', alignItems: 'center', gap: 10,
            width: '100%', padding: '9px 10px', borderRadius: 8,
            background: 'none', border: 'none',
            color: 'var(--color-text-muted)', fontSize: 14,
            transition: 'all 0.15s',
          }}
            onMouseEnter={e => e.currentTarget.style.color = 'var(--color-danger)'}
            onMouseLeave={e => e.currentTarget.style.color = 'var(--color-text-muted)'}
          >
            <LogOut size={18} style={{ flexShrink: 0 }} />
            {sidebarOpen && 'Sign out'}
          </button>
        </div>
      </aside>

      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
        <header style={{
          height: 52, background: 'var(--color-surface)',
          borderBottom: '1px solid var(--color-border)',
          display: 'flex', alignItems: 'center', padding: '0 20px', gap: 12,
        }}>
          <button onClick={() => setSidebarOpen(o => !o)} style={{ background: 'none', border: 'none', color: 'var(--color-text-muted)', padding: 4, borderRadius: 6, display: 'flex' }}>
            {sidebarOpen ? <X size={18} /> : <Menu size={18} />}
          </button>
          <span style={{ fontSize: 13, color: 'var(--color-text-muted)' }}>heartsync-b4e9f</span>
        </header>

        <main style={{ flex: 1, overflow: 'auto', padding: 24 }}>
          <Outlet />
        </main>
      </div>
    </div>
  );
}

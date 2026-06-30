import React, { useState } from 'react';
import { Outlet, NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '../lib/auth';
import {
  LayoutDashboard, Users, Flag, Bell, BarChart2,
  ShieldAlert, Cpu, Sparkles, LogOut, Menu, X, Heart,
  Palette, HeadphonesIcon, TrendingUp, ClipboardList, Shield,
  ChevronRight,
} from 'lucide-react';

const navGroups = [
  {
    label: 'Core',
    items: [
      { to: '/dashboard',   icon: LayoutDashboard, label: 'Dashboard'       },
      { to: '/couples',     icon: Users,           label: 'Couples'         },
      { to: '/reports',     icon: ShieldAlert,     label: 'Moderation'      },
      { to: '/revenue',     icon: BarChart2,       label: 'Revenue'         },
    ],
  },
  {
    label: 'Intelligence',
    items: [
      { to: '/analytics',    icon: TrendingUp, label: 'Funnel & Retention' },
      { to: '/ai-usage',     icon: Cpu,        label: 'AI Usage'           },
      { to: '/ai-playground',icon: Sparkles,   label: 'AI Playground'      },
    ],
  },
  {
    label: 'Operations',
    items: [
      { to: '/notifications', icon: Bell,            label: 'Notifications'  },
      { to: '/flags',         icon: Flag,            label: 'Feature Flags'  },
      { to: '/themes',        icon: Palette,         label: 'Themes'         },
      { to: '/support',       icon: HeadphonesIcon,  label: 'Support Inbox'  },
    ],
  },
  {
    label: 'Compliance',
    items: [
      { to: '/audit', icon: ClipboardList, label: 'Audit Log'     },
      { to: '/gdpr',  icon: Shield,        label: 'GDPR Requests' },
    ],
  },
];

export default function Layout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [open, setOpen] = useState(true);

  function handleLogout() { logout(); navigate('/login'); }

  return (
    <div style={{ display: 'flex', height: '100vh', overflow: 'hidden' }}>
      {/* ── Sidebar ── */}
      <aside className="sidebar-glass" style={{
        width: open ? 224 : 62,
        display: 'flex', flexDirection: 'column',
        transition: 'width 0.25s cubic-bezier(0.4,0,0.2,1)',
        flexShrink: 0, overflow: 'hidden',
        zIndex: 10,
      }}>
        {/* Logo row */}
        <div style={{
          padding: open ? '16px 14px' : '16px 14px',
          display: 'flex', alignItems: 'center',
          gap: open ? 10 : 0,
          borderBottom: '1px solid rgba(255,255,255,0.06)',
          minHeight: 60,
        }}>
          <div className="logo-orb">
            <Heart size={16} color="#fff" fill="#fff" />
          </div>
          {open && (
            <div>
              <div style={{ fontWeight: 800, fontSize: 13.5, whiteSpace: 'nowrap', letterSpacing: '-0.01em' }}>
                HeartSync
              </div>
              <div style={{ fontSize: 10, color: 'rgba(120,120,180,0.7)', fontWeight: 500, letterSpacing: '0.06em' }}>
                CONSOLE
              </div>
            </div>
          )}
        </div>

        {/* Nav */}
        <nav style={{ flex: 1, padding: '8px', overflowY: 'auto', overflowX: 'hidden' }}>
          {navGroups.map(group => (
            <div key={group.label} style={{ marginBottom: 6 }}>
              {open && <div className="section-label">{group.label}</div>}
              {group.items.map(({ to, icon: Icon, label }) => (
                <NavLink key={to} to={to} className={({ isActive }) => `nav-item${isActive ? ' active' : ''}`}
                  style={{ justifyContent: open ? 'flex-start' : 'center' }}
                  title={!open ? label : undefined}
                >
                  <Icon size={16} style={{ flexShrink: 0 }} />
                  {open && <span>{label}</span>}
                </NavLink>
              ))}
            </div>
          ))}
        </nav>

        {/* Footer */}
        <div style={{ padding: '10px 8px', borderTop: '1px solid rgba(255,255,255,0.05)' }}>
          {open && user?.email && (
            <div style={{
              padding: '7px 10px 10px',
              fontSize: 11,
              color: 'var(--color-text-muted)',
              overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
              display: 'flex', alignItems: 'center', gap: 6,
            }}>
              <div style={{ width: 6, height: 6, borderRadius: '50%', background: 'var(--color-success)', flexShrink: 0, boxShadow: '0 0 8px var(--color-success)' }} />
              {user.email}
              {user?.mock && (
                <span style={{ background: 'rgba(250,204,21,0.15)', color: 'var(--color-warning)', borderRadius: 5, padding: '1px 5px', fontSize: 9, fontWeight: 700, letterSpacing: '0.05em' }}>
                  DEMO
                </span>
              )}
            </div>
          )}
          <button
            onClick={handleLogout}
            className="nav-item"
            style={{ width: '100%', background: 'none', border: '1px solid transparent', justifyContent: open ? 'flex-start' : 'center' }}
            onMouseEnter={e => { e.currentTarget.style.color = 'var(--color-danger)'; e.currentTarget.style.borderColor = 'rgba(248,113,113,0.2)'; e.currentTarget.style.background = 'rgba(248,113,113,0.06)'; }}
            onMouseLeave={e => { e.currentTarget.style.color = ''; e.currentTarget.style.borderColor = 'transparent'; e.currentTarget.style.background = 'none'; }}
          >
            <LogOut size={15} style={{ flexShrink: 0 }} />
            {open && 'Sign out'}
          </button>
        </div>
      </aside>

      {/* ── Content area ── */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden', minWidth: 0 }}>
        {/* Header */}
        <header className="header-glass" style={{
          height: 52, display: 'flex', alignItems: 'center',
          padding: '0 20px', gap: 14, flexShrink: 0,
        }}>
          <button
            onClick={() => setOpen(o => !o)}
            style={{ background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 8, color: 'var(--color-text-muted)', padding: '6px 7px', display: 'flex', cursor: 'pointer', transition: 'all 0.18s' }}
            onMouseEnter={e => { e.currentTarget.style.color = 'var(--color-text)'; e.currentTarget.style.background = 'rgba(255,255,255,0.1)'; }}
            onMouseLeave={e => { e.currentTarget.style.color = 'var(--color-text-muted)'; e.currentTarget.style.background = 'rgba(255,255,255,0.06)'; }}
          >
            {open ? <X size={16} /> : <Menu size={16} />}
          </button>

          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <ChevronRight size={13} style={{ color: 'rgba(255,255,255,0.2)' }} />
            <span style={{ fontSize: 12, color: 'rgba(120,120,180,0.8)', letterSpacing: '0.04em' }}>heartsync-b4e9f</span>
          </div>

          <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: 8 }}>
            <div style={{ width: 28, height: 28, borderRadius: 8, background: 'linear-gradient(135deg, rgba(224,92,126,0.3), rgba(180,79,222,0.3))', border: '1px solid rgba(224,92,126,0.3)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 13 }}>
              ♥
            </div>
          </div>
        </header>

        {/* Main */}
        <main style={{ flex: 1, overflow: 'auto', padding: '28px 28px' }}>
          <Outlet />
        </main>
      </div>
    </div>
  );
}

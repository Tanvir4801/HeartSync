import React, { useEffect, useState } from 'react';
import { api } from '../lib/api';
import Card, { Badge } from '../components/Card';
import { Search, Shield, ShieldOff, Crown, MoreHorizontal } from 'lucide-react';

function statusVariant(status) {
  if (status === 'active') return 'success';
  if (status === 'suspended') return 'danger';
  if (status === 'unlinked') return 'warning';
  return 'default';
}

function tierVariant(tier) {
  if (tier === 'Premium') return 'primary';
  if (tier === 'Lifetime') return 'info';
  return 'default';
}

export default function Couples() {
  const [couples, setCouples] = useState([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState(null);
  const [actionMsg, setActionMsg] = useState('');

  function load(q = '') {
    setLoading(true);
    api.couples.list(q).then(setCouples).catch(console.error).finally(() => setLoading(false));
  }

  useEffect(() => { load(); }, []);

  function handleSearch(e) {
    const q = e.target.value;
    setSearch(q);
    if (q.length === 0 || q.length >= 3) load(q);
  }

  async function grantTier(id, tier) {
    try {
      await api.couples.updateSubscription(id, tier);
      setActionMsg(`Granted ${tier} to couple ${id}`);
      load();
    } catch (err) {
      setActionMsg(`Error: ${err.message}`);
    }
  }

  async function toggleSuspend(couple) {
    const newStatus = couple.status === 'suspended' ? 'active' : 'suspended';
    try {
      await api.couples.updateStatus(couple.id, newStatus);
      setActionMsg(`Couple ${couple.id} is now ${newStatus}`);
      load();
    } catch (err) {
      setActionMsg(`Error: ${err.message}`);
    }
  }

  return (
    <div>
      <div style={{ marginBottom: 24 }}>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>Couples</h1>
        <p style={{ fontSize: 14, color: 'var(--color-text-muted)' }}>Search and manage couple spaces</p>
      </div>

      {actionMsg && (
        <div style={{ marginBottom: 16, padding: '10px 14px', background: 'var(--color-primary-soft)', border: '1px solid var(--color-primary)', borderRadius: 'var(--radius)', fontSize: 13, color: 'var(--color-primary)' }}>
          {actionMsg}
        </div>
      )}

      <Card style={{ marginBottom: 20 }}>
        <div style={{ position: 'relative' }}>
          <Search size={16} style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)', color: 'var(--color-text-muted)' }} />
          <input
            value={search}
            onChange={handleSearch}
            placeholder="Search by invite code, email, or couple ID…"
            style={{
              width: '100%',
              padding: '10px 12px 10px 36px',
              background: 'var(--color-bg)',
              border: '1px solid var(--color-border)',
              borderRadius: 'var(--radius)',
              color: 'var(--color-text)',
              fontSize: 14,
              outline: 'none',
            }}
          />
        </div>
      </Card>

      <Card style={{ padding: 0, overflow: 'hidden' }}>
        {loading ? (
          <div style={{ padding: 24, color: 'var(--color-text-muted)', fontSize: 14 }}>Loading…</div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead>
                <tr style={{ borderBottom: '1px solid var(--color-border)' }}>
                  {['Invite Code', 'Members', 'Anniversary', 'Tier', 'Memories', 'Messages', 'Last Active', 'Status', 'Actions'].map(h => (
                    <th key={h} style={{ padding: '12px 16px', textAlign: 'left', fontSize: 12, fontWeight: 600, color: 'var(--color-text-muted)', whiteSpace: 'nowrap' }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {couples.map(c => (
                  <tr key={c.id} style={{ borderBottom: '1px solid var(--color-border)', cursor: 'pointer' }}
                    onMouseEnter={e => e.currentTarget.style.background = 'var(--color-surface-2)'}
                    onMouseLeave={e => e.currentTarget.style.background = 'transparent'}
                  >
                    <td style={{ padding: '12px 16px', fontFamily: 'monospace', fontWeight: 700, fontSize: 13 }}>{c.inviteCode}</td>
                    <td style={{ padding: '12px 16px', fontSize: 13 }}>
                      {Array.isArray(c.members) ? c.members.map(m => <div key={m} style={{ color: 'var(--color-text-muted)' }}>{m}</div>) : '—'}
                    </td>
                    <td style={{ padding: '12px 16px', fontSize: 13, color: 'var(--color-text-muted)' }}>{c.anniversaryDate || '—'}</td>
                    <td style={{ padding: '12px 16px' }}><Badge variant={tierVariant(c.tier)}>{c.tier || 'Free'}</Badge></td>
                    <td style={{ padding: '12px 16px', fontSize: 13 }}>{c.memoryCount ?? '—'}</td>
                    <td style={{ padding: '12px 16px', fontSize: 13 }}>{c.messageCount ?? '—'}</td>
                    <td style={{ padding: '12px 16px', fontSize: 13, color: 'var(--color-text-muted)' }}>{c.lastActive || '—'}</td>
                    <td style={{ padding: '12px 16px' }}><Badge variant={statusVariant(c.status)}>{c.status}</Badge></td>
                    <td style={{ padding: '12px 16px' }}>
                      <div style={{ display: 'flex', gap: 6 }}>
                        <button onClick={() => grantTier(c.id, 'Premium')} title="Grant Premium" style={{ padding: '4px 8px', background: 'var(--color-primary-soft)', border: 'none', borderRadius: 6, color: 'var(--color-primary)', cursor: 'pointer', fontSize: 11, fontWeight: 600 }}>
                          <Crown size={12} style={{ verticalAlign: 'middle' }} /> Premium
                        </button>
                        <button onClick={() => toggleSuspend(c)} title={c.status === 'suspended' ? 'Unsuspend' : 'Suspend'} style={{ padding: '4px 8px', background: c.status === 'suspended' ? 'rgba(74,222,128,0.15)' : 'rgba(248,113,113,0.1)', border: 'none', borderRadius: 6, color: c.status === 'suspended' ? 'var(--color-success)' : 'var(--color-danger)', cursor: 'pointer', fontSize: 11, fontWeight: 600 }}>
                          {c.status === 'suspended' ? <Shield size={12} style={{ verticalAlign: 'middle' }} /> : <ShieldOff size={12} style={{ verticalAlign: 'middle' }} />}
                          {c.status === 'suspended' ? ' Restore' : ' Suspend'}
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {couples.length === 0 && (
              <div style={{ padding: 32, textAlign: 'center', color: 'var(--color-text-muted)', fontSize: 14 }}>No couples found</div>
            )}
          </div>
        )}
      </Card>
    </div>
  );
}

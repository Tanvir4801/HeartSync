import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../lib/auth';
import { Heart, Lock, Mail, KeyRound } from 'lucide-react';

const HEARTS = ['❤️','💕','💗','💖','💝','✨','🌸','💫'];

function HeartParticles() {
  const [particles, setParticles] = useState([]);
  useEffect(() => {
    const list = Array.from({ length: 12 }, (_, i) => ({
      id: i,
      left: `${5 + Math.random() * 90}%`,
      delay: `${Math.random() * 8}s`,
      duration: `${10 + Math.random() * 10}s`,
      emoji: HEARTS[Math.floor(Math.random() * HEARTS.length)],
      size: 14 + Math.random() * 14,
    }));
    setParticles(list);
  }, []);

  return (
    <>
      {particles.map(p => (
        <span key={p.id} className="heart-particle" style={{
          left: p.left, bottom: '-5vh',
          fontSize: p.size,
          animationDuration: p.duration,
          animationDelay: p.delay,
        }}>
          {p.emoji}
        </span>
      ))}
    </>
  );
}

export default function Login() {
  const { loginWithEmailPassword, loginWithToken, loginMock, firebaseAvailable } = useAuth();
  const navigate = useNavigate();
  const [mode, setMode]       = useState('email');
  const [email, setEmail]     = useState('');
  const [password, setPassword] = useState('');
  const [idToken, setIdToken] = useState('');
  const [error, setError]     = useState('');
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e) {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      if (mode === 'email') await loginWithEmailPassword(email, password);
      else                  await loginWithToken(idToken);
      navigate('/dashboard');
    } catch (err) {
      setError(formatFirebaseError(err.message));
    } finally {
      setLoading(false);
    }
  }

  function formatFirebaseError(msg) {
    if (msg.includes('invalid-credential') || msg.includes('wrong-password')) return 'Incorrect email or password';
    if (msg.includes('user-not-found')) return 'No account found with this email';
    if (msg.includes('too-many-requests')) return 'Too many attempts — try again later';
    if (msg.includes('network')) return 'Network error — check your connection';
    return msg;
  }

  function handleDemo() { loginMock(); navigate('/dashboard'); }

  return (
    <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 20, position: 'relative', overflow: 'hidden' }}>
      <div className="login-bg" />
      <HeartParticles />

      {/* Glow orbs */}
      <div style={{ position: 'fixed', top: '20%', left: '15%', width: 320, height: 320, borderRadius: '50%', background: 'radial-gradient(circle, rgba(224,92,126,0.15) 0%, transparent 70%)', pointerEvents: 'none', filter: 'blur(40px)' }} />
      <div style={{ position: 'fixed', bottom: '20%', right: '15%', width: 280, height: 280, borderRadius: '50%', background: 'radial-gradient(circle, rgba(180,79,222,0.12) 0%, transparent 70%)', pointerEvents: 'none', filter: 'blur(40px)' }} />

      {/* Card */}
      <div className="anim-slide-up" style={{
        width: '100%', maxWidth: 420,
        background: 'rgba(255,255,255,0.04)',
        backdropFilter: 'blur(24px)',
        WebkitBackdropFilter: 'blur(24px)',
        border: '1px solid rgba(255,255,255,0.1)',
        borderRadius: 24,
        padding: 40,
        boxShadow: '0 32px 80px rgba(0,0,0,0.6), 0 0 0 1px rgba(255,255,255,0.05)',
        position: 'relative',
        zIndex: 1,
      }}>
        {/* Top gradient line */}
        <div style={{ position: 'absolute', top: 0, left: '15%', right: '15%', height: 1, background: 'linear-gradient(90deg, transparent, rgba(224,92,126,0.8), rgba(180,79,222,0.6), transparent)', borderRadius: 1 }} />

        {/* Logo + heading */}
        <div style={{ textAlign: 'center', marginBottom: 32 }}>
          <div style={{
            width: 68, height: 68, borderRadius: 20,
            background: 'linear-gradient(135deg, #e05c7e, #b44fde)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            margin: '0 auto 18px',
            boxShadow: '0 8px 32px rgba(224,92,126,0.5), 0 0 60px rgba(180,79,222,0.3)',
            animation: 'pulse-orb 4s ease-in-out infinite',
          }}>
            <Heart size={32} color="#fff" fill="#fff" />
          </div>
          <h1 className="grad-text" style={{ fontSize: 26, fontWeight: 800, marginBottom: 6, letterSpacing: '-0.02em' }}>
            HeartSync Console
          </h1>
          <p style={{ fontSize: 13, color: 'rgba(120,120,180,0.8)', letterSpacing: '0.02em' }}>
            Internal admin dashboard · authorized access only
          </p>
        </div>

        {/* Mode tabs */}
        <div style={{ display: 'flex', gap: 5, marginBottom: 22, background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.07)', borderRadius: 12, padding: 4 }}>
          {[
            { id: 'email', label: 'Email & Password', icon: Mail },
            { id: 'token', label: 'ID Token',         icon: KeyRound },
          ].map(({ id, label, icon: Icon }) => (
            <button key={id} onClick={() => { setMode(id); setError(''); }} style={{
              flex: 1, padding: '8px', borderRadius: 8,
              border: mode === id ? '1px solid rgba(224,92,126,0.3)' : '1px solid transparent',
              cursor: 'pointer',
              background: mode === id ? 'rgba(224,92,126,0.15)' : 'transparent',
              color: mode === id ? '#f0a0b8' : 'var(--color-text-muted)',
              fontSize: 12, fontWeight: mode === id ? 600 : 400,
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 5,
              transition: 'all 0.2s ease',
              fontFamily: 'inherit',
            }}>
              <Icon size={12} /> {label}
            </button>
          ))}
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {mode === 'email' ? (
            <>
              <div style={{ position: 'relative' }}>
                <Mail size={15} style={{ position: 'absolute', left: 13, top: '50%', transform: 'translateY(-50%)', color: 'var(--color-text-muted)', pointerEvents: 'none' }} />
                <input type="email" value={email} onChange={e => setEmail(e.target.value)} placeholder="admin@yourapp.com" required className="input-glass" />
              </div>
              <div style={{ position: 'relative' }}>
                <KeyRound size={15} style={{ position: 'absolute', left: 13, top: '50%', transform: 'translateY(-50%)', color: 'var(--color-text-muted)', pointerEvents: 'none' }} />
                <input type="password" value={password} onChange={e => setPassword(e.target.value)} placeholder="Password" required className="input-glass" />
              </div>
              {!firebaseAvailable && (
                <p style={{ fontSize: 12, color: 'var(--color-warning)', background: 'rgba(250,204,21,0.08)', padding: '8px 12px', borderRadius: 8, border: '1px solid rgba(250,204,21,0.2)' }}>
                  Firebase not configured — use Demo mode to explore.
                </p>
              )}
            </>
          ) : (
            <div>
              <label style={{ display: 'block', fontSize: 12, fontWeight: 500, marginBottom: 6, color: 'var(--color-text-muted)' }}>
                Firebase ID Token (with <code style={{ background: 'rgba(255,255,255,0.07)', padding: '1px 4px', borderRadius: 4 }}>isAdmin</code> claim)
              </label>
              <textarea value={idToken} onChange={e => setIdToken(e.target.value)} placeholder="eyJhbGci…" rows={4} style={{
                width: '100%',
                background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)',
                borderRadius: 10, padding: '10px 12px',
                color: 'var(--color-text)', fontSize: 12,
                fontFamily: 'monospace', resize: 'vertical', outline: 'none',
              }} />
            </div>
          )}

          {error && (
            <div style={{ padding: '10px 14px', background: 'rgba(248,113,113,0.08)', border: '1px solid rgba(248,113,113,0.25)', borderRadius: 10, fontSize: 13, color: 'var(--color-danger)' }}>
              {error}
            </div>
          )}

          <button
            type="submit"
            disabled={loading || (mode === 'email' ? (!email || !password) : !idToken.trim())}
            className="btn-grad"
            style={{ marginTop: 4 }}
          >
            {loading ? '✦ Signing in…' : '✦ Sign in to Console'}
          </button>
        </form>

        {/* Divider */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, margin: '18px 0' }}>
          <div style={{ flex: 1, height: 1, background: 'rgba(255,255,255,0.07)' }} />
          <span style={{ fontSize: 12, color: 'rgba(120,120,180,0.6)' }}>or</span>
          <div style={{ flex: 1, height: 1, background: 'rgba(255,255,255,0.07)' }} />
        </div>

        {/* Demo button */}
        <button onClick={handleDemo} style={{
          width: '100%', padding: '11px',
          background: 'rgba(255,255,255,0.04)',
          color: 'var(--color-text-muted)',
          border: '1px solid rgba(255,255,255,0.09)',
          borderRadius: 10, fontWeight: 500, fontSize: 13,
          cursor: 'pointer', fontFamily: 'inherit',
          transition: 'all 0.2s ease',
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
        }}
          onMouseEnter={e => { e.currentTarget.style.background = 'rgba(255,255,255,0.08)'; e.currentTarget.style.color = 'var(--color-text)'; }}
          onMouseLeave={e => { e.currentTarget.style.background = 'rgba(255,255,255,0.04)'; e.currentTarget.style.color = 'var(--color-text-muted)'; }}
        >
          ✨ Demo mode — explore with mock data
        </button>

        {/* Footer note */}
        <p style={{ textAlign: 'center', fontSize: 11.5, color: 'rgba(120,120,180,0.5)', marginTop: 18, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 5 }}>
          <Lock size={11} /> Never share this URL publicly
        </p>
      </div>
    </div>
  );
}

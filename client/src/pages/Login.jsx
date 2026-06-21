import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../lib/auth';
import { Heart, Lock, Mail, KeyRound, ChevronDown } from 'lucide-react';

export default function Login() {
  const { loginWithEmailPassword, loginWithToken, loginMock, firebaseAvailable } = useAuth();
  const navigate = useNavigate();
  const [mode, setMode] = useState('email');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [idToken, setIdToken] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e) {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      if (mode === 'email') {
        await loginWithEmailPassword(email, password);
      } else {
        await loginWithToken(idToken);
      }
      navigate('/dashboard');
    } catch (err) {
      setError(err.message.includes('auth/') 
        ? formatFirebaseError(err.message) 
        : err.message);
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

  function handleDemo() {
    loginMock();
    navigate('/dashboard');
  }

  const inputStyle = {
    width: '100%',
    background: 'var(--color-bg)',
    border: '1px solid var(--color-border)',
    borderRadius: 'var(--radius)',
    padding: '10px 12px 10px 38px',
    color: 'var(--color-text)',
    fontSize: 14,
    outline: 'none',
    transition: 'border-color 0.15s',
  };

  return (
    <div style={{
      minHeight: '100vh',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      background: 'var(--color-bg)',
      padding: 20,
    }}>
      <div style={{
        width: '100%',
        maxWidth: 400,
        background: 'var(--color-surface)',
        border: '1px solid var(--color-border)',
        borderRadius: 'var(--radius-lg)',
        padding: 40,
        boxShadow: '0 8px 32px rgba(0,0,0,0.4)',
      }}>
        <div style={{ textAlign: 'center', marginBottom: 32 }}>
          <div style={{
            width: 60, height: 60, borderRadius: 18,
            background: 'linear-gradient(135deg, #e05c7e, #c04060)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            margin: '0 auto 16px',
            boxShadow: '0 4px 16px rgba(224,92,126,0.4)',
          }}>
            <Heart size={30} color="#fff" fill="#fff" />
          </div>
          <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 6 }}>HeartSync Console</h1>
          <p style={{ fontSize: 13, color: 'var(--color-text-muted)' }}>Internal admin dashboard — authorized access only</p>
        </div>

        <div style={{ display: 'flex', gap: 6, marginBottom: 20, background: 'var(--color-bg)', borderRadius: 'var(--radius)', padding: 4 }}>
          {[
            { id: 'email', label: 'Email & Password', icon: Mail },
            { id: 'token', label: 'ID Token', icon: KeyRound },
          ].map(({ id, label, icon: Icon }) => (
            <button key={id} onClick={() => { setMode(id); setError(''); }} style={{
              flex: 1, padding: '8px', borderRadius: 7, border: 'none', cursor: 'pointer',
              background: mode === id ? 'var(--color-surface)' : 'transparent',
              color: mode === id ? 'var(--color-text)' : 'var(--color-text-muted)',
              fontSize: 12, fontWeight: mode === id ? 600 : 400,
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 5,
              boxShadow: mode === id ? '0 1px 4px rgba(0,0,0,0.2)' : 'none',
              transition: 'all 0.15s',
            }}>
              <Icon size={12} /> {label}
            </button>
          ))}
        </div>

        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          {mode === 'email' ? (
            <>
              <div style={{ position: 'relative' }}>
                <Mail size={15} style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)', color: 'var(--color-text-muted)' }} />
                <input
                  type="email"
                  value={email}
                  onChange={e => setEmail(e.target.value)}
                  placeholder="admin@yourapp.com"
                  required
                  style={inputStyle}
                  onFocus={e => e.target.style.borderColor = 'var(--color-primary)'}
                  onBlur={e => e.target.style.borderColor = 'var(--color-border)'}
                />
              </div>
              <div style={{ position: 'relative' }}>
                <KeyRound size={15} style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)', color: 'var(--color-text-muted)' }} />
                <input
                  type="password"
                  value={password}
                  onChange={e => setPassword(e.target.value)}
                  placeholder="Password"
                  required
                  style={inputStyle}
                  onFocus={e => e.target.style.borderColor = 'var(--color-primary)'}
                  onBlur={e => e.target.style.borderColor = 'var(--color-border)'}
                />
              </div>
              {!firebaseAvailable && (
                <p style={{ fontSize: 12, color: 'var(--color-warning)', background: 'rgba(250,204,21,0.08)', padding: '8px 12px', borderRadius: 'var(--radius)', border: '1px solid rgba(250,204,21,0.2)' }}>
                  Firebase not configured — add <code>VITE_FIREBASE_API_KEY</code> to secrets to enable real login.
                </p>
              )}
            </>
          ) : (
            <div>
              <label style={{ display: 'block', fontSize: 12, fontWeight: 500, marginBottom: 6, color: 'var(--color-text-muted)' }}>
                Firebase ID Token (with isAdmin claim)
              </label>
              <textarea
                value={idToken}
                onChange={e => setIdToken(e.target.value)}
                placeholder="eyJhbGci…"
                rows={4}
                style={{
                  width: '100%',
                  background: 'var(--color-bg)',
                  border: '1px solid var(--color-border)',
                  borderRadius: 'var(--radius)',
                  padding: '10px 12px',
                  color: 'var(--color-text)',
                  fontSize: 12,
                  fontFamily: 'monospace',
                  resize: 'vertical',
                  outline: 'none',
                }}
              />
            </div>
          )}

          {error && (
            <div style={{ padding: '10px 14px', background: 'rgba(248, 113, 113, 0.1)', border: '1px solid rgba(248, 113, 113, 0.3)', borderRadius: 'var(--radius)', fontSize: 13, color: 'var(--color-danger)' }}>
              {error}
            </div>
          )}

          <button
            type="submit"
            disabled={loading || (mode === 'email' ? (!email || !password) : !idToken.trim())}
            style={{
              padding: '12px',
              background: 'linear-gradient(135deg, #e05c7e, #c04060)',
              color: '#fff',
              border: 'none',
              borderRadius: 'var(--radius)',
              fontWeight: 600,
              fontSize: 14,
              opacity: loading || (mode === 'email' ? (!email || !password) : !idToken.trim()) ? 0.6 : 1,
              transition: 'opacity 0.15s',
              cursor: 'pointer',
            }}>
            {loading ? 'Signing in…' : 'Sign in'}
          </button>
        </form>

        <div style={{ display: 'flex', alignItems: 'center', gap: 12, margin: '18px 0' }}>
          <div style={{ flex: 1, height: 1, background: 'var(--color-border)' }} />
          <span style={{ fontSize: 12, color: 'var(--color-text-muted)' }}>or</span>
          <div style={{ flex: 1, height: 1, background: 'var(--color-border)' }} />
        </div>

        <button onClick={handleDemo} style={{
          width: '100%',
          padding: '11px',
          background: 'var(--color-surface-2)',
          color: 'var(--color-text)',
          border: '1px solid var(--color-border)',
          borderRadius: 'var(--radius)',
          fontWeight: 500,
          fontSize: 13,
          cursor: 'pointer',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          gap: 8,
        }}>
          Demo mode — explore with mock data
        </button>

        <p style={{ textAlign: 'center', fontSize: 12, color: 'var(--color-text-muted)', marginTop: 18, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 5 }}>
          <Lock size={11} />
          Never share this URL publicly
        </p>
      </div>
    </div>
  );
}

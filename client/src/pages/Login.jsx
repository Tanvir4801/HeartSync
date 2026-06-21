import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../lib/auth';
import { Heart, Lock } from 'lucide-react';

export default function Login() {
  const { loginWithToken, loginMock } = useAuth();
  const navigate = useNavigate();
  const [idToken, setIdToken] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e) {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await loginWithToken(idToken);
      navigate('/dashboard');
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  function handleDemo() {
    loginMock();
    navigate('/dashboard');
  }

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
      }}>
        <div style={{ textAlign: 'center', marginBottom: 32 }}>
          <div style={{
            width: 56, height: 56, borderRadius: 16,
            background: 'var(--color-primary)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            margin: '0 auto 16px',
          }}>
            <Heart size={28} color="#fff" fill="#fff" />
          </div>
          <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 6 }}>HeartSync Console</h1>
          <p style={{ fontSize: 14, color: 'var(--color-text-muted)' }}>Internal admin dashboard — authorized access only</p>
        </div>

        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
          <div>
            <label style={{ display: 'block', fontSize: 13, fontWeight: 500, marginBottom: 6, color: 'var(--color-text-muted)' }}>
              Firebase Admin ID Token
            </label>
            <textarea
              value={idToken}
              onChange={e => setIdToken(e.target.value)}
              placeholder="Paste your Firebase ID token with isAdmin claim…"
              rows={4}
              style={{
                width: '100%',
                background: 'var(--color-bg)',
                border: '1px solid var(--color-border)',
                borderRadius: 'var(--radius)',
                padding: '10px 12px',
                color: 'var(--color-text)',
                fontSize: 13,
                resize: 'vertical',
                outline: 'none',
              }}
            />
          </div>

          {error && (
            <div style={{ padding: '10px 14px', background: 'rgba(248, 113, 113, 0.1)', border: '1px solid rgba(248, 113, 113, 0.3)', borderRadius: 'var(--radius)', fontSize: 13, color: 'var(--color-danger)' }}>
              {error}
            </div>
          )}

          <button type="submit" disabled={loading || !idToken.trim()} style={{
            padding: '12px',
            background: 'var(--color-primary)',
            color: '#fff',
            border: 'none',
            borderRadius: 'var(--radius)',
            fontWeight: 600,
            fontSize: 14,
            opacity: loading || !idToken.trim() ? 0.6 : 1,
            transition: 'opacity 0.15s',
          }}>
            {loading ? 'Verifying…' : 'Sign in'}
          </button>
        </form>

        <div style={{ display: 'flex', alignItems: 'center', gap: 12, margin: '20px 0' }}>
          <div style={{ flex: 1, height: 1, background: 'var(--color-border)' }} />
          <span style={{ fontSize: 12, color: 'var(--color-text-muted)' }}>or</span>
          <div style={{ flex: 1, height: 1, background: 'var(--color-border)' }} />
        </div>

        <button onClick={handleDemo} style={{
          width: '100%',
          padding: '12px',
          background: 'var(--color-surface-2)',
          color: 'var(--color-text)',
          border: '1px solid var(--color-border)',
          borderRadius: 'var(--radius)',
          fontWeight: 500,
          fontSize: 14,
        }}>
          Demo mode (no Firebase)
        </button>

        <p style={{ textAlign: 'center', fontSize: 12, color: 'var(--color-text-muted)', marginTop: 20 }}>
          <Lock size={12} style={{ verticalAlign: 'middle', marginRight: 4 }} />
          This URL should never be shared or linked from the app
        </p>
      </div>
    </div>
  );
}

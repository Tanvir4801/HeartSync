import React, { useState } from 'react';
import { api } from '../lib/api';
import Card from '../components/Card';
import { Sparkles, Copy, Check } from 'lucide-react';

function ResultBox({ text, loading, label }) {
  const [copied, setCopied] = useState(false);
  function copy() {
    navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }
  return (
    <div style={{ marginTop: 14 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 6 }}>
        <span style={{ fontSize: 12, fontWeight: 600, color: 'var(--color-text-muted)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>{label}</span>
        {text && (
          <button onClick={copy} style={{ display: 'flex', alignItems: 'center', gap: 4, background: 'none', border: 'none', color: 'var(--color-text-muted)', cursor: 'pointer', fontSize: 12 }}>
            {copied ? <Check size={12} color="var(--color-success)" /> : <Copy size={12} />}
            {copied ? 'Copied' : 'Copy'}
          </button>
        )}
      </div>
      <div style={{
        minHeight: 80, padding: '12px 14px', borderRadius: 'var(--radius)',
        background: 'var(--color-bg)', border: '1px solid var(--color-border)',
        fontSize: 14, lineHeight: 1.65, color: loading ? 'var(--color-text-muted)' : 'var(--color-text)',
        whiteSpace: 'pre-wrap',
      }}>
        {loading ? 'Generating…' : text || <span style={{ color: 'var(--color-text-muted)' }}>Output will appear here</span>}
      </div>
    </div>
  );
}

function LoveLetter() {
  const [occasion, setOccasion] = useState('');
  const [tone, setTone] = useState('romantic');
  const [coupleId, setCoupleId] = useState('');
  const [result, setResult] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  async function generate() {
    setError(''); setLoading(true);
    try {
      const r = await api.ai.loveLetter(occasion, tone, coupleId);
      setResult(r.text);
    } catch (e) { setError(e.message); }
    finally { setLoading(false); }
  }

  const inputStyle = { width: '100%', padding: '9px 12px', background: 'var(--color-bg)', border: '1px solid var(--color-border)', borderRadius: 'var(--radius)', color: 'var(--color-text)', fontSize: 13, outline: 'none' };

  return (
    <Card>
      <h3 style={{ fontSize: 14, fontWeight: 700, marginBottom: 14, display: 'flex', alignItems: 'center', gap: 7 }}>
        <Sparkles size={15} color="var(--color-primary)" /> Love Letter Generator
      </h3>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
        <div>
          <label style={{ display: 'block', fontSize: 12, color: 'var(--color-text-muted)', marginBottom: 5 }}>Occasion</label>
          <input value={occasion} onChange={e => setOccasion(e.target.value)} placeholder="e.g. anniversary, missing you" style={inputStyle} />
        </div>
        <div>
          <label style={{ display: 'block', fontSize: 12, color: 'var(--color-text-muted)', marginBottom: 5 }}>Tone</label>
          <select value={tone} onChange={e => setTone(e.target.value)} style={{ ...inputStyle, cursor: 'pointer' }}>
            {['romantic', 'playful', 'heartfelt', 'poetic', 'funny'].map(t => <option key={t}>{t}</option>)}
          </select>
        </div>
      </div>
      <div style={{ marginTop: 10 }}>
        <label style={{ display: 'block', fontSize: 12, color: 'var(--color-text-muted)', marginBottom: 5 }}>Couple ID (for cost tracking)</label>
        <input value={coupleId} onChange={e => setCoupleId(e.target.value)} placeholder="optional" style={inputStyle} />
      </div>
      <button onClick={generate} disabled={loading || !occasion} style={{ marginTop: 12, padding: '9px 18px', background: 'var(--color-primary)', color: '#fff', border: 'none', borderRadius: 'var(--radius)', fontWeight: 600, fontSize: 13, cursor: loading || !occasion ? 'not-allowed' : 'pointer', opacity: loading || !occasion ? 0.6 : 1 }}>
        {loading ? 'Generating…' : 'Generate'}
      </button>
      {error && <div style={{ marginTop: 10, fontSize: 13, color: 'var(--color-danger)' }}>{error}</div>}
      <ResultBox text={result} loading={loading} label="Generated letter" />
    </Card>
  );
}

function CaptionGenerator() {
  const [description, setDescription] = useState('');
  const [coupleId, setCoupleId] = useState('');
  const [captions, setCaptions] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  async function generate() {
    setError(''); setLoading(true);
    try {
      const r = await api.ai.caption(description, coupleId);
      setCaptions(r.captions);
    } catch (e) { setError(e.message); }
    finally { setLoading(false); }
  }

  const inputStyle = { width: '100%', padding: '9px 12px', background: 'var(--color-bg)', border: '1px solid var(--color-border)', borderRadius: 'var(--radius)', color: 'var(--color-text)', fontSize: 13, outline: 'none' };

  return (
    <Card>
      <h3 style={{ fontSize: 14, fontWeight: 700, marginBottom: 14, display: 'flex', alignItems: 'center', gap: 7 }}>
        <Sparkles size={15} color="var(--color-primary)" /> Caption Generator
      </h3>
      <div>
        <label style={{ display: 'block', fontSize: 12, color: 'var(--color-text-muted)', marginBottom: 5 }}>Memory description</label>
        <input value={description} onChange={e => setDescription(e.target.value)} placeholder="e.g. sunset photo from our Goa trip" style={inputStyle} />
      </div>
      <div style={{ marginTop: 10 }}>
        <label style={{ display: 'block', fontSize: 12, color: 'var(--color-text-muted)', marginBottom: 5 }}>Couple ID</label>
        <input value={coupleId} onChange={e => setCoupleId(e.target.value)} placeholder="optional" style={inputStyle} />
      </div>
      <button onClick={generate} disabled={loading} style={{ marginTop: 12, padding: '9px 18px', background: 'var(--color-primary)', color: '#fff', border: 'none', borderRadius: 'var(--radius)', fontWeight: 600, fontSize: 13, cursor: loading ? 'not-allowed' : 'pointer', opacity: loading ? 0.6 : 1 }}>
        {loading ? 'Generating…' : 'Suggest captions'}
      </button>
      {error && <div style={{ marginTop: 10, fontSize: 13, color: 'var(--color-danger)' }}>{error}</div>}
      {captions.length > 0 && (
        <div style={{ marginTop: 14 }}>
          <span style={{ fontSize: 12, fontWeight: 600, color: 'var(--color-text-muted)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Suggestions</span>
          {captions.map((c, i) => (
            <div key={i} style={{ marginTop: 8, padding: '10px 14px', borderRadius: 'var(--radius)', background: 'var(--color-bg)', border: '1px solid var(--color-border)', fontSize: 14 }}>
              {c}
            </div>
          ))}
        </div>
      )}
    </Card>
  );
}

function MonthlyRecap() {
  const [coupleId, setCoupleId] = useState('');
  const [month, setMonth] = useState(new Date().toLocaleString('default', { month: 'long' }));
  const [stats, setStats] = useState({ memories: '', messages: '', moods: '', streak: '' });
  const [result, setResult] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  async function generate() {
    setError(''); setLoading(true);
    try {
      const cleanStats = { memories: +stats.memories || 0, messages: +stats.messages || 0, moods: +stats.moods || 0, streak: +stats.streak || 0 };
      const r = await api.ai.monthlyRecap(coupleId, month, new Date().getFullYear(), cleanStats);
      setResult(r.recap);
    } catch (e) { setError(e.message); }
    finally { setLoading(false); }
  }

  const inputStyle = { width: '100%', padding: '9px 12px', background: 'var(--color-bg)', border: '1px solid var(--color-border)', borderRadius: 'var(--radius)', color: 'var(--color-text)', fontSize: 13, outline: 'none' };

  return (
    <Card>
      <h3 style={{ fontSize: 14, fontWeight: 700, marginBottom: 14, display: 'flex', alignItems: 'center', gap: 7 }}>
        <Sparkles size={15} color="var(--color-primary)" /> Monthly Recap Generator
      </h3>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
        <div>
          <label style={{ display: 'block', fontSize: 12, color: 'var(--color-text-muted)', marginBottom: 5 }}>Couple ID</label>
          <input value={coupleId} onChange={e => setCoupleId(e.target.value)} placeholder="e.g. c001" style={inputStyle} />
        </div>
        <div>
          <label style={{ display: 'block', fontSize: 12, color: 'var(--color-text-muted)', marginBottom: 5 }}>Month</label>
          <input value={month} onChange={e => setMonth(e.target.value)} placeholder="e.g. June" style={inputStyle} />
        </div>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 8, marginTop: 10 }}>
        {['memories', 'messages', 'moods', 'streak'].map(k => (
          <div key={k}>
            <label style={{ display: 'block', fontSize: 11, color: 'var(--color-text-muted)', marginBottom: 4, textTransform: 'capitalize' }}>{k}</label>
            <input type="number" value={stats[k]} onChange={e => setStats(s => ({ ...s, [k]: e.target.value }))} placeholder="0" style={{ ...inputStyle, padding: '7px 10px' }} />
          </div>
        ))}
      </div>
      <button onClick={generate} disabled={loading || !coupleId} style={{ marginTop: 12, padding: '9px 18px', background: 'var(--color-primary)', color: '#fff', border: 'none', borderRadius: 'var(--radius)', fontWeight: 600, fontSize: 13, cursor: loading || !coupleId ? 'not-allowed' : 'pointer', opacity: loading || !coupleId ? 0.6 : 1 }}>
        {loading ? 'Generating…' : 'Generate recap'}
      </button>
      {error && <div style={{ marginTop: 10, fontSize: 13, color: 'var(--color-danger)' }}>{error}</div>}
      <ResultBox text={result} loading={loading} label="Generated recap" />
    </Card>
  );
}

export default function AIPlayground() {
  return (
    <div>
      <div style={{ marginBottom: 24 }}>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 4 }}>AI Playground</h1>
        <p style={{ fontSize: 14, color: 'var(--color-text-muted)' }}>Test the AI endpoints the Flutter app calls — all via Gemini, all cost-logged</p>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20 }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
          <LoveLetter />
          <MonthlyRecap />
        </div>
        <div>
          <CaptionGenerator />
          <div style={{ marginTop: 20, padding: '14px 16px', background: 'var(--color-surface)', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-lg)', fontSize: 13 }}>
            <div style={{ fontWeight: 600, marginBottom: 8 }}>Flutter app endpoints</div>
            {[
              ['POST', '/api/ai/love-letter', '{ occasion, tone }'],
              ['POST', '/api/ai/caption', '{ memoryId, description }'],
              ['POST', '/api/ai/monthly-recap', '{ coupleId, month, year, stats }'],
            ].map(([method, path, body]) => (
              <div key={path} style={{ marginBottom: 8, fontFamily: 'monospace', fontSize: 12 }}>
                <span style={{ color: 'var(--color-primary)', fontWeight: 700 }}>{method}</span>{' '}
                <span style={{ color: 'var(--color-text)' }}>{path}</span>{' '}
                <span style={{ color: 'var(--color-text-muted)' }}>{body}</span>
              </div>
            ))}
            <div style={{ marginTop: 10, fontSize: 12, color: 'var(--color-text-muted)', lineHeight: 1.6 }}>
              These routes require a Bearer token. The Flutter app must send the couple's Firebase ID token. Costs are logged to <code style={{ background: 'var(--color-bg)', padding: '1px 4px', borderRadius: 3 }}>admin/ai_usage/logs</code>.
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

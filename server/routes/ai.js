const express = require('express');
const router = express.Router();
const { getFirestore } = require('../firebase');

async function callGemini(prompt) {
  const apiKey = process.env.GOOGLE_API_KEY;
  if (!apiKey) throw new Error('GOOGLE_API_KEY not configured');

  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { maxOutputTokens: 1024, temperature: 0.9 },
      }),
    }
  );
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error?.message || `Gemini API error ${res.status}`);
  }
  const data = await res.json();
  const text = data.candidates?.[0]?.content?.parts?.[0]?.text || '';
  const tokensUsed = data.usageMetadata?.totalTokenCount || 0;
  return { text, tokensUsed };
}

async function logUsage(db, { endpoint, coupleId, tokensUsed }) {
  const costPer1kTokens = 0.000075;
  const costEstimate = parseFloat(((tokensUsed / 1000) * costPer1kTokens).toFixed(6));
  const entry = { endpoint, coupleId: coupleId || 'unknown', tokensUsed, costEstimate, timestamp: new Date().toISOString() };
  if (db) {
    await db.collection('admin').doc('ai_usage').collection('logs').add(entry).catch(console.error);
  }
  return costEstimate;
}

router.post('/love-letter', async (req, res) => {
  const { occasion, tone, coupleId } = req.body;
  if (!occasion || !tone) return res.status(400).json({ error: 'occasion and tone are required' });

  try {
    const prompt = `Write a heartfelt love letter for a long-distance couple. Occasion: ${occasion}. Tone: ${tone}. Make it personal, warm, and about 150-200 words. Do not include a salutation or signature — just the body of the letter.`;
    const { text, tokensUsed } = await callGemini(prompt);
    const db = getFirestore();
    await logUsage(db, { endpoint: 'love-letter', coupleId, tokensUsed });
    res.json({ text, tokensUsed });
  } catch (err) {
    console.error('AI love-letter error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

router.post('/caption', async (req, res) => {
  const { memoryId, description, coupleId } = req.body;

  try {
    const prompt = `Suggest 3 short, heartfelt captions for a couple's photo or memory. ${description ? `Context: ${description}.` : ''} Each caption should be under 15 words, romantic, and suitable for a private couple's app. Return them as a numbered list.`;
    const { text, tokensUsed } = await callGemini(prompt);
    const db = getFirestore();
    await logUsage(db, { endpoint: 'caption', coupleId, tokensUsed });
    const captions = text.split('\n').filter(l => l.match(/^\d/)).map(l => l.replace(/^\d+\.\s*/, '').trim()).filter(Boolean);
    res.json({ captions: captions.length ? captions : [text.trim()], tokensUsed });
  } catch (err) {
    console.error('AI caption error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

router.post('/monthly-recap', async (req, res) => {
  const { coupleId, month, year, stats } = req.body;
  if (!coupleId) return res.status(400).json({ error: 'coupleId required' });

  try {
    const statsStr = stats
      ? `They shared ${stats.memories || 0} memories, sent ${stats.messages || 0} messages, logged ${stats.moods || 0} moods, and maintained a ${stats.streak || 0}-day streak.`
      : 'Data not provided.';
    const prompt = `Write a warm, poetic 2-3 sentence monthly recap for a couple's private app. Month: ${month || 'this month'} ${year || ''}. ${statsStr} Make it feel celebratory and personal, highlighting their connection.`;
    const { text, tokensUsed } = await callGemini(prompt);
    const db = getFirestore();
    await logUsage(db, { endpoint: 'monthly-recap', coupleId, tokensUsed });
    res.json({ recap: text.trim(), tokensUsed });
  } catch (err) {
    console.error('AI monthly-recap error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

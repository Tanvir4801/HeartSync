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

const GENERATE_PROMPTS = {
  anniversary: ({ tone, context }) =>
    `Write a heartfelt anniversary message for a couple. Tone: ${tone || 'romantic'}. ${context ? `Context: ${context}.` : ''} Keep it 100-150 words. Just the message body, no salutation.`,
  birthday: ({ tone, context }) =>
    `Write a birthday message from one partner to another. Tone: ${tone || 'warm'}. ${context ? `Context: ${context}.` : ''} Keep it 80-120 words. Just the message body.`,
  apology: ({ tone, context }) =>
    `Write a sincere apology message from one partner to another. Tone: ${tone || 'sincere'}. ${context ? `Context: ${context}.` : ''} Keep it 100-130 words. Acknowledge the issue, express genuine remorse, and offer to do better. Just the body.`,
  poem: ({ tone, context }) =>
    `Write a short love poem for a couple. Tone: ${tone || 'tender'}. ${context ? `Context: ${context}.` : ''} 4-6 stanzas, rhyming or free verse. Just the poem.`,
  'love-letter': ({ tone, context }) =>
    `Write a heartfelt love letter. Tone: ${tone || 'romantic'}. ${context ? `Context: ${context}.` : ''} 150-200 words. Just the body of the letter, no salutation or signature.`,
  'good-morning': ({ tone, context }) =>
    `Write a sweet good morning message from one partner to another. Tone: ${tone || 'warm'}. ${context ? `Context: ${context}.` : ''} Keep it 50-80 words. Just the message.`,
  'good-night': ({ tone, context }) =>
    `Write a tender good night message from one partner to another. Tone: ${tone || 'cozy'}. ${context ? `Context: ${context}.` : ''} Keep it 50-80 words. Just the message.`,
  'miss-you': ({ tone, context }) =>
    `Write a heartfelt "I miss you" message. Tone: ${tone || 'longing'}. ${context ? `Context: ${context}.` : ''} Keep it 60-90 words. Just the message body.`,
};

router.post('/generate', async (req, res) => {
  const { type, tone, context, coupleId } = req.body;
  if (!type) return res.status(400).json({ error: 'type is required' });

  const promptFn = GENERATE_PROMPTS[type];
  if (!promptFn) return res.status(400).json({ error: `Unknown type "${type}". Valid: ${Object.keys(GENERATE_PROMPTS).join(', ')}` });

  try {
    const prompt = promptFn({ tone, context });
    const { text, tokensUsed } = await callGemini(prompt);
    const db = getFirestore();
    await logUsage(db, { endpoint: `generate/${type}`, coupleId, tokensUsed });
    res.json({ text: text.trim(), type, tokensUsed });
  } catch (err) {
    console.error(`AI generate/${type} error:`, err.message);
    res.status(500).json({ error: err.message });
  }
});

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
    const prompt = `Write a warm, poetic 2-3 sentence monthly recap for a couple's private app. Month: ${month || 'this month'} ${year || ''}. ${statsStr} Make it feel celebratory and personal, highlighting their connection. Important: Label it clearly as a generated reflection, not an assessment of the relationship.`;
    const { text, tokensUsed } = await callGemini(prompt);
    const db = getFirestore();
    await logUsage(db, { endpoint: 'monthly-recap', coupleId, tokensUsed });
    res.json({ recap: text.trim(), tokensUsed });
  } catch (err) {
    console.error('AI monthly-recap error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

router.post('/insights', async (req, res) => {
  const { coupleId, month, year, stats } = req.body;
  if (!coupleId) return res.status(400).json({ error: 'coupleId required' });

  try {
    const statsStr = stats
      ? `Messages sent: ${stats.messages || 0}. Mood trend: ${stats.moodTrend || 'not available'}. Memories added: ${stats.memories || 0}. Streak: ${stats.streak || 0} days.`
      : 'Activity data not provided.';
    const prompt = `Write a warm, 2-paragraph AI-generated relationship reflection for a private couple's app for ${month || 'this month'} ${year || ''}. ${statsStr} IMPORTANT: Label this clearly as a generated reflection based on activity data — not an assessment or evaluation of the relationship or the people in it. Be encouraging and celebratory. Keep it under 120 words total.`;
    const { text, tokensUsed } = await callGemini(prompt);
    const db = getFirestore();
    await logUsage(db, { endpoint: 'insights', coupleId, tokensUsed });
    res.json({ insights: text.trim(), tokensUsed, disclaimer: 'This is an AI-generated reflection based on your activity data. It is not a relationship assessment.' });
  } catch (err) {
    console.error('AI insights error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

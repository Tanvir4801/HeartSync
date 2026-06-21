const express = require('express');
const router = express.Router();
const { getMessaging } = require('../firebase');

router.post('/broadcast', async (req, res) => {
  const { title, body } = req.body;
  if (!title || !body) return res.status(400).json({ error: 'title and body required' });

  const messaging = getMessaging();
  if (!messaging) {
    console.log(`[MOCK] Broadcast: "${title}" — ${body}`);
    return res.json({ success: true, mock: true, messageId: 'mock-msg-id' });
  }

  try {
    const messageId = await messaging.send({
      topic: 'all-users',
      notification: { title, body },
    });
    res.json({ success: true, messageId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

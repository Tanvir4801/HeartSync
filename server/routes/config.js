const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
  res.json({
    firebase: {
      apiKey: process.env.GOOGLE_API_KEY || '',
      authDomain: process.env.VITE_FIREBASE_AUTH_DOMAIN || 'heartsync-b4e9f.firebaseapp.com',
      projectId: process.env.VITE_FIREBASE_PROJECT_ID || 'heartsync-b4e9f',
      storageBucket: process.env.VITE_FIREBASE_STORAGE_BUCKET || 'heartsync-b4e9f.firebasestorage.app',
      messagingSenderId: process.env.VITE_FIREBASE_MESSAGING_SENDER_ID || '324450946196',
      appId: process.env.VITE_FIREBASE_APP_ID || '1:324450946196:web:cc0d6675befd6a712eb881',
      measurementId: process.env.VITE_FIREBASE_MEASUREMENT_ID || 'G-KELNLQ2YKY',
    },
  });
});

module.exports = router;

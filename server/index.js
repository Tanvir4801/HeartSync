const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;

app.use(helmet({ contentSecurityPolicy: false }));
app.use(cors({ origin: true, credentials: true }));
app.use(morgan('dev'));
app.use(express.json());

const { initFirebase } = require('./firebase');
initFirebase();

const adminMiddleware = require('./middleware/adminAuth');

app.use('/api/config', require('./routes/config'));
app.use('/api/auth', require('./routes/auth'));
app.use('/api/stats', adminMiddleware, require('./routes/stats'));
app.use('/api/couples', adminMiddleware, require('./routes/couples'));
app.use('/api/reports', adminMiddleware, require('./routes/reports'));
app.use('/api/notifications', adminMiddleware, require('./routes/notifications'));
app.use('/api/flags', adminMiddleware, require('./routes/flags'));
app.use('/api/ai-usage', adminMiddleware, require('./routes/aiUsage'));
app.use('/api/ai', adminMiddleware, require('./routes/ai'));
app.use('/api/webhooks/revenuecat', require('./routes/revenuecat'));
app.use('/api/spotify', require('./routes/spotify'));

app.use('/api/themes', adminMiddleware, require('./routes/themes'));
app.use('/api/support', adminMiddleware, require('./routes/support'));
app.use('/api/analytics', adminMiddleware, require('./routes/analytics'));
app.use('/api/audit', adminMiddleware, require('./routes/audit'));
app.use('/api/gdpr', adminMiddleware, require('./routes/gdpr'));
app.use('/api/revenue', adminMiddleware, require('./routes/revenue'));

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Internal server error' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`HeartSync Console API running on port ${PORT}`);
});

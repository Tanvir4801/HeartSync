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

app.use('/api/auth', require('./routes/auth'));
app.use('/api/stats', adminMiddleware, require('./routes/stats'));
app.use('/api/couples', adminMiddleware, require('./routes/couples'));
app.use('/api/reports', adminMiddleware, require('./routes/reports'));
app.use('/api/notifications', adminMiddleware, require('./routes/notifications'));
app.use('/api/flags', adminMiddleware, require('./routes/flags'));
app.use('/api/ai-usage', adminMiddleware, require('./routes/aiUsage'));
app.use('/api/webhooks/revenuecat', require('./routes/revenuecat'));

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Internal server error' });
});

app.listen(PORT, 'localhost', () => {
  console.log(`HeartSync Console API running on http://localhost:${PORT}`);
});

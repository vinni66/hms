require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');
const db = require('./services/database');
const apiRoutes = require('./routes/api');
const reportsRoutes = require('./routes/reports');
const wellnessRoutes = require('./routes/wellness');
const auth = require('./services/auth');
const authenticate = (req, res, next) => auth.authMiddleware(req, res, next);

const app = express();
const PORT = process.env.PORT || 3000;

// ── Middleware ──
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Ensure DB is ready before any request
app.use(async (req, res, next) => {
  try {
    await db.ready;
    next();
  } catch (err) {
    res.status(500).json({ error: 'Database initialization failed', details: err.message });
  }
});

// ── Static uploads folder ──
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// ── API Routes ──
app.use('/api', apiRoutes);
app.use('/api/reports', authenticate, reportsRoutes);
app.use('/api/wellness', authenticate, wellnessRoutes);

// ── Root ──
app.get('/', (req, res) => {
  res.json({
    name: '🏥 AI Healthcare Backend',
    version: '1.0.0',
    description: 'Intelligent Healthcare System for Early Disease Prediction Using AI',
    ai_engine: 'Ollama (Offline)',
    model: process.env.OLLAMA_MODEL || 'llama3.2',
    endpoints: {
      health: 'GET /api/health',
      users: 'POST /api/users | GET /api/users/:id | PUT /api/users/:id',
      chat: 'GET /api/chat/:userId/:convoId | POST /api/chat/send | DELETE /api/chat/:userId/:convoId',
      appointments: 'GET /api/appointments/:userId | POST /api/appointments | PUT /api/appointments/:id/complete | DELETE /api/appointments/:id',
      metrics: 'GET /api/metrics/:userId | POST /api/metrics | DELETE /api/metrics/:id',
      reports: 'GET /api/reports/:userId | POST /api/reports | POST /api/reports/:id/analyze | DELETE /api/reports/:id',
      symptoms: 'POST /api/analyze/symptoms',
    },
  });
});

// ── 404 ──
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found', path: req.path });
});

// ── Error handler ──
app.use((err, req, res, next) => {
  console.error('❌ Server error:', err);
  res.status(500).json({ error: 'Internal server error', message: err.message });
});

// ── Export App (Required for Vercel) ──
module.exports = app;

// ── Start (Only if running directly / locally) ──
if (require.main === module) {
  async function start() {
    await db.ready;

    app.listen(PORT, () => {
      console.log(`
    ╔══════════════════════════════════════════════╗
    ║   🏥 AI Healthcare Backend                  ║
    ║   Port: ${PORT}                                ║
    ║   AI: Ollama (${process.env.OLLAMA_MODEL || 'llama3.2'})                    ║
    ║   Ollama: ${process.env.OLLAMA_URL || 'http://localhost:11434'}    ║
    ╚══════════════════════════════════════════════╝
    
    API:      http://localhost:${PORT}/api
    Health:   http://localhost:${PORT}/api/health
      `);
    });
  }

  start().catch(err => {
    console.error('Failed to start server:', err);
    process.exit(1);
  });
}

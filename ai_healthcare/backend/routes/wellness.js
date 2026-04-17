const express = require('express');
const router = express.Router();
const db = require('../services/database');

// Get all wellness goals for the authenticated user
router.get('/goals', async (req, res) => {
  try {
    const goals = await db.getWellnessGoals(req.user.id);
    res.json(goals);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update or create a wellness goal
router.post('/goals', async (req, res) => {
  try {
    const { type, value, unit } = req.body;
    if (!type || value === undefined) {
      return res.status(400).json({ error: 'Type and value are required' });
    }
    const goal = await db.updateWellnessGoal(req.user.id, type, value, unit);
    res.json(goal);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get daily progress (aggregates metrics for today)
router.get('/progress', async (req, res) => {
  try {
    const userId = req.user.id;
    const date = req.query.date || new Date().toISOString().split('T')[0];
    
    // In a real app, this would be a more complex SQL query
    // For now, we'll fetch all metrics for today and manually aggregate or return raw
    const metrics = await db._all(`
      SELECT type, SUM(value) as total, unit 
      FROM health_metrics 
      WHERE user_id = $1 AND timestamp::date = $2::date
      GROUP BY type, unit
    `, [userId, date]);
    
    res.json(metrics);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

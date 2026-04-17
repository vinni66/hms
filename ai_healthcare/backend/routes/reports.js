const express = require('express');
const router = express.Router();
const db = require('../services/database');
const ollama = require('../services/ollama');

// middleware to ensure user is in req.user (already handled by authenticate in server.js)

// Get all reports for the user
router.get('/', async (req, res) => {
  try {
    const userId = req.user.id;
    const reports = await db.getReports(userId);
    res.json(reports);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create a new report
router.post('/', async (req, res) => {
  try {
    const userId = req.user.id;
    const { image_path, extracted_text } = req.body;
    
    let report = await db.insertReport({
      user_id: userId,
      image_path: image_path || '',
      extracted_text: extracted_text || '',
    });

    // Auto-analyze if text is provided
    if (extracted_text) {
      const analysis = await ollama.analyzeReport(extracted_text);
      await db.updateReport(report.id, { ai_summary: analysis.text });
      report = { ...report, ai_summary: analysis.text };
    }

    res.json(report);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Analyze existing report
router.post('/:id/analyze', async (req, res) => {
  try {
    const { id } = req.params;
    const { extracted_text } = req.body; // Optional if already in DB
    
    let textToAnalyze = extracted_text;
    if (!textToAnalyze) {
      const reports = await db.getReports(req.user.id);
      const report = reports.find(r => r.id === id);
      if (!report) return res.status(404).json({ error: 'Report not found' });
      textToAnalyze = report.extracted_text;
    }

    if (!textToAnalyze) return res.status(400).json({ error: 'No text to analyze' });

    const analysis = await ollama.analyzeReport(textToAnalyze);
    await db.updateReport(id, { ai_summary: analysis.text });
    
    res.json({ ai_summary: analysis.text, risk: analysis.risk });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete report
router.delete('/:id', async (req, res) => {
  try {
    await db.deleteReport(req.params.id);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

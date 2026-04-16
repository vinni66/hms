const express = require('express');
const { v4: uuidv4 } = require('uuid');
const db = require('../services/database');
const auth = require('../services/auth');
const ollama = require('../services/ollama');

const router = express.Router();
const mw = auth.authMiddleware.bind(auth);

// Global active calls registry -> targetId: { callerId, callerName, role }
global.activeCalls = {};

// ═══════════════════════════════════════
//  AUTH (Public)
// ═══════════════════════════════════════
router.post('/auth/register', async (req, res) => {
  try {
    const { email, password, name, role, age, gender, phone, blood_group } = req.body;
    if (!email || !password || !name) return res.status(400).json({ error: 'Missing required fields' });
    if (await db.getUserByEmail(email)) return res.status(400).json({ error: 'Email already exists' });

    // Restrict role assignment unless specified securely (simplified for prototype)
    const assignedRole = role && ['patient', 'doctor', 'receptionist', 'admin'].includes(role) ? role : 'patient';

    const hashedPassword = await auth.hashPassword(password);
    const user = await db.createUser({
      email, password: hashedPassword, name,
      role: assignedRole,
      age, gender, phone, blood_group,
    });
    const token = auth.generateToken(user);
    res.status(201).json({ token, user });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ error: 'email and password required' });

    const user = await db.getUserByEmail(email);
    if (!user) return res.status(401).json({ error: 'Invalid email or password' });

    const valid = await auth.comparePassword(password, user.password);
    if (!valid) return res.status(401).json({ error: 'Invalid email or password' });

    delete user.password;
    const token = auth.generateToken(user);
    res.json({ token, user });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/auth/me', mw, async (req, res) => {
  const user = await db.getUser(req.user.id);
  if (!user) return res.status(404).json({ error: 'User not found' });
  res.json(user);
});

// ═══════════════════════════════════════
//  CALL SIGNALING (Real-time Simulation)
// ═══════════════════════════════════════

router.post('/calls/start', mw, (req, res) => {
  const { target_id, caller_name, role } = req.body;
  if (!target_id) return res.status(400).json({ error: 'target_id is required' });
  
  global.activeCalls[target_id] = {
    caller_id: req.user.id,
    caller_name: caller_name || 'Anonymous',
    role: role || 'user',
    timestamp: Date.now()
  };
  res.json({ success: true, message: 'Call initiated' });
});

router.get('/calls/ping', mw, (req, res) => {
  const incoming = global.activeCalls[req.user.id];
  // Auto-expire calls older than 30 seconds
  if (incoming && (Date.now() - incoming.timestamp > 30000)) {
    delete global.activeCalls[req.user.id];
    return res.json({ incoming: null });
  }
  res.json({ incoming: incoming || null });
});

router.post('/calls/end', mw, (req, res) => {
  const { target_id } = req.body;
  // If user ends incoming call
  if (global.activeCalls[req.user.id]) {
    delete global.activeCalls[req.user.id];
  }
  // If caller ends outgoing call
  if (target_id && global.activeCalls[target_id] && global.activeCalls[target_id].caller_id === req.user.id) {
    delete global.activeCalls[target_id];
  }
  res.json({ success: true });
});

// ═══════════════════════════════════════
//  HEALTH CHECK (Public)
// ═══════════════════════════════════════
router.get('/health', async (req, res) => {
  const ollamaStatus = await ollama.checkHealth();
  res.json({ status: 'ok', server: 'AI Healthcare Backend', ollama: ollamaStatus, timestamp: new Date().toISOString() });
});

// ═══════════════════════════════════════
//  DOCTORS (Public listing)
// ═══════════════════════════════════════
router.get('/doctors', async (req, res) => {
  res.json(await db.getDoctors());
});

// ═══════════════════════════════════════
//  USER PROFILE (Protected)
// ═══════════════════════════════════════
router.get('/users/:id', mw, async (req, res) => {
  const user = await db.getUser(req.params.id);
  if (!user) return res.status(404).json({ error: 'User not found' });
  res.json(user);
});

router.put('/users/:id', mw, async (req, res) => {
  if (req.user.id !== req.params.id && req.user.role !== 'admin')
    return res.status(403).json({ error: 'Cannot update other users' });
  const user = await db.updateUser(req.params.id, req.body);
  res.json(user);
});

// ═══════════════════════════════════════
//  APPOINTMENTS (Protected)
// ═══════════════════════════════════════
router.get('/appointments', mw, async (req, res) => {
  res.json(await db.getAppointments(req.user.id, req.user.role));
});

router.get('/appointments/:id', mw, async (req, res) => {
  const apt = await db.getAppointment(req.params.id);
  if (!apt) return res.status(404).json({ error: 'Appointment not found' });
  res.json(apt);
});

router.post('/appointments', mw, async (req, res) => {
  try {
    const { doctor_id, date_time, location, notes, patient_id } = req.body;
    if (!doctor_id || !date_time) return res.status(400).json({ error: 'doctor_id and date_time required' });

    const doctor = await db.getUser(doctor_id);
    if (!doctor) return res.status(404).json({ error: 'Doctor not found' });

    // Allow receptionist or admin to specify patient_id, otherwise use current user
    const actualPatientId = (req.user.role === 'receptionist' || req.user.role === 'admin') && patient_id ? patient_id : req.user.id;
    const patient = await db.getUser(actualPatientId);

    const apt = await db.insertAppointment({
      patient_id: actualPatientId,
      doctor_id,
      doctor_name: doctor.name,
      patient_name: patient?.name || req.user.name,
      specialty: doctor.specialty || '',
      date_time,
      location: location || '',
      notes: notes || '',
    });
    res.status(201).json(apt);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/appointments/:id/status', mw, async (req, res) => {
  const { status } = req.body;
  await db.updateAppointmentStatus(req.params.id, status);
  res.json({ success: true });
});

router.put('/appointments/:id/notes', mw, async (req, res) => {
  const { consultation_notes } = req.body;
  await db.addConsultationNotes(req.params.id, consultation_notes);
  res.json({ success: true });
});

router.delete('/appointments/:id', mw, async (req, res) => {
  await db.deleteAppointment(req.params.id);
  res.json({ success: true });
});

// ═══════════════════════════════════════
//  PRESCRIPTIONS & PHARMACIES (Protected)
// ═══════════════════════════════════════
router.get('/prescriptions', mw, async (req, res) => {
  res.json(await db.getPrescriptions(req.user.id, req.user.role));
});

router.get('/pharmacies/search', mw, async (req, res) => {
  const { medicine } = req.query;
  if (!medicine) return res.status(400).json({ error: 'medicine query param required' });
  res.json(await db.getPharmaciesForMedicine(medicine));
});

router.post('/prescriptions', mw, async (req, res) => {
  try {
    const { patient_id, diagnosis, medications, instructions, appointment_id } = req.body;
    if (!patient_id || !diagnosis) return res.status(400).json({ error: 'patient_id and diagnosis required' });

    const patient = await db.getUser(patient_id);
    const doctor = await db.getUser(req.user.id);
    const p = await db.insertPrescription({
      appointment_id, patient_id,
      doctor_id: req.user.id,
      doctor_name: doctor?.name || req.user.name,
      patient_name: patient?.name || 'Patient',
      diagnosis, medications: medications || [], instructions: instructions || '',
    });
    res.status(201).json(p);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/prescriptions/:id', mw, async (req, res) => {
  await db.deletePrescription(req.params.id);
  res.json({ success: true });
});

// ═══════════════════════════════════════
//  HEALTH METRICS (Protected)
// ═══════════════════════════════════════
router.get('/metrics', mw, async (req, res) => {
  res.json(await db.getMetrics(req.user.id));
});

router.get('/metrics/latest/:type', mw, async (req, res) => {
  const m = await db.getLatestMetric(req.user.id, req.params.type);
  res.json(m || {});
});

router.post('/metrics', mw, async (req, res) => {
  try {
    const m = await db.insertMetric({ ...req.body, user_id: req.user.id });
    res.status(201).json(m);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/metrics/:id', mw, async (req, res) => {
  await db.deleteMetric(req.params.id);
  res.json({ success: true });
});

// ═══════════════════════════════════════
//  SCAN REPORTS (Protected)
// ═══════════════════════════════════════
router.get('/reports', mw, async (req, res) => {
  res.json(await db.getReports(req.user.id));
});

router.post('/reports', mw, async (req, res) => {
  try {
    const r = await db.insertReport({ ...req.body, user_id: req.user.id });
    res.status(201).json(r);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/reports/:id/analyze', mw, async (req, res) => {
  try {
    const { extracted_text, image } = req.body;
    let analysis;
    if (image) {
      analysis = await ollama.chat([], 'Extract all text from this medical report and then provide a summary of the key findings in simple English, highlighting any abnormalities.', image);
    } else if (extracted_text) {
      analysis = await ollama.analyzeReport(extracted_text);
    } else {
      return res.status(400).json({ error: 'extracted_text or image required' });
    }
    await db.updateReport(req.params.id, { ai_summary: analysis.text });
    res.json({ ai_summary: analysis.text, risk: analysis.risk });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/reports/:id', mw, async (req, res) => {
  await db.deleteReport(req.params.id);
  res.json({ success: true });
});

// ═══════════════════════════════════════
//  MEDICAL RECORDS (Protected)
// ═══════════════════════════════════════
router.get('/records/:patientId', mw, async (req, res) => {
  res.json(await db.getRecords(req.params.patientId));
});

router.post('/records', mw, async (req, res) => {
  try {
    const r = await db.insertRecord({ ...req.body, created_by: req.user.id });
    res.status(201).json(r);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/records/:id', mw, async (req, res) => {
  await db.deleteRecord(req.params.id);
  res.json({ success: true });
});

// ═══════════════════════════════════════
//  CHAT / AI (Protected)
// ═══════════════════════════════════════
router.get('/chat/:conversationId', mw, async (req, res) => {
  res.json(await db.getMessages(req.user.id, req.params.conversationId));
});

router.post('/chat/send', mw, async (req, res) => {
  try {
    const { conversation_id, message, history, image } = req.body;
    if (!message && !image) return res.status(400).json({ error: 'message or image required' });

    const convoId = conversation_id || uuidv4();
    const userMsg = { 
      id: uuidv4(), user_id: req.user.id, conversation_id: convoId, 
      text: message || '[Image Attached]', is_user: true, 
      risk_level: 'normal', timestamp: new Date().toISOString() 
    };
    await db.insertMessage(userMsg);

    // Build patient context
    const patientData = await db.getUser(req.user.id);
    const pastAppointments = (await db.getAppointments(req.user.id, req.user.role)).filter(a => a.status === 'completed');
    const prescriptions = await db.getPrescriptions(req.user.id, req.user.role);
    
    let contextStr = `Patient Name: ${patientData.name}\nAge: ${patientData.age || 'Unknown'}\nBlood Group: ${patientData.blood_group || 'Unknown'}\n`;
    
    if (pastAppointments.length > 0) {
      contextStr += `Past Medical History (Completed Appointments):\n`;
      pastAppointments.forEach(a => {
        contextStr += `- Seen by ${a.doctor_name} (${a.specialty}) on ${new Date(a.date_time).toLocaleDateString()}. Notes: ${a.consultation_notes || 'None'}\n`;
      });
    }
    
    if (prescriptions.length > 0) {
      contextStr += `Active Prescriptions:\n`;
      prescriptions.forEach(p => {
        let medList = 'None';
        try {
          const meds = typeof p.medications === 'string' ? JSON.parse(p.medications) : p.medications;
          medList = Array.isArray(meds) ? meds.map(m => m.name || m.medication || m).join(', ') : meds;
        } catch(e) {}
        contextStr += `- Diagnosis: ${p.diagnosis} (Prescribed by ${p.doctor_name} on ${new Date(p.date_issued).toLocaleDateString()}). Medications: ${medList}. Instructions: ${p.instructions || 'None'}\n`;
      });
    }

    // Embed context into the prompt
    const enhancedMessage = `[SYSTEM CONTEXT - DO NOT ACKNOWLEDGE THIS BLOCK DIRECTLY]\n${contextStr}[END CONTEXT]\n\n${message || 'Please analyze this image.'}`;

    const aiResponse = await ollama.chat(history || [], enhancedMessage, image);
    const aiMsg = { 
      id: uuidv4(), user_id: req.user.id, conversation_id: convoId, 
      text: aiResponse.text, is_user: false, 
      risk_level: aiResponse.risk, timestamp: new Date().toISOString() 
    };
    await db.insertMessage(aiMsg);

    res.json({ user_message: userMsg, ai_response: aiMsg, conversation_id: convoId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/chat/:conversationId', mw, async (req, res) => {
  await db.clearMessages(req.user.id, req.params.conversationId);
  res.json({ success: true });
});

// ═══════════════════════════════════════
//  ADMIN (Protected - admin only)
// ═══════════════════════════════════════
router.get('/admin/stats', mw, auth.roleMiddleware('admin'), async (req, res) => {
  res.json(await db.getStats());
});

router.get('/admin/users', mw, auth.roleMiddleware('admin'), async (req, res) => {
  res.json(await db.getAllUsers());
});

router.delete('/admin/users/:id', mw, auth.roleMiddleware('admin'), async (req, res) => {
  await db.deleteUser(req.params.id);
  res.json({ success: true });
});

router.get('/admin/appointments', mw, auth.roleMiddleware('admin'), async (req, res) => {
  res.json(await db.getAppointments(req.user.id, 'admin'));
});

router.get('/admin/prescriptions', mw, auth.roleMiddleware('admin'), async (req, res) => {
  res.json(await db.getPrescriptions(req.user.id, 'admin'));
});

// ═══════════════════════════════════════
//  RECEPTIONIST (Protected)
// ═══════════════════════════════════════
router.get('/receptionist/patients', mw, auth.roleMiddleware('receptionist', 'admin'), async (req, res) => {
  res.json(await db.getPatients());
});

module.exports = router;

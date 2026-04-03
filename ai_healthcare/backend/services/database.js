const initSqlJs = require('sql.js');
const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

const DB_PATH = path.join(__dirname, '..', 'healthcare.db');

class DatabaseService {
  constructor() {
    this.db = null;
    this.ready = this._init();
  }

  async _init() {
    const SQL = await initSqlJs();
    if (fs.existsSync(DB_PATH)) {
      const buffer = fs.readFileSync(DB_PATH);
      this.db = new SQL.Database(buffer);
    } else {
      this.db = new SQL.Database();
    }

    this.db.run(`
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        name TEXT NOT NULL DEFAULT 'User',
        role TEXT NOT NULL DEFAULT 'patient',
        age INTEGER DEFAULT 0,
        gender TEXT DEFAULT '',
        phone TEXT DEFAULT '',
        blood_group TEXT DEFAULT '',
        allergies TEXT DEFAULT '',
        emergency_contact TEXT DEFAULT '',
        specialty TEXT DEFAULT '',
        qualification TEXT DEFAULT '',
        experience_years INTEGER DEFAULT 0,
        avatar_color TEXT DEFAULT '#667EEA',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS chat_messages (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        conversation_id TEXT NOT NULL,
        text TEXT NOT NULL,
        is_user INTEGER NOT NULL DEFAULT 1,
        risk_level TEXT DEFAULT 'normal',
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS appointments (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        doctor_id TEXT NOT NULL,
        doctor_name TEXT NOT NULL,
        patient_name TEXT NOT NULL,
        specialty TEXT NOT NULL,
        date_time DATETIME NOT NULL,
        location TEXT DEFAULT '',
        notes TEXT DEFAULT '',
        status TEXT DEFAULT 'pending',
        consultation_notes TEXT DEFAULT '',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS prescriptions (
        id TEXT PRIMARY KEY,
        appointment_id TEXT,
        patient_id TEXT NOT NULL,
        doctor_id TEXT NOT NULL,
        doctor_name TEXT NOT NULL,
        patient_name TEXT NOT NULL,
        diagnosis TEXT DEFAULT '',
        medications TEXT DEFAULT '[]',
        instructions TEXT DEFAULT '',
        date_issued DATETIME DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS health_metrics (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        value REAL NOT NULL,
        unit TEXT DEFAULT '',
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS scan_reports (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        image_path TEXT DEFAULT '',
        extracted_text TEXT DEFAULT '',
        ai_summary TEXT DEFAULT '',
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS medical_records (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT DEFAULT '',
        record_type TEXT DEFAULT 'general',
        file_path TEXT DEFAULT '',
        created_by TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS pharmacies (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        distance_km REAL NOT NULL,
        phone TEXT DEFAULT ''
      );

      CREATE TABLE IF NOT EXISTS pharmacy_inventory (
        id TEXT PRIMARY KEY,
        pharmacy_id TEXT NOT NULL,
        medicine_name TEXT NOT NULL,
        stock_status TEXT DEFAULT 'In Stock',
        price REAL DEFAULT 0.0
      );
    `);

    // Seed default users if empty
    const count = this._get('SELECT COUNT(*) as c FROM users');
    if (!count || count.c === 0) {
      await this._seedData();
    }

    // Seed pharmacies if empty
    try {
      const phCount = this._get('SELECT COUNT(*) as c FROM pharmacies');
      if (!phCount || phCount.c === 0) {
        await this._seedPharmacies();
      }
    } catch(e) {}

    this._save();
    console.log('✅ Database initialized with tables & seed data');
  }

  async _seedData() {
    const adminPass = await bcrypt.hash('admin123', 10);
    const doctorPass = await bcrypt.hash('doctor123', 10);
    const patientPass = await bcrypt.hash('patient123', 10);
    const receptionistPass = await bcrypt.hash('receptionist123', 10);

    // Admin
    this.db.run('INSERT INTO users (id, email, password, name, role, avatar_color) VALUES (?, ?, ?, ?, ?, ?)',
      [uuidv4(), 'admin@healthcare.com', adminPass, 'System Admin', 'admin', '#FF6B6B']);

    // Receptionist
    this.db.run('INSERT INTO users (id, email, password, name, role, avatar_color) VALUES (?, ?, ?, ?, ?, ?)',
      [uuidv4(), 'receptionist@healthcare.com', receptionistPass, 'Front Desk', 'receptionist', '#F5A623']);

    // Doctors
    const doctors = [
      { name: 'Dr. Sarah Mitchell', email: 'sarah@healthcare.com', specialty: 'Cardiologist', qualification: 'MD, DM Cardiology', exp: 12, color: '#667EEA' },
      { name: 'Dr. Rajesh Kumar', email: 'rajesh@healthcare.com', specialty: 'Neurologist', qualification: 'MD, DM Neurology', exp: 8, color: '#4ECDC4' },
      { name: 'Dr. Emily Chen', email: 'emily@healthcare.com', specialty: 'Dermatologist', qualification: 'MD Dermatology', exp: 6, color: '#F093FB' },
      { name: 'Dr. James Wilson', email: 'james@healthcare.com', specialty: 'Orthopedic Surgeon', qualification: 'MS Orthopedics', exp: 15, color: '#43E97B' },
      { name: 'Dr. Priya Sharma', email: 'priya@healthcare.com', specialty: 'Pediatrician', qualification: 'MD Pediatrics', exp: 10, color: '#FA709A' },
    ];

    for (const d of doctors) {
      this.db.run(
        'INSERT INTO users (id, email, password, name, role, specialty, qualification, experience_years, avatar_color) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [uuidv4(), d.email, doctorPass, d.name, 'doctor', d.specialty, d.qualification, d.exp, d.color]
      );
    }

    // Demo patient
    this.db.run('INSERT INTO users (id, email, password, name, role, age, blood_group, avatar_color) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [uuidv4(), 'patient@test.com', patientPass, 'Demo Patient', 'patient', 25, 'O+', '#667EEA']);

    console.log('📦 Seed data inserted: 1 admin, 1 receptionist, 5 doctors, 1 demo patient');

    await this._seedPharmacies();
  }

  async _seedPharmacies() {
    // Seed Pharmacies
    const ph1 = uuidv4();
    const ph2 = uuidv4();
    const ph3 = uuidv4();
    
    this.db.run('INSERT INTO pharmacies (id, name, address, distance_km, phone) VALUES (?,?,?,?,?)', 
      [ph1, 'Apollo Pharmacy', '12 Health Avenue, Downtown', 1.2, '+1-555-0101']);
    this.db.run('INSERT INTO pharmacies (id, name, address, distance_km, phone) VALUES (?,?,?,?,?)', 
      [ph2, 'City Care Meds', '45 Main Street, Westside', 2.5, '+1-555-0202']);
    this.db.run('INSERT INTO pharmacies (id, name, address, distance_km, phone) VALUES (?,?,?,?,?)', 
      [ph3, '24/7 Wellness Pharmacy', '88 River Road, Eastside', 4.1, '+1-555-0303']);
      
    // Seed Inventory for common meds
    const meds = ['Paracetamol', 'Amoxicillin', 'Lisinopril', 'Metformin', 'Atorvastatin', 'Aspirin', 'Ibuprofen'];
    for (const m of meds) {
      this.db.run('INSERT INTO pharmacy_inventory (id, pharmacy_id, medicine_name, stock_status, price) VALUES (?,?,?,?,?)',
        [uuidv4(), ph1, m, Math.random() > 0.2 ? 'In Stock' : 'Low Stock', (Math.random() * 20 + 5).toFixed(2)]);
      this.db.run('INSERT INTO pharmacy_inventory (id, pharmacy_id, medicine_name, stock_status, price) VALUES (?,?,?,?,?)',
        [uuidv4(), ph2, m, Math.random() > 0.4 ? 'In Stock' : 'Out of Stock', (Math.random() * 20 + 5).toFixed(2)]);
      this.db.run('INSERT INTO pharmacy_inventory (id, pharmacy_id, medicine_name, stock_status, price) VALUES (?,?,?,?,?)',
        [uuidv4(), ph3, m, 'In Stock', (Math.random() * 20 + 5).toFixed(2)]);
    }
    console.log('📦 Seeded dummy pharmacies and inventory data');
  }

  _save() {
    const data = this.db.export();
    fs.writeFileSync(DB_PATH, Buffer.from(data));
  }

  _all(sql, params = []) {
    const stmt = this.db.prepare(sql);
    if (params.length) stmt.bind(params);
    const results = [];
    while (stmt.step()) results.push(stmt.getAsObject());
    stmt.free();
    return results;
  }

  _get(sql, params = []) {
    const r = this._all(sql, params);
    return r.length > 0 ? r[0] : null;
  }

  _run(sql, params = []) {
    this.db.run(sql, params);
    this._save();
  }

  // ── Auth ──
  getUserByEmail(email) {
    return this._get('SELECT * FROM users WHERE email = ?', [email]);
  }

  createUser(data) {
    const id = uuidv4();
    this._run(
      'INSERT INTO users (id, email, password, name, role, age, gender, phone, blood_group, avatar_color) VALUES (?,?,?,?,?,?,?,?,?,?)',
      [id, data.email, data.password, data.name, data.role || 'patient', data.age || 0, data.gender || '', data.phone || '', data.blood_group || '', data.avatar_color || '#667EEA']
    );
    return this.getUser(id);
  }

  getUser(id) {
    const u = this._get('SELECT * FROM users WHERE id = ?', [id]);
    if (u) delete u.password;
    return u;
  }

  updateUser(id, data) {
    const allowed = ['name', 'age', 'gender', 'phone', 'blood_group', 'allergies', 'emergency_contact', 'specialty', 'qualification', 'experience_years', 'avatar_color'];
    const fields = [], values = [];
    for (const [k, v] of Object.entries(data)) {
      if (allowed.includes(k)) { fields.push(`${k}=?`); values.push(v); }
    }
    if (!fields.length) return this.getUser(id);
    values.push(id);
    this._run(`UPDATE users SET ${fields.join(',')}, updated_at=CURRENT_TIMESTAMP WHERE id=?`, values);
    return this.getUser(id);
  }

  getAllUsers() {
    return this._all("SELECT id, email, name, role, age, gender, phone, blood_group, specialty, avatar_color, created_at FROM users ORDER BY created_at DESC");
  }

  getPatients() {
    return this._all("SELECT id, email, name, age, gender, phone, blood_group, avatar_color, created_at FROM users WHERE role='patient' ORDER BY created_at DESC");
  }

  getDoctors() {
    return this._all("SELECT id, name, email, specialty, qualification, experience_years, avatar_color FROM users WHERE role='doctor' ORDER BY name");
  }

  deleteUser(id) { this._run('DELETE FROM users WHERE id=?', [id]); }

  // ── Chat ──
  getMessages(userId, conversationId) {
    return this._all('SELECT * FROM chat_messages WHERE user_id=? AND conversation_id=? ORDER BY timestamp ASC', [userId, conversationId]);
  }
  insertMessage(m) {
    this._run('INSERT INTO chat_messages (id,user_id,conversation_id,text,is_user,risk_level,timestamp) VALUES (?,?,?,?,?,?,?)',
      [m.id, m.user_id, m.conversation_id, m.text, m.is_user ? 1 : 0, m.risk_level || 'normal', m.timestamp || new Date().toISOString()]);
  }
  clearMessages(userId, convoId) { this._run('DELETE FROM chat_messages WHERE user_id=? AND conversation_id=?', [userId, convoId]); }

  // ── Appointments ──
  getAppointments(userId, role) {
    if (role === 'doctor') return this._all('SELECT * FROM appointments WHERE doctor_id=? ORDER BY date_time DESC', [userId]);
    if (role === 'admin' || role === 'receptionist') return this._all('SELECT * FROM appointments ORDER BY date_time DESC');
    return this._all('SELECT * FROM appointments WHERE patient_id=? ORDER BY date_time DESC', [userId]);
  }
  getAppointment(id) { return this._get('SELECT * FROM appointments WHERE id=?', [id]); }
  insertAppointment(a) {
    const id = a.id || uuidv4();
    this._run('INSERT INTO appointments (id,patient_id,doctor_id,doctor_name,patient_name,specialty,date_time,location,notes,status) VALUES (?,?,?,?,?,?,?,?,?,?)',
      [id, a.patient_id, a.doctor_id, a.doctor_name, a.patient_name, a.specialty, a.date_time, a.location||'', a.notes||'', a.status||'pending']);
    return { id, ...a };
  }
  updateAppointmentStatus(id, status) { this._run('UPDATE appointments SET status=? WHERE id=?', [status, id]); }
  addConsultationNotes(id, notes) { this._run('UPDATE appointments SET consultation_notes=?, status=? WHERE id=?', [notes, 'completed', id]); }
  deleteAppointment(id) { this._run('DELETE FROM appointments WHERE id=?', [id]); }

  // ── Prescriptions ──
  getPrescriptions(userId, role) {
    if (role === 'doctor') return this._all('SELECT * FROM prescriptions WHERE doctor_id=? ORDER BY date_issued DESC', [userId]);
    if (role === 'admin') return this._all('SELECT * FROM prescriptions ORDER BY date_issued DESC');
    return this._all('SELECT * FROM prescriptions WHERE patient_id=? ORDER BY date_issued DESC', [userId]);
  }
  insertPrescription(p) {
    const id = p.id || uuidv4();
    this._run('INSERT INTO prescriptions (id,appointment_id,patient_id,doctor_id,doctor_name,patient_name,diagnosis,medications,instructions) VALUES (?,?,?,?,?,?,?,?,?)',
      [id, p.appointment_id||'', p.patient_id, p.doctor_id, p.doctor_name, p.patient_name, p.diagnosis||'', JSON.stringify(p.medications||[]), p.instructions||'']);
    return { id, ...p };
  }
  deletePrescription(id) { this._run('DELETE FROM prescriptions WHERE id=?', [id]); }

  // ── Health Metrics ──
  getMetrics(userId) { return this._all('SELECT * FROM health_metrics WHERE user_id=? ORDER BY timestamp DESC', [userId]); }
  getLatestMetric(userId, type) { return this._get('SELECT * FROM health_metrics WHERE user_id=? AND type=? ORDER BY timestamp DESC LIMIT 1', [userId, type]); }
  insertMetric(m) {
    const id = m.id || uuidv4();
    this._run('INSERT INTO health_metrics (id,user_id,type,value,unit,timestamp) VALUES (?,?,?,?,?,?)',
      [id, m.user_id, m.type, m.value, m.unit||'', m.timestamp || new Date().toISOString()]);
    return { id, ...m };
  }
  deleteMetric(id) { this._run('DELETE FROM health_metrics WHERE id=?', [id]); }

  // ── Reports ──
  getReports(userId) { return this._all('SELECT * FROM scan_reports WHERE user_id=? ORDER BY timestamp DESC', [userId]); }
  insertReport(r) {
    const id = r.id || uuidv4();
    this._run('INSERT INTO scan_reports (id,user_id,image_path,extracted_text,ai_summary) VALUES (?,?,?,?,?)',
      [id, r.user_id, r.image_path||'', r.extracted_text||'', r.ai_summary||'']);
    return { id, ...r };
  }
  updateReport(id, data) {
    const f = [], v = [];
    if (data.ai_summary !== undefined) { f.push('ai_summary=?'); v.push(data.ai_summary); }
    if (data.extracted_text !== undefined) { f.push('extracted_text=?'); v.push(data.extracted_text); }
    if (!f.length) return;
    v.push(id);
    this._run(`UPDATE scan_reports SET ${f.join(',')} WHERE id=?`, v);
  }
  deleteReport(id) { this._run('DELETE FROM scan_reports WHERE id=?', [id]); }

  // ── Medical Records ──
  getRecords(patientId) { return this._all('SELECT * FROM medical_records WHERE patient_id=? ORDER BY created_at DESC', [patientId]); }
  insertRecord(r) {
    const id = r.id || uuidv4();
    this._run('INSERT INTO medical_records (id,patient_id,title,description,record_type,created_by) VALUES (?,?,?,?,?,?)',
      [id, r.patient_id, r.title, r.description||'', r.record_type||'general', r.created_by]);
    return { id, ...r };
  }
  deleteRecord(id) { this._run('DELETE FROM medical_records WHERE id=?', [id]); }

  // ── Pharmacy Inventory ──
  getPharmaciesForMedicine(medicineName) {
    // Basic fuzzy search
    const query = `
      SELECT p.*, i.stock_status, i.price 
      FROM pharmacies p
      JOIN pharmacy_inventory i ON p.id = i.pharmacy_id
      WHERE i.medicine_name LIKE ?
      ORDER BY p.distance_km ASC
    `;
    return this._all(query, [`%${medicineName}%`]);
  }

  // ── Admin Stats ──
  getStats() {
    return {
      totalUsers: this._get("SELECT COUNT(*) as c FROM users WHERE role='patient'")?.c || 0,
      totalDoctors: this._get("SELECT COUNT(*) as c FROM users WHERE role='doctor'")?.c || 0,
      totalAppointments: this._get('SELECT COUNT(*) as c FROM appointments')?.c || 0,
      pendingAppointments: this._get("SELECT COUNT(*) as c FROM appointments WHERE status='pending'")?.c || 0,
      completedAppointments: this._get("SELECT COUNT(*) as c FROM appointments WHERE status='completed'")?.c || 0,
      totalPrescriptions: this._get('SELECT COUNT(*) as c FROM prescriptions')?.c || 0,
      totalReports: this._get('SELECT COUNT(*) as c FROM scan_reports')?.c || 0,
    };
  }
}

module.exports = new DatabaseService();

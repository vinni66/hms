const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

const DB_URL = process.env.SUPABASE_DB_URL;

class DatabaseService {
  constructor() {
    if (!DB_URL || DB_URL.includes('[YOUR-PASSWORD]')) {
      console.warn('⚠️ SUPABASE_DB_URL not properly configured. Database service will be limited.');
    }
    
    this.pool = new Pool({
      connectionString: DB_URL,
      ssl: {
        rejectUnauthorized: false // Required for Supabase/Heroku/DigitalOcean
      }
    });

    this.ready = this._init();
  }

  async _init() {
    try {
      // 1. Users table
      await this._run(`
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
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
      `);

      // 2. Chat messages table
      await this._run(`
        CREATE TABLE IF NOT EXISTS chat_messages (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          conversation_id TEXT NOT NULL,
          text TEXT NOT NULL,
          is_user BOOLEAN NOT NULL DEFAULT TRUE,
          risk_level TEXT DEFAULT 'normal',
          timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
      `);

      // 3. Appointments table
      await this._run(`
        CREATE TABLE IF NOT EXISTS appointments (
          id TEXT PRIMARY KEY,
          patient_id TEXT NOT NULL,
          doctor_id TEXT NOT NULL,
          doctor_name TEXT NOT NULL,
          patient_name TEXT NOT NULL,
          specialty TEXT NOT NULL,
          date_time TIMESTAMP WITH TIME ZONE NOT NULL,
          location TEXT DEFAULT '',
          notes TEXT DEFAULT '',
          status TEXT DEFAULT 'pending',
          consultation_notes TEXT DEFAULT '',
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
      `);

      // 4. Prescriptions table
      await this._run(`
        CREATE TABLE IF NOT EXISTS prescriptions (
          id TEXT PRIMARY KEY,
          appointment_id TEXT,
          patient_id TEXT NOT NULL,
          doctor_id TEXT NOT NULL,
          doctor_name TEXT NOT NULL,
          patient_name TEXT NOT NULL,
          diagnosis TEXT DEFAULT '',
          medications JSONB DEFAULT '[]',
          instructions TEXT DEFAULT '',
          date_issued TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
      `);

      // 5. Health metrics table
      await this._run(`
        CREATE TABLE IF NOT EXISTS health_metrics (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          type TEXT NOT NULL,
          value REAL NOT NULL,
          unit TEXT DEFAULT '',
          timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
      `);

      // 6. Scan reports table
      await this._run(`
        CREATE TABLE IF NOT EXISTS scan_reports (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          image_path TEXT DEFAULT '',
          extracted_text TEXT DEFAULT '',
          ai_summary TEXT DEFAULT '',
          timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
      `);

      // 7. Medical records table
      await this._run(`
        CREATE TABLE IF NOT EXISTS medical_records (
          id TEXT PRIMARY KEY,
          patient_id TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT DEFAULT '',
          record_type TEXT DEFAULT 'general',
          file_path TEXT DEFAULT '',
          created_by TEXT NOT NULL,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
      `);

      // 8. Pharmacies table
      await this._run(`
        CREATE TABLE IF NOT EXISTS pharmacies (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          address TEXT NOT NULL,
          distance_km REAL NOT NULL,
          phone TEXT DEFAULT ''
        );
      `);

      // 9. Pharmacy Inventory
      await this._run(`
        CREATE TABLE IF NOT EXISTS pharmacy_inventory (
          id TEXT PRIMARY KEY,
          pharmacy_id TEXT NOT NULL,
          medicine_name TEXT NOT NULL,
          stock_status TEXT DEFAULT 'In Stock',
          price REAL DEFAULT 0.0
        );
      `);

      // Seed default users if empty
      const countData = await this._get('SELECT COUNT(*) as c FROM users');
      const count = parseInt(countData?.c || '0');
      if (count === 0) {
        await this._seedData();
      }

      // Seed pharmacies if empty
      try {
        const phCountData = await this._get('SELECT COUNT(*) as c FROM pharmacies');
        const phCount = parseInt(phCountData?.c || '0');
        if (phCount === 0) {
          await this._seedPharmacies();
        }
      } catch(e) {}
      
      // Pro Phase 1: Add new columns if they don't exist
      try {
        await this._run('ALTER TABLE users ADD COLUMN IF NOT EXISTS health_streak INTEGER DEFAULT 0');
        await this._run('ALTER TABLE users ADD COLUMN IF NOT EXISTS last_checkin TIMESTAMP WITH TIME ZONE');
        await this._run('ALTER TABLE appointments ADD COLUMN IF NOT EXISTS risk_level TEXT DEFAULT \'normal\'');
        await this._run('ALTER TABLE appointments ADD COLUMN IF NOT EXISTS risk_reason TEXT DEFAULT \'\'');
      } catch(e) {
        console.warn('⚠️ Column Update Warning:', e.message);
      }

      // Pro Phase 2: Medication Adherence Tracker
      await this._run(`
        CREATE TABLE IF NOT EXISTS medication_schedule (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          med_name TEXT NOT NULL,
          frequency TEXT NOT NULL, -- e.g. "Daily", "Twice a day"
          doses_per_day INTEGER DEFAULT 1,
          is_active BOOLEAN DEFAULT TRUE,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
      `);

      await this._run(`
        CREATE TABLE IF NOT EXISTS medication_logs (
          id TEXT PRIMARY KEY,
          schedule_id TEXT NOT NULL,
          user_id TEXT NOT NULL,
          taken_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
      `);

      // Pro Phase 5: Family Social Circle
      await this._run(`
        CREATE TABLE IF NOT EXISTS family_links (
          id TEXT PRIMARY KEY,
          requester_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          target_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          UNIQUE(requester_id, target_id)
        );
      `);

      // Pro Phase 7: Wellness & Nutrition
      await this._run(`
        CREATE TABLE IF NOT EXISTS wellness_goals (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          type TEXT NOT NULL, -- 'water', 'steps', 'calories', 'sleep'
          target_value REAL NOT NULL,
          unit TEXT DEFAULT '',
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          UNIQUE(user_id, type)
        );
      `);

      console.log('✅ Supabase Database initialized with tables & seed data');
    } catch (err) {
      console.error('❌ Database Initialization Error:', err);
    }
  }

  async _seedData() {
    const adminPass = await bcrypt.hash('admin123', 10);
    const doctorPass = await bcrypt.hash('doctor123', 10);
    const patientPass = await bcrypt.hash('patient123', 10);
    const receptionistPass = await bcrypt.hash('receptionist123', 10);

    // Admin
    await this._run('INSERT INTO users (id, email, password, name, role, avatar_color) VALUES ($1, $2, $3, $4, $5, $6)',
      [uuidv4(), 'admin@healthcare.com', adminPass, 'System Admin', 'admin', '#FF6B6B']);

    // Receptionist
    await this._run('INSERT INTO users (id, email, password, name, role, avatar_color) VALUES ($1, $2, $3, $4, $5, $6)',
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
      await this._run(
        'INSERT INTO users (id, email, password, name, role, specialty, qualification, experience_years, avatar_color) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)',
        [uuidv4(), d.email, doctorPass, d.name, 'doctor', d.specialty, d.qualification, d.exp, d.color]
      );
    }

    // Demo patient
    await this._run('INSERT INTO users (id, email, password, name, role, age, blood_group, avatar_color) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)',
      [uuidv4(), 'patient@test.com', patientPass, 'Demo Patient', 'patient', 25, 'O+', '#667EEA']);

    await this._seedPharmacies();
  }

  async _seedPharmacies() {
    const ph1 = uuidv4();
    const ph2 = uuidv4();
    const ph3 = uuidv4();
    
    await this._run('INSERT INTO pharmacies (id, name, address, distance_km, phone) VALUES ($1,$2,$3,$4,$5)', 
      [ph1, 'Apollo Pharmacy', '12 Health Avenue, Downtown', 1.2, '+1-555-0101']);
    await this._run('INSERT INTO pharmacies (id, name, address, distance_km, phone) VALUES ($1,$2,$3,$4,$5)', 
      [ph2, 'City Care Meds', '45 Main Street, Westside', 2.5, '+1-555-0202']);
    await this._run('INSERT INTO pharmacies (id, name, address, distance_km, phone) VALUES ($1,$2,$3,$4,$5)', 
      [ph3, '24/7 Wellness Pharmacy', '88 River Road, Eastside', 4.1, '+1-555-0303']);
      
    const meds = ['Paracetamol', 'Amoxicillin', 'Lisinopril', 'Metformin', 'Atorvastatin', 'Aspirin', 'Ibuprofen'];
    for (const m of meds) {
      await this._run('INSERT INTO pharmacy_inventory (id, pharmacy_id, medicine_name, stock_status, price) VALUES ($1,$2,$3,$4,$5)',
        [uuidv4(), ph1, m, Math.random() > 0.2 ? 'In Stock' : 'Low Stock', parseFloat((Math.random() * 20 + 5).toFixed(2))]);
      await this._run('INSERT INTO pharmacy_inventory (id, pharmacy_id, medicine_name, stock_status, price) VALUES ($1,$2,$3,$4,$5)',
        [uuidv4(), ph2, m, Math.random() > 0.4 ? 'In Stock' : 'Out of Stock', parseFloat((Math.random() * 20 + 5).toFixed(2))]);
      await this._run('INSERT INTO pharmacy_inventory (id, pharmacy_id, medicine_name, stock_status, price) VALUES ($1,$2,$3,$4,$5)',
        [uuidv4(), ph3, m, 'In Stock', parseFloat((Math.random() * 20 + 5).toFixed(2))]);
    }
  }

  async _all(sql, params = []) {
    const res = await this.pool.query(sql, params);
    return res.rows;
  }

  async _get(sql, params = []) {
    const rows = await this._all(sql, params);
    return rows.length > 0 ? rows[0] : null;
  }

  async _run(sql, params = []) {
    return await this.pool.query(sql, params);
  }

  // ── Auth ──
  async getUserByEmail(email) {
    return await this._get('SELECT * FROM users WHERE email = $1', [email]);
  }

  async createUser(data) {
    const id = uuidv4();
    await this._run(
      'INSERT INTO users (id, email, password, name, role, age, gender, phone, blood_group, avatar_color) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)',
      [id, data.email, data.password, data.name, data.role || 'patient', data.age || 0, data.gender || '', data.phone || '', data.blood_group || '', data.avatar_color || '#667EEA']
    );
    return await this.getUser(id);
  }

  async getUser(id) {
    const u = await this._get('SELECT * FROM users WHERE id = $1', [id]);
    if (u) delete u.password;
    return u;
  }

  async updateUser(id, data) {
    const allowed = ['name', 'age', 'gender', 'phone', 'blood_group', 'allergies', 'emergency_contact', 'specialty', 'qualification', 'experience_years', 'avatar_color'];
    const fields = [], values = [];
    let i = 1;
    for (const [k, v] of Object.entries(data)) {
      if (allowed.includes(k)) { 
        fields.push(`${k}=$${i}`); 
        values.push(v);
        i++;
      }
    }
    if (!fields.length) return await this.getUser(id);
    values.push(id);
    await this._run(`UPDATE users SET ${fields.join(',')}, updated_at=CURRENT_TIMESTAMP WHERE id=$${i}`, values);
    return await this.getUser(id);
  }

  async getAllUsers() {
    return await this._all("SELECT id, email, name, role, age, gender, phone, blood_group, specialty, avatar_color, created_at FROM users ORDER BY created_at DESC");
  }

  async getPatients() {
    return await this._all("SELECT id, email, name, age, gender, phone, blood_group, avatar_color, created_at FROM users WHERE role='patient' ORDER BY created_at DESC");
  }

  async getDoctors() {
    return await this._all("SELECT id, name, email, specialty, qualification, experience_years, avatar_color FROM users WHERE role='doctor' ORDER BY name");
  }

  async deleteUser(id) { await this._run('DELETE FROM users WHERE id=$1', [id]); }

  // ── Chat ──
  async getMessages(userId, conversationId) {
    return await this._all('SELECT * FROM chat_messages WHERE user_id=$1 AND conversation_id=$2 ORDER BY timestamp ASC', [userId, conversationId]);
  }
  async insertMessage(m) {
    await this._run('INSERT INTO chat_messages (id,user_id,conversation_id,text,is_user,risk_level,timestamp) VALUES ($1,$2,$3,$4,$5,$6,$7)',
      [m.id, m.user_id, m.conversation_id, m.text, m.is_user ? true : false, m.risk_level || 'normal', m.timestamp || new Date().toISOString()]);
  }
  async clearMessages(userId, convoId) { await this._run('DELETE FROM chat_messages WHERE user_id=$1 AND conversation_id=$2', [userId, convoId]); }

  // ── Appointments ──
  async getAppointments(userId, role) {
    if (role === 'doctor') return await this._all('SELECT * FROM appointments WHERE doctor_id=$1 ORDER BY date_time DESC', [userId]);
    if (role === 'admin' || role === 'receptionist') return await this._all('SELECT * FROM appointments ORDER BY date_time DESC');
    return await this._all('SELECT * FROM appointments WHERE patient_id=$1 ORDER BY date_time DESC', [userId]);
  }
  async getAppointment(id) { return await this._get('SELECT * FROM appointments WHERE id=$1', [id]); }
  async insertAppointment(a) {
    const id = a.id || uuidv4();
    await this._run('INSERT INTO appointments (id,patient_id,doctor_id,doctor_name,patient_name,specialty,date_time,location,notes,status) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)',
      [id, a.patient_id, a.doctor_id, a.doctor_name, a.patient_name, a.specialty, a.date_time, a.location||'', a.notes||'', a.status||'pending']);
    return { id, ...a };
  }
  async updateAppointmentStatus(id, status) { await this._run('UPDATE appointments SET status=$1 WHERE id=$2', [status, id]); }
  async addConsultationNotes(id, notes) { await this._run('UPDATE appointments SET consultation_notes=$1, status=$2 WHERE id=$3', [notes, 'completed', id]); }
  async deleteAppointment(id) { await this._run('DELETE FROM appointments WHERE id=$1', [id]); }

  // ── Prescriptions ──
  async getPrescriptions(userId, role) {
    if (role === 'doctor') return await this._all('SELECT * FROM prescriptions WHERE doctor_id=$1 ORDER BY date_issued DESC', [userId]);
    if (role === 'admin') return await this._all('SELECT * FROM prescriptions ORDER BY date_issued DESC');
    return await this._all('SELECT * FROM prescriptions WHERE patient_id=$1 ORDER BY date_issued DESC', [userId]);
  }
  async insertPrescription(p) {
    const id = p.id || uuidv4();
    await this._run('INSERT INTO prescriptions (id,appointment_id,patient_id,doctor_id,doctor_name,patient_name,diagnosis,medications,instructions) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)',
      [id, p.appointment_id||'', p.patient_id, p.doctor_id, p.doctor_name, p.patient_name, p.diagnosis||'', JSON.stringify(p.medications||[]), p.instructions||'']);
    return { id, ...p };
  }
  async deletePrescription(id) { await this._run('DELETE FROM prescriptions WHERE id=$1', [id]); }

  // ── Health Metrics ──
  async getMetrics(userId) { return await this._all('SELECT * FROM health_metrics WHERE user_id=$1 ORDER BY timestamp DESC', [userId]); }
  async getLatestMetric(userId, type) { return await this._get('SELECT * FROM health_metrics WHERE user_id=$1 AND type=$2 ORDER BY timestamp DESC LIMIT 1', [userId, type]); }
  async insertMetric(m) {
    const id = m.id || uuidv4();
    await this._run('INSERT INTO health_metrics (id,user_id,type,value,unit,timestamp) VALUES ($1,$2,$3,$4,$5,$6)',
      [id, m.user_id, m.type, m.value, m.unit||'', m.timestamp || new Date().toISOString()]);
    return { id, ...m };
  }
  async deleteMetric(id) { await this._run('DELETE FROM health_metrics WHERE id=$1', [id]); }

  // ── Reports ──
  async getReports(userId) { return await this._all('SELECT * FROM scan_reports WHERE user_id=$1 ORDER BY timestamp DESC', [userId]); }
  async insertReport(r) {
    const id = r.id || uuidv4();
    await this._run('INSERT INTO scan_reports (id,user_id,image_path,extracted_text,ai_summary) VALUES ($1,$2,$3,$4,$5)',
      [id, r.user_id, r.image_path||'', r.extracted_text||'', r.ai_summary||'']);
    return { id, ...r };
  }
  async updateReport(id, data) {
    const f = [], v = [];
    let i = 1;
    if (data.ai_summary !== undefined) { f.push(`ai_summary=$${i}`); v.push(data.ai_summary); i++; }
    if (data.extracted_text !== undefined) { f.push(`extracted_text=$${i}`); v.push(data.extracted_text); i++; }
    if (!f.length) return;
    v.push(id);
    await this._run(`UPDATE scan_reports SET ${f.join(',')} WHERE id=$${i}`, v);
  }
  async deleteReport(id) { await this._run('DELETE FROM scan_reports WHERE id=$1', [id]); }

  // ── Medical Records ──
  async getRecords(patientId) { return await this._all('SELECT * FROM medical_records WHERE patient_id=$1 ORDER BY created_at DESC', [patientId]); }
  async insertRecord(r) {
    const id = r.id || uuidv4();
    await this._run('INSERT INTO medical_records (id,patient_id,title,description,record_type,created_by) VALUES ($1,$2,$3,$4,$5,$6)',
      [id, r.patient_id, r.title, r.description||'', r.record_type||'general', r.created_by]);
    return { id, ...r };
  }
  async deleteRecord(id) { await this._run('DELETE FROM medical_records WHERE id=$1', [id]); }

  // ── Pharmacy Inventory ──
  async getPharmaciesForMedicine(medicineName) {
    const query = `
      SELECT p.*, i.stock_status, i.price 
      FROM pharmacies p
      JOIN pharmacy_inventory i ON p.id = i.pharmacy_id
      WHERE i.medicine_name ILIKE $1
      ORDER BY p.distance_km ASC
    `;
    return await this._all(query, [`%${medicineName}%`]);
  }

  // ── Admin Stats ──
  async getStats() {
    return {
      totalUsers: parseInt((await this._get("SELECT COUNT(*) as c FROM users WHERE role='patient'"))?.c || '0'),
      totalDoctors: parseInt((await this._get("SELECT COUNT(*) as c FROM users WHERE role='doctor'"))?.c || '0'),
      totalAppointments: parseInt((await this._get('SELECT COUNT(*) as c FROM appointments'))?.c || '0'),
      pendingAppointments: parseInt((await this._get("SELECT COUNT(*) as c FROM appointments WHERE status='pending'"))?.c || '0'),
      completedAppointments: parseInt((await this._get("SELECT COUNT(*) as c FROM appointments WHERE status='completed'"))?.c || '0'),
      totalPrescriptions: parseInt((await this._get('SELECT COUNT(*) as c FROM prescriptions'))?.c || '0'),
      totalReports: parseInt((await this._get('SELECT COUNT(*) as c FROM scan_reports'))?.c || '0'),
    };
  }

  // ── Pro Phase 1: Risk & Streaks ──
  async updateAppointmentRisk(id, level, reason) {
    await this._run('UPDATE appointments SET risk_level=$1, risk_reason=$2 WHERE id=$3', [level, reason, id]);
  }

  async updateUserStreak(userId) {
    const user = await this.getUser(userId);
    if (!user) return;
    
    const now = new Date();
    const lastCheckin = user.last_checkin ? new Date(user.last_checkin) : null;
    
    let newStreak = (user.health_streak || 0) + 1;
    
    if (lastCheckin) {
      const diffDays = Math.floor((now - lastCheckin) / (1000 * 60 * 60 * 24));
      if (diffDays === 0) return; // Already checked in today
      if (diffDays > 1) newStreak = 1; // Streak broken
    }
    
    await this._run('UPDATE users SET health_streak=$1, last_checkin=CURRENT_TIMESTAMP WHERE id=$2', [newStreak, userId]);
    return newStreak;
  }

  // ── Pro Phase 2: Medication ──
  async getMedicationSchedule(userId) {
    return await this._all('SELECT * FROM medication_schedule WHERE user_id=$1 AND is_active=TRUE', [userId]);
  }

  async getDosesLoggedToday(userId) {
    return await this._all(`
      SELECT * FROM medication_logs 
      WHERE user_id=$1 AND taken_at > CURRENT_DATE
    `, [userId]);
  }

  async logMedicationDose(userId, scheduleId) {
    const id = uuidv4();
    await this._run('INSERT INTO medication_logs (id, schedule_id, user_id) VALUES ($1,$2,$3)', [id, scheduleId, userId]);
    return { id };
  }

  async insertMedicationSchedule(s) {
    const id = uuidv4();
    await this._run('INSERT INTO medication_schedule (id, user_id, med_name, frequency, doses_per_day) VALUES ($1,$2,$3,$4,$5)',
      [id, s.user_id, s.med_name, s.frequency || 'Daily', s.doses_per_day || 1]);
    return { id, ...s };
  }

  // ── Pro Phase 5: Family ──
  async getFamilyLinks(userId) {
    // Get both requests sent and received
    return await this._all(`
      SELECT f.*, u1.name as requester_name, u2.name as target_name, u1.email as requester_email, u2.email as target_email
      FROM family_links f
      JOIN users u1 ON f.requester_id = u1.id
      JOIN users u2 ON f.target_id = u2.id
      WHERE requester_id = $1 OR target_id = $1
    `, [userId]);
  }

  async sendFamilyRequest(requesterId, targetEmail) {
    const target = await this.getUserByEmail(targetEmail);
    if (!target) throw new Error('User not found');
    if (target.id === requesterId) throw new Error('Cannot link with self');
    
    // Check existing
    const existing = await this._get('SELECT * FROM family_links WHERE (requester_id=$1 AND target_id=$2) OR (requester_id=$2 AND target_id=$1)', [requesterId, target.id]);
    if (existing) throw new Error('Request already exists or linked');

    const id = uuidv4();
    await this._run('INSERT INTO family_links (id, requester_id, target_id) VALUES ($1,$2,$3)', [id, requesterId, target.id]);
    return { id, target_email: targetEmail };
  }

  async handleFamilyRequest(requestId, status) {
    await this._run('UPDATE family_links SET status=$1 WHERE id=$2', [status, requestId]);
  }

  async getFamilyMembersHealth(userId) {
    // Get approved family members (requester or target)
    const links = await this._all(`
      SELECT * FROM family_links 
      WHERE (requester_id = $1 OR target_id = $1) AND status = 'approved'
    `, [userId]);

    const members = [];
    for (const link of links) {
      const otherId = link.requester_id === userId ? link.target_id : link.requester_id;
      const user = await this.getUser(otherId);
      
      // Get latest metrics for each member
      const hr = await this.getLatestMetric(otherId, 'Heart Rate');
      const bp = await this.getLatestMetric(otherId, 'Blood Pressure');
      const spo2 = await this.getLatestMetric(otherId, 'SpO2');
      
      members.push({
        id: otherId,
        name: user.name,
        avatar_color: user.avatar_color,
        vitals: {
          heart_rate: hr ? hr.value : null,
          blood_pressure: bp ? bp.value : null,
          spo2: spo2 ? spo2.value : null,
          last_updated: hr?.timestamp || bp?.timestamp || spo2?.timestamp || null
        }
      });
    }
    return members;
  }

  // ── Pro Phase 7: Wellness ──
  async getWellnessGoals(userId) {
    return await this._all('SELECT * FROM wellness_goals WHERE user_id=$1', [userId]);
  }

  async updateWellnessGoal(userId, type, value, unit = '') {
    const id = uuidv4();
    await this._run(`
      INSERT INTO wellness_goals (id, user_id, type, target_value, unit, updated_at)
      VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP)
      ON CONFLICT (user_id, type) 
      DO UPDATE SET target_value = EXCLUDED.target_value, unit = EXCLUDED.unit, updated_at = CURRENT_TIMESTAMP
    `, [id, userId, type, value, unit]);
    return { user_id: userId, type, target_value: value, unit };
  }
}

module.exports = new DatabaseService();

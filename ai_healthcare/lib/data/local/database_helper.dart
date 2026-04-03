import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/chat_message.dart';
import '../models/appointment.dart';
import '../models/scan_report.dart';
import '../models/health_metric.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ai_healthcare.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        text TEXT NOT NULL,
        isUser INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        riskLevel INTEGER DEFAULT 0,
        conversationId TEXT DEFAULT 'default'
      )
    ''');

    await db.execute('''
      CREATE TABLE appointments (
        id TEXT PRIMARY KEY,
        doctorName TEXT NOT NULL,
        specialty TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        location TEXT DEFAULT '',
        notes TEXT DEFAULT '',
        isCompleted INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE reports (
        id TEXT PRIMARY KEY,
        imagePath TEXT NOT NULL,
        extractedText TEXT DEFAULT '',
        aiSummary TEXT DEFAULT '',
        findings TEXT DEFAULT '',
        timestamp TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE health_metrics (
        id TEXT PRIMARY KEY,
        type INTEGER NOT NULL,
        value REAL NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  // ── Messages ──
  Future<void> insertMessage(ChatMessage msg) async {
    final db = await database;
    await db.insert('messages', msg.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ChatMessage>> getMessages({String conversationId = 'default'}) async {
    final db = await database;
    final maps = await db.query(
      'messages',
      where: 'conversationId = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp ASC',
    );
    return maps.map((m) => ChatMessage.fromMap(m)).toList();
  }

  Future<void> clearMessages({String conversationId = 'default'}) async {
    final db = await database;
    await db.delete('messages',
        where: 'conversationId = ?', whereArgs: [conversationId]);
  }

  // ── Appointments ──
  Future<void> insertAppointment(Appointment apt) async {
    final db = await database;
    await db.insert('appointments', apt.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Appointment>> getAppointments() async {
    final db = await database;
    final maps = await db.query('appointments', orderBy: 'dateTime ASC');
    return maps.map((m) => Appointment.fromMap(m)).toList();
  }

  Future<void> updateAppointment(Appointment apt) async {
    final db = await database;
    await db.update('appointments', apt.toMap(),
        where: 'id = ?', whereArgs: [apt.id]);
  }

  Future<void> deleteAppointment(String id) async {
    final db = await database;
    await db.delete('appointments', where: 'id = ?', whereArgs: [id]);
  }

  // ── Reports ──
  Future<void> insertReport(ScanReport report) async {
    final db = await database;
    await db.insert('reports', report.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ScanReport>> getReports() async {
    final db = await database;
    final maps = await db.query('reports', orderBy: 'timestamp DESC');
    return maps.map((m) => ScanReport.fromMap(m)).toList();
  }

  Future<void> deleteReport(String id) async {
    final db = await database;
    await db.delete('reports', where: 'id = ?', whereArgs: [id]);
  }

  // ── Health Metrics ──
  Future<void> insertMetric(HealthMetric metric) async {
    final db = await database;
    await db.insert('health_metrics', metric.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<HealthMetric>> getMetrics({MetricType? type}) async {
    final db = await database;
    final maps = await db.query(
      'health_metrics',
      where: type != null ? 'type = ?' : null,
      whereArgs: type != null ? [type.index] : null,
      orderBy: 'timestamp DESC',
    );
    return maps.map((m) => HealthMetric.fromMap(m)).toList();
  }

  Future<void> deleteMetric(String id) async {
    final db = await database;
    await db.delete('health_metrics', where: 'id = ?', whereArgs: [id]);
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String _baseUrl = 'https://hms-blue-sigma.vercel.app/api';
  String? _token;
  Map<String, dynamic>? _currentUser;

  String get baseUrl => _baseUrl;
  String? get token => _token;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoggedIn => _token != null;
  String get role => _currentUser?['role'] ?? '';

  void setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ── Persistence ──
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    final userJson = prefs.getString('auth_user');
    if (userJson != null) _currentUser = jsonDecode(userJson);
    final url = prefs.getString('server_url');
    if (url != null && url.isNotEmpty) _baseUrl = url;
  }

  Future<void> _saveAuth(String token, Map<String, dynamic> user) async {
    _token = token;
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('auth_user', jsonEncode(user));
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
  }

  // ── HTTP helpers ──
  Future<dynamic> _get(String path) async {
    final res = await http.get(Uri.parse('$_baseUrl$path'), headers: _headers);
    if (res.statusCode == 401) throw AuthException('Session expired');
    if (res.statusCode != 200) throw Exception('GET $path failed: ${res.statusCode}');
    return jsonDecode(res.body);
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final res = await http.post(Uri.parse('$_baseUrl$path'), headers: _headers, body: jsonEncode(body));
    if (res.statusCode == 401) throw AuthException('Session expired');
    if (res.statusCode >= 400) {
      final err = jsonDecode(res.body);
      throw Exception(err['error'] ?? 'POST $path failed');
    }
    return jsonDecode(res.body);
  }

  Future<dynamic> _put(String path, Map<String, dynamic> body) async {
    final res = await http.put(Uri.parse('$_baseUrl$path'), headers: _headers, body: jsonEncode(body));
    if (res.statusCode == 401) throw AuthException('Session expired');
    return jsonDecode(res.body);
  }

  Future<dynamic> _delete(String path) async {
    final res = await http.delete(Uri.parse('$_baseUrl$path'), headers: _headers);
    if (res.statusCode == 401) throw AuthException('Session expired');
    return jsonDecode(res.body);
  }

  // ═══════════════════════════════════════
  //  AUTH
  // ═══════════════════════════════════════
  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await _post('/auth/login', {'email': email, 'password': password});
    await _saveAuth(data['token'], Map<String, dynamic>.from(data['user']));
    return data;
  }

  Future<Map<String, dynamic>> register({
    required String name, required String email, required String password,
    int age = 0, String gender = '', String phone = '', String bloodGroup = '',
  }) async {
    final data = await _post('/auth/register', {
      'name': name, 'email': email, 'password': password,
      'age': age, 'gender': gender, 'phone': phone, 'blood_group': bloodGroup,
    });
    await _saveAuth(data['token'], Map<String, dynamic>.from(data['user']));
    return data;
  }

  Future<Map<String, dynamic>> getMe() async => await _get('/auth/me');

  // ═══════════════════════════════════════
  //  DOCTORS
  // ═══════════════════════════════════════
  Future<List<dynamic>> getDoctors() async => await _get('/doctors');

  // ═══════════════════════════════════════
  //  PROFILE
  // ═══════════════════════════════════════
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final user = await _put('/users/${_currentUser!['id']}', data);
    _currentUser = Map<String, dynamic>.from(user);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_user', jsonEncode(_currentUser));
    return user;
  }

  // ═══════════════════════════════════════
  //  APPOINTMENTS
  // ═══════════════════════════════════════
  Future<List<dynamic>> getAppointments() async => await _get('/appointments');
  Future<Map<String, dynamic>> createAppointment(Map<String, dynamic> data) async => await _post('/appointments', data);
  Future<void> updateAppointmentStatus(String id, String status) async => await _put('/appointments/$id/status', {'status': status});
  Future<void> addConsultationNotes(String id, String notes) async => await _put('/appointments/$id/notes', {'consultation_notes': notes});
  Future<void> deleteAppointment(String id) async => await _delete('/appointments/$id');

  // ═══════════════════════════════════════
  //  PRESCRIPTIONS & PHARMACIES
  // ═══════════════════════════════════════
  Future<List<dynamic>> getPrescriptions() async => await _get('/prescriptions');
  Future<Map<String, dynamic>> createPrescription(Map<String, dynamic> data) async => await _post('/prescriptions', data);
  Future<void> deletePrescription(String id) async => await _delete('/prescriptions/$id');
  Future<List<dynamic>> checkPharmacyStock(String medicine) async => await _get('/pharmacies/search?medicine=$medicine');

  // ═══════════════════════════════════════
  //  HEALTH METRICS
  // ═══════════════════════════════════════
  Future<List<dynamic>> getMetrics() async => await _get('/metrics');
  Future<Map<String, dynamic>> addMetric(Map<String, dynamic> data) async => await _post('/metrics', data);
  Future<void> deleteMetric(String id) async => await _delete('/metrics/$id');
  Future<Map<String, dynamic>> getMetricsAnalysis() async => await _post('/metrics/analyze/trends', {});

  // ═══════════════════════════════════════
  //  REPORTS
  // ═══════════════════════════════════════
  Future<List<dynamic>> getReports() async => await _get('/reports');
  Future<Map<String, dynamic>> createReport(Map<String, dynamic> data) async => await _post('/reports', data);
  Future<Map<String, dynamic>> analyzeReport(String reportId, {String? text, String? imageBase64}) async {
    final payload = <String, dynamic>{};
    if (text != null) payload['extracted_text'] = text;
    if (imageBase64 != null) payload['image'] = imageBase64;
    return await _post('/reports/$reportId/analyze', payload);
  }
  Future<void> deleteReport(String id) async => await _delete('/reports/$id');

  // ═══════════════════════════════════════
  //  CALL SIGNALING
  // ═══════════════════════════════════════
  Future<void> startCall(String targetId, String callerName, String role) async {
    await _post('/calls/start', {'target_id': targetId, 'caller_name': callerName, 'role': role});
  }
  Future<Map<String, dynamic>?> pingCallStatus() async {
    try {
      final res = await _get('/calls/ping');
      return res is Map<String, dynamic> ? res : null;
    } catch (_) { return null; }
  }
  Future<void> endCall(String targetId) async {
    await _post('/calls/end', {'target_id': targetId});
  }

  // ═══════════════════════════════════════
  //  CHAT / AI
  // ═══════════════════════════════════════
  Future<List<dynamic>> getChatHistory(String convoId) async => await _get('/chat/$convoId');
  Future<Map<String, dynamic>> sendMessage(String message, String convoId, List history, {String? imageBase64}) async {
    final payload = {
      'message': message,
      'conversation_id': convoId,
      'history': history,
    };
    if (imageBase64 != null) {
      payload['image'] = imageBase64;
    }
    return await _post('/chat/send', payload);
  }
  Future<void> clearChat(String convoId) async => await _delete('/chat/$convoId');

  // ═══════════════════════════════════════
  //  RECEPTIONIST
  // ═══════════════════════════════════════
  Future<List<dynamic>> getPatients() async => await _get('/receptionist/patients');

  // ═══════════════════════════════════════
  //  PRO FEATURES
  // ═══════════════════════════════════════
  Future<Map<String, dynamic>> suggestTreatment(String patientId, String diagnosis) async {
    return await _post('/doctor/suggest-treatment', {'patient_id': patientId, 'diagnosis': diagnosis});
  }

  Future<int> checkIn() async {
    final res = await _post('/patient/check-in', {});
    return res['streak'] ?? 0;
  }

  // ═══════════════════════════════════════
  //  ADMIN
  // ═══════════════════════════════════════
  Future<Map<String, dynamic>> getAdminStats() async => await _get('/admin/stats');
  Future<List<dynamic>> getAdminUsers() async => await _get('/admin/users');
  Future<void> deleteUser(String id) async => await _delete('/admin/users/$id');
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

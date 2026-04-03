import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class PreferencesHelper {
  static final PreferencesHelper _instance = PreferencesHelper._internal();
  factory PreferencesHelper() => _instance;
  PreferencesHelper._internal();

  static const _keyName = 'user_name';
  static const _keyAge = 'user_age';
  static const _keyBloodGroup = 'user_blood_group';
  static const _keyAllergies = 'user_allergies';
  static const _keyEmergencyContact = 'user_emergency_contact';
  static const _keyOnboarded = 'user_onboarded';
  static const _keyThemeMode = 'theme_mode'; // 0=system, 1=light, 2=dark

  Future<UserProfile> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return UserProfile(
      name: prefs.getString(_keyName) ?? 'User',
      age: prefs.getInt(_keyAge) ?? 0,
      bloodGroup: prefs.getString(_keyBloodGroup) ?? '',
      allergies: prefs.getString(_keyAllergies) ?? '',
      emergencyContact: prefs.getString(_keyEmergencyContact) ?? '',
      onboarded: prefs.getBool(_keyOnboarded) ?? false,
    );
  }

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, profile.name);
    await prefs.setInt(_keyAge, profile.age);
    await prefs.setString(_keyBloodGroup, profile.bloodGroup);
    await prefs.setString(_keyAllergies, profile.allergies);
    await prefs.setString(_keyEmergencyContact, profile.emergencyContact);
    await prefs.setBool(_keyOnboarded, profile.onboarded);
  }

  Future<void> setOnboarded(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboarded, value);
  }

  Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboarded) ?? false;
  }

  Future<int> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyThemeMode) ?? 0;
  }

  Future<void> setThemeMode(int mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode);
  }

  // ── Backend User ID ──
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('backend_user_id');
  }

  Future<void> setUserId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backend_user_id', id);
  }

  // ── Server URL ──
  Future<String?> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('server_url');
  }

  Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', url);
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/colors.dart';
import '../../data/services/api_service.dart';
import 'register_screen.dart';
import 'patient/patient_shell.dart';
import 'doctor/doctor_shell.dart';
import 'admin/admin_shell.dart';
import 'receptionist/receptionist_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  void _showServerSettings() {
    final controller = TextEditingController(text: ApiService().baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Server Settings'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'API Base URL'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              ApiService().setBaseUrl(controller.text.trim());
              await ApiService().loadToken(); // Refresh configuration
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      final data = await ApiService().login(_emailC.text.trim(), _passC.text);
      if (!mounted) return;
      final role = data['user']['role'];
      _navigateByRole(role);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navigateByRole(String role) {
    Widget destination;
    switch (role) {
      case 'doctor':
        destination = const DoctorShell();
        break;
      case 'admin':
        destination = const AdminShell();
        break;
      case 'receptionist':
        destination = const ReceptionistShell();
        break;
      default:
        destination = const PatientShell();
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => destination,
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: 500.ms,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -100, left: -50,
            child: Container(width: 300, height: 300, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient))
              .animate(onPlay: (c) => c.repeat(reverse: true)).scale(end: const Offset(1.2, 1.2), duration: 6.seconds, curve: Curves.easeInOut),
          ),
          Positioned(
            bottom: -50, right: -100,
            child: Container(width: 400, height: 400, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.accentGradient))
              .animate(onPlay: (c) => c.repeat(reverse: true)).slideX(begin: 0, end: -0.2, duration: 5.seconds, curve: Curves.easeInOut),
          ),
          // Blur layer
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: (isDark ? AppColors.bgDark : Colors.white).withAlpha(150)),
            ),
          ),
          // Content
          SafeArea(
            child: Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark.withAlpha(200) : Colors.white.withAlpha(200),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.white.withAlpha(isDark ? 20 : 100), width: 1.5),
                          boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 80 : 20), blurRadius: 40, offset: const Offset(0, 15))],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Logo
                              Container(
                                padding: const EdgeInsets.all(16),
                                width: 100, height: 100,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withAlpha(10) : Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(isDark ? 40 : 60), blurRadius: 30, offset: const Offset(0, 10))],
                                  border: Border.all(color: Colors.white.withAlpha(isDark ? 30 : 100), width: 1.5),
                                ),
                                child: Image.asset('assets/images/logo.png'),
                              ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),

                              const SizedBox(height: 28),

                              Text('Welcome Back',
                                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.textDark : AppColors.textLight)),
                              const SizedBox(height: 8),
                              Text('Sign in to your healthcare account',
                                style: TextStyle(fontSize: 15, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),

                              const SizedBox(height: 36),

                              // Error banner
                              if (_error != null)
                                Container(
                                  width: double.infinity, padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withAlpha(25),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.error.withAlpha(60)),
                                  ),
                                  child: Row(children: [
                                    const Icon(LucideIcons.alertCircle, color: AppColors.error, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                                  ]),
                                ).animate().fadeIn().slideY(begin: -0.2),

                              if (_error != null) const SizedBox(height: 16),

                              // Email field
                              TextFormField(
                                controller: _emailC,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  hintText: 'Email address',
                                  prefixIcon: Icon(LucideIcons.mail, size: 20, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                                ),
                                validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                              ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),

                              const SizedBox(height: 16),

                              // Password field
                              TextFormField(
                                controller: _passC,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _login(),
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  prefixIcon: Icon(LucideIcons.lock, size: 20, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscure ? LucideIcons.eyeOff : LucideIcons.eye, size: 20),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (v) => v == null || v.length < 4 ? 'Password too short' : null,
                              ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),

                              const SizedBox(height: 28),

                              // Login button
                              SizedBox(
                                width: double.infinity, height: 56,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: _loading
                                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                      : const Text('Sign In', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
                                ),
                              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

                              const SizedBox(height: 20),

                              // Register link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("Don't have an account? ",
                                    style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
                                  GestureDetector(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                                    child: const Text('Sign Up', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ).animate().fadeIn(delay: 400.ms),

                              const SizedBox(height: 32),

                              // Demo credentials
                              Container(
                                width: double.infinity, padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: (isDark ? Colors.white : Colors.black).withAlpha(10),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: (isDark ? Colors.white : Colors.black).withAlpha(15)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Demo Accounts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
                                    const SizedBox(height: 10),
                                    _demoRow('Patient', 'patient@test.com', 'patient123', isDark),
                                    _demoRow('Doctor', 'sarah@healthcare.com', 'doctor123', isDark),
                                    _demoRow('Receptionist', 'receptionist@healthcare.com', 'receptionist123', isDark),
                                    _demoRow('Admin', 'admin@healthcare.com', 'admin123', isDark),
                                  ],
                                ),
                              ).animate().fadeIn(delay: 500.ms),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10, right: 10,
                  child: IconButton(
                    icon: Icon(LucideIcons.settings, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                    onPressed: _showServerSettings,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _demoRow(String label, String email, String pass, bool isDark) {
    final roleColor = label == 'Admin' ? AppColors.adminColor : label == 'Doctor' ? AppColors.doctorColor : label == 'Receptionist' ? const Color(0xFFF5A623) : AppColors.patientColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          _emailC.text = email;
          _passC.text = pass;
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: roleColor.withAlpha(30), borderRadius: BorderRadius.circular(6)),
              child: Text(label, style: TextStyle(color: roleColor, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(email, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary))),
            Text(pass, style: TextStyle(fontSize: 11, color: (isDark ? Colors.white : Colors.black).withAlpha(50))),
          ],
        ),
      ),
    );
  }
}

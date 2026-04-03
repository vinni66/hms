import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'data/services/api_service.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/patient/patient_shell.dart';
import 'presentation/screens/doctor/doctor_shell.dart';
import 'presentation/screens/admin/admin_shell.dart';
import 'presentation/screens/receptionist/receptionist_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().loadToken();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Healthcare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const SplashGate(),
    );
  }
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});
  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final api = ApiService();
    Widget destination;

    if (api.isLoggedIn) {
      // Auto-login: verify token is still valid
      try {
        final me = await api.getMe();
        final role = me['role'] ?? 'patient';
        switch (role) {
          case 'doctor': destination = const DoctorShell(); break;
          case 'admin': destination = const AdminShell(); break;
          case 'receptionist': destination = const ReceptionistShell(); break;
          default: destination = const PatientShell();
        }
      } catch (_) {
        await api.logout();
        destination = const LoginScreen();
      }
    } else {
      destination = const LoginScreen();
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => destination,
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(
          colors: [Color(0xFF0A0E21), Color(0xFF1A2040)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        )),
        child: const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.favorite, size: 60, color: Color(0xFF667EEA)),
            SizedBox(height: 20),
            Text('AI Healthcare', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Color(0xFF667EEA), strokeWidth: 2),
          ]),
        ),
      ),
    );
  }
}

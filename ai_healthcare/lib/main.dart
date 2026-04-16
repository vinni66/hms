import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'data/services/api_service.dart';
import 'data/services/call_service.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/patient/patient_shell.dart';
import 'presentation/screens/doctor/doctor_shell.dart';
import 'presentation/screens/admin/admin_shell.dart';
import 'presentation/screens/receptionist/receptionist_shell.dart';

final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().loadToken();
  CallService().startListening(); // Run globally and persistently
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: globalNavigatorKey,
      title: 'AI Healthcare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
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

  @override
  void dispose() {
    super.dispose();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: isDark 
          ? const LinearGradient(colors: [Color(0xFF0A0E21), Color(0xFF1A2040)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
          : const LinearGradient(colors: [Color(0xFFF5F7FF), Color(0xFFE2E8F0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
        ),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.favorite, size: 60, color: Color(0xFF667EEA)),
            const SizedBox(height: 20),
            Text('AI Healthcare', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            CircularProgressIndicator(color: Color(0xFF667EEA), strokeWidth: 2),
          ]),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    await Future.delayed(const Duration(milliseconds: 1500)); // Smooth splash duration
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
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: isDark 
          ? const LinearGradient(colors: [Color(0xFF0A0E21), Color(0xFF1A2040)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
          : const LinearGradient(colors: [Color(0xFFF5F7FF), Color(0xFFE2E8F0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
        ),
        child: Stack(
          children: [
            Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Image.asset('assets/images/logo.png', width: 140, height: 140)
                  .animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
                const SizedBox(height: 30),
                Text('AI Healthcare', style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 1.5))
                  .animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                const SizedBox(height: 40),
                CircularProgressIndicator(color: const Color(0xFF667EEA), strokeWidth: 2, backgroundColor: const Color(0xFF667EEA).withAlpha(40))
                  .animate().fadeIn(delay: 400.ms),
              ]),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text('Developed by', 
                    style: TextStyle(color: textColor.withAlpha(150), fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _devName('Nithya', '👩‍💻', textColor),
                      _separator(textColor),
                      _devName('Bharath', '👨‍💻', textColor),
                      _separator(textColor),
                      _devName('Tushar', '🚀', textColor),
                    ],
                  ),
                ],
              ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _devName(String name, String emoji, Color color) {
    return Row(
      children: [
        Text(name, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        Text(emoji, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _separator(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text('|', style: TextStyle(color: color.withAlpha(50), fontSize: 14)),
    );
  }
}

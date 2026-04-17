import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/colors.dart';
import '../../data/services/api_service.dart';
import '../widgets/glass_container.dart';
import 'patient/patient_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _phoneC = TextEditingController();
  int _age = 25;
  String _gender = 'Male';
  String _bloodGroup = 'O+';
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  final _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final _genders = ['Male', 'Female', 'Other'];

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      await ApiService().register(
        name: _nameC.text.trim(), email: _emailC.text.trim(), password: _passC.text,
        age: _age, gender: _gender, phone: _phoneC.text.trim(), bloodGroup: _bloodGroup,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PatientShell()),
        (_) => false,
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -150, right: -50,
            child: Container(width: 350, height: 350, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.accentGradient))
              .animate(onPlay: (c) => c.repeat(reverse: true)).slideY(begin: 0, end: 0.15, duration: 6.seconds, curve: Curves.easeInOut),
          ),
          Positioned(
            bottom: -100, left: -100,
            child: Container(width: 400, height: 400, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient))
              .animate(onPlay: (c) => c.repeat(reverse: true)).scale(end: const Offset(1.15, 1.15), duration: 5.seconds, curve: Curves.easeInOut),
          ),
          // Blur layer
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: (isDark ? AppColors.bgDark : Colors.white).withAlpha(150)),
            ),
          ),
          SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => Navigator.pop(context)),
                    const Spacer(),
                    Text('Create Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? AppColors.textDark : AppColors.textLight)),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(32),
                      opacity: isDark ? 0.08 : 0.6,
                      blur: 25,
                      borderRadius: 32,
                      child: Form(
                        key: _formKey,
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_error != null)
                            Container(
                              width: double.infinity, padding: const EdgeInsets.all(14), margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(color: AppColors.error.withAlpha(25), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.error.withAlpha(60))),
                              child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                            ),

                          // Name
                          TextFormField(
                            controller: _nameC,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(hintText: 'Full Name', prefixIcon: Icon(LucideIcons.user, size: 20)),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                          ).animate().fadeIn(delay: 100.ms),
                          const SizedBox(height: 14),

                          // Email
                          TextFormField(
                            controller: _emailC,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(hintText: 'Email', prefixIcon: Icon(LucideIcons.mail, size: 20)),
                            validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                          ).animate().fadeIn(delay: 150.ms),
                          const SizedBox(height: 14),

                          // Password
                          TextFormField(
                            controller: _passC,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              hintText: 'Password (min 6 chars)',
                              prefixIcon: const Icon(LucideIcons.lock, size: 20),
                              suffixIcon: IconButton(icon: Icon(_obscure ? LucideIcons.eyeOff : LucideIcons.eye, size: 20), onPressed: () => setState(() => _obscure = !_obscure)),
                            ),
                            validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                          ).animate().fadeIn(delay: 200.ms),
                          const SizedBox(height: 14),

                          // Phone
                          TextFormField(
                            controller: _phoneC,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(hintText: 'Phone Number', prefixIcon: Icon(LucideIcons.phone, size: 20)),
                          ).animate().fadeIn(delay: 250.ms),
                          const SizedBox(height: 14),

                          // Age slider
                          Text('Age: $_age', style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? AppColors.textDark : AppColors.textLight)),
                          Slider(value: _age.toDouble(), min: 1, max: 100, divisions: 99, activeColor: AppColors.primary, label: '$_age',
                            onChanged: (v) => setState(() => _age = v.toInt())),
                          const SizedBox(height: 8),

                          // Gender chips
                          Text('Gender', style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? AppColors.textDark : AppColors.textLight)),
                          const SizedBox(height: 8),
                          Wrap(spacing: 10, children: _genders.map((g) => ChoiceChip(
                            label: Text(g), selected: _gender == g, selectedColor: AppColors.primary.withAlpha(40),
                            labelStyle: TextStyle(color: _gender == g ? AppColors.primary : null, fontWeight: _gender == g ? FontWeight.w600 : null),
                            onSelected: (_) => setState(() => _gender = g),
                          )).toList()),
                          const SizedBox(height: 14),

                          // Blood group
                          Text('Blood Group', style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? AppColors.textDark : AppColors.textLight)),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, runSpacing: 8, children: _bloodGroups.map((b) => ChoiceChip(
                            label: Text(b), selected: _bloodGroup == b, selectedColor: AppColors.error.withAlpha(40),
                            labelStyle: TextStyle(color: _bloodGroup == b ? AppColors.error : null, fontWeight: _bloodGroup == b ? FontWeight.w600 : null),
                            onSelected: (_) => setState(() => _bloodGroup = b),
                          )).toList()),

                          const SizedBox(height: 28),

                          SizedBox(
                            width: double.infinity, height: 56,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _register,
                              child: _loading
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                  : const Text('Create Account', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
                            ),
                          ).animate().fadeIn(delay: 400.ms),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  ),
);
  }
}

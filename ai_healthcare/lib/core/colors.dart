import 'package:flutter/material.dart';

class AppColors {
  // Primary palette
  static const Color primary = Color(0xFF667EEA);
  static const Color primaryDark = Color(0xFF5A67D8);
  static const Color accent = Color(0xFF64FFDA);
  static const Color accentAlt = Color(0xFFF093FB);

  // Background
  static const Color bgDark = Color(0xFF0A0E21);
  static const Color bgDarkSecondary = Color(0xFF111633);
  static const Color cardDark = Color(0xFF161B40);
  static const Color surfaceDark = Color(0xFF1A2040);

  static const Color bgLight = Color(0xFFF5F7FF);
  static const Color bgLightSecondary = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF0F2FF);

  // Status
  static const Color success = Color(0xFF43E97B);
  static const Color warning = Color(0xFFFFB547);
  static const Color error = Color(0xFFFF6B6B);
  static const Color info = Color(0xFF4FC3F7);

  // Text
  static const Color textDark = Color(0xFFF1F5F9);
  static const Color textDarkSecondary = Color(0xFF94A3B8);
  static const Color textLight = Color(0xFF1E293B);
  static const Color textLightSecondary = Color(0xFF64748B);

  // Role colors
  static const Color patientColor = Color(0xFF667EEA);
  static const Color doctorColor = Color(0xFF4ECDC4);
  static const Color adminColor = Color(0xFFFF6B6B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0A0E21), Color(0xFF1A2040)],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
  );
}

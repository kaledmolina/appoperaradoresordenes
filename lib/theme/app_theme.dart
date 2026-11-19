import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF1E3A8A); // Deep Slate Navy
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color secondary = Color(0xFF0F766E); // Teal accent
  static const Color accent = Color(0xFF6366F1); // Indigo

  // Neutral Colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Status Colors
  static const Color statusPending = Color(0xFFF59E0B); // Amber
  static const Color statusAssigned = Color(0xFF3B82F6); // Blue
  static const Color statusInSite = Color(0xFF8B5CF6); // Purple
  static const Color statusInProgress = Color(0xFF06B6D4); // Cyan
  static const Color statusCompleted = Color(0xFF10B981); // Emerald Green
  static const Color statusClosed = Color(0xFF059669); // Dark Green
  static const Color statusSpecial = Color(0xFFEF4444); // Red/Rose
  static const Color statusCancelled = Color(0xFF6B7280); // Gray

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: Colors.red.shade600,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          color: textSecondary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withAlpha(25),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        hintStyle: GoogleFonts.inter(
          color: textMuted,
          fontSize: 14,
        ),
      ),
    );
  }

  static Color getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pendiente':
        return statusPending;
      case 'asignada':
        return statusAssigned;
      case 'en_sitio':
        return statusInSite;
      case 'en_proceso':
        return statusInProgress;
      case 'ejecutada':
        return statusCompleted;
      case 'cerrada':
        return statusClosed;
      case 'reasignar':
      case 'reprogramada':
      case 'anulada':
        return statusSpecial;
      default:
        return statusCancelled;
    }
  }

  static String formatStatusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'pendiente':
        return 'Pendiente';
      case 'asignada':
        return 'Asignada';
      case 'en_sitio':
        return 'En Sitio';
      case 'en_proceso':
        return 'En Proceso';
      case 'ejecutada':
        return 'Ejecutada';
      case 'cerrada':
        return 'Cerrada';
      case 'reasignar':
        return 'Reasignar';
      case 'reprogramada':
        return 'Reprogramada';
      case 'anulada':
        return 'Anulada';
      default:
        return status ?? 'Desconocido';
    }
  }
}

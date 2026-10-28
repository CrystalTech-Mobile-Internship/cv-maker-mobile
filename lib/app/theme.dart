import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Application Material 3 Theme Configuration
class AppTheme {
  // Brand Color Palette (Slate Navy & Modern Teal)
  static const Color brandIndigo = Color(0xFF4338CA);
  static const Color primarySlate = Color(0xFF1E293B);
  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color accentTeal = Color(0xFF0EA5E9);
  static const Color accentCyan = Color(0xFF38BDF8);
  static const Color createAction = Color(0xFF0F766E);
  static const Color createActionDark = Color(0xFF115E59);
  static const Color successGreen = Color(0xFF047857);
  static const Color warningAmber = Color(0xFFD97706);
  static const Color dangerRose = Color(0xFFE11D48);
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color inputSurface = Color(0xFFEEF6FB);
  static const Color mutedText = Color(0xFF475569);

  /// Light Theme
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: brandIndigo,
        onPrimary: Colors.white,
        secondary: createAction,
        onSecondary: Colors.white,
        tertiary: accentTeal,
        onTertiary: Colors.white,
        surface: surfaceLight,
        onSurface: primaryNavy,
        error: dangerRose,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: surfaceLight,
      iconTheme: const IconThemeData(color: primarySlate, size: 24),
      primaryIconTheme: const IconThemeData(color: primarySlate, size: 24),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: primarySlate,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: primarySlate,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 1,
        shadowColor: primarySlate.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.grey.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        prefixIconColor: primarySlate.withValues(alpha: 0.78),
        suffixIconColor: primarySlate.withValues(alpha: 0.78),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentTeal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dangerRose),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brandIndigo,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFCBD5E1),
          disabledForegroundColor: const Color(0xFF64748B),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primarySlate,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primarySlate,
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: const BorderSide(color: Color(0xFF94A3B8), width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: createAction,
        foregroundColor: Colors.white,
        elevation: 4,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE0E7FF),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? brandIndigo : mutedText,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? brandIndigo : mutedText,
            size: 24,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        selectedColor: const Color(0xFFE0E7FF),
        backgroundColor: Colors.white,
        disabledColor: const Color(0xFFE2E8F0),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: primaryNavy,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: brandIndigo,
        ),
        side: const BorderSide(color: Color(0xFFCBD5E1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textTheme: textTheme.copyWith(
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: primarySlate,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: primarySlate,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          color: const Color(0xFF334155),
        ),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: mutedText),
      ),
    );
  }

  static ButtonStyle get createCvButton => FilledButton.styleFrom(
    backgroundColor: createAction,
    foregroundColor: Colors.white,
    disabledBackgroundColor: const Color(0xFF99F6E4),
    disabledForegroundColor: createActionDark,
  );

  static ButtonStyle get logoutButton => OutlinedButton.styleFrom(
    foregroundColor: dangerRose,
    backgroundColor: Colors.white,
    side: const BorderSide(color: dangerRose, width: 1.6),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
  );
}

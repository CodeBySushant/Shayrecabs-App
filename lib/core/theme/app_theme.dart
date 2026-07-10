import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand tokens — mirrors the web app's tailwind.config.js exactly.
class AppColors {
  AppColors._();

  static const brand = Color(0xFF5B5FFF); // brand-500
  static const brand600 = Color(0xFF4F46E5);
  static const brand700 = Color(0xFF4338CA);
  static const brand100 = Color(0xFFE0E2FF);
  static const brand50 = Color(0xFFEEF0FF);
  static const sky = Color(0xFF1C9CF6); // --brand-from accent
  static const gold = Color(0xFFF5B301); // Signal Gold (logo accent)

  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFDC2626);
  static const womenPink = Color(0xFFEC4899);

  // Dark surfaces (deep navy family, matches splash #0B0F1A)
  static const darkBg = Color(0xFF0B0F1A);
  static const darkSurface = Color(0xFF121828);
  static const darkCard = Color(0xFF1A2138);
}

class AppTheme {
  AppTheme._();

  static TextTheme _textTheme(TextTheme base) {
    // Outfit for headings, Inter for body — same as the website.
    final inter = GoogleFonts.interTextTheme(base);
    final outfit = GoogleFonts.outfitTextTheme(base);
    return inter.copyWith(
      displayLarge: outfit.displayLarge?.copyWith(fontWeight: FontWeight.w700),
      displayMedium: outfit.displayMedium?.copyWith(fontWeight: FontWeight.w700),
      displaySmall: outfit.displaySmall?.copyWith(fontWeight: FontWeight.w700),
      headlineLarge: outfit.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium: outfit.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      headlineSmall: outfit.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
      titleLarge: outfit.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: inter.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  static ThemeData _base(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: brightness,
      primary: AppColors.brand,
      secondary: AppColors.sky,
    );
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        surface: isDark ? AppColors.darkSurface : Colors.white,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor:
          isDark ? AppColors.darkBg : const Color(0xFFF7F8FC),
      textTheme: _textTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF7F8FC),
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? Colors.white.withOpacity(.06) : const Color(0xFFE9EBF3),
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(
              color: isDark ? Colors.white24 : const Color(0xFFD7DAE5)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkCard : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? Colors.white12 : const Color(0xFFD7DAE5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? Colors.white12 : const Color(0xFFD7DAE5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.brand, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E4EE)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white.withOpacity(.08) : const Color(0xFFECEEF5),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  static ThemeData get light => _base(Brightness.light);
  static ThemeData get dark => _base(Brightness.dark);
}

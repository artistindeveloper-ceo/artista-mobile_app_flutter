import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ============================================================
/// "THE STAGE" — PREMIUM ENTERPRISE THEME
/// Dark charcoal base + warm gold accent + magenta secondary
/// Fonts: Playfair Display (headings/logo) + Poppins (body/UI)
/// ============================================================
class AppColors {
  // ---- Core backgrounds ----
  static const Color bgBase = Color(0xFF141416); // Main app background
  static const Color bgSurface = Color(0xFF1E1E22); // Cards, sheets, panels
  static const Color bgSurfaceElevated =
      Color(0xFF28282D); // Dialogs, popups, raised surfaces
  static const Color bgAppBar =
      Color(0xFF141416); // App bar / bottom nav (same as base = seamless)

  // ---- Primary accent: warm gold ----
  static const Color gold = Color(0xFFD4AF37); // Primary brand accent
  static const Color goldDim = Color(0xFFB08D2B); // Pressed / darker variant
  static const Color goldLight = Color(0xFFE9CE7A); // Highlight / hover tint
  static const List<Color> goldGradient = [
    Color(0xFFE3C567),
    Color(0xFFC79A34)
  ];

  // ---- Secondary accent: magenta (for CTA / create actions) ----
  static const Color magenta = Color(0xFFE0348C);
  static const Color magentaDim = Color(0xFFB02870);

  // ---- Text ----
  static const Color textPrimary = Color(0xFFFAFAFA); // Headings
  static const Color textSecondary =
      Color(0xFFA8A6A0); // Subtext, captions (warm grey)
  static const Color textTertiary = Color(0xFF6E6C68); // Disabled / hints
  static const Color textOnGold =
      Color(0xFF141416); // Dark text on gold buttons (contrast)
  static const Color textOnMagenta = Color(0xFFFFFFFF);

  // ---- Borders / dividers ----
  static const Color border = Color(0xFF2E2E33);
  static const Color divider = Color(0xFF232326);

  // ---- Status / semantic ----
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE05555);
  static const Color warning = Color(0xFFE0A845);
  static const Color notification =
      Color(0xFFE0348C); // Uses magenta for badges (pops on gold theme)

  // ---- Social login ----
  static const Color googleRed = Color(0xFFDB4437);
  static const Color facebookBlue = Color(0xFF1877F2);
  static const Color appleBlack = Color(0xFF000000);
  static const Color spotifyGreen = Color(0xFF1DB954);

  // ---- Legacy aliases (migration safety net) ----
  static const Color primaryDark = bgAppBar;
  static const Color primaryMid = bgSurface;
  static const Color primaryLight = gold;
  static const Color accent = gold;
  static const Color white = textPrimary;
  static const Color lightGrey = bgSurface;
  static const Color textGrey = textSecondary;
  static const Color darkText = textPrimary;
  static const Color skyBlue = goldLight;
  static const Color logoutRed = error;
}

/// ============================================================
/// FONTS
/// - headingFont: Playfair Display — elegant serif for "The Stage"
///   logo/title, big headlines, artist display names.
/// - bodyFont: Poppins — clean geometric sans for everything else
///   (buttons, tabs, body copy, form fields).
/// ============================================================
class AppFonts {
  static TextStyle heading({
    double fontSize = 22,
    FontWeight fontWeight = FontWeight.w600,
    Color color = AppColors.textPrimary,
    double? letterSpacing,
  }) =>
      GoogleFonts.playfairDisplay(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle body({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double? letterSpacing,
  }) =>
      GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bgBase,
        fontFamily: GoogleFonts.poppins().fontFamily,

        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.gold,
          brightness: Brightness.dark,
          primary: AppColors.gold,
          secondary: AppColors.magenta,
          surface: AppColors.bgSurface,
          error: AppColors.error,
        ),

        // ---- App Bar ----
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.bgAppBar,
          foregroundColor: AppColors.textPrimary,
          centerTitle: false,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          // "The Stage" style title — Playfair Display, gold, elegant
          titleTextStyle: GoogleFonts.playfairDisplay(
            color: AppColors.gold,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),

        // ---- Bottom Navigation ----
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.bgAppBar,
          selectedItemColor: AppColors.gold,
          unselectedItemColor: AppColors.textTertiary,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle:
              GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500),
          unselectedLabelStyle:
              GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w400),
        ),

        // ---- Floating Action Button (the "+" create button) ----
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.magenta,
          foregroundColor: Colors.white,
          elevation: 4,
        ),

        // ---- Cards ----
        cardTheme: CardThemeData(
          color: AppColors.bgSurface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
        ),

        // ---- Inputs ----
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.bgSurface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
          ),
          labelStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
          hintStyle: GoogleFonts.poppins(color: AppColors.textTertiary),
          floatingLabelStyle: GoogleFonts.poppins(color: AppColors.gold),
        ),

        // ---- Buttons ----
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.textOnGold,
            disabledBackgroundColor: AppColors.bgSurfaceElevated,
            disabledForegroundColor: AppColors.textTertiary,
            minimumSize: const Size(double.infinity, 52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.border),
            minimumSize: const Size(double.infinity, 52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.gold,
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
        ),

        // ---- Checkbox / chips (genre selection, tags) ----
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.gold;
            return Colors.transparent;
          }),
          checkColor: const WidgetStatePropertyAll(AppColors.textOnGold),
          side: const BorderSide(color: AppColors.border, width: 1.5),
        ),

        chipTheme: ChipThemeData(
          backgroundColor: AppColors.bgSurface,
          selectedColor: AppColors.gold.withValues(alpha: 0.15),
          labelStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
          secondaryLabelStyle: GoogleFonts.poppins(color: AppColors.gold),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),

        // ---- Icons ----
        iconTheme: const IconThemeData(color: AppColors.textPrimary),

        // ---- Dividers ----
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
        ),

        // ---- Text ----
        // headlineLarge/Medium + titleLarge use Playfair Display (elegant,
        // matches "The Stage" branding / artist display names).
        // Everything else uses Poppins for clean readability.
        textTheme: TextTheme(
          headlineLarge: GoogleFonts.playfairDisplay(
              color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          headlineMedium: GoogleFonts.playfairDisplay(
              color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          titleLarge: GoogleFonts.playfairDisplay(
              color: AppColors.gold, fontWeight: FontWeight.w600),
          titleMedium: GoogleFonts.poppins(
              color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          bodyLarge: GoogleFonts.poppins(color: AppColors.textPrimary),
          bodyMedium: GoogleFonts.poppins(color: AppColors.textSecondary),
          bodySmall: GoogleFonts.poppins(color: AppColors.textTertiary),
          labelLarge: GoogleFonts.poppins(
              color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),

        // ---- Bottom sheets / dialogs ----
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.bgSurface,
          modalBackgroundColor: AppColors.bgSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.bgSurfaceElevated,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titleTextStyle: GoogleFonts.playfairDisplay(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          contentTextStyle: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),

        // ---- Progress indicators (upload, loading) ----
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.gold,
          linearTrackColor: AppColors.bgSurfaceElevated,
        ),

        // ---- Tab bar (Following / Explore style tabs) ----
        tabBarTheme: TabBarThemeData(
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.gold,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              GoogleFonts.poppins(fontWeight: FontWeight.w400),
        ),
      );
}

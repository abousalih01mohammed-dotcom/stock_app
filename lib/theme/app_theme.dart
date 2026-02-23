import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // NEON PALETTE - Ultra moderne
  static const Color primaryPurple = Color(0xFFB721FF); // Violet néon
  static const Color secondaryPurple = Color(0xFF8A2BE2); // Violet électrique
  static const Color lightPurple = Color(0xFFD4A5FF); // Violet clair
  static const Color veryLightPurple = Color(0xFFF3E5FF); // Violet très clair
  static const Color darkPurple = Color(0xFF4A1B6D); // Violet foncé
  static const Color electricBlue = Color(0xFF21D4FD); // Bleu électrique
  static const Color neonPink = Color(0xFFFF007A); // Rose néon
  static const Color darkBg = Color(0xFF0A0A0F); // Fond sombre
  static const Color cardBg = Color(0xFF1A1A2E); // Fond carte
  static const Color glassEffect = Color(0x2A2A2A3C); // Effet verre
  static const Color accentColor = Color(0xFFFFB74D); // Orange pour accents
  static const Color errorRed = Color(0xFFEF4444); // Rouge erreur
  static const Color successGreen = Color(0xFF10B981); // Vert succès
  static const Color warningOrange = Color(0xFFF97316); // Orange warning

  static const Color white = Colors.white;
  static const Color black = Color(0xFF111827);
  static const Color greyLight = Color(0xFFF9FAFB);
  static const Color greyMedium = Color(0xFFE5E7EB);
  static const Color greyDark = Color(0xFF6B7280);

  // Dégradés
  static const LinearGradient cyberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFB721FF), // Violet néon
      Color(0xFF8A2BE2), // Violet électrique
      Color(0xFF21D4FD), // Bleu électrique
    ],
  );

  static const RadialGradient neonRadial = RadialGradient(
    center: Alignment.topLeft,
    radius: 1.5,
    colors: [
      Color(0xFFB721FF),
      Color(0xFF8A2BE2),
      Color(0xFF21D4FD),
      Color(0xFF0A0A0F),
    ],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1A1A2E), // Violet foncé
      Color(0xFF0A0A0F), // Noir profond
    ],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x33FFFFFF), // Blanc transparent
      Color(0x33B721FF), // Violet transparent
    ],
  );

  // Ombres élégantes
  static List<BoxShadow> get elegantShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 5),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.02),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> get neonShadow => [
    BoxShadow(
      color: primaryPurple.withOpacity(0.3),
      blurRadius: 15,
      spreadRadius: 2,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: electricBlue.withOpacity(0.2),
      blurRadius: 30,
      spreadRadius: -5,
      offset: const Offset(0, 8),
    ),
  ];

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryPurple,
    scaffoldBackgroundColor: darkBg,

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.orbitron(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: white,
        letterSpacing: 0.5,
      ),
      iconTheme: IconThemeData(color: white),
    ),

    // CORRECTION ICI : CardThemeData au lieu de CardTheme
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: glassEffect,
      shadowColor: primaryPurple.withOpacity(0.3),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryPurple,
        foregroundColor: white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        elevation: 8,
        shadowColor: primaryPurple.withOpacity(0.3),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryPurple,
      foregroundColor: white,
      elevation: 8,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: glassEffect,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: greyMedium.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryPurple, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: errorRed, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      labelStyle: GoogleFonts.inter(color: greyDark, fontSize: 14),
      hintStyle: GoogleFonts.inter(color: greyMedium, fontSize: 14),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
  );
}

// ANIMATIONS PERSONNALISÉES
class Animations {
  static Duration get quick => const Duration(milliseconds: 300);
  static Duration get medium => const Duration(milliseconds: 600);
  static Duration get slow => const Duration(milliseconds: 1000);

  static Curve get bounce => Curves.elasticOut;
  static Curve get smooth => Curves.easeInOutCubicEmphasized;
  static Curve get spring => Curves.fastOutSlowIn;
}

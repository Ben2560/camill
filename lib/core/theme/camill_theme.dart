import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'camill_colors.dart';

/// CamillColors から Flutter ThemeData を生成する
class CamillThemeData {
  static ThemeData build(CamillColors colors) {
    final base = colors.isDark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);

    final textTheme = GoogleFonts.zenMaruGothicTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.outfit(
          fontSize: 48, fontWeight: FontWeight.w700, color: colors.textPrimary),
      displayMedium: GoogleFonts.outfit(
          fontSize: 36, fontWeight: FontWeight.w700, color: colors.textPrimary),
      displaySmall: GoogleFonts.outfit(
          fontSize: 28, fontWeight: FontWeight.w700, color: colors.textPrimary),
      headlineMedium: GoogleFonts.outfit(
          fontSize: 22, fontWeight: FontWeight.w600, color: colors.textPrimary),
    );

    return base.copyWith(
      scaffoldBackgroundColor: colors.background,
      extensions: [colors],
      textTheme: textTheme,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primary,
        brightness: colors.isDark ? Brightness.dark : Brightness.light,
      ).copyWith(
        surface: colors.surface,
        primary: colors.primary,
        error:   colors.danger,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor:  colors.background,
        foregroundColor:  colors.textPrimary,
        elevation:        0,
        titleTextStyle: GoogleFonts.zenMaruGothic(
          fontSize:   17,
          fontWeight: FontWeight.w700,
          color:      colors.textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.fabIcon,
          minimumSize:     const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.zenMaruGothic(
              fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled:    true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:   BorderSide(color: colors.surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:   BorderSide(color: colors.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:   BorderSide(color: colors.primary, width: 1.5),
        ),
        labelStyle:     TextStyle(color: colors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerColor: colors.surfaceBorder,
      tabBarTheme: TabBarThemeData(
        labelColor:         colors.primary,
        unselectedLabelColor: colors.textMuted,
        indicatorColor:     colors.primary,
      ),
    );
  }
}

/// 金額表示用テキストスタイル (Outfit Bold)
TextStyle camillAmountStyle(double size, Color color) =>
    GoogleFonts.outfit(
        fontSize: size, fontWeight: FontWeight.w700, color: color);

/// ヘッダ日付用テキストスタイル (Zen Maru Gothic Bold)
TextStyle camillHeadingStyle(double size, Color color) =>
    GoogleFonts.zenMaruGothic(
        fontSize: size, fontWeight: FontWeight.w700, color: color);

/// 本文用テキストスタイル (Zen Maru Gothic)
TextStyle camillBodyStyle(double size, Color color,
        {FontWeight weight = FontWeight.w400}) =>
    GoogleFonts.zenMaruGothic(
        fontSize: size, fontWeight: weight, color: color);

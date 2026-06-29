import 'package:flutter/material.dart';

class AppColors {
  static bool _isDark = true;
  static bool get isDark => _isDark;

  static void setDark(bool value) {
    _isDark = value;
  }

  // ── Backgrounds ──────────────────────────────────────────────────────────
  static Color get background => _isDark ? const Color(0xFF0B0F1A) : const Color(0xFFF0F4F8);
  static Color get surface    => _isDark ? const Color(0xFF151C2C) : const Color(0xFFFFFFFF);
  static Color get card       => _isDark ? const Color(0xFF1E2640) : const Color(0xFFFFFFFF);
  static Color get cardHover  => _isDark ? const Color(0xFF242D4A) : const Color(0xFFF8FAFC);
  static Color get border     => _isDark ? const Color(0xFF2A3355) : const Color(0xFFE8EEF4);
  static Color get borderLight=> _isDark ? const Color(0xFF3A4570) : const Color(0xFFF1F5F9);

  // ── Accent (constant – same in both modes) ────────────────────────────────
  static const accent      = Color(0xFF10B981);
  static const accentLight = Color(0xFF34D399);
  static const accentDark  = Color(0xFF059669);
  static const accentGlow  = Color(0x2010B981);

  // ── Text ─────────────────────────────────────────────────────────────────
  static Color get textPrimary   => _isDark ? const Color(0xFFE8EEFF) : const Color(0xFF0F172A);
  static Color get textSecondary => _isDark ? const Color(0xFF8B9CC8) : const Color(0xFF475569);
  static Color get textMuted     => _isDark ? const Color(0xFF4A5780) : const Color(0xFF94A3B8);

  // ── Status colours ────────────────────────────────────────────────────────
  static const warning = Color(0xFFF59E0B);
  static Color get warningBg => _isDark ? const Color(0x1FF59E0B) : const Color(0xFFFEF3C7);
  static const error = Color(0xFFEF4444);
  static Color get errorBg   => _isDark ? const Color(0x1FEF4444) : const Color(0xFFFEE2E2);
  static const success = Color(0xFF10B981);
  static Color get successBg => _isDark ? const Color(0x1F10B981) : const Color(0xFFD1FAE5);
  static const info = Color(0xFF6366F1);
  static Color get infoBg    => _isDark ? const Color(0x1F6366F1) : const Color(0xFFEEF2FF);

  // ── Sidebar ───────────────────────────────────────────────────────────────
  static Color get sidebarBg       => _isDark ? const Color(0xFF080C16) : const Color(0xFFFFFFFF);
  static Color get sidebarSelected => _isDark ? const Color(0xFF1A2540) : const Color(0xFFF0F4F8);
  static Color get sidebarHover    => _isDark ? const Color(0xFF131A2E) : const Color(0xFFF8FAFC);

  // ── Shadows (empty list in dark mode so no shadow is painted) ─────────────
  static List<BoxShadow> get cardShadow => _isDark
      ? const []
      : const [
          BoxShadow(
            color: Color(0x0D64748B), // ~5 % slate-500
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
          BoxShadow(
            color: Color(0x1464748B), // ~8 % slate-500
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ];

  static List<BoxShadow> get sidebarShadow => _isDark
      ? const []
      : const [
          BoxShadow(
            color: Color(0x1464748B),
            blurRadius: 24,
            offset: Offset(4, 0),
          ),
        ];
}

class AppTheme {
  static ThemeData get dark => _buildTheme(Brightness.dark);
  static ThemeData get light => _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: AppColors.accent,
              secondary: AppColors.accentLight,
              surface: AppColors.surface,
              error: AppColors.error,
              onPrimary: Colors.black,
              onSecondary: Colors.black,
              onSurface: AppColors.textPrimary,
              onError: Colors.white,
            )
          : ColorScheme.light(
              primary: AppColors.accent,
              secondary: AppColors.accentLight,
              surface: AppColors.surface,
              error: AppColors.error,
              onPrimary: Colors.black,
              onSecondary: Colors.black,
              onSurface: AppColors.textPrimary,
              onError: Colors.white,
            ),
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.card,
      dividerColor: AppColors.border,
      textTheme: TextTheme(
        displayLarge: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5),
        headlineLarge: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3),
        headlineMedium: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2),
        headlineSmall: TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(
            color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 14),
        bodyMedium: TextStyle(color: AppColors.textPrimary, fontSize: 13),
        bodySmall: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        labelLarge: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14),
        labelMedium: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
            fontSize: 12),
        labelSmall: TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
            fontSize: 11),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: TextStyle(color: AppColors.textSecondary),
        hintStyle: TextStyle(color: AppColors.textMuted),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle:
              TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: AppColors.border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle:
              TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter'),
        contentTextStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontFamily: 'Inter'),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.card,
        contentTextStyle: TextStyle(
            color: AppColors.textPrimary, fontFamily: 'Inter'),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(AppColors.surface),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return AppColors.cardHover;
          }
          return AppColors.card;
        }),
        headingTextStyle: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
            fontFamily: 'Inter'),
        dataTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontFamily: 'Inter'),
        dividerThickness: 1,
        columnSpacing: 20,
        horizontalMargin: 16,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontFamily: 'Inter'),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accent;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.black),
        side: BorderSide(color: AppColors.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.card),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: AppColors.border)),
          ),
        ),
        textStyle: TextStyle(
            color: AppColors.textPrimary, fontFamily: 'Inter', fontSize: 14),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.border),
        trackColor: WidgetStateProperty.all(AppColors.surface),
        radius: const Radius.circular(8),
        thickness: WidgetStateProperty.all(6),
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'colors.dart';
import 'typography.dart';
import 'spacing.dart';
import 'radius.dart';

final class LexioTheme {
  LexioTheme._();

  static TextStyle sentenceTextStyle([Color? color]) {
    return LexioTextStyles.sentence.copyWith(
      color: color ?? LexioColors.textPrimary,
      fontFamily: 'NoticiaText',
    );
  }

  static ThemeData get light {
    final colorScheme = ColorScheme.light(
      primary: LexioColors.primary,
      onPrimary: LexioColors.textOnPrimary,
      primaryContainer: LexioColors.primaryLight,
      secondary: LexioColors.secondary,
      onSecondary: LexioColors.textOnPrimary,
      secondaryContainer: LexioColors.secondaryMuted,
      surface: LexioColors.surface,
      onSurface: LexioColors.textPrimary,
      error: LexioColors.error,
      onError: LexioColors.textOnPrimary,
      errorContainer: LexioColors.errorBackground,
      outline: LexioColors.divider,
      outlineVariant: LexioColors.surfaceTertiary,
    );

    final textTheme = TextTheme(
      displayLarge: LexioTextStyles.displayLarge.copyWith(
        color: LexioColors.textPrimary,
      ),
      displayMedium: LexioTextStyles.displayMedium.copyWith(
        color: LexioColors.textPrimary,
      ),
      headlineLarge: LexioTextStyles.headingLarge.copyWith(
        color: LexioColors.textPrimary,
      ),
      headlineMedium: LexioTextStyles.headingMedium.copyWith(
        color: LexioColors.textPrimary,
      ),
      headlineSmall: LexioTextStyles.headingSmall.copyWith(
        color: LexioColors.textPrimary,
      ),
      bodyLarge: LexioTextStyles.bodyLarge.copyWith(
        color: LexioColors.textPrimary,
      ),
      bodyMedium: LexioTextStyles.bodyMedium.copyWith(
        color: LexioColors.textSecondary,
      ),
      bodySmall: LexioTextStyles.bodySmall.copyWith(
        color: LexioColors.textTertiary,
      ),
      labelLarge: LexioTextStyles.labelLarge.copyWith(
        color: LexioColors.textPrimary,
      ),
      labelMedium: LexioTextStyles.labelMedium.copyWith(
        color: LexioColors.textSecondary,
      ),
      labelSmall: LexioTextStyles.labelSmall.copyWith(
        color: LexioColors.textTertiary,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: LexioColors.background,
      dividerColor: LexioColors.divider,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: LexioColors.primary.withValues(alpha: 0.04),
      cardTheme: CardThemeData(
        color: LexioColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LexioRadius.xl),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LexioColors.primary,
          foregroundColor: LexioColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: LexioSpacing.xl,
            vertical: LexioSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LexioRadius.lg),
          ),
          textStyle: LexioTextStyles.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: LexioColors.primary,
          side: const BorderSide(color: LexioColors.primary),
          padding: const EdgeInsets.symmetric(
            horizontal: LexioSpacing.xl,
            vertical: LexioSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LexioRadius.lg),
          ),
          textStyle: LexioTextStyles.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: LexioColors.primary,
          textStyle: LexioTextStyles.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LexioColors.surfaceSecondary,
        contentPadding: const EdgeInsets.all(LexioSpacing.inputPadding),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LexioRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LexioRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LexioRadius.md),
          borderSide: const BorderSide(color: LexioColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LexioRadius.md),
          borderSide: const BorderSide(color: LexioColors.error, width: 1),
        ),
        labelStyle: LexioTextStyles.bodyMedium,
        hintStyle: LexioTextStyles.bodyMedium.copyWith(
          color: LexioColors.textTertiary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: LexioColors.surface,
        selectedItemColor: LexioColors.primary,
        unselectedItemColor: LexioColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: LexioColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: LexioTextStyles.headingSmall.copyWith(
          color: LexioColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: LexioColors.textPrimary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: LexioColors.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LexioRadius.md),
        ),
        contentTextStyle: LexioTextStyles.bodyMedium.copyWith(
          color: LexioColors.textOnPrimary,
        ),
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

abstract class LexioColors {
  LexioColors._();

  // --- Blue (primary) ---
  static const blue = Color(0xFF4588E0);
  static const blueMuted = Color(0xFFEEF4FD);

  // --- Coral (decorative warmth) ---
  static const coral = Color(0xFFE04B40);
  static const coralMuted = Color(0xFFFFF0EE);

  // --- Green (success / correct) ---
  static const green = Color(0xFF52A860);
  static const greenMuted = Color(0xFFEDF8EF);

  // --- Red (error / incorrect) ---
  static const red = Color(0xFFCC3333);
  static const redMuted = Color(0xFFFFECEC);

  // --- Amber (warning / accent) ---
  static const amber = Color(0xFFE6981A);
  static const amberMuted = Color(0xFFFFF7EE);

  // --- Teal (decorative) ---
  static const teal = Color(0xFF7FBAC3);
  static const tealMuted = Color(0xFFEEF7F8);

  // --- Semantic aliases ---
  static const primary = blue;
  static const primaryLight = Color(0xFF6FA3EF);
  static const primaryDark = Color(0xFF336EC4);

  static const secondary = coral;
  static const secondaryMuted = coralMuted;

  static const accent = amber;
  static const success = green;
  static const error = red;
  static const warning = amber;
  static const info = blue;

  // --- Surfaces ---
  static const background = Color(0xFFF2F4F4);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSecondary = Color(0xFFEDEFF0);
  static const surfaceTertiary = Color(0xFFE5E8E9);

  // --- Semantic backgrounds ---
  static const successBackground = greenMuted;
  static const errorBackground = redMuted;
  static const warningBackground = amberMuted;
  static const infoBackground = blueMuted;

  // --- Text ---
  static const textPrimary = Color(0xFF4C4F50);
  static const textSecondary = Color(0xFF838788);
  static const textTertiary = Color(0xFFB0B3B5);
  static const textOnPrimary = Color(0xFFFFFFFF);

  // --- Misc ---
  static const divider = Color(0xFFDDE0E1);
  static const shimmer = Color(0xFFEAEDED);
}

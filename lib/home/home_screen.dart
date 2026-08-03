import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../design/animations.dart';
import '../design/colors.dart';
import '../design/radius.dart';
import '../design/spacing.dart';
import '../design/typography.dart';
import '../games/grammar/grammar_screen.dart';
import '../games/idioms/idioms_screen.dart';
import '../games/spot/spot_screen.dart';
import '../games/vocabulary/vocabulary_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LexioColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LexioSpacing.screenHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: LexioSpacing.sectionGap),
              _buildHeader(),
              const Spacer(),
              _GameEntry(
                number: '01',
                title: 'Corect sau greșit?',
                accentColor: LexioColors.primary,
                backgroundColor: LexioColors.blueMuted,
                onTap: () => _open(context, const GrammarScreen()),
              ),
              const SizedBox(height: LexioSpacing.screenHorizontal),
              _GameEntry(
                number: '02',
                title: 'Ce înseamnă?',
                accentColor: LexioColors.secondary,
                backgroundColor: LexioColors.coralMuted,
                onTap: () => _open(context, const VocabularyScreen()),
              ),
              const SizedBox(height: LexioSpacing.screenHorizontal),
              _GameEntry(
                number: '03',
                title: 'Vorba vine',
                accentColor: LexioColors.teal,
                backgroundColor: LexioColors.tealMuted,
                onTap: () => _open(context, const IdiomsScreen()),
              ),
              const SizedBox(height: LexioSpacing.screenHorizontal),
              _GameEntry(
                number: '04',
                title: 'Găsește greșeala',
                accentColor: LexioColors.accent,
                backgroundColor: LexioColors.amberMuted,
                onTap: () => _open(context, const SpotScreen()),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Slove',
          style: GoogleFonts.noticiaText(
            textStyle: LexioTextStyles.displayLarge.copyWith(
              color: LexioColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: LexioSpacing.xs),
        Text(
          'Joacă-te cu limba română.',
          style: LexioTextStyles.bodyLarge.copyWith(
            color: LexioColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offsetAnimation =
              Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: LexioCurves.easeOut),
              );

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offsetAnimation, child: child),
          );
        },
        transitionDuration: LexioDurations.page,
      ),
    );
  }
}

class _GameEntry extends StatelessWidget {
  const _GameEntry({
    required this.number,
    required this.title,
    required this.accentColor,
    required this.backgroundColor,
    required this.onTap,
  });

  final String number;
  final String title;
  final Color accentColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LexioRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: LexioSpacing.md,
            vertical: LexioSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(LexioRadius.md),
          ),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: LexioSpacing.xxl,
                  child: Text(
                    number,
                    style: LexioTextStyles.labelSmall.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: LexioSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.noticiaText(
                      textStyle: LexioTextStyles.bodyLarge.copyWith(
                        color: LexioColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: LexioSpacing.md),
                Container(
                  width: LexioSpacing.xxxl,
                  height: LexioSpacing.xxxl,
                  decoration: BoxDecoration(
                    border: Border.all(color: LexioColors.divider),
                    borderRadius: BorderRadius.circular(LexioRadius.full),
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: LexioColors.textPrimary,
                    size: LexioSpacing.xl,
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}

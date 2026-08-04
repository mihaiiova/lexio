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
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LexioSpacing.screenHorizontal,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: LexioSpacing.sectionGap),
                    _buildHeader(),
                    const Spacer(),
                    const Divider(color: LexioColors.divider),
                    _GameEntry(
                      number: '01',
                      title: 'Corect sau greșit?',
                      accentColor: LexioColors.primary,
                      onTap: () => _open(context, const GrammarScreen()),
                    ),
                    const Divider(color: LexioColors.divider),
                    _GameEntry(
                      number: '02',
                      title: 'Ce înseamnă?',
                      accentColor: LexioColors.secondary,
                      onTap: () => _open(context, const VocabularyScreen()),
                    ),
                    const Divider(color: LexioColors.divider),
                    _GameEntry(
                      number: '03',
                      title: 'Vorba vine',
                      accentColor: LexioColors.teal,
                      onTap: () => _open(context, const IdiomsScreen()),
                    ),
                    const Divider(color: LexioColors.divider),
                    _GameEntry(
                      number: '04',
                      title: 'Găsește greșeala',
                      accentColor: LexioColors.accent,
                      onTap: () => _open(context, const SpotScreen()),
                    ),
                    const Divider(color: LexioColors.divider),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
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
            textStyle: LexioTextStyles.bodyLarge.copyWith(
              color: LexioColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          'Joacă-te cu limba română.',
          style: GoogleFonts.noticiaText(
            textStyle: LexioTextStyles.labelMedium.copyWith(
              color: LexioColors.textSecondary,
            ),
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
    required this.onTap,
  });

  final String number;
  final String title;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LexioRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LexioSpacing.md,
            vertical: LexioSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                number,
                style: LexioTextStyles.labelSmall.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: LexioSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.noticiaText(
                        textStyle: LexioTextStyles.displayLarge.copyWith(
                          color: LexioColors.textPrimary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: LexioSpacing.md),
                  Icon(
                    Icons.arrow_forward,
                    color: accentColor,
                    size: LexioSpacing.xl,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

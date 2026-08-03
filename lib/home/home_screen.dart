import 'package:flutter/material.dart';

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
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LexioSpacing.screenHorizontal,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _GameEntry(
                      number: '01',
                      title: 'Corect sau greșit?',
                      details: 'Scriere  ·  15 întrebări',
                      accentColor: LexioColors.primary,
                      onTap: () => _open(context, const GrammarScreen()),
                    ),
                    _GameEntry(
                      number: '02',
                      title: 'Ce înseamnă?',
                      details: 'Vocabular  ·  10 întrebări',
                      accentColor: LexioColors.secondary,
                      onTap: () => _open(context, const VocabularyScreen()),
                    ),
                    _GameEntry(
                      number: '03',
                      title: 'Vorba vine',
                      details: 'Idiomuri  ·  10 expresii',
                      accentColor: LexioColors.teal,
                      onTap: () => _open(context, const IdiomsScreen()),
                    ),
                    _GameEntry(
                      number: '04',
                      title: 'Găsește greșeala',
                      details: 'Contra cronometru  ·  60 de secunde',
                      accentColor: LexioColors.accent,
                      onTap: () => _open(context, const SpotScreen()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
    required this.details,
    required this.accentColor,
    required this.onTap,
  });

  final String number;
  final String title;
  final String details;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LexioColors.background,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LexioRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: LexioSpacing.xl),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: LexioColors.divider)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: LexioTextStyles.bodyLarge.copyWith(
                        color: LexioColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: LexioSpacing.sm),
                    Text(
                      details,
                      style: LexioTextStyles.bodySmall.copyWith(
                        color: LexioColors.textTertiary,
                      ),
                    ),
                  ],
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

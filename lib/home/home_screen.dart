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
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            LexioSpacing.screenHorizontal,
            LexioSpacing.xxl,
            LexioSpacing.screenHorizontal,
            LexioSpacing.huge,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(),
              const SizedBox(height: LexioSpacing.huge),
              _SectionLabel(
                label: 'Provocarea zilei',
                accentColor: LexioColors.primary,
              ),
              const SizedBox(height: LexioSpacing.lg),
              _GameEntry(
                number: '01',
                title: 'Corect sau greșit?',
                details: 'Scriere  ·  15 întrebări',
                accentColor: LexioColors.primary,
                isFeatured: true,
                onTap: () => _open(context, const GrammarScreen()),
              ),
              const SizedBox(height: LexioSpacing.huge),
              const _SectionLabel(label: 'Alege un joc'),
              const SizedBox(height: LexioSpacing.lg),
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
              const SizedBox(height: LexioSpacing.huge),
              const _ComingSoon(),
            ],
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

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lexio',
          style: LexioTextStyles.displayHero.copyWith(
            color: LexioColors.textPrimary,
          ),
        ),
        const SizedBox(height: LexioSpacing.sm),
        Text(
          'Jocuri cu cuvinte în limba română',
          style: LexioTextStyles.bodyLarge.copyWith(
            color: LexioColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.accentColor});

  final String label;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (accentColor != null) ...[
          Container(
            width: LexioSpacing.xl,
            height: LexioSpacing.xxs,
            color: accentColor,
          ),
          const SizedBox(width: LexioSpacing.md),
        ],
        Text(
          label,
          style: LexioTextStyles.labelMedium.copyWith(
            color: LexioColors.textTertiary,
          ),
        ),
      ],
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
    this.isFeatured = false,
  });

  final String number;
  final String title;
  final String details;
  final Color accentColor;
  final VoidCallback onTap;
  final bool isFeatured;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LexioColors.background,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LexioRadius.md),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isFeatured ? LexioSpacing.xxl : LexioSpacing.xl,
          ),
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
                      style:
                          (isFeatured
                                  ? LexioTextStyles.displayMedium
                                  : LexioTextStyles.headingLarge)
                              .copyWith(color: LexioColors.textPrimary),
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

class _ComingSoon extends StatelessWidget {
  const _ComingSoon();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'În pregătire'),
        const SizedBox(height: LexioSpacing.lg),
        Text(
          'Ortografie  /  Logică',
          style: LexioTextStyles.headingLarge.copyWith(
            color: LexioColors.textTertiary,
          ),
        ),
        const SizedBox(height: LexioSpacing.sm),
        Text(
          'Două jocuri noi sosesc în curând.',
          style: LexioTextStyles.bodySmall.copyWith(
            color: LexioColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

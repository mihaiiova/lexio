import 'package:flutter/material.dart';
import '../design/animations.dart';
import '../design/colors.dart';
import '../design/spacing.dart';
import '../design/radius.dart';
import '../design/typography.dart';
import '../design/shadows.dart';
import '../design/components/lexio_card.dart';
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
          padding: const EdgeInsets.only(
            top: LexioSpacing.xxl,
            bottom: LexioSpacing.xxxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: LexioSpacing.xxxl),
              _buildTodaySection(context),
              const SizedBox(height: LexioSpacing.huge),
              _buildVocabularySection(context),
              const SizedBox(height: LexioSpacing.huge),
              _buildIdiomsSection(context),
              const SizedBox(height: LexioSpacing.huge),
              _buildSpotSection(context),
              const SizedBox(height: LexioSpacing.huge),
              _buildComingSoon(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdiomsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LexioSpacing.screenHorizontal,
          ),
          child: Row(
            children: [
              Container(
                width: LexioSpacing.xs,
                height: LexioSpacing.xl,
                decoration: BoxDecoration(
                  color: LexioColors.teal,
                  borderRadius: BorderRadius.circular(LexioRadius.sm),
                ),
              ),
              const SizedBox(width: LexioSpacing.md),
              Text(
                'Expresii românești',
                style: LexioTextStyles.labelSmall.copyWith(
                  color: LexioColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: LexioSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LexioSpacing.screenHorizontal,
          ),
          child: _IdiomsChallengeCard(
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const IdiomsScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(0, 0.05),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: LexioCurves.easeOut,
                                  ),
                                ),
                            child: child,
                          ),
                        );
                      },
                  transitionDuration: LexioDurations.page,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVocabularySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LexioSpacing.screenHorizontal,
          ),
          child: Row(
            children: [
              Container(
                width: LexioSpacing.xs,
                height: LexioSpacing.xl,
                decoration: BoxDecoration(
                  color: LexioColors.secondary,
                  borderRadius: BorderRadius.circular(LexioRadius.sm),
                ),
              ),
              const SizedBox(width: LexioSpacing.md),
              Text(
                'Descoperă cuvinte',
                style: LexioTextStyles.labelSmall.copyWith(
                  color: LexioColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: LexioSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LexioSpacing.screenHorizontal,
          ),
          child: _VocabularyChallengeCard(
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const VocabularyScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(0, 0.05),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: LexioCurves.easeOut,
                                  ),
                                ),
                            child: child,
                          ),
                        );
                      },
                  transitionDuration: LexioDurations.page,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LexioSpacing.screenHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lexio',
            style: LexioTextStyles.displayLarge.copyWith(
              color: LexioColors.textPrimary,
            ),
          ),
          const SizedBox(height: LexioSpacing.xs),
          Text(
            'Jocuri cu cuvinte în limba română',
            style: LexioTextStyles.bodyMedium.copyWith(
              color: LexioColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LexioSpacing.screenHorizontal,
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: LexioColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: LexioSpacing.md),
              Text(
                'Provocarea zilei',
                style: LexioTextStyles.labelSmall.copyWith(
                  color: LexioColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: LexioSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LexioSpacing.screenHorizontal,
          ),
          child: _GrammarChallengeCard(
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const GrammarScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(0, 0.05),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOut,
                                  ),
                                ),
                            child: child,
                          ),
                        );
                      },
                  transitionDuration: const Duration(milliseconds: 350),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSpotSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LexioSpacing.screenHorizontal,
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: LexioColors.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: LexioSpacing.md),
              Text(
                'Găsește greșeala',
                style: LexioTextStyles.labelSmall.copyWith(
                  color: LexioColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: LexioSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LexioSpacing.screenHorizontal,
          ),
          child: _SpotChallengeCard(
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const SpotScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(0, 0.05),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOut,
                                  ),
                                ),
                            child: child,
                          ),
                        );
                      },
                  transitionDuration: const Duration(milliseconds: 350),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildComingSoon() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LexioSpacing.screenHorizontal,
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: LexioColors.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: LexioSpacing.md),
              Text(
                'În curând',
                style: LexioTextStyles.labelSmall.copyWith(
                  color: LexioColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: LexioSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LexioSpacing.screenHorizontal,
          ),
          child: LexioCard(child: _buildComingSoonItems()),
        ),
      ],
    );
  }

  Widget _buildComingSoonItems() {
    return Column(
      children: [
        _ComingSoonItem(
          icon: Icons.text_fields,
          title: 'Ortografie',
          subtitle: 'Scrie corect',
        ),
        const SizedBox(height: LexioSpacing.lg),
        _ComingSoonItem(
          icon: Icons.extension,
          title: 'Logică',
          subtitle: 'Puzzle-uri de limbaj',
        ),
      ],
    );
  }
}

class _IdiomsChallengeCard extends StatelessWidget {
  const _IdiomsChallengeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: LexioCard(
        backgroundColor: LexioColors.teal,
        padding: const EdgeInsets.all(LexioSpacing.xl),
        shadows: LexioShadows.elevatedCombined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LexioSpacing.md,
                    vertical: LexioSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: LexioColors.background.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(LexioRadius.sm),
                  ),
                  child: Text(
                    'Idiomuri',
                    style: LexioTextStyles.labelSmall.copyWith(
                      color: LexioColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward,
                  color: LexioColors.textPrimary,
                  size: LexioSpacing.xl,
                ),
              ],
            ),
            const SizedBox(height: LexioSpacing.lg),
            Text(
              'Vorba vine',
              style: LexioTextStyles.headingMedium.copyWith(
                color: LexioColors.textPrimary,
              ),
            ),
            const SizedBox(height: LexioSpacing.sm),
            Text(
              'Descoperă ce înseamnă expresiile românești folosite în contexte reale.',
              style: LexioTextStyles.bodyMedium.copyWith(
                color: LexioColors.textPrimary.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: LexioSpacing.lg),
            Row(
              children: [
                const Icon(
                  Icons.quiz_outlined,
                  size: LexioSpacing.lg,
                  color: LexioColors.textPrimary,
                ),
                const SizedBox(width: LexioSpacing.xs),
                Text(
                  '10 expresii',
                  style: LexioTextStyles.labelSmall.copyWith(
                    color: LexioColors.textPrimary.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(width: LexioSpacing.lg),
                const Icon(
                  Icons.auto_stories,
                  size: LexioSpacing.lg,
                  color: LexioColors.textPrimary,
                ),
                const SizedBox(width: LexioSpacing.xs),
                Text(
                  '5 niveluri',
                  style: LexioTextStyles.labelSmall.copyWith(
                    color: LexioColors.textPrimary.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VocabularyChallengeCard extends StatelessWidget {
  const _VocabularyChallengeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: LexioCard(
        backgroundColor: LexioColors.secondary,
        padding: const EdgeInsets.all(LexioSpacing.xl),
        shadows: LexioShadows.elevatedCombined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LexioSpacing.md,
                    vertical: LexioSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: LexioColors.textOnPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(LexioRadius.sm),
                  ),
                  child: Text(
                    'Vocabular',
                    style: LexioTextStyles.labelSmall.copyWith(
                      color: LexioColors.textOnPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward,
                  color: LexioColors.textOnPrimary,
                  size: LexioSpacing.xl,
                ),
              ],
            ),
            const SizedBox(height: LexioSpacing.lg),
            Text(
              'Ce înseamnă?',
              style: LexioTextStyles.headingMedium.copyWith(
                color: LexioColors.textOnPrimary,
              ),
            ),
            const SizedBox(height: LexioSpacing.sm),
            Text(
              'Descoperă sensul cuvintelor din context și învață sinonime noi.',
              style: LexioTextStyles.bodyMedium.copyWith(
                color: LexioColors.textOnPrimary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: LexioSpacing.lg),
            Row(
              children: [
                const Icon(
                  Icons.quiz_outlined,
                  size: LexioSpacing.lg,
                  color: LexioColors.textOnPrimary,
                ),
                const SizedBox(width: LexioSpacing.xs),
                Text(
                  '10 întrebări',
                  style: LexioTextStyles.labelSmall.copyWith(
                    color: LexioColors.textOnPrimary.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(width: LexioSpacing.lg),
                const Icon(
                  Icons.auto_stories,
                  size: LexioSpacing.lg,
                  color: LexioColors.textOnPrimary,
                ),
                const SizedBox(width: LexioSpacing.xs),
                Text(
                  '5 niveluri',
                  style: LexioTextStyles.labelSmall.copyWith(
                    color: LexioColors.textOnPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonItem extends StatelessWidget {
  const _ComingSoonItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: LexioColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(LexioRadius.md),
          ),
          child: Icon(icon, size: 22, color: LexioColors.primaryLight),
        ),
        const SizedBox(width: LexioSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: LexioTextStyles.bodyLarge.copyWith(
                  color: LexioColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: LexioTextStyles.bodySmall.copyWith(
                  color: LexioColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: LexioSpacing.md,
            vertical: LexioSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: LexioColors.surfaceTertiary,
            borderRadius: BorderRadius.circular(LexioRadius.sm),
          ),
          child: Text(
            'Curând',
            style: LexioTextStyles.labelSmall.copyWith(
              color: LexioColors.textTertiary,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}

class _SpotChallengeCard extends StatelessWidget {
  const _SpotChallengeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: LexioCard(
        backgroundColor: LexioColors.accent,
        padding: const EdgeInsets.all(LexioSpacing.xl),
        shadows: LexioShadows.elevatedCombined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LexioSpacing.md,
                    vertical: LexioSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: LexioColors.textOnPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(LexioRadius.sm),
                  ),
                  child: Text(
                    'Contra cronometru',
                    style: LexioTextStyles.labelSmall.copyWith(
                      color: LexioColors.textOnPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward,
                  color: LexioColors.textOnPrimary,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: LexioSpacing.lg),
            Text(
              'Găsește greșeala',
              style: LexioTextStyles.headingMedium.copyWith(
                color: LexioColors.textOnPrimary,
              ),
            ),
            const SizedBox(height: LexioSpacing.sm),
            Text(
              'Citește texte reale și atinge cuvintele greșite pentru a le corecta.',
              style: LexioTextStyles.bodyMedium.copyWith(
                color: LexioColors.textOnPrimary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: LexioSpacing.lg),
            Row(
              children: [
                const Icon(
                  Icons.timer,
                  size: 16,
                  color: LexioColors.textOnPrimary,
                ),
                const SizedBox(width: LexioSpacing.xs),
                Text(
                  '60 de secunde',
                  style: LexioTextStyles.labelSmall.copyWith(
                    color: LexioColors.textOnPrimary.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(width: LexioSpacing.lg),
                const Icon(
                  Icons.auto_stories,
                  size: 16,
                  color: LexioColors.textOnPrimary,
                ),
                const SizedBox(width: LexioSpacing.xs),
                Text(
                  '5 texte',
                  style: LexioTextStyles.labelSmall.copyWith(
                    color: LexioColors.textOnPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GrammarChallengeCard extends StatelessWidget {
  const _GrammarChallengeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: LexioCard(
        backgroundColor: LexioColors.primary,
        padding: const EdgeInsets.all(LexioSpacing.xl),
        shadows: LexioShadows.elevatedCombined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LexioSpacing.md,
                    vertical: LexioSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: LexioColors.textOnPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(LexioRadius.sm),
                  ),
                  child: Text(
                    'Scriere',
                    style: LexioTextStyles.labelSmall.copyWith(
                      color: LexioColors.textOnPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward,
                  color: LexioColors.textOnPrimary,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: LexioSpacing.lg),
            Text(
              'Corect sau gre\u0219it?',
              style: LexioTextStyles.headingMedium.copyWith(
                color: LexioColors.textOnPrimary,
              ),
            ),
            const SizedBox(height: LexioSpacing.sm),
            Text(
              'Analizează propoziții în limba română și descoperă greșelile gramaticale.',
              style: LexioTextStyles.bodyMedium.copyWith(
                color: LexioColors.textOnPrimary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: LexioSpacing.lg),
            Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: LexioColors.textOnPrimary,
                ),
                const SizedBox(width: LexioSpacing.xs),
                Text(
                  '15 întrebări',
                  style: LexioTextStyles.labelSmall.copyWith(
                    color: LexioColors.textOnPrimary.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(width: LexioSpacing.lg),
                const Icon(
                  Icons.auto_stories,
                  size: 16,
                  color: LexioColors.textOnPrimary,
                ),
                const SizedBox(width: LexioSpacing.xs),
                Text(
                  'Învață',
                  style: LexioTextStyles.labelSmall.copyWith(
                    color: LexioColors.textOnPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

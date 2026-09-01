import 'dart:async';

import 'package:flutter/material.dart';

import '../analytics/analytics_service.dart';
import '../design/animations.dart';
import '../design/colors.dart';
import '../design/components/lexio_game_card.dart';
import '../design/spacing.dart';
import '../design/typography.dart';
import '../games/grammar/grammar_screen.dart';
import '../games/idioms/idioms_screen.dart';
import '../games/spot/spot_screen.dart';
import '../games/vocabulary/vocabulary_screen.dart';
import '../privacy/privacy_screen.dart';
import '../progress/user_progress.dart';
import 'discovery_catalog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.progressStorage});

  final ProgressStorage? progressStorage;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ProgressRepository? _progress;
  Map<String, int>? _totals;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final totals = await DiscoveryCatalog.totalNotionsByGame();
      final progress = await ProgressRepository.load(
        storage: widget.progressStorage,
      );
      if (!mounted) return;
      setState(() {
        _totals = totals;
        _progress = progress;
      });
    } catch (error) {
      debugPrint('HomeScreen: failed to load discovery progress: $error');
    }
  }

  int? _discoveredFor(String gameId) => _totals == null
      ? null
      : (_progress?.forGame(gameId).countStarted() ?? 0);

  int? _totalFor(String gameId) => _totals?[gameId];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LexioColors.backgroundSubtle,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: LexioSpacing.screenHorizontal,
            vertical: LexioSpacing.sectionGap,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: LexioSpacing.sectionGap),
              _buildGameCard(
                title: 'Corect sau greșit?',
                accentColor: LexioColors.primary,
                mutedColor: LexioColors.primaryMuted,
                gameId: 'grammar',
                screen: const GrammarScreen(),
              ),
              const SizedBox(height: LexioSpacing.itemGap),
              _buildGameCard(
                title: 'Ce înseamnă?',
                accentColor: LexioColors.secondary,
                mutedColor: LexioColors.secondaryMuted,
                gameId: 'vocabulary',
                screen: const VocabularyScreen(),
              ),
              const SizedBox(height: LexioSpacing.itemGap),
              _buildGameCard(
                title: 'Vorba vine',
                accentColor: LexioColors.teal,
                mutedColor: LexioColors.tealMuted,
                gameId: 'idioms',
                screen: const IdiomsScreen(),
              ),
              const SizedBox(height: LexioSpacing.itemGap),
              _buildGameCard(
                title: 'Găsește greșeala',
                accentColor: LexioColors.accent,
                mutedColor: LexioColors.accentMuted,
                gameId: 'spot',
                screen: const SpotScreen(),
              ),
              const SizedBox(height: LexioSpacing.xxl),
              _buildLegalFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard({
    required String title,
    required Color accentColor,
    required Color mutedColor,
    required String gameId,
    required Widget screen,
  }) {
    final discovered = _discoveredFor(gameId) ?? 0;
    final total = _totalFor(gameId) ?? 0;

    return LexioGameCard(
      title: title,
      accentColor: accentColor,
      mutedColor: mutedColor,
      discovered: discovered,
      total: total,
      onTap: () => _openGame(context, gameId, screen),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Slove',
          style: LexioTextStyles.bodyLarge.copyWith(
            color: LexioColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontFamily: 'NoticiaText',
          ),
        ),
        Text(
          'Joacă-te cu limba română.',
          style: LexioTextStyles.labelMedium.copyWith(
            color: LexioColors.textSecondary,
            fontFamily: 'NoticiaText',
          ),
        ),
      ],
    );
  }

  void _openGame(BuildContext context, String gameId, Widget screen) {
    unawaited(AnalyticsService.logGameOpened(gameId));
    _open(context, screen);
  }

  void _open(BuildContext context, Widget screen) {
    unawaited(
      Navigator.of(context)
          .push(
            PageRouteBuilder<void>(
              pageBuilder: (context, animation, secondaryAnimation) => screen,
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    final offsetAnimation =
                        Tween<Offset>(
                          begin: const Offset(0, 0.05),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: LexioCurves.easeOut,
                          ),
                        );

                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: offsetAnimation,
                        child: child,
                      ),
                    );
                  },
              transitionDuration: LexioDurations.page,
            ),
          )
          .then((_) => _reloadProgress()),
    );
  }

  Future<void> _reloadProgress() async {
    try {
      final progress = await ProgressRepository.load(
        storage: widget.progressStorage,
      );
      if (!mounted) return;
      setState(() {
        _progress = progress;
      });
    } catch (error) {
      debugPrint('HomeScreen: failed to reload progress: $error');
    }
  }

  Widget _buildLegalFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: LexioSpacing.md,
        bottom: LexioSpacing.xl,
      ),
      child: Center(
        child: TextButton(
          onPressed: () => _open(context, const PrivacyScreen()),
          child: Text(
            'Confidențialitate',
            style: LexioTextStyles.labelSmall.copyWith(
              color: LexioColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}


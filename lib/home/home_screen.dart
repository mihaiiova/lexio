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
  const HomeScreen({
    super.key,
    this.progressRepository,
    this.grammarScreenBuilder,
    this.vocabularyScreenBuilder,
    this.idiomsScreenBuilder,
    this.spotScreenBuilder,
  });

  final ProgressRepository? progressRepository;
  final Widget Function()? grammarScreenBuilder;
  final Widget Function()? vocabularyScreenBuilder;
  final Widget Function()? idiomsScreenBuilder;
  final Widget Function()? spotScreenBuilder;

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
      final progress =
          widget.progressRepository ?? await ProgressRepository.load();
      if (!mounted) return;
      setState(() {
        _totals = totals;
        _progress = progress;
      });
    } catch (error) {
      debugPrint('HomeScreen: failed to load discovery progress: $error');
    }
  }

  int _discoveredFor(String gameId) =>
      _progress?.forGame(gameId).countStarted() ?? 0;

  int _totalFor(String gameId) => _totals?[gameId] ?? 0;

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
                semanticLabel: 'Joc 01: Corect sau greșit?',
                accentColor: LexioColors.primary,
                mutedColor: LexioColors.primaryMuted,
                gameId: 'grammar',
                screen:
                    widget.grammarScreenBuilder?.call() ??
                    GrammarScreen(progressRepository: widget.progressRepository),
              ),
              const SizedBox(height: LexioSpacing.itemGap),
              _buildGameCard(
                title: 'Ce înseamnă?',
                semanticLabel: 'Joc 02: Ce înseamnă?',
                accentColor: LexioColors.secondary,
                mutedColor: LexioColors.secondaryMuted,
                gameId: 'vocabulary',
                screen:
                    widget.vocabularyScreenBuilder?.call() ??
                    VocabularyScreen(
                      progressRepository: widget.progressRepository,
                    ),
              ),
              const SizedBox(height: LexioSpacing.itemGap),
              _buildGameCard(
                title: 'Vorba vine',
                semanticLabel: 'Joc 03: Vorba vine',
                accentColor: LexioColors.teal,
                mutedColor: LexioColors.tealMuted,
                gameId: 'idioms',
                screen:
                    widget.idiomsScreenBuilder?.call() ??
                    IdiomsScreen(progressRepository: widget.progressRepository),
              ),
              const SizedBox(height: LexioSpacing.itemGap),
              _buildGameCard(
                title: 'Găsește greșeala',
                semanticLabel: 'Joc 04: Găsește greșeala',
                accentColor: LexioColors.accent,
                mutedColor: LexioColors.accentMuted,
                gameId: 'spot',
                screen:
                    widget.spotScreenBuilder?.call() ??
                    SpotScreen(progressRepository: widget.progressRepository),
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
    required String semanticLabel,
    required Color accentColor,
    required Color mutedColor,
    required String gameId,
    required Widget screen,
  }) {
    return LexioGameCard(
      title: title,
      semanticLabel: semanticLabel,
      accentColor: accentColor,
      mutedColor: mutedColor,
      discovered: _discoveredFor(gameId),
      total: _totalFor(gameId),
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
      final progress =
          widget.progressRepository ?? await ProgressRepository.load();
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

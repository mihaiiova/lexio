import 'package:flutter/material.dart';

import '../design/colors.dart';
import '../design/components/lexio_button.dart';
import '../design/sizes.dart';
import '../design/spacing.dart';
import '../design/typography.dart';
import '../privacy/privacy_screen.dart';
import 'analytics_repository.dart';

Future<void> showAnalyticsConsentScreen(
  BuildContext context,
  AnalyticsRepository repository,
) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => AnalyticsConsentScreen(repository: repository),
    ),
  );
  // Leaving without choosing must never grant consent or repeat the prompt.
  if (repository.isConsentUndecided) await repository.decline();
}

class AnalyticsConsentScreen extends StatefulWidget {
  const AnalyticsConsentScreen({super.key, required this.repository});

  final AnalyticsRepository repository;

  @override
  State<AnalyticsConsentScreen> createState() => _AnalyticsConsentScreenState();
}

class _AnalyticsConsentScreenState extends State<AnalyticsConsentScreen> {
  bool _busy = false;

  Future<void> _submit(bool enable) async {
    if (_busy || ModalRoute.of(context)?.isCurrent != true) return;
    setState(() => _busy = true);
    if (enable) {
      await widget.repository.enable();
    } else {
      await widget.repository.decline();
    }
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    if (enable && !widget.repository.isConsentEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Alegerea nu a putut fi salvată. Analiza rămâne oprită. '
            'Poți încerca din nou din Setări.',
          ),
        ),
      );
    }
    Navigator.of(context).pop();
  }

  void _openPrivacy() {
    if (_busy || ModalRoute.of(context)?.isCurrent != true) return;
    Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => const PrivacyScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: LexioColors.backgroundSubtle,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: LexioSpacing.screenHorizontal,
                vertical: LexioSpacing.sectionGap,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: LexioSizes.readableContentMaxWidth,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Ne ajuți să îmbunătățim Slove?',
                        style: LexioTextStyles.headingMedium.copyWith(
                          color: LexioColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: LexioSpacing.lg),
                    Text(
                      'Putem colecta date despre utilizarea jocurilor pentru a '
                      'înțelege ce funcționează bine și ce putem îmbunătăți.',
                      style: LexioTextStyles.bodyMedium.copyWith(
                        color: LexioColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: LexioSpacing.xl),
                    Text(
                      'Nu colectăm nume, răspunsuri sau texte introduse.',
                      style: LexioTextStyles.bodyMedium.copyWith(
                        color: LexioColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: LexioSpacing.sm),
                    Text(
                      'Jocurile funcționează la fel și fără acord.',
                      style: LexioTextStyles.bodyMedium.copyWith(
                        color: LexioColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: LexioSpacing.lg),
                    Text(
                      'Această opțiune este pentru părinți sau tutori. '
                      'Poți schimba alegerea oricând din Setări.',
                      style: LexioTextStyles.bodySmall.copyWith(
                        color: LexioColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: LexioSpacing.xxl),
                    LexioButton(
                      label: 'Permite analiza utilizării',
                      isExpanded: true,
                      wrapLabel: true,
                      onPressed: _busy ? null : () => _submit(true),
                    ),
                    const SizedBox(height: LexioSpacing.sm),
                    LexioButton(
                      label: 'Nu, mulțumesc',
                      variant: LexioButtonVariant.secondary,
                      isExpanded: true,
                      wrapLabel: true,
                      onPressed: _busy ? null : () => _submit(false),
                    ),
                    const SizedBox(height: LexioSpacing.sm),
                    TextButton(
                      onPressed: _busy ? null : _openPrivacy,
                      child: Text(
                        'Detalii despre confidențialitate',
                        textAlign: TextAlign.center,
                        style: LexioTextStyles.labelMedium,
                      ),
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
}

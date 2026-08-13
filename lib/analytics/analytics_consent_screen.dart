import 'dart:async';

import 'package:flutter/material.dart';

import '../design/colors.dart';
import '../design/components/lexio_button.dart';
import '../design/spacing.dart';
import '../design/typography.dart';
import 'analytics_service.dart';

class AnalyticsConsentScreen extends StatelessWidget {
  const AnalyticsConsentScreen({super.key, required this.onDecided});

  final VoidCallback onDecided;

  Future<void> _decide(bool granted) async {
    await AnalyticsService.setConsent(granted);
    onDecided();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LexioColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            LexioSpacing.screenHorizontal,
            LexioSpacing.xxl,
            LexioSpacing.screenHorizontal,
            LexioSpacing.screenBottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                'Statistici anonime',
                style: LexioTextStyles.headingMedium.copyWith(
                  color: LexioColors.textPrimary,
                ),
              ),
              const SizedBox(height: LexioSpacing.lg),
              Text(
                'Slove colectează un set minimal de date anonime pentru a '
                'garanta funcționarea corectă a jocurilor. Nu colectăm nume, '
                'adrese de email sau răspunsurile tale. Poți folosi aplicația '
                'și fără aceste statistici.',
                style: LexioTextStyles.bodyMedium.copyWith(
                  color: LexioColors.textSecondary,
                ),
              ),
              const SizedBox(height: LexioSpacing.lg),
              Text(
                'Prin accept, confirmi că ai peste 13 ani.',
                style: LexioTextStyles.bodySmall.copyWith(
                  color: LexioColors.textTertiary,
                ),
              ),
              const Spacer(),
              LexioButton(
                label: 'Sunt de acord',
                onPressed: () => unawaited(_decide(true)),
                isExpanded: true,
              ),
              const SizedBox(height: LexioSpacing.md),
              LexioButton(
                label: 'Fără statistici',
                onPressed: () => unawaited(_decide(false)),
                variant: LexioButtonVariant.secondary,
                isExpanded: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

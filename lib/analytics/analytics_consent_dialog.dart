import 'package:flutter/material.dart';

import '../design/colors.dart';
import '../design/components/lexio_button.dart';
import '../design/components/lexio_card.dart';
import '../design/spacing.dart';
import '../design/typography.dart';
import 'analytics_repository.dart';

/// First-launch, guardian-directed opt-in for anonymous analytics.
///
/// It is dismissible without losing gameplay and defaults to off. The
/// guardian confirmation is self-declared: we state that plainly instead of
/// claiming legal compliance.
Future<void> showAnalyticsConsentDialog(
  BuildContext context,
  AnalyticsRepository repository,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => AnalyticsConsentDialog(repository: repository),
  ).then((_) async {
    // A barrier dismiss is a silent decline; record it so the prompt does not
    // return on every launch.
    if (repository.isConsentUndecided) {
      await repository.decline();
    }
  });
}

final class AnalyticsConsentDialog extends StatelessWidget {
  const AnalyticsConsentDialog({super.key, required this.repository});

  final AnalyticsRepository repository;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: LexioCard(
        padding: const EdgeInsets.all(LexioSpacing.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Analiză anonimă',
              style: LexioTextStyles.headingSmall.copyWith(
                color: LexioColors.textPrimary,
              ),
            ),
            const SizedBox(height: LexioSpacing.sm),
            Text(
              'Putem înregistra anonim cum sunt folosite exercițiile, pentru a '
              'asigura calitatea exercițiilor. Nu colectăm textele '
              'exercițiilor, răspunsurile tale, numele sau date de contact.',
              style: LexioTextStyles.bodyMedium.copyWith(
                color: LexioColors.textSecondary,
              ),
            ),
            const SizedBox(height: LexioSpacing.sm),
            Text(
              'Confirmarea este dată de părinte sau tutore și este declarată '
              'pe proprie răspundere; aplicația nu verifică identitatea și nu '
              'reprezintă o garanție de conformitate legală.',
              style: LexioTextStyles.bodySmall.copyWith(
                color: LexioColors.textTertiary,
              ),
            ),
            const SizedBox(height: LexioSpacing.lg),
            LexioButton(
              label: 'Permite',
              variant: LexioButtonVariant.primary,
              size: LexioButtonSize.large,
              isExpanded: true,
              onPressed: () async {
                await repository.enable();
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: LexioSpacing.sm),
            LexioButton(
              label: 'Nu, mulțumesc',
              variant: LexioButtonVariant.ghost,
              size: LexioButtonSize.large,
              isExpanded: true,
              onPressed: () async {
                await repository.decline();
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

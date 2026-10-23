import 'package:flutter/material.dart';

import '../design/colors.dart';
import '../design/components/lexio_button.dart';
import '../design/components/lexio_card.dart';
import '../design/spacing.dart';
import '../design/typography.dart';
import 'analytics_repository.dart';

/// First-launch, guardian-directed opt-in for installation-linked analytics.
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

final class AnalyticsConsentDialog extends StatefulWidget {
  const AnalyticsConsentDialog({super.key, required this.repository});

  final AnalyticsRepository repository;

  @override
  State<AnalyticsConsentDialog> createState() => _AnalyticsConsentDialogState();
}

class _AnalyticsConsentDialogState extends State<AnalyticsConsentDialog> {
  bool _busy = false;

  Future<void> _submit(bool enable) async {
    if (_busy) return;
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
            'Activarea nu a reușit. Colectarea rămâne oprită. '
            'Verifică stocarea și eventualele cereri de ștergere din Setări.',
          ),
        ),
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: Dialog(
        backgroundColor: LexioColors.transparent,
        child: LexioCard(
          padding: const EdgeInsets.all(LexioSpacing.cardPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Analiză opțională',
                style: LexioTextStyles.headingSmall.copyWith(
                  color: LexioColors.textPrimary,
                ),
              ),
              const SizedBox(height: LexioSpacing.sm),
              Text(
                'Putem înregistra utilizarea exercițiilor pe această instalare pentru a '
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
              const SizedBox(height: LexioSpacing.sm),
              Text(
                'Datele sunt legate de un identificator aleatoriu al instalării '
                'cu termen de păstrare de 90 de zile și eliminare zilnică; '
                'defecțiunile pot întârzia ștergerea. Apoi pot rămâne totaluri fără această legătură. '
                'Poți opri colectarea și cere ștergerea din Setări. '
                'Jocul rămâne disponibil fără acord sau internet.',
                style: LexioTextStyles.bodySmall.copyWith(
                  color: LexioColors.textSecondary,
                ),
              ),
              const SizedBox(height: LexioSpacing.lg),
              LexioButton(
                label: 'Permite',
                variant: LexioButtonVariant.primary,
                size: LexioButtonSize.large,
                isExpanded: true,
                onPressed: _busy ? null : () => _submit(true),
              ),
              const SizedBox(height: LexioSpacing.sm),
              LexioButton(
                label: 'Nu, mulțumesc',
                variant: LexioButtonVariant.ghost,
                size: LexioButtonSize.large,
                isExpanded: true,
                onPressed: _busy ? null : () => _submit(false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../design/colors.dart';
import '../design/components/lexio_button.dart';
import '../design/components/lexio_card.dart';
import '../design/spacing.dart';
import '../design/typography.dart';
import 'analytics_repository.dart';
import 'analytics_consent_dialog.dart';

/// Settings section for installation-linked, opt-in analytics.
///
/// The user can enable, disable, or delete this installation's linked server
/// records. All collection is opt-in and off by default.
class AnalyticsSettingsScreen extends StatefulWidget {
  const AnalyticsSettingsScreen({super.key, required this.analytics});

  final AnalyticsRepository analytics;

  @override
  State<AnalyticsSettingsScreen> createState() =>
      _AnalyticsSettingsScreenState();
}

class _AnalyticsSettingsScreenState extends State<AnalyticsSettingsScreen> {
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final analytics = widget.analytics;
    final enabled = analytics.isConsentEnabled;

    return Scaffold(
      backgroundColor: LexioColors.background,
      appBar: AppBar(
        backgroundColor: LexioColors.background,
        title: const Text('Setări'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            LexioSpacing.screenHorizontal,
            LexioSpacing.xl,
            LexioSpacing.screenHorizontal,
            LexioSpacing.screenBottom,
          ),
          children: [
            LexioCard(
              padding: const EdgeInsets.all(LexioSpacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Analiză opțională',
                          style: LexioTextStyles.headingSmall.copyWith(
                            color: LexioColors.textPrimary,
                          ),
                        ),
                      ),
                      Switch(
                        value: enabled,
                        onChanged: _deleting || analytics.needsDeletion
                            ? null
                            : (value) => _setConsent(value),
                      ),
                    ],
                  ),
                  const SizedBox(height: LexioSpacing.sm),
                  Text(
                    'Doar cu acordul tău, înregistrăm utilizarea exercițiilor '
                    'pentru a asigura calitatea exercițiilor. Nu colectăm textele '
                    'exercițiilor, răspunsurile tale sau date de contact.',
                    style: LexioTextStyles.bodyMedium.copyWith(
                      color: LexioColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: LexioSpacing.sm),
                  Text(
                    'Confirmarea este dată de părinte sau tutore și este '
                    'declarată pe proprie răspundere.',
                    style: LexioTextStyles.bodySmall.copyWith(
                      color: LexioColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: LexioSpacing.sm),
                  Text(
                    'Datele sunt legate de un identificator aleatoriu al acestei '
                    'instalări, nu al unei persoane, timp de cel mult 90 de zile. '
                    'Apoi pot rămâne doar totaluri fără legătură cu instalarea. '
                    'Jocul funcționează și fără acord sau internet.',
                    style: LexioTextStyles.bodySmall.copyWith(
                      color: LexioColors.textSecondary,
                    ),
                  ),
                  if (analytics.consentPersistenceFailed) ...[
                    const SizedBox(height: LexioSpacing.sm),
                    Text(
                      'Setarea locală nu a putut fi salvată. Colectarea este oprită '
                      'acum, dar reîncearcă salvarea înainte de a închide aplicația: '
                      'la redeschidere poate reveni setarea veche.',
                      style: LexioTextStyles.bodySmall.copyWith(
                        color: LexioColors.textSecondary,
                      ),
                    ),
                    LexioButton(
                      label: 'Reîncearcă salvarea opririi',
                      variant: LexioButtonVariant.secondary,
                      onPressed: () => _setConsent(false),
                    ),
                  ],
                  if (analytics.needsDeletion) ...[
                    const SizedBox(height: LexioSpacing.sm),
                    Text(
                      'Colectarea este oprită. Înainte de reactivare, finalizează '
                      'ștergerea datelor vechii instalări folosind butonul de mai jos. '
                      'Dacă ești offline, încearcă din nou când ai internet.',
                      style: LexioTextStyles.bodySmall.copyWith(
                        color: LexioColors.textSecondary,
                      ),
                    ),
                  ],
                  if (enabled || analytics.needsDeletion) ...[
                    const SizedBox(height: LexioSpacing.lg),
                    LexioButton(
                      label: 'Șterge datele de pe server',
                      variant: LexioButtonVariant.danger,
                      size: LexioButtonSize.medium,
                      isExpanded: true,
                      isLoading: _deleting,
                      onPressed: _deleting ? null : _delete,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setConsent(bool enabled) async {
    if (enabled) {
      await showAnalyticsConsentDialog(context, widget.analytics);
    } else {
      await widget.analytics.disable();
    }
    if (mounted) setState(() {});
  }

  Future<void> _delete() async {
    setState(() => _deleting = true);
    final deleted = await widget.analytics.disableAndDelete();
    if (!mounted) return;
    setState(() => _deleting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted
              ? 'Datele legate de această instalare au fost șterse.'
              : 'Ștergerea nu a putut fi finalizată. Încearcă din nou.',
        ),
      ),
    );
  }
}

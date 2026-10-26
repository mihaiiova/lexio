import 'package:flutter/material.dart';

import '../design/colors.dart';
import '../design/components/lexio_button.dart';
import '../design/components/lexio_card.dart';
import '../design/spacing.dart';
import '../design/typography.dart';
import '../privacy/privacy_screen.dart';
import 'analytics_consent_screen.dart';
import 'analytics_repository.dart';

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
                    'Analiza utilizării ne ajută să îmbunătățim jocurile. '
                    'Nu colectăm nume, răspunsuri sau texte introduse. '
                    'Jocurile funcționează la fel și fără acord.',
                    style: LexioTextStyles.bodyMedium.copyWith(
                      color: LexioColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: LexioSpacing.sm),
                  Text(
                    'Opțiunea este pentru părinți sau tutori. '
                    'Poți opri analiza oricând.',
                    style: LexioTextStyles.bodySmall.copyWith(
                      color: LexioColors.textTertiary,
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
                      wrapLabel: true,
                      variant: LexioButtonVariant.secondary,
                      onPressed: () => _setConsent(false),
                    ),
                  ],
                  if (analytics.needsDeletion) ...[
                    const SizedBox(height: LexioSpacing.sm),
                    Text(
                      'Colectarea este oprită. Cererea de ștergere este în '
                      'așteptare. Reactivarea este disponibilă după confirmarea '
                      'ștergerii.',
                      style: LexioTextStyles.bodySmall.copyWith(
                        color: LexioColors.textSecondary,
                      ),
                    ),
                  ],
                  if (analytics.hasRetainedIdentity ||
                      analytics.needsDeletion) ...[
                    const SizedBox(height: LexioSpacing.lg),
                    LexioButton(
                      label: 'Șterge datele de pe server',
                      wrapLabel: true,
                      variant: LexioButtonVariant.danger,
                      size: LexioButtonSize.medium,
                      isExpanded: true,
                      isLoading: _deleting,
                      onPressed: _deleting || !analytics.isServerConfigured
                          ? null
                          : _delete,
                    ),
                    if (!analytics.isServerConfigured) ...[
                      const SizedBox(height: LexioSpacing.sm),
                      Text(
                        'Ștergerea de pe server nu este disponibilă: serverul de '
                        'analiză nu este configurat în această versiune.',
                        style: LexioTextStyles.bodySmall.copyWith(
                          color: LexioColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: LexioSpacing.md),
            TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => const PrivacyScreen()),
              ),
              child: Text(
                'Detalii despre confidențialitate',
                textAlign: TextAlign.center,
                style: LexioTextStyles.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setConsent(bool enabled) async {
    if (enabled) {
      await showAnalyticsConsentScreen(context, widget.analytics);
    } else {
      await widget.analytics.disable();
    }
    if (mounted) setState(() {});
  }

  Future<void> _delete() async {
    if (_deleting || !widget.analytics.isServerConfigured) return;
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

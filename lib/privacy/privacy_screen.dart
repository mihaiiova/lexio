import 'package:flutter/material.dart';

import '../design/colors.dart';
import '../design/spacing.dart';
import '../design/typography.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LexioColors.background,
      appBar: AppBar(
        backgroundColor: LexioColors.background,
        title: const Text('Confidențialitate'),
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
          children: const [
            _PolicyIntro(),
            _PolicySection(
              title: 'Ce date colectăm',
              body:
                  'Slove folosește Firebase Analytics pentru statistici de '
                  'utilizare fără nume sau cont. Înregistrăm deschiderea '
                  'unui joc și identificatorul fix al jocului ales. Nu trimitem '
                  'răspunsurile tale, scorul, progresul, numele, adresa de email '
                  'sau texte introduse de tine.',
            ),
            _PolicySection(
              title: 'Date tehnice',
              body:
                  'Firebase Analytics poate colecta automat informații tehnice '
                  'precum un identificator al instalării, modelul dispozitivului, '
                  'sistemul de operare, versiunea aplicației, limba și regiunea '
                  'aproximativă. Aceste informații ne ajută să înțelegem ce '
                  'jocuri sunt folosite și să îmbunătățim aplicația.',
            ),
            _PolicySection(
              title: 'Cum folosim datele',
              body:
                  'Folosim datele numai pentru statistici agregate, evaluarea '
                  'funcțiilor aplicației și îmbunătățirea jocurilor. Nu folosim '
                  'datele pentru reclame personalizate și nu vindem datele. '
                  'Google procesează datele prin serviciul Firebase Analytics, '
                  'conform propriilor condiții și măsuri de securitate.',
            ),
            _PolicySection(
              title: 'Progresul tău',
              body:
                  'Răspunsurile corecte și greșite și progresul de învățare sunt '
                  'stocate local pe dispozitiv. Aceste date nu sunt trimise la '
                  'Firebase și nu sunt asociate cu statisticile de utilizare.',
            ),
            _PolicySection(
              title: 'Linkuri externe',
              body:
                  'Unele explicații pot deschide în browser pagini ale '
                  'Dicționarului Ortografic, Ortoepic și Morfologic al Limbii '
                  'Române. Site-ul extern primește informațiile tehnice obișnuite '
                  'ale unei accesări web și aplică propria politică de '
                  'confidențialitate.',
            ),
            _PolicySection(
              title: 'Copii',
              body: 'Slove este o aplicație educațională potrivită pentru copii.',
            ),
            _PolicySection(
              title: 'Modificări și contact',
              body:
                  'Putem actualiza această politică atunci când se schimbă '
                  'aplicația sau cerințele legale. Versiunea curentă este '
                  'disponibilă permanent în aplicație. Pentru întrebări despre '
                  'confidențialitate, folosește datele de contact ale '
                  'dezvoltatorului afișate în pagina aplicației din magazin.',
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicyIntro extends StatelessWidget {
  const _PolicyIntro();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Politica de confidențialitate',
          style: LexioTextStyles.headingMedium.copyWith(
            color: LexioColors.textPrimary,
          ),
        ),
        const SizedBox(height: LexioSpacing.sm),
        Text(
          'Ultima actualizare: 7 august 2026',
          style: LexioTextStyles.labelSmall.copyWith(
            color: LexioColors.textTertiary,
          ),
        ),
        const SizedBox(height: LexioSpacing.lg),
        Text(
          'Slove este dezvoltată de un creator independent. Această politică '
          'explică simplu ce informații folosim și ce rămâne doar pe '
          'dispozitivul tău.',
          style: LexioTextStyles.bodyMedium.copyWith(
            color: LexioColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: LexioSpacing.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: LexioTextStyles.headingSmall.copyWith(
              color: LexioColors.textPrimary,
            ),
          ),
          const SizedBox(height: LexioSpacing.sm),
          Text(
            body,
            style: LexioTextStyles.bodyMedium.copyWith(
              color: LexioColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

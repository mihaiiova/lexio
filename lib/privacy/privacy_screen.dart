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
                  'Slove poate fi folosită de persoane de orice vârstă. În mod '
                  'implicit nu colectăm și nu transmitem date despre utilizarea '
                  'jocurilor. Numai dacă analiza anonimă este activată explicit '
                  'de părinte sau tutore, aplicația trimite semnale limitate: '
                  'un identificator anonim de instalare, jocul, exercițiul și '
                  'rezultatul corect/greșit. Nu trimitem textele exercițiilor, '
                  'răspunsurile introduse, scorurile detaliate sau progresul de '
                  'învățare și nu solicităm numele, adresa de email, '
                  'identificatori de publicitate ori date de localizare.',
            ),
            _PolicySection(
              title: 'Cum folosim datele',
              body:
                  'Jocurile și progresul funcționează local și offline. Când există '
                  'o conexiune, aplicația poate descărca actualizări statice pentru '
                  'exerciții și, numai dacă analiza anonimă este activată, poate '
                  'trimite semnalele limitate descrise mai sus către infrastructura '
                  'noastră proprie (Cloudflare). Furnizorul de găzduire poate '
                  'procesa metadatele tehnice obișnuite ale conexiunii, precum '
                  'adresa IP; cererile nu includ răspunsuri, scoruri sau progres. '
                  'Nu folosim datele pentru reclame și nu vindem date.',
            ),
            _PolicySection(
              title: 'Progresul tău',
              body:
                  'Răspunsurile corecte și greșite și progresul de învățare sunt '
                  'stocate local pe dispozitiv. Aceste date nu părăsesc dispozitivul '
                  'și nu sunt asociate cu un cont.',
            ),
            _PolicySection(
              title: 'Analiza anonimă opțională',
              body:
                  'Analiza este dezactivată implicit. Dacă este activată de părinte '
                  'sau tutore, înregistrăm anonim ce exerciții sunt afișate și '
                  'rezolvate, pentru a asigura calitatea exercițiilor. '
                  'Identificatorul de instalare este generat aleatoriu și nu este '
                  'legat de o persoană. Confirmarea părintelui sau tutorelui este '
                  'declarată pe proprie răspundere și nu reprezintă o garanție de '
                  'conformitate legală. Poți dezactiva oricând analiza și poți '
                  'șterge datele legate de această instalare din secțiunea Setări.',
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
              body:
                  'Slove poate fi folosită și de copii sub 13 ani. Analiza anonimă '
                  'este dezactivată implicit și poate fi activată doar de un părinte '
                  'sau tutore, pe proprie răspundere. Nu colectăm prin Slove date '
                  'de identificare sau texte ale exercițiilor; progresul rămâne '
                  'doar pe dispozitiv.',
            ),
            _PolicySection(
              title: 'Modificări și contact',
              body:
                  'Putem actualiza această politică atunci când se schimbă '
                  'aplicația sau cerințele legale. Versiunea curentă este '
                  'disponibilă permanent în aplicație. Pentru întrebări despre '
                  'confidențialitate, scrie la contact@didactiv.ro.',
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
          'Ultima actualizare: 23 septembrie 2026',
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

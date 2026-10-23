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
              title: 'Analiza este alegerea ta',
              body:
                  'Analiza utilizării este oprită implicit. Trimitem date despre jocuri '
                  'numai după ce alegi să o permiți. Refuzul nu schimbă jocurile sau '
                  'funcțiile disponibile. Jocurile și progresul funcționează local și '
                  'offline. Nu trimitem ulterior utilizarea dinaintea acordului.',
            ),
            _PolicySection(
              title: 'Ce informații trimitem',
              body:
                  'Pentru a îmbunătăți Slove, înregistrăm jocurile și rundele începute '
                  'sau încheiate, exercițiile afișate și rezolvate, precum și rezultatul '
                  'corect sau greșit. Înregistrăm motivul încheierii și exercițiul la '
                  'care te-ai oprit. Un exercițiu fără răspuns nu este considerat greșit. '
                  'O întrerupere poate fi dedusă la următoarea lansare, nu observată '
                  'exact în momentul închiderii.\n\n'
                  'În «Găsește greșeala», numărăm apăsările, greșelile găsite și '
                  'câte poziții greșite distincte au fost alese. Nu trimitem cuvintele '
                  'apăsate sau pozițiile lor. Pentru celelalte jocuri trimitem rezultatul '
                  'corect/greșit, nu răspunsul ales.\n\n'
                  'Datele includ identificatori tehnici de instalare, rundă, eveniment '
                  'și exercițiu, poziția exercițiului în rundă, versiunea conținutului '
                  'și data și ora. Nu colectăm nume, emailuri, texte introduse, '
                  'identificatori de publicitate sau locația. Textele exercițiilor, '
                  'scorurile complete și progresul de învățare rămân pe dispozitiv.',
            ),
            _PolicySection(
              title: 'Un identificator pentru această instalare',
              body:
                  'La prima activare generăm un identificator aleatoriu. El ne permite să '
                  'grupăm evenimentele aceleiași instalări, fără să cerem un cont sau '
                  'numele persoanei. Aceste date nu sunt complet anonime: pot fi '
                  'legate de instalare. Nu unim activitatea de pe dispozitive diferite. '
                  'Reinstalarea poate genera alt identificator. Dacă oprești și '
                  'pornești din nou analiza fără ștergere, refolosim același '
                  'identificator. Nu adăugăm activitatea din perioada în care '
                  'analiza a fost oprită. Rapoartele sunt accesibile doar '
                  'proprietarului aplicației, prin acces protejat.',
            ),
            _PolicySection(
              title: 'Cum oprești analiza',
              body:
                  'Deschide Setări și oprește «Analiză opțională». Colectarea viitoare '
                  'se oprește imediat, iar evenimentele care așteaptă pe dispozitiv '
                  'sunt eliminate. Pentru datele deja trimise, folosește și '
                  '«Șterge datele de pe server». Oprirea nu cere ștergerea. Poți '
                  'porni din nou analiza din Setări, confirmând alegerea, chiar și '
                  'offline.',
            ),
            _PolicySection(
              title: 'Cum ceri ștergerea',
              body:
                  'În Setări, «Șterge datele de pe server» oprește analiza și cere '
                  'eliminarea evenimentelor încă legate de această instalare. Este '
                  'nevoie de internet. Dacă cererea nu reușește, păstrăm pe dispozitiv '
                  'identificatorul și cheia necesară reîncercării. Mesajul de succes '
                  'apare numai după confirmare și salvarea alegerii.\n\n'
                  'După ce ceri ștergerea, reactivarea așteaptă confirmarea '
                  'serverului. Apoi, reactivarea creează un identificator nou. '
                  'Cererea privește această instalare, nu alte dispozitive.',
            ),
            _PolicySection(
              title: 'Cât timp păstrăm datele',
              body:
                  'Evenimentele legate de instalare expiră după 90 de zile. Ștergerea '
                  'rulează zilnic, deci poate adăuga până la o zi; o defecțiune poate '
                  'întârzia operațiunea. Folosim și momentul primirii pe server, '
                  'pentru ca o oră greșită pe dispozitiv să nu prelungească păstrarea. '
                  'Cheile instalărilor inactive sunt eliminate după 90 de zile fără '
                  'trimitere, după eliminarea evenimentelor lor.\n\n'
                  'După o cerere de ștergere, păstrăm timp de 90 de zile o înregistrare '
                  'tehnică de blocare: identificatorul instalării, amprenta cheii de '
                  'ștergere și data cererii. Astfel, trimiterile întârziate nu readuc '
                  'datele șterse. Cererile repetate nu prelungesc această perioadă. '
                  'Se aplică aceeași ștergere zilnică și aceleași posibile întârzieri. '
                  'După expirare nu putem recunoaște date noi falsificate folosind '
                  'un identificator vechi; trimiterile originale sunt deja prea vechi.',
            ),
            _PolicySection(
              title: 'Ce poate rămâne după ștergere',
              body:
                  'Putem păstra totaluri pe zile sau săptămâni, separate de '
                  'instalări: de exemplu, câte runde s-au încheiat sau câte exerciții '
                  'au fost rezolvate. Ele nu conțin identificatori de instalare, '
                  'rundă sau eveniment și nu mai pot fi retrase prin cererea acestei '
                  'instalări. Totalurile pot include jocul, versiunea, exercițiul, '
                  'poziția, rezultatul și motivul încheierii.\n\n'
                  'Păstrăm numai grupuri cu cel puțin cinci instalări distincte. '
                  'La numărătorile din «Găsește greșeala», fiecare numărătoare are '
                  'nevoie de cinci instalări care au contribuit la ea. Grupurile '
                  'rare sunt eliminate sau ascunse, nu afișate ca zero. '
                  'De aceea, totalurile pot fi incomplete.',
            ),
            _PolicySection(
              title: 'Dacă nu e internet sau alegerea nu se salvează',
              body:
                  'Jocurile rămân disponibile offline. Cu acordul activ, unele '
                  'evenimente pot aștepta local până revine conexiunea. Spațiul este '
                  'limitat, deci unele evenimente se pot pierde.\n\n'
                  'Dacă oprirea analizei nu poate fi salvată, colectarea este oprită '
                  'în sesiunea curentă, iar Setări arată un avertisment și o opțiune '
                  'de reîncercare. Reîncearcă înainte de a închide aplicația: la '
                  'redeschidere poate reveni setarea veche. Ștergerea de pe server '
                  'necesită în continuare confirmare.',
            ),
            _PolicySection(
              title: 'Găzduire și linkuri externe',
              body:
                  'Folosim infrastructura noastră pe Cloudflare și conexiuni HTTPS. '
                  'Cloudflare poate procesa metadatele obișnuite ale conexiunii, '
                  'inclusiv adresa IP. Nu folosim IP-ul ca identificator de analiză; '
                  'poate fi folosit pentru protecția împotriva abuzului. Nu folosim '
                  'datele pentru reclame și nu le vindem.\n\n'
                  'Aplicația poate descărca separat actualizări statice ale '
                  'exercițiilor. Linkurile DOOM se deschid în browser, unde site-ul '
                  'extern primește datele obișnuite ale accesării și aplică propria '
                  'politică de confidențialitate.',
            ),
            _PolicySection(
              title: 'Pentru părinți sau tutori',
              body:
                  'Slove poate fi folosită și de copii sub 13 ani. Această opțiune '
                  'este adresată părinților sau tutorilor, dar nu verifică vârsta '
                  'sau identitatea. Înainte de activarea colectării pentru copii, '
                  'trebuie verificate cerințele de acord parental, confidențialitate '
                  'și regulile magazinelor. Aceste verificări nu sunt înlocuite de '
                  'alegerea unui buton.',
            ),
            _PolicySection(
              title: 'Întrebări și contact',
              body:
                  'Ne poți scrie la contact@didactiv.ro. Politica publică este la '
                  'https://didactiv.ro/confidentialitate/slove/. Textul și '
                  'declarațiile magazinelor necesită revizuire înainte de '
                  'activarea colectorului și publicare; această pagină nu afirmă '
                  'că verificările au fost finalizate.',
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
          'Ultima actualizare: 23 octombrie 2026',
          style: LexioTextStyles.labelSmall.copyWith(
            color: LexioColors.textTertiary,
          ),
        ),
        const SizedBox(height: LexioSpacing.lg),
        Text(
          'Slove este dezvoltată de un creator independent. Aici explicăm '
          'ce informații folosim și cum îți poți schimba alegerea.',
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

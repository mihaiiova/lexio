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
              title: "Ce date colectăm",
              body:
                  "În mod implicit nu colectăm date despre utilizarea jocurilor. Numai după activarea explicită de către părinte sau tutore, trimitem către infrastructura noastră proprie Cloudflare un identificator aleatoriu de instalare, identificatori de eveniment și rundă, jocul, versiunea conținutului, identificatorul și poziția exercițiului, data și ora UTC. Înregistrăm începutul și sfârșitul rundelor, afișarea exercițiilor, primul rezultat corect/greșit și rezolvarea sau lăsarea nerezolvată a exercițiului. Sfârșitul poate indica finalizarea, ieșirea, repornirea sau o întrerupere dedusă la următoarea lansare; nu observăm închiderea forțată în timp real. Un exercițiu fără răspuns nu este considerat greșit. Nu trimitem textele exercițiilor, răspunsurile introduse sau alese, numele, emailul, identificatori publicitari ori locația. Progresul complet și scorurile rămân locale, dar rezultatele limitate corect/greșit descrise mai sus sunt transmise dacă analiza este activată.",
            ),
            _PolicySection(
              title: "Analiza opțională și alegerea ta",
              body:
                  "Scopul este asigurarea calității exercițiilor. Datele sunt pseudonime, nu complet anonime: evenimentele aceleiași instalări pot fi corelate. Identificatorul nu reprezintă o persoană și nu unește dispozitivele; reinstalarea poate genera alt identificator. Confirmarea părintelui sau tutorelui este autodeclarată, nu verificată și nu reprezintă o garanție de conformitate legală. Poți retrage acordul din Setări. Colectarea se oprește imediat și coada locală este golită. Dacă salvarea retragerii eșuează, aplicația avertizează să reîncerci înainte de închidere: o eroare totală de stocare poate păstra vechea setare după relansare. Ștergerea serverului necesită conexiune; până la confirmare, păstrăm local doar identificatorul și secretul necesar reîncercării, iar reactivarea este blocată. După confirmare și curățarea locală, reactivarea creează o instalare nouă. Nu recuperăm utilizarea dinaintea acordului. Coada offline este limitată și poate pierde evenimente.",
            ),
            _PolicySection(
              title: "Păstrare și ștergere",
              body:
                  "Evenimentele legate de instalare sunt eliminate după 90 de zile, printr-o operațiune zilnică (poate adăuga până la o zi; o defecțiune operațională poate întârzia ștergerea). Momentul primirii pe server limitează păstrarea chiar dacă ora dispozitivului este greșită. Credențialele instalărilor inactive sunt eliminate după 90 de zile fără trimitere și după eliminarea evenimentelor legate. Ștergerea din Setări elimină evenimentele încă legate de instalare. Pentru a bloca retransmiterile întârziate, serverul păstrează identificatorul, amprenta secretului de ștergere și datele tehnice ale revocării timp de 90 de zile de la prima cerere, apoi le elimină. Cererile repetate nu prelungesc perioada. Și aceste înregistrări sunt eliminate prin operațiunea zilnică, cu aceleași limite operaționale. Serverul respinge datele din viitor și pe cele vechi de cel puțin 90 de zile; precizia este normalizată la milisecunde. Nu există o zi suplimentară de păstrare a credențialelor. După această limită, retransmiterile originale sunt prea vechi, dar serverul nu poate recunoaște date noi falsificate cu o identitate expirată. Pot rămâne totaluri agregate pe zi/săptămână, fără identificatori de instalare, rundă sau eveniment. Fiecare grup păstrat necesită cel puțin cinci instalări distincte; grupurile rare sunt eliminate. Totalurile includ tipuri de evenimente, rezultate, motive de încheiere, starea de rezolvare și, unde pragul este îndeplinit, versiunea, exercițiul și poziția. Aceste totaluri deja separate de instalare nu pot fi retrase prin ștergerea ulterioară.",
            ),
            _PolicySection(
              title: "Găzduire și linkuri externe",
              body:
                  "Trimiterile folosesc HTTPS. Cloudflare poate procesa metadatele obișnuite ale conexiunii, inclusiv adresa IP, conform propriilor practici. Nu folosim IP-ul ca identitate de analiză; poate fi folosit tehnic pentru limitarea abuzului. Nu folosim datele pentru reclame și nu le vindem. Aplicația poate descărca separat actualizări statice ale exercițiilor. Linkurile DOOM se deschid în browser; site-ul extern primește metadatele obișnuite ale accesării și aplică propria politică.",
            ),
            _PolicySection(
              title: "Copii și contact",
              body:
                  "Slove poate fi folosită și de copii sub 13 ani. Analiza este implicit oprită, iar activarea este adresată părintelui sau tutorelui. Această interfață nu dovedește singură consimțământul legal. Pentru întrebări: contact@didactiv.ro.",
            ),
            _PolicySection(
              title: "Condiție de publicare",
              body:
                  "Acest text și declarațiile magazinelor sunt propuneri pentru revizuire. Publicarea colectorului și lansarea necesită verificare manuală juridică/de confidențialitate pentru copii, a politicilor magazinelor și a fluxurilor de acord, offline și ștergere. Nu afirmăm că aceste aprobări au avut loc. Versiunea aprobată trebuie publicată la URL-ul canonic și în aplicație înainte de lansare.",
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

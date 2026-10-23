# Politica de confidențialitate Slove

**Ultima actualizare:** 23 octombrie 2026

URL canonic: https://didactiv.ro/confidentialitate/slove/

Slove poate fi folosită de persoane de orice vârstă. Nu necesită cont, nu afișează reclame și nu folosește identificatori de publicitate. Jocurile funcționează local și offline. Analiza opțională este dezactivată implicit; refuzul nu limitează jocul.

## Ce date colectăm

În mod implicit nu colectăm date despre utilizarea jocurilor. Numai după activarea explicită de către părinte sau tutore, trimitem către infrastructura noastră proprie Cloudflare un identificator aleatoriu de instalare, identificatori de eveniment și rundă, jocul, versiunea conținutului, identificatorul și poziția exercițiului, data și ora UTC. Înregistrăm începutul și sfârșitul rundelor, afișarea exercițiilor, primul rezultat corect/greșit și rezolvarea sau lăsarea nerezolvată a exercițiului. Sfârșitul poate indica finalizarea, ieșirea, repornirea sau o întrerupere dedusă la următoarea lansare; nu observăm închiderea forțată în timp real. Un exercițiu fără răspuns nu este considerat greșit.

Nu trimitem textele exercițiilor, răspunsurile introduse sau alese, numele, emailul, identificatori publicitari ori locația. Progresul complet și scorurile rămân locale, dar rezultatele limitate corect/greșit descrise mai sus sunt transmise dacă analiza este activată.

## Analiza opțională și alegerea ta

Scopul este asigurarea calității exercițiilor. Datele sunt pseudonime, nu complet anonime: evenimentele aceleiași instalări pot fi corelate. Identificatorul nu reprezintă o persoană și nu unește dispozitivele; reinstalarea poate genera alt identificator. Confirmarea părintelui sau tutorelui este autodeclarată, nu verificată și nu reprezintă o garanție de conformitate legală.

Poți retrage acordul din Setări. Colectarea se oprește imediat și coada locală este golită. Dacă salvarea retragerii eșuează, aplicația avertizează să reîncerci înainte de închidere: o eroare totală de stocare poate păstra vechea setare după relansare. Ștergerea serverului necesită conexiune; până la confirmare, păstrăm local doar identificatorul și secretul necesar reîncercării, iar reactivarea este blocată. După confirmare și curățarea locală, reactivarea creează o instalare nouă. Nu recuperăm utilizarea dinaintea acordului. Coada offline este limitată și poate pierde evenimente.

## Păstrare și ștergere

Evenimentele legate de instalare sunt eliminate după 90 de zile, printr-o operațiune zilnică (poate adăuga până la o zi; o defecțiune operațională poate întârzia ștergerea). Momentul primirii pe server limitează păstrarea chiar dacă ora dispozitivului este greșită. Credențialele instalărilor inactive sunt eliminate după 90 de zile fără trimitere și după eliminarea evenimentelor legate.

Ștergerea din Setări elimină evenimentele încă legate de instalare. Pentru a bloca retransmiterile întârziate, serverul păstrează identificatorul, amprenta secretului de ștergere și datele tehnice ale revocării timp de 90 de zile de la prima cerere, apoi le elimină. Cererile repetate nu prelungesc perioada. Și aceste înregistrări sunt eliminate prin operațiunea zilnică, cu aceleași limite operaționale. Serverul respinge datele din viitor și pe cele vechi de cel puțin 90 de zile; precizia este normalizată la milisecunde. Nu există o zi suplimentară de păstrare a credențialelor. După această limită, retransmiterile originale sunt prea vechi, dar serverul nu poate recunoaște date noi falsificate cu o identitate expirată.

Pot rămâne totaluri agregate pe zi/săptămână, fără identificatori de instalare, rundă sau eveniment. Fiecare grup păstrat necesită cel puțin cinci instalări distincte; grupurile rare sunt eliminate. Totalurile includ tipuri de evenimente, rezultate, motive de încheiere, starea de rezolvare și, unde pragul este îndeplinit, versiunea, exercițiul și poziția. Aceste totaluri deja separate de instalare nu pot fi retrase prin ștergerea ulterioară.

## Găzduire și linkuri externe

Trimiterile folosesc HTTPS. Cloudflare poate procesa metadatele obișnuite ale conexiunii, inclusiv adresa IP, conform propriilor practici. Nu folosim IP-ul ca identitate de analiză; poate fi folosit tehnic pentru limitarea abuzului. Nu folosim datele pentru reclame și nu le vindem. Aplicația poate descărca separat actualizări statice ale exercițiilor.

Linkurile DOOM se deschid în browser; site-ul extern primește metadatele obișnuite ale accesării și aplică propria politică.

## Copii și contact

Slove poate fi folosită și de copii sub 13 ani. Analiza este implicit oprită, iar activarea este adresată părintelui sau tutorelui. Această interfață nu dovedește singură consimțământul legal. Pentru întrebări: contact@didactiv.ro.

## Condiție de publicare

Acest text și declarațiile magazinelor sunt propuneri pentru revizuire. Publicarea colectorului și lansarea necesită verificare manuală juridică/de confidențialitate pentru copii, a politicilor magazinelor și a fluxurilor de acord, offline și ștergere. Nu afirmăm că aceste aprobări au avut loc. Versiunea aprobată trebuie publicată la URL-ul canonic și în aplicație înainte de lansare.

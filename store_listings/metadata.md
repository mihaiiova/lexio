# Slove — Store Listing Metadata

## Product Identity

| Field | Value |
|---|---|
| Product name | Slove |
| Tagline | Joacă-te cu limba română. |
| Bundle ID (Android) | `com.mihaiiova.lexio` |
| Bundle ID (iOS) | `com.mihaiiova.lexio` |
| Version | 1.0.0 |
| Languages | Română (limba principală) |
| Primary locale | ro-RO |
| Primary brand color | `#4588E0` (albastru) |
| Font | NoticiaText |

## URLs

| Field | URL |
|---|---|
| Website | Public Slove URL to be configured before store submission |
| Privacy policy | https://didactiv.ro/confidentialitate/slove/ |

## Categories

| Store | Primary | Secondary |
|---|---|---|
| App Store | Education | Word / Trivia |
| Google Play | Educational | Word |

## Age Rating

| Criteria | Value |
|---|---|
| Target audience | 12+ |
| User-generated content | Nu |
| In-app purchases | Nu |
| Advertising | Nu |
| Account required | Nu |
| Data collection | Opțional — analiză pseudonimă dezactivată implicit; utilizarea și progresul rămân locale |
| Unrestricted web access | Nu (doar linkuri DOOM) |
| Gambling / simulated gambling | Nu |
| Alcohol / tobacco / drug references | Nu |
| Profanity / crude humour | Nu |
| Sexual / nudity content | Nu |
| Violence / realistic violence | Nu |
| Mature / suggestive themes | Nu |
| Health / fitness data | Nu |
| Location data | Nu |
| User data transmitted | Opțional — doar dacă analiza pseudonimă este activată, semnale limitate (identificator aleatoriu de instalare, rundă, joc, versiune, exercițiu/poziție, dată/oră, afișare, corect/greșit, rezolvare și motiv de încheiere) |
| Encryption | Analiza opțională și linkurile DOOM folosesc HTTPS |
| Children under 13 | Aplicația poate fi folosită de copii sub 13 ani |

## App Privacy (App Store)

- **Data Linked to You**: Requires manual App Privacy classification; a persistent installation identifier is pseudonymous even without accounts
- **Data Used to Track You**: None
- **Optional collection (classification requires review)**: Optional pseudonymous installation analytics — installation/event/session IDs, game, revision, exercise ID/index, UTC time, shown/answered/resolved, outcome and end reason (only after opt-in; off by default; no raw content or answers)

## Data Safety (Google Play)

- **Data collected**: Optional pseudonymous installation analytics (opt-in, off by default)
- **Data shared**: None
- **Data encrypted in transit**: HTTPS for the optional analytics endpoint and DOOM links
- **Data can be deleted**: Yes — from in-app Setări, the installation's linked records are deleted
- **Data safety label**: Optional pseudonymous installation analytics, user can delete

## Export Compliance

- Encryption: Analiza opțională și linkurile DOOM folosesc HTTPS.
- ITAR / EAR: Nu se aplică — aplicație educațională fără tehnologie de export-controlat.

## Contact

| Field | Value |
|---|---|
| Developer name | Creator independent |
| Support email | Must be supplied directly in each store listing |
| Marketing URL | Public Slove URL to be configured before store submission |

## App Review Notes (pentru Apple)

Slove este o aplicație educațională cu patru jocuri de limbă română.
Nu necesită cont sau autentificare. Jocurile funcționează offline.

Exercițiile și progresul complet sunt stocate local pe dispozitiv. Analiza
opțională, implicit oprită, transmite doar după activarea de către tutore
evenimentele pseudonime de instalare și rezultatele limitate descrise mai sus.

Linkurile externe se deschid doar în browserul sistemului și trimit către
Dicționarul Ortografic, Ortoepic și Morfologic al Limbii Române (DOOM) —
o resursă academică publică.

Aplicația este complet funcțională fără conexiune la internet.

## Screenshot Specifications

| Store | Device | Required sizes |
|---|---|---|
| App Store | iPhone Dynamic Island (medium display) | 1179 × 2556 px |
| App Store | iPhone 6.7" | 1290 × 2796 px |
| App Store | iPhone 6.5" | 1242 × 2688 px (optionally 1284 × 2778) |
| App Store | iPhone 5.5" | 1242 × 2208 px |
| App Store | iPad 12.9" | 2048 × 2732 px |
| App Store | iPad 11" | 1668 × 2388 px |
| Google Play | Phone | 1320 × 2640 px; minimum 320 px, maximum 3840 px, 2:1 to 1:2 ratio |
| Google Play | Tablet 7" | Same as phone |
| Google Play | Tablet 10" | Same as phone |
| Google Play | Feature graphic | 1024 × 500 px |
| Google Play | Promo graphic | 180 × 120 px (optional) |

### Screenshot Content Plan (6 screenshots per store)

1. **Ecran principal**: Cele patru jocuri pe fundal alb, curat
2. **Corect sau greșit?**: O propoziție cu butoanele Corect/Greșit și explicația vizibilă
3. **Ce înseamnă?**: Un cuvânt cu opțiunile multiple-choice și răspunsul corect evidențiat
4. **Vorba vine**: O expresie idiomatică cu opțiunile și sensul corect
5. **Găsește greșeala**: Un text cu greșeli găsite evidențiate și cronometrul
6. **Sumar/Rezultat**: Ecranul de final cu scorul și statistica (demonstrând progresul)

### Files prepared

The complete upload set is in [`../store_assets/`](../store_assets/README.md),
including six screenshots per device set, the required App Store Dynamic
Island medium iPhone and 13-inch iPad sizes, Google Play phone and tablet sets,
the 1024 × 500 feature graphic, and the approved store icons. Generate it again with:

```bash
python3 scripts/prepare_store_assets.py
```

## Revizuire obligatorie înainte de lansare (#60)

Datele legate de instalare sunt pseudonime, nu complet anonime. Evenimentele sunt păstrate 90 de zile, apoi eliminate prin operațiunea zilnică (până la o zi suplimentară; monitorizare obligatorie). Credențialele inactive expiră după 90 de zile fără trimitere, fără evenimente rămase. Ștergerea elimină datele încă legate; o înregistrare minimă de revocare expiră la 90 de zile de la prima cerere, fără prelungire la repetare, și este eliminată prin aceeași operațiune zilnică (defecțiunile pot întârzia ștergerea). Serverul respinge datele din viitor și pe cele vechi de cel puțin 90 de zile; nu există o excepție suplimentară de păstrare a credențialelor. Totalurile deja separate de instalare, cu minimum cinci instalări distincte per grup, nu pot fi retrase ulterior. Detalii și limite: [politica de confidențialitate](privacy_policy.md).

Acestea sunt texte propuse, nu declarații deja aprobate sau modificate în console. Confirmarea tutorelui este autodeclarată. Sunt obligatorii aprobarea manuală juridică/de confidențialitate pentru copii și a politicilor magazinelor, clasificarea exactă App Privacy/Data Safety, publicarea politicii canonice și testele manuale acord/offline/ștergere. Nicio aprobare manuală nu este afirmată aici.

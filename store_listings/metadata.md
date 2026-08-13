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
| Privacy policy | https://mihaiiova.github.io/lexio/ |

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
| Data collection | Da — interacțiuni cu aplicația și identificator al instalării pentru analiză |
| Unrestricted web access | Nu (doar linkuri DOOM) |
| Gambling / simulated gambling | Nu |
| Alcohol / tobacco / drug references | Nu |
| Profanity / crude humour | Nu |
| Sexual / nudity content | Nu |
| Violence / realistic violence | Nu |
| Mature / suggestive themes | Nu |
| Health / fitness data | Nu |
| Location data | Nu |
| User data transmitted | Evenimente `game_opened`, `game_completed` (scor, durată) și `game_abandoned`, identificatorul jocului și date tehnice Firebase |
| Encryption | Da, în tranzit către Firebase |
| Children under 13 | Nu este destinat copiilor sub 13 ani |

## App Privacy (App Store)

- **Data Linked to You**: No data linked to an account or known identity
- **Data Used to Track You**: No data collected
- **Data Not Linked to You**: Product interaction, device identifier, diagnostics and technical app/device data

## Data Safety (Google Play)

- **Data collected**: App activity, device or other identifiers, diagnostics and technical app/device data
- **Data shared**: Processed by Google Firebase Analytics for app analytics
- **Data encrypted in transit**: Yes
- **Data can be deleted**: N/A (no user accounts)
- **Data safety label**: App activity, device or other identifiers, diagnostics, and technical app/device data are collected for analytics

## Export Compliance

- Encryption: Se folosește HTTPS pentru Firebase Analytics și linkurile DOOM.
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

Toate exercițiile și progresul sunt stocate local pe dispozitiv. Firebase
Analytics primește evenimentele `game_opened`, `game_completed` (scor și durată)
și `game_abandoned`, identificatorul jocului și datele tehnice descrise în
politica de confidențialitate.

Linkurile externe se deschid doar în browserul sistemului și trimit către
Dicționarul Ortografic, Ortoepic și Morfologic al Limbii Române (DOOM) —
o resursă academică publică.

Aplicația este complet funcțională fără conexiune la internet.

## Screenshot Specifications

| Store | Device | Required sizes |
|---|---|---|
| App Store | iPhone 6.7" | 1290 × 2796 px |
| App Store | iPhone 6.5" | 1242 × 2688 px (optionally 1284 × 2778) |
| App Store | iPhone 5.5" | 1242 × 2208 px |
| App Store | iPad 12.9" | 2048 × 2732 px |
| App Store | iPad 11" | 1668 × 2388 px |
| Google Play | Phone | Minimum 320 px, maximum 3840 px, 2:1 to 1:2 ratio |
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

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
| Data collection | Nu — utilizarea și progresul rămân locale |
| Unrestricted web access | Nu (doar linkuri DOOM) |
| Gambling / simulated gambling | Nu |
| Alcohol / tobacco / drug references | Nu |
| Profanity / crude humour | Nu |
| Sexual / nudity content | Nu |
| Violence / realistic violence | Nu |
| Mature / suggestive themes | Nu |
| Health / fitness data | Nu |
| Location data | Nu |
| User data transmitted | Nimic — aplicația nu transmite date de utilizare sau identificatori |
| Encryption | Nu se aplică datelor de utilizare; linkurile DOOM folosesc HTTPS |
| Children under 13 | Aplicația poate fi folosită de copii sub 13 ani |

## App Privacy (App Store)

- **Data Linked to You**: None
- **Data Used to Track You**: None
- **Data Not Linked to You**: None

## Data Safety (Google Play)

- **Data collected**: None
- **Data shared**: None
- **Data encrypted in transit**: Not applicable to app data
- **Data can be deleted**: N/A (no user accounts)
- **Data safety label**: No data collected

## Export Compliance

- Encryption: Linkurile DOOM folosesc HTTPS; aplicația nu transmite date de utilizare.
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

Toate exercițiile, rezultatele și progresul sunt stocate local pe dispozitiv.
Aplicația nu transmite date de utilizare sau identificatori.

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

### Files prepared

The complete upload set is in [`../store_assets/`](../store_assets/README.md),
including six screenshots per platform, App Store iPhone and iPad sizes,
Google Play phone and tablet sets, the 1024 × 500 feature graphic, and the
approved store icons. Generate it again with:

```bash
python3 scripts/prepare_store_assets.py
```

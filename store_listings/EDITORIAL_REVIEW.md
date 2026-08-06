# Editorial Review Checklist

## Normative Sources
- **DOOM3** — Dicționarul Ortografic, Ortoepic și Morfologic al Limbii Române, ediția a III-a (2024)
- **dexonline.ro** — sursă publică de referință pentru definiții și forme flexionare
- **Gramatica Academiei (GALR)** — pentru reguli gramaticale normative

## Review Status Legend
- `✅ reviewed` — verificat și validat
- `⚠️ needs_attention` — necesită verificare suplimentară
- `❌ error` — conține o eroare confirmată
- `⏳ pending` — nerevizuit

---

## Per-File Review Checklist

### grammar_exercises.json (423 exerciții)

| Check | Status |
|---|---|
| Fiecare propoziție `isCorrect=true` este într-adevăr corectă gramatical | ⏳ |
| Fiecare propoziție `isCorrect=false` conține o greșeală clară | ⏳ |
| `correctSentence` repară TOATE greșelile și NUMAI greșelile | ⏳ |
| `explanation` explică corect greșeala, nu conține informații false | ⏳ |
| `explanation` nu prezintă preferințe stilistice ca erori categorice | ⏳ |
| `difficulty` (1-3) este consistent: 1=ușor/flagrant, 2=mediu, 3=subtil/avansat | ⏳ |
| `category` și `topic` se potrivesc cu conținutul | ⏳ |
| `tags` sunt coerente cu `category` | ⏳ |
| `pairId` corespunde unui index valid din `common_error_pairs.json` | ⏳ |
| `doomWord` și `doomDefinition` se potrivesc | ⏳ |
| **Bug fixat:** w116 — explicația se referea la „foarfece/foarfeci” în loc de articolul de gen | ✅ |

**Progres:** 1/423 ✅ | 0/423 ⚠️ | 0/423 ❌ | 422/423 ⏳

### vocabulary_exercises.json (100 exerciții)

| Check | Status |
|---|---|
| `word` este un cuvânt real din limba română | ⏳ |
| `partOfSpeech` este corect (substantiv, verb, adjectiv, adverb etc.) | ⏳ |
| `sentence` folosește corect cuvântul în context | ⏳ |
| `options` conține 3 variante (design intenționat, nu 4) — verificat structural | ✅ |
| `correctOptionIndex` (0-2) indică răspunsul corect | ⏳ |
| `definition` este definiția corectă conform dexonline | ⏳ |
| `synonyms` sunt sinonime reale | ⏳ |
| `explanation` completează corect definiția | ⏳ |
| `category` se potrivește cu sensul | ⏳ |

**Progres:** 1/100 ✅ | 0/100 ⚠️ | 0/100 ❌ | 99/100 ⏳

### idiom_exercises.json (60 exerciții)

| Check | Status |
|---|---|
| `expression` este o expresie idiomatică reală | ⏳ |
| `example` folosește corect expresia în context | ⏳ |
| `options` conține 3 variante (design intenționat) — verificat structural | ✅ |
| `correctOptionIndex` (0-2) indică sensul corect | ⏳ |
| `meaning` explică corect sensul expresiei | ⏳ |
| `category` se potrivește | ⏳ |
| Fără confuzie între sensul literal și cel figurat | ⏳ |

**Progres:** 1/60 ✅ | 0/60 ⚠️ | 0/60 ❌ | 59/60 ⏳

### spot_texts.json (60 texte, 240 greșeli)

| Check | Status |
|---|---|
| `title` descrie corect conținutul textului | ⏳ |
| `content` este un text coerent în limba română | ⏳ |
| Fiecare `mistake.token` este o greșeală reală | ⏳ |
| Fiecare `mistake.replacement` este corectarea corectă | ⏳ |
| `mistake.explanation` explică corect natura greșelii | ⏳ |
| `commonErrorPairIndex` trimite la un index valid | ⏳ |
| Fiecare text are exact 3-4 greșeli | ✅ |
| **Bug:** text_023 lipsește din secvență (salt de la text_022 la text_024) — doar numbering gap | ⚠️ |

**Progres:** 1/60 ✅ | 1/60 ⚠️ | 0/60 ❌ | 58/60 ⏳

### common_error_pairs.json (210 perechi)

| Check | Status |
|---|---|
| `corect` este forma corectă conform DOOM | ⏳ |
| `incorect` este o greșeală frecventă reală | ⏳ |
| `explanation` explică regula | ⏳ |
| `severity` reflectă gravitatea greșelii | ⏳ |

### hyphenation_pairs.json (26 perechi)

| Check | Status |
|---|---|
| `hyphenated` respectă regulile de despărțire la capăt de rând | ⏳ |
| `unhyphenated` funcționează valid | ⏳ |
| `unhyphenatedIsValid` este corect setat | ⏳ |

---

## Open Issues

| # | File | Item | Issue | Severity |
|---|---|---|---|---|
| 1 | grammar_exercises.json | w116 | Explicația a fost reparată (de la „foarfece/foarfeci” la articol de gen) | ✅ Fixed |
| 2 | spot_texts.json | text_023 | Lipsește din secvență — numbering gap, fără impact funcțional | Low |
| 3 | common_error_pairs.json | p121 | `foarfeci`/`foarfece` — de verificat care e forma corectă conform DOOM3 | Medium |
| 4 | all files | — | Review-ul editorial complet necesită un vorbitor nativ calificat | High |

## Validation Script

```bash
# Rulează validarea structurală automată a conținutului
python3 scripts/validate_content.py
```

# Grammar Exercises Dataset

The grammar dataset powers the "Corect sau greșit?" game and is the foundation
for future grammar and vocabulary games.

## Quick start

1. Edit `lib/content/grammar_exercises.json`
2. Run `flutter analyze` to verify the JSON parses correctly
3. Run `flutter test` to verify game logic works with new exercises

## JSON Schema

Each exercise is a JSON object with the following fields:

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `string` | yes | Unique identifier (e.g. `"w0"`, `"g3"`, `"w0c"`) |
| `sentence` | `string` | yes | The sentence shown to the player (Romanian) |
| `isCorrect` | `boolean` | yes | `true` = grammatically correct, `false` = contains a mistake |
| `explanation` | `string` | yes | Short explanation shown after answering (1-2 sentences, Romanian) |
| `category` | `string` | yes | Broad category (see Categories below) |
| `topic` | `string` | yes | Specific grammatical topic (see Topics below) |
| `difficulty` | `integer` | yes | 1 (common mistake), 2 (moderate), 3 (advanced) |
| `tags` | `string[]` | yes | Search/filter tags (see Tags below) |
| `pairId` | `string` | yes | Groups correct/incorrect versions of the same sentence |
| `correctSentence` | `string?` | — | The corrected version; `null` when `isCorrect: true` |

## Pairing system

Every exercise has a `pairId`. Exercises sharing the same `pairId` are
alternative versions of the same sentence:

- One with `isCorrect: false` — the sentence contains a mistake
- One with `isCorrect: true` — the corrected sentence

Both versions exist in the dataset, but the game's selection algorithm
guarantees they never appear together in the same session.

### Creating a new pair

Add both an incorrect and correct version:

```json
{
  "id": "w999",
  "sentence": "El greșește mereu aici.",
  "isCorrect": false,
  "explanation": "Forma corectă este «greșește», de la verbul «a greși».",
  "category": "ortografie",
  "topic": "formă corectă",
  "difficulty": 1,
  "tags": ["ortografie", "greșeală frecventă"],
  "pairId": "p999",
  "correctSentence": "El greșește mereu aici."
},
{
  "id": "w999c",
  "sentence": "El greșește mereu aici.",
  "isCorrect": true,
  "explanation": "Propoziția este corectă. «Greșește» este forma corectă a verbului «a greși».",
  "category": "ortografie",
  "topic": "formă corectă",
  "difficulty": 1,
  "tags": ["ortografie", "greșeală frecventă", "confirmare"],
  "pairId": "p999",
  "correctSentence": null
}
```

Use unique `pairId` values. The convention for w* exercises is `p0`–`p202`.
For g* exercises, use `g2000`+.

## Categories

| Category | When to use |
|---|---|
| `ortografie` | Spelling rules, diacritics, word forms |
| `morfologie` | Verb conjugation, pronouns, articles, numerals |
| `sintaxă` | Prepositions, sentence construction |
| `acord` | Agreement (number, gender, case), genitive/dative |
| `cratimă` | Hyphen rules (s-a, s-au, le-am etc.) |
| `plural` | Plural forms of nouns |
| `exprimare` | Pleonasms, usage (doar/decât, datorită/din cauza) |

## Topics

More specific than categories. Examples:

- `pluralul substantivelor` — noun plural forms
- `genitiv-dativ` — genitive/dative case
- `moduri verbale` — imperative, conjunctive, conditional
- `conjugare` — verb conjugation patterns
- `cratima` — hyphen usage rules
- `pleonasm` — redundant expressions
- `pronume` — pronoun forms
- `articulare` — definite article usage
- `vocativ` — vocative case
- `numerale` — numeral forms
- `adverb` — adverb/adjective invariability
- `prepoziții` — preposition usage
- `decât vs doar` — restrictive adverb usage
- `datorită vs din cauza` — positive vs negative cause
- `formă corectă` — general spelling (correct form)
- `utilizare corectă` — proper usage rules

## Tags

Flat keywords for filtering. Common tags:

- `greșeală frecventă` — common mistake
- `confirmare` — this is a correct-version exercise from a pair
- Grammar-specific: `plural`, `genitiv`, `dativ`, `verb`, `pronume`, `cratimă`, `imperativ`, `conjunctiv`, `condițional`, `conjugare`, `pleonasm`, `prepoziție`, `acord`, `vocativ`, `articulare`, `adverb`

## Difficulty

| Level | Description |
|---|---|
| 1 | Very common, beginner-level mistakes (diacritics, plurals) |
| 2 | Intermediate mistakes (hyphens, pronouns, imperatives) |
| 3 | Advanced rules (genitive/dative agreement, conditionals, subjonctives) |

## Selection algorithm

When generating a round of 15 exercises, the algorithm:

1. Loads all exercises from JSON and shuffles them
2. Picks exercises respecting these constraints:
   - **Pair separation**: never pick two exercises with the same `pairId`
   - **Balance**: aims for ~7 correct / ~8 incorrect (or vice versa)
   - **Topic diversity**: tracks used topics (future enhancement)
3. If after one pass fewer than 15 are selected, makes a second pass
   (loosening only the correctness balance constraint)
4. Shuffles the final selection before returning

## Content guidelines

- One rule per exercise — avoid sentences with multiple unrelated mistakes
- Incorrect sentences should look plausible, not obviously broken
- Correct sentences should contain words that users often doubt
- Explanations should be 1-2 sentences, written for normal users not linguists
- All visible content (sentence, explanation) is in Romanian
- All structural keys (id, category, topic, tags, etc.) are in English

## File location

`lib/content/grammar_exercises.json`

Loaded by `lib/games/grammar/grammar_content.dart` via `rootBundle.loadString()`.

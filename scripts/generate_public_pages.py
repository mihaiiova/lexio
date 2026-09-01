#!/usr/bin/env python3
"""Generate public Markdown pages listing all Slove game content.

Output directory: content_public/ (one page per game + an index).

The pages are meant for editorial review: a Romanian language expert can read
the full content and flag mistakes without running the app.

Regenerate after any content change:

    python3 scripts/generate_public_pages.py
"""

import json
from collections import OrderedDict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONTENT_DIR = ROOT / "lib" / "content"
DATA_DIR = ROOT / "data"
OUT_DIR = ROOT / "content_public"

ISSUES_URL = "https://github.com/mihaiiova/lexio/issues/new"
# Completează emailul de contact pentru feedback (fără cont GitHub).
CONTACT_EMAIL = ""


def load(name, base=CONTENT_DIR):
    with open(base / name, encoding="utf-8") as f:
        return json.load(f)


def esc(value):
    """Escape Markdown-sensitive characters so raw content never breaks the page."""
    s = str(value)
    for ch in ("\\", "`", "*", "_", "[", "]"):
        s = s.replace(ch, "\\" + ch)
    return s


def stars(difficulty):
    return "⭐" * int(difficulty)


def footer():
    if CONTACT_EMAIL:
        email_line = f"- **Fără cont GitHub:** trimite un email la **{CONTACT_EMAIL}**."
    else:
        email_line = (
            "- **Fără cont GitHub:** trimite un email la adresa de contact "
            "din pagina aplicației din magazin."
        )
    return f"""

---

## Semnalarea unei greșeli

Ai observat o greșeală sau o formulare nepotrivită? Ajută-ne să corectăm.

- **Cu cont GitHub:** deschide un [issue]({ISSUES_URL}) sau lasă un comentariu pe pagină.
{email_line}

*Pagina este generată automat din fișierele de conținut (`lib/content/`, `data/hyphenation_pairs.json`) prin `scripts/generate_public_pages.py`. Nu edita paginile manual — modifică JSON-ul și rulează din nou scriptul.*
"""


def gen_vocab(data):
    items = sorted(data, key=lambda x: (x.get("word", "").lower(), x.get("id", "")))
    lines = [
        "# Vocabular — „Ce înseamnă?\"",
        "",
        f"{len(items)} de cuvinte, cu definiții, exemple, variante de răspuns și sinonime.",
        "",
    ]
    for x in items:
        lines.append(f"### {esc(x['word'])} — *{esc(x.get('partOfSpeech', ''))}*")
        lines.append("")
        lines.append(
            f"**Categorie:** {esc(x.get('category', ''))} · "
            f"**Dificultate:** {stars(x.get('difficulty', 1))}"
        )
        lines.append("")
        lines.append(f"- **Definiție:** {esc(x.get('definition', ''))}")
        lines.append(f"- **Exemplu:** *{esc(x.get('example', ''))}*")
        synonyms = x.get("synonyms", [])
        if synonyms:
            lines.append(f"- **Sinonime:** {', '.join(esc(s) for s in synonyms)}")
        options = x.get("options", [])
        correct = x.get("correctOptionIndex", 0)
        lines.append("- **Variante de răspuns:**")
        for i, opt in enumerate(options):
            mark = " ✅ *(corect)*" if i == correct else ""
            lines.append(f"  {i + 1}. **{esc(opt)}**{mark}")
        lines.append(f"- **Explicație:** {esc(x.get('explanation', ''))}")
        lines.append("")
    return "\n".join(lines) + footer()


def gen_idioms(data):
    items = sorted(
        data, key=lambda x: (x.get("expression", "").lower(), x.get("id", ""))
    )
    lines = [
        "# Expresii — „Vorba vine\"",
        "",
        f"{len(items)} de expresii, cu sensul, un exemplu și variantele de răspuns.",
        "",
    ]
    for x in items:
        lines.append(f"### {esc(x['expression'])}")
        lines.append("")
        lines.append(
            f"**Categorie:** {esc(x.get('category', ''))} · "
            f"**Dificultate:** {stars(x.get('difficulty', 1))}"
        )
        lines.append("")
        lines.append(f"- **Sens:** {esc(x.get('meaning', ''))}")
        lines.append(f"- **Exemplu:** *{esc(x.get('example', ''))}*")
        highlighted = x.get("highlightedText")
        if highlighted and highlighted != x.get("expression"):
            lines.append(f"- **Text evidențiat:** *{esc(highlighted)}*")
        options = x.get("options", [])
        correct = x.get("correctOptionIndex", 0)
        lines.append("- **Variante de răspuns:**")
        for i, opt in enumerate(options):
            mark = " ✅ *(corect)*" if i == correct else ""
            lines.append(f"  {i + 1}. **{esc(opt)}**{mark}")
        lines.append("")
    return "\n".join(lines) + footer()


def gen_grammar(data, hyphenation):
    wrong = [x for x in data if x.get("isCorrect") is False]
    wrong.sort(key=lambda x: (x.get("category", "").lower(), x.get("id", "")))
    cats = OrderedDict()
    for x in wrong:
        cats.setdefault(x.get("category", "altele"), []).append(x)

    lines = [
        "# Gramatică — „Corect sau greșit?\"",
        "",
        f"{len(wrong)} perechi de propoziții (greșit → corect) "
        f"plus {len(hyphenation)} perechi de cratimă generate în joc.",
        "",
        "## Cuprins",
        "",
    ]
    for cat, items in cats.items():
        lines.append(f"- **{esc(cat)}** — {len(items)} perechi")
    lines.append(f"- **Perechi de cratimă (generate în joc)** — {len(hyphenation)} perechi")
    lines.append("")

    for cat, items in cats.items():
        lines.append(f"## {esc(cat)}")
        lines.append("")
        for x in items:
            lines.append(f"### {esc(x['id'])} · {esc(x.get('topic', ''))}")
            lines.append("")
            lines.append(f"- **Greșit:** {esc(x.get('sentence', ''))}")
            lines.append(f"- **Corect:** {esc(x.get('correctSentence', ''))}")
            lines.append(f"- **Explicație:** {esc(x.get('explanation', ''))}")
            doom_word = x.get("doomWord")
            doom_def = x.get("doomDefinition")
            if doom_word:
                lines.append(f"- **Cuvânt DOOM:** *{esc(doom_word)}* — {esc(doom_def)}")
            lines.append(
                f"- **Categorie:** {esc(x.get('category', ''))} · "
                f"**Topic:** {esc(x.get('topic', ''))} · "
                f"**Dificultate:** {stars(x.get('difficulty', 1))}"
            )
            tags = x.get("tags", [])
            if tags:
                lines.append(f"- **Etichete:** {', '.join(esc(t) for t in tags)}")
            lines.append("")

    lines.append("## Perechi de cratimă (generate în joc)")
    lines.append("")
    lines.append(
        "Perechi generate automat în jocul de gramatică (scrierea cu și fără cratimă)."
    )
    lines.append("")
    for h in hyphenation:
        lines.append(f"### {esc(h['id'])}")
        lines.append("")
        lines.append(
            f"- **Cu cratimă:** **{esc(h['hyphenatedForm'])}** "
            f"— {esc(h.get('hyphenatedExplanation', ''))}"
        )
        lines.append(f"- **Exemplu:** *{esc(h.get('hyphenatedExample', ''))}*")
        lines.append(f"- **Fără cratimă:** **{esc(h['unhyphenatedForm'])}**")
        if h.get("unhyphenatedIsValid"):
            lines.append(
                f"- **Exemplu fără cratimă:** *{esc(h.get('unhyphenatedExample', ''))}*"
            )
            lines.append(
                f"- **Explicație:** {esc(h.get('unhyphenatedExplanation', ''))}"
            )
        lines.append("")
    return "\n".join(lines) + footer()


def gen_spot(data):
    items = sorted(data, key=lambda t: (t.get("title", "").lower(), t.get("id", "")))
    lines = [
        "# Spot — „Găsește greșeala\"",
        "",
        f"{len(items)} texte, fiecare cu greșelile marcate (forma greșită → forma corectă).",
        "",
    ]
    for t in items:
        lines.append(f"## {esc(t.get('title', ''))}")
        lines.append("")
        lines.append(
            f"- **Tip:** {esc(t.get('type', ''))} · "
            f"**Dificultate:** {stars(t.get('difficulty', 1))} · "
            f"**ID:** `{t.get('id', '')}`"
        )
        lines.append("")
        lines.append(f"> {esc(t.get('content', ''))}")
        lines.append("")
        mistakes = t.get("mistakes", [])
        lines.append(f"**Greșeli ({len(mistakes)}):**")
        lines.append("")
        for i, m in enumerate(mistakes, 1):
            lines.append(
                f"{i}. **{esc(m.get('token', ''))}** → **{esc(m.get('replacement', ''))}** "
                f"— *{esc(m.get('explanation', ''))}*"
            )
            doom_word = m.get("doomWord")
            if doom_word:
                lines.append(
                    f"   - **Cuvânt DOOM:** *{esc(doom_word)}* — {esc(m.get('doomDefinition', ''))}"
                )
        lines.append("")
    return "\n".join(lines) + footer()


def gen_index(vocab, idioms, grammar, hyphenation, spot):
    wrong_grammar = sum(1 for x in grammar if x.get("isCorrect") is False)
    return f"""# Conținut Slove — verificare publică

Aceste pagini listează integral conținutul lingvistic din jocurile aplicației
**Slove**, pentru verificare editorială și semnalarea eventualelor greșeli.

| Joc | Pagină | Conținut |
|---|---|---|
| Vocabular — „Ce înseamnă?\" | [vocabular.md](vocabular.md) | {len(vocab)} de cuvinte |
| Expresii — „Vorba vine\" | [expresii.md](expresii.md) | {len(idioms)} de expresii |
| Gramatică — „Corect sau greșit?\" | [gramatica.md](gramatica.md) | {wrong_grammar} perechi greșit → corect + {len(hyphenation)} perechi de cratimă |
| Spot — „Găsește greșeala\" | [spot.md](spot.md) | {len(spot)} texte |

Paginile sunt ordonate alfabetic (vocabular, expresii, spot) sau pe categorii
(gramatică), pentru o parcurgere ușoară.
""" + footer()


def main():
    vocab = load("vocabulary_exercises.json")
    idioms = load("idiom_exercises.json")
    grammar = load("grammar_exercises.json")
    spot = load("spot_texts.json")
    hyphenation = load("hyphenation_pairs.json", base=DATA_DIR)

    OUT_DIR.mkdir(parents=True, exist_ok=True)

    pages = {
        "README.md": gen_index(vocab, idioms, grammar, hyphenation, spot),
        "vocabular.md": gen_vocab(vocab),
        "expresii.md": gen_idioms(idioms),
        "gramatica.md": gen_grammar(grammar, hyphenation),
        "spot.md": gen_spot(spot),
    }
    for name, content in pages.items():
        (OUT_DIR / name).write_text(content, encoding="utf-8")

    print("Generated public pages in", OUT_DIR.relative_to(ROOT))
    for name in pages:
        print(f"  - {name}")


if __name__ == "__main__":
    main()

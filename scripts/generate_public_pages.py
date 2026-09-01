#!/usr/bin/env python3
"""Generate public Markdown pages and a GitHub Pages site for Slove content.

Outputs:
- content_public/  — Markdown, one page per game + an index (for GitHub review)
- docs/content/    — HTML, one page per game + index + stylesheet (GitHub Pages)

Regenerate after any content change:

    python3 scripts/generate_public_pages.py
"""

import json
import unicodedata
from collections import OrderedDict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONTENT_DIR = ROOT / "lib" / "content"
DATA_DIR = ROOT / "data"
OUT_DIR = ROOT / "content_public"
SITE_DIR = ROOT / "docs" / "content"

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


def hesc(value):
    """Escape HTML-sensitive characters for safe inline rendering."""
    return (
        str(value)
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )


def hstars(difficulty):
    return "★" * int(difficulty)


def slug(value):
    """ASCII-safe anchor id from a category name (diacritics stripped)."""
    s = unicodedata.normalize("NFKD", str(value))
    s = "".join(c for c in s if not unicodedata.combining(c))
    s = "".join(c if c.isalnum() else "-" for c in s.lower())
    return s.strip("-") or "sectiune"


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


def feedback_html():
    if CONTACT_EMAIL:
        email_line = (
            "<li><strong>Fără cont GitHub:</strong> trimite un email la "
            f"<strong>{hesc(CONTACT_EMAIL)}</strong>.</li>"
        )
    else:
        email_line = (
            "<li><strong>Fără cont GitHub:</strong> trimite un email la adresa "
            "de contact din pagina aplicației din magazin.</li>"
        )
    return (
        '<div class="feedback">'
        "<h2>Semnalarea unei greșeli</h2>"
        "<p>Ai observat o greșeală sau o formulare nepotrivită? Ajută-ne să corectăm.</p>"
        "<ul>"
        "<li><strong>Cu cont GitHub:</strong> deschide un "
        f'<a href="{ISSUES_URL}" target="_blank" rel="noopener">issue</a> '
        "sau lasă un comentariu.</li>"
        f"{email_line}"
        "</ul>"
        '<p class="gen">Pagina este generată automat din fișierele de conținut '
        "(<code>lib/content/</code>, <code>data/hyphenation_pairs.json</code>) prin "
        "<code>scripts/generate_public_pages.py</code>. Nu edita paginile manual.</p>"
        "</div>"
    )


def html_page(title, subtitle, body, back=True):
    back_link = (
        '<a class="back" href="index.html">← Conținut Slove</a>' if back else ""
    )
    return f"""<!DOCTYPE html>
<html lang="ro">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{hesc(title)}</title>
<link rel="stylesheet" href="style.css">
</head>
<body>
<header>
  <div class="wrap">
    {back_link}
    <h1>{hesc(title)}</h1>
    <p>{hesc(subtitle)}</p>
  </div>
</header>
<main class="wrap">{body}</main>
<footer class="wrap">{feedback_html()}</footer>
</body>
</html>
"""


def vocab_html(data):
    items = sorted(data, key=lambda x: (x.get("word", "").lower(), x.get("id", "")))
    cards = []
    for x in items:
        correct = x.get("correctOptionIndex", 0)
        opts = []
        for i, opt in enumerate(x.get("options", [])):
            cls = "opt correct" if i == correct else "opt"
            mark = "✓ " if i == correct else ""
            opts.append(f'<li class="{cls}"><span>{hesc(mark + opt)}</span></li>')
        syns = x.get("synonyms", [])
        syn = (
            f'<p class="syns"><span>Sinonime:</span> {hesc(", ".join(syns))}</p>'
            if syns
            else ""
        )
        cards.append(
            '<section class="card">'
            f'<div class="card-head"><h2>{hesc(x["word"])} '
            f'<em>{hesc(x.get("partOfSpeech", ""))}</em></h2>'
            f'<span class="diff">{hstars(x.get("difficulty", 1))}</span></div>'
            f'<div class="meta">{hesc(x.get("category", ""))}</div>'
            f'<p class="def"><strong>Definiție:</strong> {hesc(x.get("definition", ""))}</p>'
            f'<p class="ex">{hesc(x.get("example", ""))}</p>'
            f"{syn}"
            "<h3>Variante de răspuns</h3>"
            f'<ul class="opts">{"".join(opts)}</ul>'
            f'<p class="expl"><strong>Explicație:</strong> {hesc(x.get("explanation", ""))}</p>'
            "</section>"
        )
    return "".join(cards)


def idioms_html(data):
    items = sorted(
        data, key=lambda x: (x.get("expression", "").lower(), x.get("id", ""))
    )
    cards = []
    for x in items:
        correct = x.get("correctOptionIndex", 0)
        opts = []
        for i, opt in enumerate(x.get("options", [])):
            cls = "opt correct" if i == correct else "opt"
            mark = "✓ " if i == correct else ""
            opts.append(f'<li class="{cls}"><span>{hesc(mark + opt)}</span></li>')
        cards.append(
            '<section class="card">'
            f'<div class="card-head"><h2>{hesc(x["expression"])}</h2>'
            f'<span class="diff">{hstars(x.get("difficulty", 1))}</span></div>'
            f'<div class="meta">{hesc(x.get("category", ""))}</div>'
            f'<p class="def"><strong>Sens:</strong> {hesc(x.get("meaning", ""))}</p>'
            f'<p class="ex">{hesc(x.get("example", ""))}</p>'
            "<h3>Variante de răspuns</h3>"
            f'<ul class="opts">{"".join(opts)}</ul>'
            "</section>"
        )
    return "".join(cards)


def grammar_html(data, hyphenation):
    wrong = [x for x in data if x.get("isCorrect") is False]
    wrong.sort(key=lambda x: (x.get("category", "").lower(), x.get("id", "")))
    cats = OrderedDict()
    for x in wrong:
        cats.setdefault(x.get("category", "altele"), []).append(x)

    toc = []
    for cat, items in cats.items():
        toc.append(
            f'<li><a href="#{slug(cat)}">{hesc(cat)}</a> '
            f'<span class="n">({len(items)})</span></li>'
        )
    toc.append(
        '<li><a href="#cratima-generate">Perechi de cratimă</a> '
        f'<span class="n">({len(hyphenation)})</span></li>'
    )

    body = ['<nav class="toc"><h3>Cuprins</h3><ul>' + "".join(toc) + "</ul></nav>"]
    for cat, items in cats.items():
        cards = []
        for x in items:
            doom = (
                '<div class="doom"><span>Cuvânt DOOM:</span> '
                f'{hesc(x["doomWord"])} — {hesc(x.get("doomDefinition", ""))}</div>'
                if x.get("doomWord")
                else ""
            )
            cards.append(
                '<section class="card">'
                f'<div class="card-head"><h3>{hesc(x["id"])} · {hesc(x.get("topic", ""))}</h3>'
                f'<span class="diff">{hstars(x.get("difficulty", 1))}</span></div>'
                f'<p class="wrong">{hesc(x.get("sentence", ""))}</p>'
                f'<p class="correct">{hesc(x.get("correctSentence", ""))}</p>'
                f'<p class="expl">{hesc(x.get("explanation", ""))}</p>'
                f"{doom}"
                f'<div class="meta">{hesc(x.get("category", ""))} · {hesc(x.get("topic", ""))}</div>'
                "</section>"
            )
        body.append(
            f'<section class="group" id="{slug(cat)}"><h2>{hesc(cat)}</h2>'
            + "".join(cards)
            + "</section>"
        )

    hcards = []
    for h in hyphenation:
        extra = ""
        if h.get("unhyphenatedIsValid"):
            extra = (
                f'<p class="ex">{hesc(h.get("unhyphenatedExample", ""))}</p>'
                f'<p class="expl">{hesc(h.get("unhyphenatedExplanation", ""))}</p>'
            )
        hcards.append(
            '<section class="card">'
            f'<div class="card-head"><h3>{hesc(h["id"])}</h3></div>'
            f'<p class="def"><strong>Cu cratimă:</strong> <strong>{hesc(h["hyphenatedForm"])}</strong>'
            f' — {hesc(h.get("hyphenatedExplanation", ""))}</p>'
            f'<p class="ex">{hesc(h.get("hyphenatedExample", ""))}</p>'
            f'<p class="def"><strong>Fără cratimă:</strong> <strong>{hesc(h["unhyphenatedForm"])}</strong></p>'
            f"{extra}"
            "</section>"
        )
    body.append(
        '<section class="group" id="cratima-generate"><h2>Perechi de cratimă (generate în joc)</h2>'
        + "".join(hcards)
        + "</section>"
    )
    return "".join(body)


def spot_html(data):
    items = sorted(data, key=lambda t: (t.get("title", "").lower(), t.get("id", "")))
    cards = []
    for t in items:
        mistakes = []
        for i, m in enumerate(t.get("mistakes", []), 1):
            doom = (
                '<div class="doom"><span>Cuvânt DOOM:</span> '
                f'{hesc(m["doomWord"])} — {hesc(m.get("doomDefinition", ""))}</div>'
                if m.get("doomWord")
                else ""
            )
            mistakes.append(
                f"<li>{i}. <span class=\"wrong\">{hesc(m.get('token', ''))}</span> → "
                f"<span class=\"correct\">{hesc(m.get('replacement', ''))}</span> — "
                f"{hesc(m.get('explanation', ''))}{doom}</li>"
            )
        cards.append(
            '<section class="card">'
            f'<div class="card-head"><h2>{hesc(t.get("title", ""))}</h2>'
            f'<span class="diff">{hstars(t.get("difficulty", 1))}</span></div>'
            f'<div class="meta">{hesc(t.get("type", ""))} · {hesc(t.get("id", ""))}</div>'
            f"<blockquote>{hesc(t.get('content', ''))}</blockquote>"
            f'<h3>Greșeli ({len(t.get("mistakes", []))})</h3>'
            f'<ol class="mistakes">{"".join(mistakes)}</ol>'
            "</section>"
        )
    return "".join(cards)


def index_html(vocab, idioms, grammar, hyphenation, spot):
    wrong = sum(1 for x in grammar if x.get("isCorrect") is False)
    games = [
        ("vocabular.html", "Vocabular", "„Ce înseamnă?”", f"{len(vocab)} cuvinte",
         "Cuvinte cu definiții, exemple, sinonime și variante de răspuns."),
        ("expresii.html", "Expresii", "„Vorba vine”", f"{len(idioms)} expresii",
         "Expresii românești cu sensul și un exemplu de folosire."),
        ("gramatica.html", "Gramatică", "„Corect sau greșit?”",
         f"{wrong} perechi + {len(hyphenation)} cratime",
         "Propoziții greșit → corect, grupate pe categorii."),
        ("spot.html", "Spot", "„Găsește greșeala”", f"{len(spot)} texte",
         "Texte integrale cu greșelile evidențiate."),
    ]
    grid = "".join(
        f'<a class="game" href="{href}"><h2>{hesc(name)}</h2>'
        f'<p class="sub">{hesc(sub)}</p><p class="count">{hesc(count)}</p>'
        f"<p>{hesc(desc)}</p></a>"
        for href, name, sub, count, desc in games
    )
    return (
        '<p class="lead">Aceste pagini listează integral conținutul lingvistic din '
        "jocurile aplicației Slove, pentru verificare editorială și semnalarea "
        "eventualelor greșeli.</p>"
        f'<div class="grid">{grid}</div>'
    )


def main():
    vocab = load("vocabulary_exercises.json")
    idioms = load("idiom_exercises.json")
    grammar = load("grammar_exercises.json")
    spot = load("spot_texts.json")
    hyphenation = load("hyphenation_pairs.json", base=DATA_DIR)

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    SITE_DIR.mkdir(parents=True, exist_ok=True)

    wrong_grammar = sum(1 for x in grammar if x.get("isCorrect") is False)

    md_pages = {
        "README.md": gen_index(vocab, idioms, grammar, hyphenation, spot),
        "vocabular.md": gen_vocab(vocab),
        "expresii.md": gen_idioms(idioms),
        "gramatica.md": gen_grammar(grammar, hyphenation),
        "spot.md": gen_spot(spot),
    }
    for name, content in md_pages.items():
        (OUT_DIR / name).write_text(content, encoding="utf-8")

    html_pages = {
        "index.html": html_page(
            "Conținut Slove",
            "Verificare publică a conținutului",
            index_html(vocab, idioms, grammar, hyphenation, spot),
            back=False,
        ),
        "vocabular.html": html_page(
            "Vocabular — „Ce înseamnă?”", f"{len(vocab)} de cuvinte", vocab_html(vocab)
        ),
        "expresii.html": html_page(
            "Expresii — „Vorba vine”", f"{len(idioms)} de expresii", idioms_html(idioms)
        ),
        "gramatica.html": html_page(
            "Gramatică — „Corect sau greșit?”",
            f"{wrong_grammar} perechi greșit → corect + {len(hyphenation)} perechi de cratimă",
            grammar_html(grammar, hyphenation),
        ),
        "spot.html": html_page(
            "Spot — „Găsește greșeala”", f"{len(spot)} texte", spot_html(spot)
        ),
    }
    for name, content in html_pages.items():
        (SITE_DIR / name).write_text(content, encoding="utf-8")

    print("Generated Markdown in", OUT_DIR.relative_to(ROOT))
    for name in md_pages:
        print(f"  - {name}")
    print("Generated HTML site in", SITE_DIR.relative_to(ROOT))
    for name in html_pages:
        print(f"  - {name}")


if __name__ == "__main__":
    main()

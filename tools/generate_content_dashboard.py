#!/usr/bin/env python3
"""Generate a self-contained HTML dashboard for all Slove exercise content."""

import json
from pathlib import Path

CONTENT_DIR = Path(__file__).parent.parent / "lib" / "content"
OUTPUT_FILE = Path(__file__).parent.parent / "tools" / "content_dashboard.html"

def load_json(name):
    with open(CONTENT_DIR / name, "r", encoding="utf-8") as f:
        return json.load(f)

def render_spot(data):
    rows = []
    for t in data:
        tid = t["id"]
        ttype = t.get("type", "")
        title = t.get("title", "")
        diff = t.get("difficulty", 1)
        content = t.get("content", "")
        diff_class = f"diff-{diff}"
        mistakes_html = ""
        for m in t.get("mistakes", []):
            token = m.get("token", "")
            repl = m.get("replacement", "")
            expl = m.get("explanation", "")
            doom = m.get("doomWord") or ""
            doom_def = m.get("doomDefinition") or ""
            doom_html = f'<div class="doom">{doom}: {doom_def}</div>' if doom else ""
            mistakes_html += f"""
                <div class="mistake">
                    <span class="err">{token}</span> → <span class="corr">{repl}</span>
                    <div class="expl">{expl}</div>
                    {doom_html}
                </div>"""
        rows.append(f"""
            <div class="card {diff_class}" id="spot-{tid}">
                <div class="card-header">
                    <span class="id">📝 {tid}</span>
                    <span class="type">{ttype}</span>
                    <span class="diff">⭐{diff}</span>
                </div>
                <div class="card-title">{title}</div>
                <div class="text-content">{content}</div>
                <div class="mistakes-list">{mistakes_html}</div>
            </div>""")
    return "\n".join(rows)

def render_grammar(data):
    rows = []
    for item in data:
        if item.get("isCorrect"):
            continue
        gid = item["id"]
        sentence = item.get("sentence", "")
        correct = item.get("correctSentence") or ""
        expl = item.get("explanation", "")
        cat = item.get("category", "")
        topic = item.get("topic", "")
        diff = item.get("difficulty", 1)
        diff_class = f"diff-{diff}"
        doom = item.get("doomWord") or ""
        doom_def = item.get("doomDefinition") or ""
        doom_html = f'<div class="doom">{doom}: {doom_def}</div>' if doom else ""
        rows.append(f"""
            <div class="card {diff_class}" id="grammar-{gid}">
                <div class="card-header">
                    <span class="id">✏️ {gid}</span>
                    <span class="type">{cat} · {topic}</span>
                    <span class="diff">⭐{diff}</span>
                </div>
                <div class="text-content err">{sentence}</div>
                <div class="text-content corr">{correct}</div>
                <div class="expl">{expl}</div>
                {doom_html}
            </div>""")
    return "\n".join(rows)

def render_idiom(data):
    rows = []
    for item in data:
        iid = item["id"]
        expr = item.get("expression", "")
        meaning = item.get("meaning", "")
        example = item.get("example", "")
        hl = item.get("highlightedText", "")
        cat = item.get("category", "")
        diff = item.get("difficulty", 1)
        diff_class = f"diff-{diff}"
        formatted_ex = example.replace(hl, f"<strong>{hl}</strong>") if hl else example
        rows.append(f"""
            <div class="card {diff_class}" id="idiom-{iid}">
                <div class="card-header">
                    <span class="id">💬 {iid}</span>
                    <span class="type">{cat}</span>
                    <span class="diff">⭐{diff}</span>
                </div>
                <div class="card-title">{expr}</div>
                <div class="expl meaning">{meaning}</div>
                <div class="text-content ex">{formatted_ex}</div>
            </div>""")
    return "\n".join(rows)

def render_vocab(data):
    rows = []
    for item in data:
        vid = item["id"]
        word = item.get("word", "")
        pos = item.get("partOfSpeech", "")
        definition = item.get("definition", "")
        example = item.get("example", "")
        cat = item.get("category", "")
        diff = item.get("difficulty", 1)
        diff_class = f"diff-{diff}"
        syns = ", ".join(item.get("synonyms", []))
        rows.append(f"""
            <div class="card {diff_class}" id="vocab-{vid}">
                <div class="card-header">
                    <span class="id">📖 {vid}</span>
                    <span class="type">{pos} · {cat}</span>
                    <span class="diff">⭐{diff}</span>
                </div>
                <div class="card-title">{word}</div>
                <div class="expl meaning">{definition}</div>
                <div class="text-content ex">{example}</div>
                <div class="syns">Sinonime: {syns}</div>
            </div>""")
    return "\n".join(rows)

def main():
    print("Loading content...")
    spot = load_json("spot_texts.json")
    grammar = load_json("grammar_exercises.json")
    idiom = load_json("idiom_exercises.json")
    vocab = load_json("vocabulary_exercises.json")

    print(f"  spot: {len(spot)} texts")
    print(f"  grammar: {len(grammar)} exercises ({len([g for g in grammar if not g.get('isCorrect')])} incorrect)")
    print(f"  idiom: {len(idiom)} idioms")
    print(f"  vocab: {len(vocab)} words")

    html = f"""<!DOCTYPE html>
<html lang="ro">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Slove — Dashboard Conținut</title>
<style>
* {{ margin:0; padding:0; box-sizing:border-box; }}
body {{ font-family: system-ui, -apple-system, sans-serif; background:#f5f5f7; color:#1d1d1f; }}
header {{ background:#fff; border-bottom:1px solid #e5e5ea; padding:16px 24px; position:sticky; top:0; z-index:10; }}
header h1 {{ font-size:18px; font-weight:700; }}
header .stats {{ font-size:12px; color:#86868b; margin-top:4px; }}
nav {{ display:flex; gap:4px; padding:8px 24px; background:#fff; border-bottom:1px solid #e5e5ea; position:sticky; top:65px; z-index:10; flex-wrap:wrap; }}
nav button {{ padding:8px 16px; border:none; border-radius:8px; cursor:pointer; font-size:13px; font-weight:500; background:transparent; color:#6e6e73; transition:all .15s; }}
nav button:hover {{ background:#f0f0f5; }}
nav button.active {{ background:#007aff; color:#fff; }}
.toolbar {{ display:flex; gap:8px; padding:12px 24px; align-items:center; flex-wrap:wrap; }}
.toolbar input {{ flex:1; min-width:200px; padding:8px 12px; border:1px solid #d1d1d6; border-radius:8px; font-size:13px; outline:none; }}
.toolbar input:focus {{ border-color:#007aff; box-shadow:0 0 0 3px rgba(0,122,255,.15); }}
.toolbar .count {{ font-size:12px; color:#86868b; white-space:nowrap; }}
select {{ padding:8px 12px; border:1px solid #d1d1d6; border-radius:8px; font-size:13px; outline:none; background:#fff; }}
.grid {{ display:grid; grid-template-columns:repeat(auto-fill,minmax(380px,1fr)); gap:24px; padding:24px 24px 48px; }}
.card {{ background:#fff; border-radius:12px; padding:16px; box-shadow:0 1px 3px rgba(0,0,0,.06); border:1px solid #f0f0f5; transition:box-shadow .15s; }}
.card:hover {{ box-shadow:0 4px 12px rgba(0,0,0,.08); }}
.card-header {{ display:flex; justify-content:space-between; align-items:center; margin-bottom:8px; gap:8px; flex-wrap:wrap; }}
.card-header .id {{ font-size:12px; font-weight:600; color:#007aff; }}
.card-header .type {{ font-size:11px; color:#86868b; background:#f5f5f7; padding:2px 8px; border-radius:4px; }}
.card-header .diff {{ font-size:11px; color:#86868b; }}
.card-title {{ font-size:15px; font-weight:600; margin-bottom:8px; }}
.text-content {{ font-size:14px; line-height:1.5; margin-bottom:8px; padding:8px 12px; background:#fafafa; border-radius:6px; }}
.text-content.err {{ background:#fff0f0; color:#c00; }}
.text-content.corr {{ background:#f0fff0; color:#060; }}
.text-content.ex {{ background:#f8f8ff; font-style:italic; }}
.mistakes-list {{ display:flex; flex-direction:column; gap:6px; margin-top:8px; }}
.mistake {{ font-size:13px; padding:6px 10px; background:#fff7e6; border-radius:6px; border-left:3px solid #ff9500; }}
.mistake .err {{ text-decoration:line-through; color:#c00; font-weight:600; }}
.mistake .corr {{ color:#060; font-weight:600; }}
.expl {{ font-size:12px; color:#6e6e73; margin-top:4px; line-height:1.4; }}
.expl.meaning {{ font-size:13px; color:#1d1d1f; font-weight:500; margin-bottom:4px; }}
.doom {{ font-size:10px; color:#86868b; margin-top:4px; font-family:monospace; background:#f0f0f5; padding:2px 6px; border-radius:4px; }}
.syns {{ font-size:11px; color:#86868b; margin-top:6px; }}
.diff-1 {{ border-left:3px solid #34c759; }}
.diff-2 {{ border-left:3px solid #ff9500; }}
.diff-3 {{ border-left:3px solid #ff3b30; }}
.hidden {{ display:none; }}
.no-results {{ grid-column:1/-1; text-align:center; padding:40px; color:#86868b; font-size:14px; }}
@media (max-width:500px) {{ .grid {{ grid-template-columns:1fr; }} }}
</style>
</head>
<body>
<header>
  <h1>Slove — Dashboard Conținut</h1>
  <div class="stats">Generat: <span id="gen-date"></span> &nbsp;|&nbsp; Texte: {len(spot)} &nbsp;|&nbsp; Gramatică: {len(grammar)} &nbsp;|&nbsp; Expresii: {len(idiom)} &nbsp;|&nbsp; Vocabular: {len(vocab)}</div>
</header>

<nav>
  <button class="active" data-tab="spot">📝 Găsește greșeala ({len(spot)})</button>
  <button data-tab="grammar">✏️ Gramatică ({len([g for g in grammar if not g.get('isCorrect')])})</button>
  <button data-tab="idiom">💬 Expresii ({len(idiom)})</button>
  <button data-tab="vocab">📖 Vocabular ({len(vocab)})</button>
  <button data-tab="all">🔍 Toate</button>
</nav>

<div class="toolbar">
  <input type="text" id="search" placeholder="Caută în tot conținutul...">
  <select id="diff-filter">
    <option value="all">Toate dificultățile</option>
    <option value="1">⭐ Ușor</option>
    <option value="2">⭐⭐ Mediu</option>
    <option value="3">⭐⭐⭐ Greu</option>
  </select>
  <span class="count" id="count"></span>
</div>

<div class="grid" id="grid">
  <div class="spot-panel">{render_spot(spot)}</div>
  <div class="grammar-panel">{render_grammar(grammar)}</div>
  <div class="idiom-panel">{render_idiom(idiom)}</div>
  <div class="vocab-panel">{render_vocab(vocab)}</div>
</div>

<script>
document.getElementById('gen-date').textContent = new Date().toISOString().slice(0, 19).replace('T',' ');

const tabs = document.querySelectorAll('nav button');
const search = document.getElementById('search');
const diffFilter = document.getElementById('diff-filter');
const count = document.getElementById('count');
const panels = {{
  spot: document.querySelector('.spot-panel'),
  grammar: document.querySelector('.grammar-panel'),
  idiom: document.querySelector('.idiom-panel'),
  vocab: document.querySelector('.vocab-panel'),
}};
let activeTab = 'spot';

function getCards(panel) {{ return panel ? panel.querySelectorAll('.card') : []; }}

function updateVisibility() {{
  const searchTerm = search.value.toLowerCase();
  const diffVal = diffFilter.value;
  let visible = 0;

  Object.entries(panels).forEach(([name, panel]) => {{
    if (!panel) return;
    const show = activeTab === 'all' || activeTab === name;
    panel.style.display = show ? '' : 'none';
    if (!show) return;

    getCards(panel).forEach(card => {{
      const text = card.textContent.toLowerCase();
      const hasDiff = diffVal === 'all' || card.classList.contains('diff-' + diffVal);
      const matches = text.includes(searchTerm);
      const v = matches && hasDiff;
      card.classList.toggle('hidden', !v);
      if (v) visible++;
    }});
  }});

  count.textContent = visible + ' rezultate';
}}

tabs.forEach(btn => {{
  btn.addEventListener('click', () => {{
    tabs.forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    activeTab = btn.dataset.tab;
    updateVisibility();
  }});
}});

search.addEventListener('input', updateVisibility);
diffFilter.addEventListener('change', updateVisibility);

updateVisibility();
setTimeout(() => count.textContent = document.querySelectorAll('#grid .card:not(.hidden)').length + ' rezultate', 100);
</script>
</body>
</html>"""

    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write(html)

    size_kb = OUTPUT_FILE.stat().st_size / 1024
    print(f"\nGenerated: {OUTPUT_FILE} ({size_kb:.0f} KB)")

if __name__ == "__main__":
    main()

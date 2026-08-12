#!/usr/bin/env python3
"""Deep editorial review — semantic consistency checks beyond structural validation."""

import json
import sys
from pathlib import Path
from collections import Counter

ROOT = Path(__file__).resolve().parent.parent

def load_json(path):
    with open(ROOT / path, encoding='utf-8') as f:
        return json.load(f)

issues = []

def issue(level, file, item_id, msg):
    issues.append((level, file, item_id, msg))

# --- Load reference data ---
common_error_pairs = load_json("data/common_error_pairs.json")
hyphenation_pairs = load_json("data/hyphenation_pairs.json")

# ============================================================
# GRAMMAR EXERCISES
# ============================================================
print("Deep review: grammar_exercises.json ...")
grammar = load_json("lib/content/grammar_exercises.json")

for ex in grammar:
    eid = ex.get('id', '?')

    # pairId: p-prefixed must point to valid common_error_pairs; g-prefixed are grammar-specific
    pid = ex.get('pairId')
    if pid:
        if pid.startswith('p'):
            try:
                idx = int(pid[1:])
                if idx < 0 or idx >= len(common_error_pairs):
                    issue('ERROR', 'grammar', eid, f"pairId '{pid}' out of range (0-{len(common_error_pairs)-1})")
            except ValueError:
                issue('ERROR', 'grammar', eid, f"pairId '{pid}' not parseable")
        elif not pid.startswith('g'):
            issue('WARN', 'grammar', eid, f"pairId '{pid}' has unknown prefix")

    # doomWord and doomDefinition consistency (case-insensitive, allow partial match)
    dw = ex.get('doomWord')
    dd = ex.get('doomDefinition', '')
    if dw and dd:
        dw_lower = dw.lower().strip()
        dd_lower = dd.lower()
        # Check if doomWord or its root appears in definition
        dw_root = dw_lower.rstrip('ul') if dw_lower.endswith('ul') else dw_lower
        if dw_lower not in dd_lower and dw_root not in dd_lower:
            issue('WARN', 'grammar', eid, f"doomWord '{dw}' not found in doomDefinition")

    # correctSentence should differ from sentence for incorrect exercises
    if not ex.get('isCorrect') and ex.get('correctSentence'):
        if ex['correctSentence'] == ex['sentence']:
            issue('ERROR', 'grammar', eid, "correctSentence equals sentence but isCorrect=false")
        # Check that the fix is minimal — the sentences should be mostly the same
        s = ex['sentence']
        cs = ex['correctSentence']
        if len(s) > 10 and len(cs) > 10:
            diff_chars = sum(1 for a, b in zip(s, cs) if a != b) + abs(len(s) - len(cs))
            if diff_chars > 40:
                issue('WARN', 'grammar', eid,
                      f"correctSentence differs by {diff_chars} chars from sentence — may fix more than the error")

    # Explanation should not be empty or too short
    expl = ex.get('explanation', '')
    if len(expl) < 10:
        issue('WARN', 'grammar', eid, f"explanation too short ({len(expl)} chars)")

    # isCorrect=true should have confirmatory explanation
    if ex.get('isCorrect'):
        if 'corect' not in expl.lower() and 'corectă' not in expl.lower():
            issue('WARN', 'grammar', eid, "isCorrect=true but explanation lacks 'corect'/'corectă'")
    else:
        if 'corect' not in expl.lower() and 'corectă' not in expl.lower() and 'greșit' not in expl.lower():
            issue('WARN', 'grammar', eid, "isCorrect=false but explanation lacks error indication")

    # Tags should match category
    cat = ex.get('category', '')
    tags = ex.get('tags', [])
    if tags and cat:
        if cat not in tags:
            issue('WARN', 'grammar', eid, f"category '{cat}' not in tags: {tags}")

    # Sentence should contain Romanian diacritics (ăâîșț) — skip proper nouns
    sentence = ex.get('sentence', '')
    if sentence and not any(c in sentence for c in 'ăâîșțĂÂÎȘȚ'):
        # Only warn if sentence has Latin chars that would need diacritics
        has_a = any(c in sentence for c in 'aAiIsStT')
        if has_a:
            issue('WARN', 'grammar', eid, 'sentence has no diacritics — verify')

print(f"  {len(grammar)} exercises checked")

# ============================================================
# VOCABULARY EXERCISES
# ============================================================
print("Deep review: vocabulary_exercises.json ...")
vocab = load_json("lib/content/vocabulary_exercises.json")
seen_words = Counter()

for ex in vocab:
    eid = ex.get('id', '?')
    word = ex.get('word', '').lower()
    seen_words[word] += 1

    # Synonyms should not contain the word itself
    synonyms = ex.get('synonyms', [])
    for s in synonyms:
        if s.lower() == word:
            issue('WARN', 'vocab', eid, f"synonym '{s}' equals the word itself")

    # Options should not duplicate
    opts = ex.get('options', [])
    opt_lower = [o.lower().strip() for o in opts]
    if len(opt_lower) != len(set(opt_lower)):
        issue('ERROR', 'vocab', eid, f"duplicate options: {opts}")



    # Example should contain the word or a conjugated/declined form
    example = ex.get('example', '').lower()
    if example and word:
        word_stem = word.lower().replace('a ', '').replace('se ', '').rstrip('aeiouăâî')[:6]
        if word.lower() not in example and word_stem not in example:
            issue('WARN', 'vocab', eid, f"word '{word}' stem not found in example")

    # Part of speech validation
    pos = ex.get('partOfSpeech', '')
    valid_pos = {'substantiv', 'verb', 'adjectiv', 'adverb', 'pronume', 'prepoziție', 'conjuncție',
                 'interjecție', 'numeral', 'articol', 'locuțiune', 'expresie'}
    if pos and pos not in valid_pos:
        issue('WARN', 'vocab', eid, f"unusual partOfSpeech: '{pos}'")

print(f"  {len(vocab)} exercises checked")
dupes = [w for w, c in seen_words.items() if c > 1]
if dupes:
    print(f"  ⚠️  {len(dupes)} duplicate words: {dupes[:10]}")

# ============================================================
# IDIOM EXERCISES
# ============================================================
print("Deep review: idiom_exercises.json ...")
idioms = load_json("lib/content/idiom_exercises.json")
seen_expr = Counter()

for ex in idioms:
    eid = ex.get('id', '?')
    expr = ex.get('expression', '').lower()
    seen_expr[expr] += 1

    # Expression should appear in example
    example = ex.get('example', '').lower()
    highlighted = ex.get('highlightedText', '').lower()
    if highlighted and highlighted not in example:
        issue('ERROR', 'idioms', eid, f"highlightedText '{highlighted}' not found in example")

    # Expression should be findable in example (at least partially)
    if expr and example:
        expr_words = expr.replace('-', ' ').split()
        found = any(w in example for w in expr_words if len(w) > 2)
        if not found:
            issue('WARN', 'idioms', eid, f"expression '{expr}' not found in example")

    # Options should not duplicate
    opts = ex.get('options', [])
    opt_lower = [o.lower().strip() for o in opts]
    if len(opt_lower) != len(set(opt_lower)):
        issue('ERROR', 'idioms', eid, f"duplicate options: {opts}")

    # Meaning should not match the expression literally
    meaning = ex.get('meaning', '').lower()
    if meaning == expr:
        issue('WARN', 'idioms', eid, "meaning equals expression")

print(f"  {len(idioms)} exercises checked")
dupes_expr = [w for w, c in seen_expr.items() if c > 1]
if dupes_expr:
    print(f"  ⚠️  {len(dupes_expr)} duplicate expressions: {dupes_expr}")

# ============================================================
# SPOT TEXTS
# ============================================================
print("Deep review: spot_texts.json ...")
spot = load_json("lib/content/spot_texts.json")
seen_titles = Counter()

for t in spot:
    tid = t.get('id', '?')
    title = t.get('title', '')
    seen_titles[title] += 1

    content = t.get('content', '')
    words = content.split()
    for m in t.get('mistakes', []):
        token = m.get('token', '')
        replacement = m.get('replacement', '')

        # Token must differ from replacement
        if token == replacement:
            issue('ERROR', 'spot', tid, f"token '{token}' equals replacement")

        # Token should exist in content
        if token and token not in content:
            issue('ERROR', 'spot', tid, f"token '{token}' not found in content")

        # commonErrorPairIndex must be valid
        cepi = m.get('commonErrorPairIndex')
        if cepi is not None:
            if cepi < 0 or cepi >= len(common_error_pairs):
                issue('ERROR', 'spot', tid, f"commonErrorPairIndex {cepi} out of range (0-{len(common_error_pairs)-1})")

        # Explanation should be non-empty
        if len(m.get('explanation', '')) < 5:
            issue('WARN', 'spot', tid, f"mistake explanation too short for '{token}'")

# Titles should be unique
dupe_titles = [t for t, c in seen_titles.items() if c > 1]
if dupe_titles:
    print(f"  ⚠️  {len(dupe_titles)} duplicate titles: {dupe_titles}")

print(f"  {len(spot)} texts checked")

# ============================================================
# COMMON ERROR PAIRS
# ============================================================
print("Deep review: common_error_pairs.json ...")
seen_pairs = set()

for i, p in enumerate(common_error_pairs):
    corect = p.get('corect', '').strip()
    incorect = p.get('incorect', '').strip()

    if corect == incorect:
        issue('ERROR', 'common_error', f"[{i}]", f"corect == incorect: '{corect}'")

    pair_key = (corect.lower(), incorect.lower())
    if pair_key in seen_pairs:
        issue('WARN', 'common_error', f"[{i}]", f"duplicate pair: {corect} / {incorect}")
    seen_pairs.add(pair_key)

    severity = p.get('severity', '')
    if severity not in {'ridicată', 'medie', 'scăzută', ''}:
        issue('WARN', 'common_error', f"[{i}]", f"unusual severity: '{severity}'")

print(f"  {len(common_error_pairs)} pairs checked")

# ============================================================
# HYPHENATION PAIRS
# ============================================================
print("Deep review: hyphenation_pairs.json ...")
for i, p in enumerate(hyphenation_pairs):
    hf = p.get('hyphenatedForm', '')
    uhf = p.get('unhyphenatedForm', '')

    if hf == uhf:
        issue('WARN', 'hyphenation', f"[{i}]", f"hyphenated equals unhyphenated: '{hf}'")

    # Hyphenated form should contain hyphens or middle dots
    if hf and '-' not in hf and '·' not in hf:
        issue('WARN', 'hyphenation', f"[{i}]", f"hyphenatedForm '{hf}' doesn't contain hyphen/middle dot")

print(f"  {len(hyphenation_pairs)} pairs checked")

# ============================================================
# REPORT
# ============================================================
print()
errors = [i for i in issues if i[0] == 'ERROR']
warns = [i for i in issues if i[0] == 'WARN']

print(f"{'='*60}")
print(f"RESULTS: {len(errors)} errors, {len(warns)} warnings")
print(f"{'='*60}")

if errors:
    print(f"\n❌ ERRORS ({len(errors)}):")
    for level, file, eid, msg in errors:
        print(f"  [{file}] {eid}: {msg}")

if warns:
    print(f"\n⚠️  WARNINGS ({len(warns)}):")
    for level, file, eid, msg in warns:
        print(f"  [{file}] {eid}: {msg}")

if errors:
    sys.exit(1)
else:
    print("\n✅ No hard errors found.")
    sys.exit(0)

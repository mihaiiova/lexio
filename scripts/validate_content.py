#!/usr/bin/env python3
"""Validate structural integrity of all Slove content files."""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

def load_json(path):
    with open(ROOT / path, encoding='utf-8') as f:
        return json.load(f)

errors = []

def check(condition, path, item_id, msg):
    if not condition:
        errors.append(f"{path} | {item_id} | {msg}")

# --- Grammar exercises ---
print("Validating grammar_exercises.json ...")
grammar = load_json("lib/content/grammar_exercises.json")
ids = set()
for ex in grammar:
    eid = ex.get('id', '?')
    check('id' in ex, 'grammar', eid, "missing id")
    check('notionId' in ex and isinstance(ex.get('notionId'), str) and ex['notionId'], 'grammar', eid, "missing/empty notionId")
    if ex.get('notionId') and ex.get('pairId'):
        check(ex['notionId'] == ex['pairId'], 'grammar', eid, "notionId must equal pairId")
    check('sentence' in ex, 'grammar', eid, "missing sentence")
    check('isCorrect' in ex and isinstance(ex['isCorrect'], bool), 'grammar', eid, "missing/invalid isCorrect")
    check('explanation' in ex, 'grammar', eid, "missing explanation")
    check('category' in ex, 'grammar', eid, "missing category")
    check('topic' in ex, 'grammar', eid, "missing topic")
    check('difficulty' in ex and 1 <= ex['difficulty'] <= 3, 'grammar', eid, "difficulty not in [1,3]")
    if not ex.get('isCorrect'):
        check('correctSentence' in ex, 'grammar', eid, "missing correctSentence for incorrect exercise")
        if 'correctSentence' in ex:
            check(ex['correctSentence'] != ex['sentence'], 'grammar', eid, "correctSentence equals sentence")
    check(eid not in ids, 'grammar', eid, "duplicate id")
    ids.add(eid)
print(f"  {len(grammar)} exercises checked")

# --- Vocabulary exercises ---
print("Validating vocabulary_exercises.json ...")
vocab = load_json("lib/content/vocabulary_exercises.json")
ids = set()
for ex in vocab:
    eid = ex.get('id', '?')
    check('id' in ex, 'vocab', eid, "missing id")
    check('notionId' in ex and isinstance(ex.get('notionId'), str) and ex['notionId'], 'vocab', eid, "missing/empty notionId")
    if ex.get('notionId') and ex.get('word'):
        check(ex['notionId'] == ex['word'], 'vocab', eid, "notionId must equal word")
    check('word' in ex, 'vocab', eid, "missing word")
    check('partOfSpeech' in ex, 'vocab', eid, "missing partOfSpeech")
    check('example' in ex, 'vocab', eid, "missing example")
    check('options' in ex and isinstance(ex['options'], list), 'vocab', eid, "missing options")
    check('correctOptionIndex' in ex, 'vocab', eid, "missing correctOptionIndex")
    opts = ex.get('options', [])
    ci = ex.get('correctOptionIndex', -1)
    check(0 <= ci < len(opts), 'vocab', eid, f"correctOptionIndex {ci} out of range [0,{len(opts)-1}]")
    check(eid not in ids, 'vocab', eid, "duplicate id")
    ids.add(eid)
print(f"  {len(vocab)} exercises checked")

# --- Idiom exercises ---
print("Validating idiom_exercises.json ...")
idioms = load_json("lib/content/idiom_exercises.json")
ids = set()
for ex in idioms:
    eid = ex.get('id', '?')
    check('id' in ex, 'idioms', eid, "missing id")
    check('notionId' in ex and isinstance(ex.get('notionId'), str) and ex['notionId'], 'idioms', eid, "missing/empty notionId")
    if ex.get('notionId') and ex.get('expression'):
        check(ex['notionId'] == ex['expression'], 'idioms', eid, "notionId must equal expression")
    check('expression' in ex, 'idioms', eid, "missing expression")
    check('example' in ex, 'idioms', eid, "missing example")
    check('options' in ex and isinstance(ex['options'], list), 'idioms', eid, "missing options")
    check('correctOptionIndex' in ex, 'idioms', eid, "missing correctOptionIndex")
    opts = ex.get('options', [])
    ci = ex.get('correctOptionIndex', -1)
    check(0 <= ci < len(opts), 'idioms', eid, f"correctOptionIndex {ci} out of range [0,{len(opts)-1}]")
    check(eid not in ids, 'idioms', eid, "duplicate id")
    ids.add(eid)
print(f"  {len(idioms)} exercises checked")

# --- Data files (loaded first so spot can validate references) ---
print("Validating common_error_pairs.json ...")
cep = load_json("data/common_error_pairs.json")
for i, p in enumerate(cep):
    check('corect' in p and 'incorect' in p, 'common_error', f"[{i}]", "missing corect/incorect")
    check(p.get('notionId') == f"gp{i}", 'common_error', f"[{i}]", "notionId must equal gp<index>")
print(f"  {len(cep)} pairs checked")

print("Validating hyphenation_pairs.json ...")
hyp = load_json("data/hyphenation_pairs.json")
hyphenation_ids = set()
for i, p in enumerate(hyp):
    check('hyphenatedForm' in p and 'unhyphenatedForm' in p, 'hyphenation', f"[{i}]", "missing fields")
    check('id' in p and isinstance(p.get('id'), str) and p['id'], 'hyphenation', f"[{i}]", "missing/empty id")
    check(p.get('notionId') == f"hyphenated_{p['id']}", 'hyphenation', f"[{i}]", "notionId must equal hyphenated_<id>")
    hyphenation_ids.add(p.get('id'))
print(f"  {len(hyp)} pairs checked")

# --- Spot texts ---
print("Validating spot_texts.json ...")
spot = load_json("lib/content/spot_texts.json")
ids = set()
total_mistakes = 0
for t in spot:
    tid = t.get('id', '?')
    check('id' in t, 'spot', tid, "missing id")
    check('title' in t, 'spot', tid, "missing title")
    check('content' in t, 'spot', tid, "missing content")
    check('mistakes' in t and isinstance(t['mistakes'], list), 'spot', tid, "missing mistakes")
    check(tid not in ids, 'spot', tid, "duplicate id")
    ids.add(tid)
    content = t.get('content', '')
    for m in t.get('mistakes', []):
        total_mistakes += 1
        check('notionId' in m and isinstance(m.get('notionId'), str) and m['notionId'], 'spot', tid, "mistake missing/empty notionId")
        check('token' in m, 'spot', tid, "mistake missing token")
        check('replacement' in m, 'spot', tid, "mistake missing replacement")
        check('explanation' in m, 'spot', tid, "mistake missing explanation")
        cep_idx = m.get('commonErrorPairIndex')
        hyp_ref = m.get('hyphenationPairId')
        check((cep_idx is None) != (hyp_ref is None), 'spot', tid, "mistake must reference exactly one source")
        if cep_idx is not None:
            check(0 <= cep_idx < len(cep), 'spot', tid, f"commonErrorPairIndex {cep_idx} out of range [0,{len(cep)-1}]")
        if hyp_ref is not None:
            check(hyp_ref in hyphenation_ids, 'spot', tid, f"unknown hyphenationPairId '{hyp_ref}'")
        if 'token' in m and 'content' in t:
            check(m['token'] in content, 'spot', tid, f"token '{m['token']}' not found in content")
print(f"  {len(spot)} texts, {total_mistakes} mistakes checked")

# --- Report ---
print()
if errors:
    print(f"=== {len(errors)} ISSUES FOUND ===")
    for e in errors:
        print(f"  ❌ {e}")
    sys.exit(1)
else:
    print("=== ALL CONTENT PASSES STRUCTURAL VALIDATION ===")
    sys.exit(0)

#!/usr/bin/env python3
"""Backfill explicit permanent notionId fields into canonical content files.

The first version of the remote-content-bundles work (#52) adds an explicit
`notionId` to every learning concept so editorial identity survives wording,
explanation, and reordering changes. The initial values are copied exactly from
the identity the app currently derives, so existing `user_progress_v2` records
continue to resolve without a migration. Existing explicit IDs are preserved
when this script is run again.

Derivation mirrors the Dart models:
- grammar:      pairId (pairs share an id)
- vocabulary:   word
- idioms:       expression
- spot mistake: "gp<commonErrorPairIndex>" when sourced from a common error,
                otherwise "sp_<token>_<replacement>" (Dart Uri.encodeComponent)
- common error: "gp<index>" (shared by every spot mistake referencing it)
- hyphenation:  "hyphenated_<id>" (its generated grammar concept)

Run from the repository root:

    python3 scripts/backfill_notion_ids.py
"""

import json
import urllib.parse
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def load(path):
    with open(ROOT / path, encoding="utf-8") as f:
        return json.load(f)


def dump(path, data):
    with open(ROOT / path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")


def insert_after(data, after_key, new_key, new_value):
    out = {}
    for key, value in data.items():
        out[key] = value
        if key == after_key and new_key not in data:
            out[new_key] = new_value
    return out


def notion_id(data, fallback):
    return data.get("notionId") or fallback


def spot_notion_id(mistake):
    index = mistake.get("commonErrorPairIndex")
    if index is not None:
        return f"gp{index}"
    token = urllib.parse.quote(mistake["token"], safe="")
    replacement = urllib.parse.quote(mistake["replacement"], safe="")
    return f"sp_{token}_{replacement}"


def main():
    grammar = load("lib/content/grammar_exercises.json")
    grammar = [
        insert_after(ex, "id", "notionId", notion_id(ex, ex["pairId"]))
        for ex in grammar
    ]
    dump("lib/content/grammar_exercises.json", grammar)
    print(f"grammar: {len(grammar)} exercises")

    vocab = load("lib/content/vocabulary_exercises.json")
    vocab = [
        insert_after(ex, "id", "notionId", notion_id(ex, ex["word"]))
        for ex in vocab
    ]
    dump("lib/content/vocabulary_exercises.json", vocab)
    print(f"vocabulary: {len(vocab)} exercises")

    idioms = load("lib/content/idiom_exercises.json")
    idioms = [
        insert_after(ex, "id", "notionId", notion_id(ex, ex["expression"]))
        for ex in idioms
    ]
    dump("lib/content/idiom_exercises.json", idioms)
    print(f"idioms: {len(idioms)} exercises")

    spot = load("lib/content/spot_texts.json")
    for text in spot:
        text["mistakes"] = [
            insert_after(
                m, "wordIndex", "notionId", notion_id(m, spot_notion_id(m))
            )
            for m in text["mistakes"]
        ]
    dump("lib/content/spot_texts.json", spot)
    print(f"spot: {len(spot)} texts")

    common = load("data/common_error_pairs.json")
    common = [
        {"notionId": notion_id(pair, f"gp{i}"), **pair}
        for i, pair in enumerate(common)
    ]
    dump("data/common_error_pairs.json", common)
    print(f"common errors: {len(common)} pairs")

    hyphenation = load("data/hyphenation_pairs.json")
    hyphenation = [
        insert_after(
            p,
            "id",
            "notionId",
            notion_id(p, f"hyphenated_{p['id']}"),
        )
        for p in hyphenation
    ]
    dump("data/hyphenation_pairs.json", hyphenation)
    print(f"hyphenation: {len(hyphenation)} pairs")


if __name__ == "__main__":
    main()

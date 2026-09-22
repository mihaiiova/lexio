#!/usr/bin/env python3
"""Generate a complete, deterministic content bundle and its manifest.

The bundle is the single source of remote content: one JSON file containing
grammar, vocabulary, idioms, spot texts, hyphenation pairs, and common-error
data, generated from the canonical Git JSON files (the editorial source).

Outputs (committed, reviewed in Git):
- content_public/content_bundle.json          — the complete bundle
- content_public/content_bundle_<v>.json      — an immutable versioned snapshot
- content_public/manifest.json                — monotonic version + bundle URL

Deterministic: given identical input files, the bundle bytes are identical.
The version is monotonic and is bumped explicitly before publishing:

    python3 scripts/generate_content_bundle.py --bump --base-url https://...

The base URL defaults to an empty string (publishing path is supplied by CI).

Run from the repository root. The script exits non-zero if any content entry
is missing an explicit notionId (the same contract validate_content.py checks).
"""

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "content_public"
SCHEMA_VERSION = 1


def load(path):
    with open(ROOT / path, encoding="utf-8") as f:
        return json.load(f)


def require_notion_ids(items, label):
    """Fail fast on any learning concept missing an explicit notionId."""
    for i, item in enumerate(items):
        if not isinstance(item.get("notionId"), str) or not item["notionId"]:
            sys.exit(f"{label}[{i}] is missing an explicit notionId")


def build_bundle():
    grammar = load("lib/content/grammar_exercises.json")
    vocabulary = load("lib/content/vocabulary_exercises.json")
    idioms = load("lib/content/idiom_exercises.json")
    spot_texts = load("lib/content/spot_texts.json")
    hyphenation = load("data/hyphenation_pairs.json")
    common_errors = load("data/common_error_pairs.json")

    require_notion_ids(grammar, "grammar")
    require_notion_ids(vocabulary, "vocabulary")
    require_notion_ids(idioms, "idioms")
    require_notion_ids(hyphenation, "hyphenation")
    require_notion_ids(common_errors, "common_error")
    for text in spot_texts:
        require_notion_ids(text.get("mistakes", []), f"spot[{text.get('id')}]")

    # Fixed key order keeps the output deterministic regardless of source order.
    return {
        "schemaVersion": SCHEMA_VERSION,
        "grammar": grammar,
        "vocabulary": vocabulary,
        "idioms": idioms,
        "spotTexts": spot_texts,
        "hyphenationPairs": hyphenation,
        "commonErrorPairs": common_errors,
    }


def dump_json(path, data):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")


def read_current_version():
    manifest_path = OUT_DIR / "manifest.json"
    if not manifest_path.exists():
        return 0
    try:
        with open(manifest_path, encoding="utf-8") as f:
            manifest = json.load(f)
        return int(manifest.get("contentVersion", 0))
    except (json.JSONDecodeError, ValueError, TypeError):
        return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--bump",
        action="store_true",
        help="increment the content version before generating",
    )
    parser.add_argument(
        "--base-url",
        default="",
        help="base URL where static content is published",
    )
    args = parser.parse_args()

    OUT_DIR.mkdir(parents=True, exist_ok=True)

    current = read_current_version()
    version = current + 1 if args.bump else (current or 1)

    bundle = build_bundle()

    bundle_path = OUT_DIR / "content_bundle.json"
    versioned_path = OUT_DIR / f"content_bundle_{version}.json"
    bundle_bytes = json.dumps(bundle, ensure_ascii=False, indent=2) + "\n"

    bundle_path.write_text(bundle_bytes, encoding="utf-8")
    versioned_path.write_text(bundle_bytes, encoding="utf-8")

    base = args.base_url.rstrip("/")
    bundle_url = (
        f"{base}/content_bundle_{version}.json" if base else ""
    )
    manifest = {
        "schemaVersion": SCHEMA_VERSION,
        "contentVersion": version,
        "bundleUrl": bundle_url,
    }
    dump_json(OUT_DIR / "manifest.json", manifest)

    print(f"schemaVersion: {SCHEMA_VERSION}")
    print(f"contentVersion: {version}")
    print(f"bundleUrl: {bundle_url or '(unset)'}")
    print(f"bundle: {bundle_path.relative_to(ROOT)}")
    print(f"snapshot: {versioned_path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()

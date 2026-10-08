#!/usr/bin/env bash
set -euo pipefail

# The first Play production draft used a Unix-seconds version code. Keep all
# subsequent codes above that upload, but advance only once per 10 seconds.
# Both Play jobs share a concurrency group so build times cannot overlap.
anchor=1791381725 # 2026-10-07 14:02:05 UTC, after the first successful upload
base=1791385000
now="${1:-$(date +%s)}"

if [[ ! "$now" =~ ^[0-9]+$ ]] || (( now < anchor )); then
  echo 'Invalid Android build timestamp' >&2
  exit 1
fi

code=$((base + (now - anchor) / 10))
if (( code > 2100000000 )); then
  echo 'Android version code exceeds the Google Play limit' >&2
  exit 1
fi
printf '%s\n' "$code"

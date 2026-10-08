#!/usr/bin/env bash
set -euo pipefail

script="$(dirname "$0")/android_version_code.sh"
check() {
  actual="$(bash "$script" "$1")"
  if [[ "$actual" != "$2" ]]; then
    echo "Expected $2 for $1, got $actual" >&2
    exit 1
  fi
}

check 1791381725 1791385000
check 1791381734 1791385000
check 1791381735 1791385001
check 1791391725 1791386000
if bash "$script" 1791381724 >/dev/null 2>&1; then
  echo 'Accepted a timestamp before the anchor' >&2
  exit 1
fi
if bash "$script" 4880000000 >/dev/null 2>&1; then
  echo 'Accepted a version code above the Play limit' >&2
  exit 1
fi
printf 'Android version-code checks passed\n'

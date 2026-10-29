#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

exec flutter run -d macos \
  --dart-define-from-file=config/analytics_test.json \
  "$@"

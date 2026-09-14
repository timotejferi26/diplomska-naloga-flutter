#!/usr/bin/env bash
# Run one profile benchmark without modifying the published thesis results.

set -euo pipefail

usage() {
  echo "Usage: DEVICE=<adb-device-id> $0 <default|advanced> <none|light|medium|heavy>"
}

if [[ $# -ne 2 ]]; then
  usage
  exit 2
fi

IMPLEMENTATION="$1"
PRESET="$2"
case "$IMPLEMENTATION" in
  default|advanced) ;;
  *) usage; exit 2 ;;
esac
case "$PRESET" in
  none|light|medium|heavy) ;;
  *) usage; exit 2 ;;
esac

if [[ -z "${DEVICE:-}" ]]; then
  echo "DEVICE is required. Obtain it with: adb devices"
  exit 2
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="integration_test/${IMPLEMENTATION}_benchmark_test.dart"

cd "$ROOT"
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target="$TARGET" \
  --profile \
  --dart-define="PRESET=$PRESET" \
  -d "$DEVICE"

echo "The app exported CSV/JSON files to the Android Downloads directory."
echo "Store new files under results/new-runs/$IMPLEMENTATION/$PRESET."

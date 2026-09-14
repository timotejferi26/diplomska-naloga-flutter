#!/usr/bin/env bash
# Run the same unit-test suite for both implementation levels.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT"
flutter pub get

for implementation in default advanced; do
  echo "== $implementation =="
  flutter test "test/$implementation/state_management_unit_test.dart"
done

echo "== shared domain and data layer =="
flutter test test/domain/user_validation_test.dart

echo "== widget edit flows =="
flutter test test/widget/edit_flow_test.dart

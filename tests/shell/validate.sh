#!/bin/bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TESTS_DIR="$SCRIPT_DIR/tests"

source "$TESTS_DIR/lib.sh"

PASSED=0
FAILED=0
FAILED_TESTS=()

run_all_tests() {
  for test_file in "$TESTS_DIR"/[0-9]*.sh; do
    TEST_NAME=""
    source "$test_file"
    echo "--- $TEST_NAME ---"
    if run_test; then
      PASSED=$((PASSED + 1))
    else
      FAILED=$((FAILED + 1))
      FAILED_TESTS+=("$TEST_NAME")
    fi
  done
}

run_all_tests

echo ""
echo "=============================="
echo " Results: $PASSED passed, $FAILED failed"
if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
  echo " Failed:"
  for t in "${FAILED_TESTS[@]}"; do
    echo "   - $t"
  done
fi
echo "=============================="

[ $FAILED -eq 0 ]

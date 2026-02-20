#!/bin/bash
TEST_NAME="OpenShift Login"

run_test() {
  if oc whoami &>/dev/null; then
    pass "Logged in as $(oc whoami)"
  else
    fail "Not logged into OpenShift. Please run login.sh."
  fi
}

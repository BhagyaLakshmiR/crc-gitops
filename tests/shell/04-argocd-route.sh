#!/bin/bash
TEST_NAME="ArgoCD Route"

run_test() {
  local route
  route=$(argocd_route)
  if [ -n "$route" ]; then
    pass "Route found: https://$route"
  else
    fail "ArgoCD route not found."
  fi
}

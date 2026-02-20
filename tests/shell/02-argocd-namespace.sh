#!/bin/bash
TEST_NAME="ArgoCD Namespace"

run_test() {
  if oc get ns "$ARGOCD_NS" &>/dev/null; then
    pass "Namespace '$ARGOCD_NS' found."
  else
    fail "Namespace '$ARGOCD_NS' not found."
  fi
}

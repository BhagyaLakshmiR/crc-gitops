#!/bin/bash
TEST_NAME="ArgoCD Server Pod"

run_test() {
  local ready
  ready=$(oc get pods -n "$ARGOCD_NS" \
    -l app.kubernetes.io/name=openshift-gitops-server \
    -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)
  if [ "$ready" == "true" ]; then
    pass "ArgoCD server pod is ready."
  else
    fail "ArgoCD server pod is not ready."
  fi
}

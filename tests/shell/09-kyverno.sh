#!/bin/bash
TEST_NAME="Kyverno"

KYVERNO_NS="kyverno"

run_test() {
  local failed=0

  # 1. ArgoCD app is Synced and Healthy
  local sync health
  sync=$(oc get application kyverno -n "$ARGOCD_NS" -o jsonpath='{.status.sync.status}' 2>/dev/null)
  health=$(oc get application kyverno -n "$ARGOCD_NS" -o jsonpath='{.status.health.status}' 2>/dev/null)
  if [ "$sync" == "Synced" ] && [ "$health" == "Healthy" ]; then
    pass "ArgoCD app kyverno is Synced/Healthy"
  else
    fail "ArgoCD app kyverno: sync=$sync health=$health"
    failed=$((failed + 1))
  fi

  # 2. All 4 Kyverno controller pods are running
  local controllers=("admission-controller" "background-controller" "cleanup-controller" "reports-controller")
  for ctrl in "${controllers[@]}"; do
    local ready
    ready=$(oc get pods -n "$KYVERNO_NS" -l "app.kubernetes.io/component=$ctrl" \
      -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)
    if [ "$ready" == "true" ]; then
      pass "Kyverno $ctrl pod is ready"
    else
      fail "Kyverno $ctrl pod is not ready (ready=$ready)"
      failed=$((failed + 1))
    fi
  done

  # 3. Kyverno CRDs are installed
  local crds=("clusterpolicies.kyverno.io" "policies.kyverno.io" "clusterephemeralreports.reports.kyverno.io")
  for crd in "${crds[@]}"; do
    if oc get crd "$crd" &>/dev/null; then
      pass "CRD $crd exists"
    else
      fail "CRD $crd missing"
      failed=$((failed + 1))
    fi
  done

  # 4. Kyverno namespace exists
  if oc get namespace "$KYVERNO_NS" &>/dev/null; then
    pass "Namespace $KYVERNO_NS exists"
  else
    fail "Namespace $KYVERNO_NS missing"
    failed=$((failed + 1))
  fi

  [ "$failed" -eq 0 ]
}

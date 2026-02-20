#!/bin/bash
TEST_NAME="Kyverno Policies"

run_test() {
  local failed=0

  # 1. ArgoCD app is Synced and Healthy
  local sync health
  sync=$(oc get application kyverno-policies -n "$ARGOCD_NS" -o jsonpath='{.status.sync.status}' 2>/dev/null)
  health=$(oc get application kyverno-policies -n "$ARGOCD_NS" -o jsonpath='{.status.health.status}' 2>/dev/null)
  if [ "$sync" == "Synced" ] && [ "$health" == "Healthy" ]; then
    pass "ArgoCD app kyverno-policies is Synced/Healthy"
  else
    fail "ArgoCD app kyverno-policies: sync=$sync health=$health"
    failed=$((failed + 1))
  fi

  # 2. At least one ClusterPolicy exists
  local policy_count
  policy_count=$(oc get clusterpolicies --no-headers 2>/dev/null | wc -l | tr -d ' ')
  if [ "${policy_count:-0}" -gt 0 ]; then
    pass "Found $policy_count ClusterPolicy/ClusterPolicies"
  else
    fail "No ClusterPolicies found"
    failed=$((failed + 1))
  fi

  # 3. No ClusterPolicy is in a Failed state
  local failed_policies
  failed_policies=$(oc get clusterpolicies -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}' 2>/dev/null | grep -v "True" | grep -v "^$" || true)
  if [ -z "$failed_policies" ]; then
    pass "All ClusterPolicies are Ready"
  else
    fail "Some ClusterPolicies not Ready: $failed_policies"
    failed=$((failed + 1))
  fi

  [ "$failed" -eq 0 ]
}

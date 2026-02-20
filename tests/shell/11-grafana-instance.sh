#!/bin/bash
TEST_NAME="Grafana Instance"

GRAFANA_NS="grafana"

run_test() {
  local failed=0

  # 1. platform-operators ArgoCD app is Synced and Healthy
  local sync health
  sync=$(oc get application platform-operators -n "$ARGOCD_NS" -o jsonpath='{.status.sync.status}' 2>/dev/null)
  health=$(oc get application platform-operators -n "$ARGOCD_NS" -o jsonpath='{.status.health.status}' 2>/dev/null)
  if [ "$sync" == "Synced" ] && [ "$health" == "Healthy" ]; then
    pass "ArgoCD app platform-operators is Synced/Healthy"
  else
    fail "ArgoCD app platform-operators: sync=$sync health=$health"
    failed=$((failed + 1))
  fi

  # 2. grafana-instance ArgoCD app is Synced and Healthy
  sync=$(oc get application grafana-instance -n "$ARGOCD_NS" -o jsonpath='{.status.sync.status}' 2>/dev/null)
  health=$(oc get application grafana-instance -n "$ARGOCD_NS" -o jsonpath='{.status.health.status}' 2>/dev/null)
  if [ "$sync" == "Synced" ] && [ "$health" == "Healthy" ]; then
    pass "ArgoCD app grafana-instance is Synced/Healthy"
  else
    fail "ArgoCD app grafana-instance: sync=$sync health=$health"
    failed=$((failed + 1))
  fi

  # 3. Grafana operator pod is running
  local ready
  ready=$(oc get pods -n "$GRAFANA_NS" -l "app.kubernetes.io/name=grafana-operator" \
    -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)
  if [ "$ready" == "true" ]; then
    pass "Grafana operator pod is ready"
  else
    fail "Grafana operator pod is not ready (ready=$ready)"
    failed=$((failed + 1))
  fi

  # 4. Grafana deployment pod is running
  ready=$(oc get pods -n "$GRAFANA_NS" -l "app=grafana" \
    -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)
  if [ "$ready" == "true" ]; then
    pass "Grafana instance pod is ready"
  else
    fail "Grafana instance pod is not ready (ready=$ready)"
    failed=$((failed + 1))
  fi

  # 5. Grafana CR stage is success
  local stage
  stage=$(oc get grafana grafana -n "$GRAFANA_NS" -o jsonpath='{.status.stageStatus}' 2>/dev/null)
  if [ "$stage" == "success" ]; then
    pass "Grafana CR stage is success"
  else
    fail "Grafana CR stage is '$stage' (expected success)"
    failed=$((failed + 1))
  fi

  # 6. GrafanaDatasource CRD exists
  if oc get crd grafanadatasources.grafana.integreatly.org &>/dev/null; then
    pass "CRD grafanadatasources.grafana.integreatly.org exists"
  else
    fail "CRD grafanadatasources.grafana.integreatly.org missing"
    failed=$((failed + 1))
  fi

  [ "$failed" -eq 0 ]
}

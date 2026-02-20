#!/bin/bash
# Shared helpers for all tests

ARGOCD_NS="openshift-gitops"

pass() { echo "  [PASS] $1"; }
fail() { echo "  [FAIL] $1"; return 1; }

argocd_route() {
  [ -n "${ARGOCD_ROUTE:-}" ] && echo "$ARGOCD_ROUTE" && return
  export ARGOCD_ROUTE
  ARGOCD_ROUTE=$(oc get route openshift-gitops-server -n "$ARGOCD_NS" -o jsonpath='{.spec.host}' 2>/dev/null)
  echo "$ARGOCD_ROUTE"
}

argocd_token() {
  [ -n "${ARGOCD_TOKEN:-}" ] && echo "$ARGOCD_TOKEN" && return
  export ARGOCD_TOKEN
  local route password
  route=$(argocd_route)
  password=$(oc get secret openshift-gitops-cluster -n "$ARGOCD_NS" \
    -o jsonpath='{.data.admin\.password}' | base64 -d)
  ARGOCD_TOKEN=$(curl -k -s -X POST -H "Content-Type: application/json" \
    -d "{\"username\":\"admin\",\"password\":\"$password\"}" \
    "https://$route/api/v1/session" | jq -r .token)
  echo "$ARGOCD_TOKEN"
}

check_repo() {
  local repo_url="$1"
  local encoded
  encoded=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$repo_url', safe=''))")
  local route token status
  route=$(argocd_route)
  token=$(argocd_token)
  status=$(curl -k -s -H "Authorization: Bearer $token" \
    "https://$route/api/v1/repositories/$encoded" | jq -r .connectionState.status)
  echo "$status"
}

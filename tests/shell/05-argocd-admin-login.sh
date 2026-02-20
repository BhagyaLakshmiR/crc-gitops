#!/bin/bash
TEST_NAME="ArgoCD Admin Login"

run_test() {
  local route password http_status
  route=$(argocd_route)
  password=$(oc get secret openshift-gitops-cluster -n "$ARGOCD_NS" \
    -o jsonpath='{.data.admin\.password}' | base64 -d)
  http_status=$(curl -k -s -o /dev/null -w "%{http_code}" \
    -X POST -H "Content-Type: application/json" \
    -d "{\"username\":\"admin\",\"password\":\"$password\"}" \
    "https://$route/api/v1/session")
  if [ "$http_status" == "200" ]; then
    pass "Admin login successful (HTTP 200)."
  else
    fail "Admin login failed (HTTP $http_status)."
  fi
}

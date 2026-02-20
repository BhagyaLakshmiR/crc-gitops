#!/bin/bash
TEST_NAME="RBAC: kubeadmin can login and see repos"

# Repos that must be visible to kubeadmin
EXPECTED_REPOS=(
  "https://github.com/BhagyaLakshmiR/crc-gitops.git"
  "https://github.com/KondaReddyR/crc-gitops.git"
)

run_test() {
  local route token repos

  route=$(argocd_route)

  # Generate a real API token for the kubeadmin local account
  token=$(argocd account generate-token --account kubeadmin 2>/dev/null)
  if [ -z "$token" ]; then
    fail "Could not generate API token for kubeadmin (account missing?)."
    return 1
  fi

  # Call the repos API as kubeadmin
  repos=$(curl -k -s -H "Authorization: Bearer $token" \
    "https://$route/api/v1/repositories" | jq -r '.items[]?.repo // empty' 2>/dev/null)

  if [ -z "$repos" ]; then
    fail "kubeadmin can authenticate but sees no repositories (RBAC not granting role:admin)."
    return 1
  fi

  # Verify each expected repo is visible
  for expected in "${EXPECTED_REPOS[@]}"; do
    if ! echo "$repos" | grep -qF "$expected"; then
      fail "kubeadmin cannot see expected repo: $expected"
      return 1
    fi
  done

  pass "kubeadmin logged in and sees all ${#EXPECTED_REPOS[@]} repos."
}

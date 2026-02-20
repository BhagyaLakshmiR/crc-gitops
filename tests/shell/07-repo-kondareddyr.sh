#!/bin/bash
TEST_NAME="Repo: KondaReddyR/crc-gitops"

REPO_URL="https://github.com/KondaReddyR/crc-gitops.git"

run_test() {
  local status
  status=$(check_repo "$REPO_URL")
  if [ "$status" == "Successful" ]; then
    pass "Repository connected: $REPO_URL"
  else
    fail "Repository not connected (status: $status): $REPO_URL"
  fi
}

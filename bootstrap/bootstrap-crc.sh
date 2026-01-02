#!/bin/bash
#
# CRC GitOps Bootstrap Script
# This script bootstraps a fresh CRC cluster with all platform components via GitOps
#
# Usage: cd gitops-repo/bootstrap && ./bootstrap-crc.sh
#

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Configuration
GITOPS_REPO="https://github.com/KondaReddyR/crc-gitops.git"
GITHUB_USER="KondaReddyR"
KYVERNO_VERSION="3.6.1"

echo "=== CRC GitOps Bootstrap ==="
echo "Repo directory: $REPO_DIR"
echo ""

# Check prerequisites
command -v oc >/dev/null 2>&1 || { echo "ERROR: oc CLI not found"; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "ERROR: helm not found"; exit 1; }
command -v gh >/dev/null 2>&1 || { echo "WARNING: gh CLI not found - you'll need to manually create the repo secret"; }

# Get GitHub token
GITHUB_TOKEN=$(gh auth token 2>/dev/null || echo "")
if [ -z "$GITHUB_TOKEN" ]; then
    echo "WARNING: Could not get GitHub token. You'll need to manually create the repo secret."
fi

# Verify cluster connection
echo "1. Verifying cluster connection..."
oc whoami >/dev/null 2>&1 || { echo "ERROR: Not logged into cluster. Run: oc login -u kubeadmin ..."; exit 1; }
echo "   Connected as: $(oc whoami)"

# Step 1: Install OpenShift GitOps
echo ""
echo "2. Installing OpenShift GitOps operator..."
oc apply -f "$SCRIPT_DIR/openshift-gitops.yaml"

# Wait for operator
echo "   Waiting for GitOps operator (60s)..."
sleep 60
oc get pods -n openshift-operators | grep gitops || { echo "ERROR: GitOps operator not running"; exit 1; }

# Wait for ArgoCD pods
echo ""
echo "3. Waiting for ArgoCD instance (45s)..."
sleep 45
oc get pods -n openshift-gitops | head -5

# Step 2: Apply ArgoCD patch (RBAC + no resource limits)
echo ""
echo "4. Patching ArgoCD (RBAC + resources)..."
oc apply -f "$SCRIPT_DIR/argocd-patch.yaml"

# Step 3: Grant cluster-admin to ArgoCD
echo ""
echo "5. Granting cluster-admin to ArgoCD app controller..."
oc adm policy add-cluster-role-to-user cluster-admin \
  -z openshift-gitops-argocd-application-controller -n openshift-gitops

# Step 4: Create repo secret
echo ""
echo "6. Creating repository secret..."
if [ -n "$GITHUB_TOKEN" ]; then
    # Apply repo-secret.yaml with PAT substituted
    sed "s/YOUR_GITHUB_PAT/$GITHUB_TOKEN/g" "$SCRIPT_DIR/repo-secret.yaml" | oc apply -f -
    echo "   Repository secret created"
else
    echo "   MANUAL STEP REQUIRED: Edit repo-secret.yaml and apply"
    echo "   1. Edit $SCRIPT_DIR/repo-secret.yaml"
    echo "   2. Replace YOUR_GITHUB_PAT with: gh auth token"
    echo "   3. Run: oc apply -f $SCRIPT_DIR/repo-secret.yaml"
fi

# Step 5: Pre-install Kyverno CRDs (WORKAROUND for ArgoCD sync issue)
echo ""
echo "7. Pre-installing Kyverno CRDs (workaround for ArgoCD sync issue)..."
helm repo add kyverno https://kyverno.github.io/kyverno/ 2>/dev/null || true
helm repo update kyverno
helm template kyverno kyverno/kyverno --version "$KYVERNO_VERSION" --include-crds | \
  oc apply -f - --server-side 2>&1 | grep -E "crd|error" | head -10
echo "   Kyverno CRDs installed"

# Step 6: Apply App-of-Apps
echo ""
echo "8. Applying App-of-Apps bootstrap..."
oc apply -f "$SCRIPT_DIR/platform-bootstrap-app.yaml"

# Wait for sync
echo ""
echo "9. Waiting for apps to sync (120s)..."
sleep 120

# Final status
echo ""
echo "=== Application Status ==="
oc get applications -n openshift-gitops

echo ""
echo "=== Pods Status ==="
echo "Kyverno:"
oc get pods -n kyverno 2>/dev/null | head -5 || echo "  Not deployed yet"
echo ""
echo "Grafana:"
oc get pods -n grafana 2>/dev/null | head -3 || echo "  Not deployed yet"

echo ""
echo "=== Access URLs ==="
echo "ArgoCD:  https://openshift-gitops-server-openshift-gitops.apps-crc.testing"
echo "Grafana: https://grafana-route-grafana.apps-crc.testing"
echo ""
echo "ArgoCD admin password:"
oc get secret openshift-gitops-cluster -n openshift-gitops -o jsonpath='{.data.admin\.password}' | base64 -d
echo ""

# Step 7: Run validation tests
echo ""
echo "=== Running Validation Tests ==="
if command -v chainsaw >/dev/null 2>&1; then
    cd "$REPO_DIR"
    chainsaw test --test-dir tests/ 2>&1 | tail -20
else
    echo "WARNING: chainsaw not installed. Install with: brew install kyverno/tap/chainsaw"
    echo "Then run: cd $REPO_DIR && chainsaw test --test-dir tests/"
fi

echo ""
echo "Bootstrap complete!"

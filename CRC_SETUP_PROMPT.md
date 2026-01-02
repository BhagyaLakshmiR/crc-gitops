# CRC Platform Components Setup Prompt

Use this prompt to set up a brand new OpenShift Local (CRC) cluster with platform components.

---

## Prompt

```
I have a local OpenShift cluster running on CodeReady Containers.

Set up a GitOps-managed platform with the following:

## Components to Install (via Operators where available)
1. **Kyverno** - Policy engine (Helm, no OLM operator available)
2. **OpenShift GitOps** - ArgoCD from redhat-operators
3. **Vault Secrets Operator** - from certified-operators
4. **Cluster Logging** - from redhat-operators (includes Vector)
5. **Grafana Operator** - from community-operators

## GitOps Structure
Use App-of-Apps pattern with kustomization.yaml in each directory:
```
gitops-repo/
├── argocd-apps/         # App-of-Apps with kustomization.yaml
│   ├── kyverno.yaml
│   ├── kyverno-policies.yaml
│   ├── platform-operators.yaml
│   └── grafana-instance.yaml
├── apps/grafana/        # Grafana CRs with kustomization.yaml
│   ├── grafana.yaml     # With OpenShift OAuth SSO
│   ├── oauth-client.yaml
│   ├── oauth-secret.yaml
│   ├── datasource-prometheus.yaml
│   └── dashboard-argocd.yaml
├── operators/           # Operator subscriptions with kustomization.yaml
├── policies/            # Kyverno policies with kustomization.yaml
├── bootstrap/           # One-time manual apply
└── tests/               # Chainsaw validation tests
```

## Requirements
1. Create a private GitHub repo (use `gh` CLI) to store all manifests
2. Use kustomization.yaml in each folder for selective deployment
3. Configure ArgoCD RBAC so kubeadmin has admin access
4. ArgoCD should be App-of-Apps pattern
5. Create Kyverno ClusterPolicy to remove all resource requests/limits
6. Create Chainsaw validation tests for each component
7. All resource requests and limits must be removed (constrained laptop)
8. Grafana should use OpenShift OAuth for login (same as ArgoCD/Console)
9. Grafana should have Prometheus datasource and ArgoCD dashboard

## After Setup
1. Verify ArgoCD UI shows all applications
2. Run `chainsaw test --test-dir tests/` - should pass
3. `argocd app list --grpc-web` should show all apps
4. Login to Grafana using OpenShift credentials
```

---

## Prerequisites on Your Mac

```bash
# CRC running and logged in
crc start
oc login -u kubeadmin ...

# GitHub CLI authenticated
gh auth login

# Chainsaw installed
brew install kyverno/tap/chainsaw

# Helm (for Kyverno)
brew install helm

# ArgoCD CLI
brew install argocd
```

---

## Bootstrap New Cluster

After initial GitOps setup, bootstrapping a new cluster requires only:

```bash
cd gitops-repo/bootstrap

# 1. Install GitOps operator
oc apply -f openshift-gitops.yaml

# 2. Wait for operator
sleep 60

# 3. Patch ArgoCD (RBAC + no resource limits)
oc apply -f argocd-patch.yaml

# 4. Create repo secret
oc create secret generic crc-gitops-repo \
  --from-literal=type=git \
  --from-literal=url=https://github.com/YOUR_USER/crc-gitops.git \
  --from-literal=username=YOUR_GITHUB_USER \
  --from-literal=password=YOUR_GITHUB_PAT \
  -n openshift-gitops
oc label secret crc-gitops-repo argocd.argoproj.io/secret-type=repository -n openshift-gitops

# 5. Grant ArgoCD cluster-admin
oc adm policy add-cluster-role-to-user cluster-admin \
  -z openshift-gitops-argocd-application-controller -n openshift-gitops

# 6. Apply app-of-apps
oc apply -f platform-bootstrap-app.yaml
```

---

## Notes

- **ARM64/Apple Silicon**: Vault Secrets Operator may have image compatibility issues
- **Channel versions**: Operator channels may need updating to latest available
- **Grafana OAuth**: Uses OpenShift OAuth for SSO - same credentials as console
- **Kyverno CRDs**: May need pre-installation due to ArgoCD sync issues (included in bootstrap script)

---

## Automated Bootstrap Script

For the fastest setup, use the `bootstrap-crc.sh` script:

```bash
cd /path/to/gitops-repo/bootstrap
./bootstrap-crc.sh
```

This script handles all steps including the Kyverno CRD workaround and runs validation tests at the end.

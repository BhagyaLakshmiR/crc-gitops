# Bootstrap Files

These files are applied **once manually** when setting up a new cluster.
After initial bootstrap, everything is managed via GitOps.

## Usage

```bash
# 1. Login to cluster
oc login -u kubeadmin ...

# 2. Install OpenShift GitOps operator
oc apply -f openshift-gitops.yaml

# 3. Wait for operator
oc wait --for=condition=Ready pod -l control-plane=gitops-operator -n openshift-gitops-operator --timeout=300s

# 4. Create repo credential secret (replace with your PAT)
oc create secret generic crc-gitops-repo \
  --from-literal=type=git \
  --from-literal=url=https://github.com/KondaReddyR/crc-gitops.git \
  --from-literal=username=YOUR_GITHUB_USERNAME \
  --from-literal=password=YOUR_GITHUB_PAT \
  -n openshift-gitops
oc label secret crc-gitops-repo argocd.argoproj.io/secret-type=repository -n openshift-gitops

# 5. Patch ArgoCD for RBAC and no resource limits
oc apply -f argocd-patch.yaml

# 6. Apply the root bootstrap app
oc apply -f platform-bootstrap-app.yaml
```

After step 6, ArgoCD will sync and manage everything else automatically.

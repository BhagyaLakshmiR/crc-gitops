# CRC GitOps Repository

Platform component manifests for CRC local OpenShift cluster, synced via ArgoCD.

## Structure

```
operators/           # Operator subscriptions
├── vault-secrets-operator.yaml
├── cluster-logging.yaml
└── grafana-operator.yaml
apps/                # Application manifests (future)
```

## Managed Components

| Component | Source | Namespace |
|-----------|--------|-----------|
| Vault Secrets Operator | certified-operators | openshift-operators |
| Cluster Logging | redhat-operators | openshift-logging |
| Grafana Operator | community-operators | grafana |

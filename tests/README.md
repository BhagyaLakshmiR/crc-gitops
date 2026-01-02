# Platform Validation Tests

## Prerequisites

- [Kyverno Chainsaw](https://kyverno.github.io/chainsaw/) installed
  ```bash
  brew install kyverno/tap/chainsaw
  ```
- kubectl/oc configured with cluster access

## Run Tests

```bash
cd /Users/ram/dev/crc/gitops-repo
chainsaw test --test-dir tests/
```

## Expected Output

```
--- PASS: chainsaw/platform-validation (5.62s)
Tests Summary...
- Passed  tests 1
- Failed  tests 0
```

## Test Coverage

| Component | Assertion |
|-----------|-----------|
| ArgoCD | `platform-operators` Application is Synced |
| Kyverno | `kyverno` Application is Synced/Healthy |
| Grafana | Subscription exists in `grafana` namespace |
| Cluster Logging | Subscription exists in `openshift-logging` |

## Run Regularly

Add to cron or CI pipeline:
```bash
chainsaw test --test-dir /Users/ram/dev/crc/gitops-repo/tests/ --report-format JSON > test-results.json
```

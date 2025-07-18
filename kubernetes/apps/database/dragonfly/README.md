# Dragonfly Database

This directory contains the Dragonfly in-memory database deployed via Flux GitOps.

## Architecture Overview

- **Operator**: `dragonfly-operator` HelmRelease manages Dragonfly custom resources and exposes metrics for Prometheus.
- **Cluster**: `Dragonfly` resource creates the database instances. Pods run without persistent storage by default.

## Metrics and Monitoring

Metrics are scraped through the included `PodMonitor`. Grafana dashboards from the chart are disabled by default.

## Persistence

Dragonfly is configured without persistent volumes. Data will be lost when pods restart. To enable persistence:

    1. Define a `PersistentVolumeClaim` and reference it in the `Dragonfly` spec.
    2. Choose an appropriate storage class for your cluster.
    3. Redeploy the cluster to apply the new volume settings.

## Troubleshooting

### Useful Commands
```bash
# Check kustomization status
flux get kustomizations -n database dragonfly-cluster

# Inspect Dragonfly resources
kubectl get dragonfly -n database
```

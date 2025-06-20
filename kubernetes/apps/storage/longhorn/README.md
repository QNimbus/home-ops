# Longhorn Configuration

This directory contains the Longhorn distributed storage system configuration for the Kubernetes cluster.

## Overview

Longhorn is deployed as a HelmRelease using Flux GitOps. It provides:
- Distributed block storage with replication
- Snapshot and backup functionality
- Web-based management UI
- Integration with Kubernetes CSI

## Structure

```
longhorn/
├── ks.yaml                     # Flux Kustomization
└── app/
    ├── kustomization.yaml      # Kustomize configuration
    ├── helmrelease.yaml        # Helm release definition
    ├── ingress.yaml           # Optional UI access (commented)
    └── helm/
        ├── values.yaml         # Longhorn configuration values
        └── kustomizeconfig.yaml # Kustomize configuration
```

## Configuration

### Storage Class
- **Default Storage Class**: `longhorn` (set as cluster default)
- **Replica Count**: 3 (for high availability)
- **Reclaim Policy**: Retain
- **File System**: ext4

### High Availability Features
- **Replica Soft Anti-Affinity**: Enabled for better distribution
- **Zone Soft Anti-Affinity**: Enabled for multi-zone deployments
- **Auto-salvage**: Enabled for automatic recovery
- **Automatic snapshot cleanup**: Enabled

### Performance Optimizations
- **Concurrent replica rebuilds**: Limited to 5 per node
- **Concurrent backup/restore**: Limited to 2 per node
- **Guaranteed CPU**: 12m for engine and replica managers
- **Image pull policy**: if-not-present to reduce registry load

## Accessing the UI

To access the Longhorn UI:

1. **Port Forward** (temporary access):
   ```bash
   kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80
   ```

2. **HTTPRoute** (permanent access):
   - Uncomment the ingress.yaml resource in kustomization.yaml
   - Configure the hostname in ingress.yaml
   - Access via https://longhorn.your-domain.com

## Backup Configuration

To enable backups, configure the backup target in values.yaml:

```yaml
defaultSettings:
  backupTarget: "s3://bucket-name@region/"
  backupTargetCredentialSecret: "longhorn-backup-secret"
```

Then create the backup credentials secret:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: longhorn-backup-secret
  namespace: longhorn-system
type: Opaque
data:
  AWS_ACCESS_KEY_ID: <base64-encoded-access-key>
  AWS_SECRET_ACCESS_KEY: <base64-encoded-secret-key>
```

## Monitoring

The configuration includes ServiceMonitor for Prometheus integration when available.

## Troubleshooting

### Common Issues

1. **"namespaces 'longhorn-system' not found" Error**:
   - This occurs when the Kustomization tries to run in a namespace that doesn't exist yet
   - **Solution**: The Kustomization should be in the `flux-system` namespace and use `targetNamespace: longhorn-system`
   - The HelmRelease will create the namespace with `createNamespace: true`

2. **Pods stuck in Pending**: Check node taints and tolerations
3. **Storage class not available**: Verify HelmRelease status
4. **Performance issues**: Check replica placement and node resources

### Useful Commands

```bash
# Check Longhorn status
kubectl get pods -n longhorn-system

# Check HelmRelease status
kubectl get helmrelease -n longhorn-system

# Check storage classes
kubectl get storageclass

# Check persistent volumes
kubectl get pv
```

## Security Considerations

- All components run with system-cluster-critical priority class
- Proper tolerations for control plane nodes
- Resource limits configured to prevent resource exhaustion
- UI access should be restricted (use HTTPRoute with authentication)

## Upgrade Process

Longhorn is upgraded automatically via Flux when the chart version is updated in helmrelease.yaml. The upgrade process includes:

1. Automatic engine upgrades (can be disabled)
2. Rolling updates with zero downtime
3. Automatic rollback on failure

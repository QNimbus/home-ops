# VolSync - Persistent Volume Backup and Replication

This directory contains the VolSync configuration for automated backup and replication of persistent volumes in the Kubernetes cluster. VolSync works in conjunction with Longhorn and OpenEBS to provide a comprehensive persistent storage and backup solution.

## Overview

VolSync is a Kubernetes operator that enables backup, restore, and migration of persistent volumes using various backends. In this cluster, it's configured to work with:

- **Longhorn**: Primary distributed block storage with replication
- **OpenEBS**: Local path provisioner for cache and temporary storage
- **NFS Server**: External backup destination for long-term data retention

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│    Longhorn     │    │     OpenEBS     │    │   NFS Server    │
│ (Primary PVs)   │    │  (Cache PVs)    │    │   (Backups)     │
│                 │    │                 │    │                 │
│ • Replicated    │    │ • Local storage │    │ • Long-term     │
│ • Snapshotable  │    │ • Fast cache    │    │ • Off-cluster   │
│ • High perf     │    │ • Temporary     │    │ • Disaster rec  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │     VolSync     │
                    │                 │
                    │ • Restic backend│
                    │ • Scheduled     │
                    │ • Incremental   │
                    │ • Encrypted     │
                    └─────────────────┘
```

## Components

### VolSync Operator

The main operator consists of:
- **Source Controller**: Manages backup sources (ReplicationSource)
- **Destination Controller**: Manages restore destinations (ReplicationDestination)
- **Restic Mover**: Handles backup/restore operations using Restic

### Storage Integration

1. **Primary Storage (Longhorn)**:
   - Provides persistent volumes for applications
   - Creates volume snapshots for consistent backups
   - Storage class: `longhorn`
   - Snapshot class: `longhorn-snapshot-vsc`

2. **Cache Storage (OpenEBS)**:
   - Provides local storage for Restic cache
   - Improves backup performance with local caching
   - Storage class: `openebs-hostpath`

3. **Backup Destination (NFS)**:
   - External NFS server for backup repositories
   - Location: `/mnt/vault/cluster/volsync`
   - Provides off-cluster disaster recovery

## Mutating Admission Policies

This cluster uses Kubernetes Mutating Admission Policies to automatically enhance VolSync jobs. These policies are critical for proper operation and provide several benefits:

### 1. VolSync Mover Jitter Policy (`volsync-mover-jitter`)

**Purpose**: Prevents backup stampede by adding random jitter to job execution.

**How it works**:
- Matches VolSync source jobs (prefix: `volsync-src-`)
- Injects an init container that sleeps for 0-10 random seconds
- Spreads backup execution across time to reduce resource contention

**Why it's required**:
- Multiple applications backing up simultaneously can overwhelm storage I/O
- Prevents resource conflicts during scheduled backup windows
- Improves overall cluster stability during backup operations

```yaml
# Adds random jitter init container to VolSync source jobs
initContainers:
- name: jitter
  image: ghcr.io/home-operations/busybox:1.37.0
  command: ["sh", "-c", "SLEEP_TIME=$(shuf -i 0-10 -n 1); echo \"Sleeping for $SLEEP_TIME seconds\"; sleep $SLEEP_TIME"]
```

### 2. VolSync Mover NFS Policy (`volsync-mover-nfs`)

**Purpose**: Automatically mounts NFS backup repository for jobs that don't have it configured.

**How it works**:
- Matches VolSync jobs without existing "repository" volume
- Injects NFS volume mount pointing to backup server
- Ensures all backup jobs have access to the repository

**Why it's required**:
- Eliminates need to manually configure NFS mounts in every ReplicationSource
- Provides consistent backup destination across all applications
- Simplifies backup configuration and reduces configuration drift

```yaml
# Automatically adds NFS repository volume and mount
volumeMounts:
- name: repository
  mountPath: /repository
volumes:
- name: repository
  nfs:
    server: "${NFS_SERVER}"
    path: "/mnt/vault/cluster/volsync"
```

### Policy Benefits

1. **Automation**: Reduces manual configuration requirements
2. **Consistency**: Ensures all backup jobs follow the same patterns
3. **Reliability**: Prevents common configuration errors
4. **Performance**: Optimizes backup scheduling and resource usage
5. **Maintainability**: Centralizes backup infrastructure configuration

## Configuration Structure

```
volsync/
├── README.md                   # This documentation
├── ks.yaml                     # Flux Kustomization
└── app/
    ├── kustomization.yaml      # Kustomize configuration
    ├── helmrelease.yaml        # VolSync operator deployment
    └── mutatingadmissionpolicy.yaml  # Admission policies for automation
```

## How Applications Use VolSync

Applications can use VolSync by including the VolSync component in their Kustomization:

### 1. Include the Component

```yaml
# In app/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
components:
  - ../../../components/volsync
```

### 2. Configure Environment Variables

```yaml
# In app/kustomization.yaml
configurations:
  - ../../components/common/kustomization.yaml
configMapGenerator:
  - name: volsync-env
    literals:
      - APP=my-app
      - VOLSYNC_CLAIM=my-app-data
      - VOLSYNC_CACHE_CAPACITY=5Gi
      - APP_UID=1000
      - APP_GID=1000
```

### 3. Automatic Resources Created

The component automatically creates:
- **ExternalSecret**: Retrieves Restic repository credentials from 1Password
- **ReplicationSource**: Configures backup schedule and retention
- **PVC**: Creates cache volume for Restic operations

## Default Backup Configuration

- **Schedule**: Hourly backups (`0 * * * *`)
- **Retention**:
  - Hourly: 24 snapshots
  - Daily: 7 snapshots
- **Prune**: Every 7 days
- **Method**: Snapshot-based for consistency
- **Encryption**: All backups encrypted with Restic

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `APP` | (required) | Application name for backup repository |
| `VOLSYNC_CLAIM` | `${APP}` | PVC name to backup |
| `VOLSYNC_CACHE_CAPACITY` | `5Gi` | Cache volume size |
| `VOLSYNC_CACHE_ACCESSMODES` | `ReadWriteOnce` | Cache volume access mode |
| `VOLSYNC_STORAGECLASS` | `longhorn` | Primary storage class |
| `VOLSYNC_SNAPSHOTCLASS` | `longhorn-snapshot-vsc` | Snapshot class |
| `VOLSYNC_CACHE_SNAPSHOTCLASS` | `openebs-hostpath` | Cache storage class |
| `VOLSYNC_COPYMETHOD` | `Snapshot` | Backup method |
| `APP_UID` | `4000` | User ID for mover pod |
| `APP_GID` | `4000` | Group ID for mover pod |

## Monitoring and Troubleshooting

### Check VolSync Status

```bash
# Check all VolSync resources
kubectl get replicationsource,replicationdestination -A

# Check specific backup status
kubectl describe replicationsource <app-name> -n <namespace>

# View backup job logs
kubectl logs job/volsync-src-<app-name> -n <namespace>
```

### Common Issues

1. **Backup Jobs Failing**:
   - Check if mutating admission policies are running
   - Verify NFS server connectivity
   - Ensure Restic repository credentials are available

2. **Resource Conflicts**:
   - Jitter policy should prevent this
   - Check if multiple large backups are running simultaneously

3. **Cache Issues**:
   - Verify OpenEBS storage class is available
   - Check cache PVC status and capacity

### Admission Policy Status

```bash
# Check if policies are active
kubectl get mutatingadmissionpolicy

# Verify policy bindings
kubectl get mutatingadmissionpolicybinding

# Check policy application logs
kubectl logs deployment/kube-apiserver -n kube-system | grep -i "admission"
```

## Security

- **Encryption**: All backups encrypted at rest using Restic
- **Credentials**: Repository passwords stored in 1Password and synced via External Secrets
- **Network**: NFS traffic within trusted network
- **Access**: Backup jobs run with minimal required privileges

## Disaster Recovery

To restore from backup:

1. **Create ReplicationDestination** in target cluster
2. **Point to same NFS repository** with appropriate credentials
3. **Specify target PVC** for restoration
4. **VolSync will restore** the latest or specified snapshot

This architecture ensures that persistent data is automatically backed up to external storage while maintaining high performance for running applications through the Longhorn + OpenEBS combination.

## Bootstrap Process for New Applications

When a kustomization including the VolSync component is applied for the first time and no PVC exists yet, the following bootstrap process occurs:

### 1. Initial Resource Creation

The VolSync component creates these resources in order:

1. **ExternalSecret**: Retrieves Restic repository credentials from 1Password
2. **ReplicationDestination** (bootstrap): Named `${APP}-bootstrap` with manual trigger
3. **PVC**: References the ReplicationDestination as a data source

### 2. Bootstrap Flow

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ ExternalSecret  │    │ ReplicationDest │    │      PVC        │
│                 │───▶│   (bootstrap)   │───▶│                 │
│ • Credentials   │    │ • Manual trigger│    │ • dataSourceRef │
│ • From 1Pass    │    │ • Restore once  │    │ • Waits for RD  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │  Restore Job    │
                       │                 │
                       │ • Checks backup │
                       │ • Creates volume│
                       │ • Restores data │
                       └─────────────────┘
```

### 3. What Happens in Each Scenario

#### Scenario A: Backup Repository Exists
If a Restic repository already exists for the application:

1. **ReplicationDestination** is created with `manual: restore-once` trigger
2. **VolSync** automatically starts a restore job
3. **Restore job** downloads the latest backup from NFS/Restic repository
4. **PVC** is populated with restored data
5. **ReplicationSource** begins regular scheduled backups

#### Scenario B: No Backup Repository Exists
If no backup repository exists (truly new application):

1. **ReplicationDestination** is created but has no backup to restore from
2. **PVC** is created but remains empty (no data source available)
3. **Application** starts with an empty volume
4. **ReplicationSource** creates a new Restic repository on first backup
5. **Subsequent backups** save application data to the repository

### 4. Bootstrap Configuration

The bootstrap ReplicationDestination has specific settings:

```yaml
spec:
  trigger:
    manual: restore-once  # Only triggers once, not on schedule
  restic:
    # ... same configuration as ReplicationSource
    capacity: "${VOLSYNC_CAPACITY:-1Gi}"  # Creates PVC of specified size
    cleanupCachePVC: true    # Cleans up temporary cache after restore
    cleanupTempPVC: true     # Cleans up temporary PVCs
    enableFileDeletion: true # Allows file deletions during restore
```

### 5. Monitoring Bootstrap Process

```bash
# Check if bootstrap ReplicationDestination exists
kubectl get replicationdestination ${APP}-bootstrap -n <namespace>

# Monitor bootstrap restore job
kubectl get jobs -n <namespace> | grep volsync-dst

# Check bootstrap job logs
kubectl logs job/volsync-dst-${APP}-bootstrap -n <namespace>

# Verify PVC was created and bound
kubectl get pvc ${APP} -n <namespace>
```

### 6. Common Bootstrap Issues

1. **PVC Stuck in Pending**:
   - ReplicationDestination may be failing to restore
   - Check if backup repository exists and is accessible
   - Verify NFS server connectivity

2. **Bootstrap Job Fails**:
   - Repository credentials may be incorrect
   - NFS mount issues in backup jobs
   - Check admission policies are working

3. **Application Won't Start**:
   - PVC may not be bound yet
   - Wait for bootstrap process to complete
   - Check application pod events

### 7. Best Practices

- **Wait for Bootstrap**: Don't start applications until PVC is bound
- **Monitor First Deployment**: Watch bootstrap logs for new applications
- **Backup Verification**: Verify first backup completes successfully
- **Repository Management**: Use consistent naming for backup repositories

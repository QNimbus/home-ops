# CloudNative-PG Backup Restore Process

This document outlines the process for restoring CloudNative-PG backups from both S3 storage and local NFS backups.

## Backup Types

### 1. S3 Binary Backups (Primary Method)
- **Format**: CloudNative-PG native binary backups with WAL files
- **Location**: Storj S3 bucket (`s3://cloudnative-pg`)
- **Restore Method**: CloudNative-PG recovery mechanism
- **Advantages**: Point-in-time recovery, faster restore, native integration

### 2. Local SQL Dump Backups (Fallback Method)
- **Format**: SQL dumps created by `postgres-backup-local`
- **Location**: NFS storage at `${CLOUDNATIVE_PG_BACKUP_PATH}/Database`
- **Restore Method**: Manual SQL restoration
- **Advantages**: Human-readable, works when S3 is unavailable

## S3 Backup Restore

### Problem

CloudNative-PG backup restore fails with "Expected empty archive" error when the WAL archive location is not empty. This occurs because:

1. Current cluster backs up to the same S3 location it's trying to restore from
2. CloudNative-PG expects a clean WAL archive during recovery
3. The S3 folder structure needs to be reorganized to separate current and backup data

## S3 Backup Solution

### Manual Process

1. **Rename S3 folder structure** - Move current backup data to a different folder name
2. **Update cluster configuration** - Point recovery source to the renamed folder
3. **Apply configuration** - Restart the recovery process

### Using the Script

The `scripts/s3-folder-rename.sh` script automates the S3 folder renaming process.

#### Basic Usage

```bash
# Rename postgres-v17 to postgres-v17-backup
./scripts/s3-folder-rename.sh postgres-v17 postgres-v17-backup

# Rename and remove source folder after successful copy
./scripts/s3-folder-rename.sh -r postgres-v17 postgres-v17-backup

# With verbose output
./scripts/s3-folder-rename.sh -v postgres-v17 postgres-v17-backup
```

#### Custom Configuration

```bash
# Use different bucket
./scripts/s3-folder-rename.sh -b s3://my-bucket postgres-v17 postgres-v17-backup

# Use different S3 endpoint (for non-Storj providers)
./scripts/s3-folder-rename.sh -e https://s3.amazonaws.com postgres-v17 postgres-v17-backup
```

## CloudNative-PG Configuration

### Recovery Configuration

In your `cluster.yaml`, ensure the recovery configuration points to the backup folder:

```yaml
bootstrap:
  recovery:
    source: &previousCluster postgres-v17-backup

externalClusters:
  - name: *previousCluster
    barmanObjectStore:
      <<: *barmanObjectStore
      serverName: *previousCluster
```

### S3 Configuration

The backup configuration should use the current cluster name:

```yaml
backup:
  barmanObjectStore: &barmanObjectStore
    destinationPath: "s3://cloudnative-pg"
    endpointURL: "https://gateway.storjshare.io"
    serverName: *currentCluster  # This creates postgres-v17/ folder
```

## Process Flow

1. **Current state**: Cluster `postgres-v17` backs up to `s3://cloudnative-pg/postgres-v17/`
2. **Rename folder**: Move `postgres-v17/` to `postgres-v17-backup/`
3. **Configure recovery**: Point recovery source to `postgres-v17-backup`
4. **Apply configuration**: Cluster starts recovery from backup data
5. **New backups**: Once recovered, cluster creates new `postgres-v17/` folder for ongoing backups

## When to Use Each Method

### Use S3 Binary Backup When:
- ✅ S3 storage is accessible
- ✅ You need point-in-time recovery
- ✅ You want the fastest restore process
- ✅ Binary backups are intact and recent

### Use Local SQL Backup When:
- ✅ S3 is unavailable (network issues, outage)
- ✅ S3 backups are corrupted or missing
- ✅ You need to inspect/modify data before restore
- ✅ Migrating to different cluster configuration
- ✅ S3 credentials are compromised/lost

## Prerequisites (S3 Method)

- AWS CLI configured with S3 credentials
- Kubernetes access to the CloudNative-PG cluster
- S3 bucket with existing backup data

## Troubleshooting

### S3 Backup Issues

#### Script Errors

- **"Source folder does not exist"**: Verify the folder name and S3 credentials
- **"Target folder already exists"**: Choose a different target name or remove existing folder
- **"AWS CLI not found"**: Install AWS CLI or ensure it's in PATH

#### CloudNative-PG Errors

- **"Expected empty archive"**: Run the folder rename process
- **"Cannot find backup"**: Verify the `externalClusters.serverName` matches the backup folder name
- **"Access denied"**: Check S3 credentials in the `cloudnative-pg-secret`

### Local Backup Issues

Refer to the "Troubleshooting Local Restore" section above for local backup specific issues.

## GitOps Integration

This process follows GitOps principles:

1. **Infrastructure as Code**: Cluster configuration is managed in Git
2. **Declarative**: Define desired state in YAML manifests
3. **Automated**: Script automates the operational S3 tasks
4. **Auditable**: All changes are tracked in version control

The hint for this solution was already present in the cluster.yaml comment:
```yaml
# Recovers from the latest S3 backup (after moving/renaming the 'currentCluster' folder to 'previousCluster' in the bucket!)
```

## Local Backup Restore (Fallback Method)

When S3 backups are unavailable (network issues, S3 outage, corrupted backups), you can restore from local SQL dump backups.

### Prerequisites
- NFS access to backup location (`${CLOUDNATIVE_PG_BACKUP_PATH}/Database`)
- SQL dump files created by `postgres-backup-local` container
- Kubernetes cluster access

### Process Overview

1. **Scale Down Applications** (Prevent data corruption)
2. **Choose Restore Strategy** (Fresh cluster vs in-place)
3. **Restore SQL Dump** (Manual restoration process)
4. **Validate and Resume** (Verify data and restart apps)

### Step-by-Step Process

#### 1. Scale Down Applications
```bash
# Stop applications that use the database
kubectl scale deployment <app-deployments> --replicas=0 -n <namespaces>

# Verify applications are stopped
kubectl get pods -A | grep <app-names>
```

#### 2. Choose Restore Strategy

##### Option A: Fresh Cluster Restore (Recommended)
Creates a new cluster and restores data to it.

```bash
# Delete existing cluster
kubectl delete cluster postgres-v17 -n database

# Wait for complete cleanup
kubectl get pods -n database
```

Modify your `cluster.yaml` to use `initdb` instead of recovery:
```yaml
bootstrap:
  initdb:
    database: postgres
    owner: postgres
    secret:
      name: cloudnative-pg-bootstrap-secret
# Comment out the recovery section:
# recovery:
#   source: postgres-v17-backup
```

Apply the configuration:
```bash
kubectl apply -f kubernetes/apps/database/cloudnative-pg/cluster/cluster.yaml
```

##### Option B: In-Place Restore
Restores to existing running cluster (higher risk).

#### 3. Restore SQL Dump

##### Method 1: Using a Kubernetes Job (Recommended)

Create a restore job manifest:
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: postgres-restore-job
  namespace: database
spec:
  template:
    spec:
      containers:
      - name: restore
        image: postgres:17
        command:
        - /bin/bash
        - -c
        - |
          echo "Starting restore from backup..."

          # Find the latest backup
          LATEST_BACKUP=$(ls -t /mnt/backups/Database/*.sql | head -1)
          echo "Using backup: $LATEST_BACKUP"

          # Drop existing data (optional - use with caution)
          # psql -h "$POSTGRES_HOST" -U postgres -d postgres -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

          # Restore the backup
          psql -h "$POSTGRES_HOST" -U postgres -d postgres -f "$LATEST_BACKUP"

          echo "Restore completed"
        env:
        - name: POSTGRES_HOST
          value: "postgres-v17-rw.database.svc.cluster.local"
        - name: PGPASSWORD
          valueFrom:
            secretKeyRef:
              name: cloudnative-pg-secret
              key: password
        volumeMounts:
        - name: backups
          mountPath: /mnt/backups
          readOnly: true
      volumes:
      - name: backups
        nfs:
          server: "${NFS_SERVER}"
          path: "${CLOUDNATIVE_PG_BACKUP_PATH}"
      restartPolicy: Never
  backoffLimit: 3
```

Apply the job:
```bash
kubectl apply -f restore-job.yaml

# Monitor the job
kubectl logs job/postgres-restore-job -n database -f

# Check job status
kubectl get jobs -n database
```

##### Method 2: Direct psql Restore

```bash
# Run temporary pod with psql
kubectl run postgres-restore --rm -i --tty \
  --image=postgres:17 \
  --restart=Never \
  --env="PGPASSWORD=$(kubectl get secret cloudnative-pg-secret -n database -o jsonpath='{.data.password}' | base64 -d)" \
  -- bash

# Inside the pod, mount NFS and restore
# (This is more complex - use Method 1 instead)
```

#### 4. Post-Restore Tasks

##### Verify Data Integrity
```bash
# Connect to database and verify
kubectl exec -it postgres-v17-1 -n database -- psql -U postgres

# Check tables and data
\dt
SELECT count(*) FROM <important_table>;
\q
```

##### Update Sequences (if needed)
Some sequences might need adjustment after restore:
```sql
-- Example: Reset sequence to current max value
SELECT setval('users_id_seq', (SELECT MAX(id) FROM users));
```

##### Restart Applications
```bash
# Scale applications back up
kubectl scale deployment <app-deployments> --replicas=<original-count> -n <namespaces>

# Monitor application startup
kubectl get pods -A | grep <app-names>
```

### Local Backup Considerations

#### Advantages
- ✅ Works when S3 is unavailable
- ✅ Human-readable SQL format
- ✅ Can be inspected/modified before restore
- ✅ Portable across different PostgreSQL versions

#### Limitations
- ❌ No point-in-time recovery
- ❌ Slower restore process
- ❌ Requires manual intervention
- ❌ May have data loss (last backup to incident time)
- ❌ Sequence values might need adjustment

#### Backup File Locations
The `postgres-backup-local` container creates files in this structure:
```
${CLOUDNATIVE_PG_BACKUP_PATH}/Database/
├── daily/
│   ├── postgres-YYYYMMDD.sql
│   └── ...
├── weekly/
│   ├── postgres-YYYYMMDD.sql
│   └── ...
├── monthly/
│   ├── postgres-YYYYMMDD.sql
│   └── ...
└── latest.sql (symlink to most recent)
```

### Troubleshooting Local Restore

#### Common Issues
- **"Connection refused"**: Ensure cluster is running and accessible
- **"Permission denied"**: Check database user permissions
- **"Relation already exists"**: Use `--clean` flag or drop schema first
- **"NFS mount failed"**: Verify NFS server and path
- **"Backup file not found"**: Check NFS mount and file permissions

#### Recovery Commands
```bash
# Check cluster status
kubectl get cluster postgres-v17 -n database

# Check pods
kubectl get pods -n database

# View logs
kubectl logs postgres-v17-1 -n database

# Check NFS mount in job
kubectl exec -it postgres-restore-job-<hash> -n database -- ls -la /mnt/backups/Database/
```

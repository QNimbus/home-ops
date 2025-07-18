# pgAdmin Kustomization

This kustomization deploys pgAdmin 4, a web-based PostgreSQL administration and management tool, using the app-template Helm chart with Flux GitOps.

## Architecture Overview

- **Namespace**: `tools`
- **Chart**: app-template (OCI Repository)
- **Dependencies**: OnePassword store, CloudNative-PG cluster, VolSync

## Persistence & Storage

### Primary Data Volume
- **PVC**: `pgadmin-config` (2Gi)
- **Storage Class**: Longhorn (default)
- **Access Mode**: ReadWriteOnce
- **Backup Strategy**: VolSync replication with restic

### Volume Mounts
- `/var/lib/pgadmin`: Persistent config directory (PVC)
- `/pgadmin4/pgpass`: PostgreSQL password file (Secret mount)
- `/pgadmin4/servers.json`: Server configuration (ConfigMap mount)

## InitContainer Pattern

The `fix-perms` initContainer serves several critical purposes:

1. **File Copying**: Copies configuration files from mounted volumes to the writable persistence volume
2. **Permission Setting**: Sets restrictive permissions (0600) on `pgpass` file
3. **Ownership Correction**: Ensures files are owned by the pgAdmin user (UID/GID 5050)

```yaml
initContainers:
  fix-perms:
    # Copies files and sets proper permissions for pgAdmin security requirements
    command:
        - /bin/sh
        - -c
        - |
        cp /pgadmin4/pgpass /var/lib/pgadmin/pgpass
        cp /pgadmin4/servers.json /var/lib/pgadmin/servers.json
        chmod 0600 /var/lib/pgadmin/pgpass
        chmod 0600 /var/lib/pgadmin/servers.json
        chown 5050:5050 /var/lib/pgadmin/pgpass
        chown 5050:5050 /var/lib/pgadmin/servers.json
```

**Why this is needed**: ConfigMaps and Secrets are mounted read-only, but pgAdmin requires write access to its config directory and specific file permissions for security.

## Security Patterns

### External Secrets Integration
- **Secret Store**: OnePassword ClusterSecretStore
- **Refresh Interval**: 5 minutes
- **Secret Contents**:
  - `pgadmin_DEFAULT_EMAIL`: Admin login email
  - `pgadmin_DEFAULT_PASSWORD`: Admin login password
  - `pgpass`: PostgreSQL connection credentials

### Security Context
- **User/Group**: 5050 (non-root)
- **fsGroup**: 5050 with `OnRootMismatch` policy
- **File Permissions**: Restricted (0600) for sensitive files

## Configuration Management

### Server Configuration
- **Source**: Static ConfigMap generated from `config/servers.json`
- **Template Variables**: Uses `${DB_SERVER}` substitution from cluster settings
- **Features**: Pre-configured connection to CloudNative-PG cluster

### Environment Variables
- **Console Log Level**: 30 (SQL)
- **Enhanced Cookie Protection**: Disabled for internal use
- **Upgrade Check**: Disabled
- **PostFix**: Disabled

## Networking & Routing

### Internal Access
- **Route**: `pgadmin.${DOMAIN_APP}` (internal domain)
- **Gateway**: Uses internal gateway with HTTPS
- **Port**: 5050 (non-privileged)

### Health Checks
- **Endpoint**: `/misc/ping`
- **Probes**: Both liveness and readiness using HTTP GET
- **Timing**: 5s initial delay, 10s period, 1s timeout

## VolSync Backup Strategy

### Configuration Variables
- `VOLSYNC_UID/GID`: 5050 (matches pgAdmin user)
- `VOLSYNC_CLAIM`: pgadmin-config
- `VOLSYNC_CAPACITY`: 2Gi

### Backup Pattern
1. **ReplicationSource**: Creates periodic snapshots of the config volume
2. **ReplicationDestination**: Enables restoration from backups
3. **Bootstrap**: PVC created from ReplicationDestination for disaster recovery

## Resource Management

### Compute Resources
- **Requests**: 10m CPU, 150Mi memory
- **Limits**: 384Mi memory
- **Strategy**: Recreate (single replica, persistent storage)

### Monitoring
- **ServiceMonitor**: Prometheus metrics collection enabled
- **Reloader**: Automatic restart on secret/configmap changes

## Deployment Dependencies

The kustomization waits for these dependencies before deploying:

1. **onepassword-store**: Required for secret management
2. **cloudnative-pg-cluster**: Database cluster must be ready
3. **volsync**: Backup/restore infrastructure

## Key Flux Patterns Used

- **PostBuild Substitution**: Dynamic variable replacement from cluster settings
- **Component Integration**: VolSync component for backup functionality
- **Dependency Management**: Explicit `dependsOn` for ordered deployment
- **Secret Management**: External Secrets Operator integration
- **GitOps**: Declarative configuration with Git as source of truth

## Troubleshooting

### Common Issues
- **Permission Errors**: Check initContainer logs for file copy/permission operations
- **Database Connection**: Verify CloudNative-PG cluster status and secret values
- **Backup Issues**: Check VolSync ReplicationSource/Destination status
- **Route Access**: Verify internal gateway and DNS resolution

### Useful Commands
```bash
# Check pgadmin status
flux get kustomizations -n tools pgadmin

# View application logs
kubectl logs -n tools deployment/pgadmin -c app

# Check initContainer execution
kubectl logs -n tools deployment/pgadmin -c fix-perms

# Verify secrets
kubectl get secret pgadmin-secret -n tools -o yaml
```

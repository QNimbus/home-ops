# Checkmate Deployment

This directory contains the Checkmate website and API monitoring application deployed using FluxCD GitOps.

## Architecture Overview

- **Application**: Combined frontend/backend Checkmate container using app-template
- **Database**: Dedicated MongoDB instance using Bitnami chart
- **Cache**: Dedicated Redis instance using Bitnami chart
- **Secrets**: External Secrets Operator with OnePassword integration
- **Storage**: VolSync for configuration persistence

## Components

### 1. Checkmate Application (`helmrelease.yaml`)
- **Image**: `ghcr.io/bluewave-labs/checkmate-backend-mono:latest`
- **Port**: 52345 (combined FE/BE)
- **Strategy**: Recreate (for persistent storage)
- **Resources**: 256Mi request, 1Gi limit

### 2. MongoDB (`helmrelease-mongodb.yaml`)
- **Chart**: Bitnami MongoDB 16.5.3
- **Configuration**: Standalone architecture
- **Storage**: 8Gi Longhorn persistent volume
- **Authentication**: Enabled with dedicated user/database

### 3. Redis (`helmrelease-redis.yaml`)
- **Chart**: Bitnami Redis 20.6.0
- **Configuration**: Standalone architecture (no replica)
- **Storage**: 2Gi Longhorn persistent volume
- **Authentication**: Enabled with password

## OnePassword Setup

Create a new entry in OnePassword with the title "checkmate" containing:

```
JWT_SECRET: <random-32-character-string>
MONGODB_ROOT_PASSWORD: <strong-password>
MONGODB_PASSWORD: <strong-password>
REDIS_PASSWORD: <strong-password>
PAGESPEED_API_KEY: <optional-google-pagespeed-api-key>
```

### Generating Secrets

```bash
# JWT Secret (32 characters)
openssl rand -hex 16

# Strong passwords
openssl rand -base64 24
```

## Access URLs

- **Internal**: `https://checkmate.${DOMAIN_APP}` (Gateway API route)
- **Tailscale**: `https://checkmate` (Tailscale ingress)

## Migration to Cluster Databases

To migrate to cluster-wide Redis (Dragonfly) and MongoDB:

1. **Update externalsecret.yaml**:
   - Change `DB_CONNECTION_STRING` to point to cluster MongoDB
   - Change `REDIS_URL` to `redis://:${DRAGONFLY_PASSWORD}@${DRAGONFLY_SERVER}:6379/0`
   - Remove MongoDB and Redis specific secrets

2. **Update kustomization.yaml**:
   - Remove `helmrelease-mongodb.yaml` and `helmrelease-redis.yaml`
   - Add dependencies on cluster database operators

3. **Update ks.yaml**:
   - Add `dependsOn` for `database/dragonfly-cluster`
   - Add `dependsOn` for your MongoDB operator when available

4. **Update helmrelease.yaml**:
   - Remove `dependsOn` for checkmate-mongodb and checkmate-redis
   - Update resource requests if needed

## Troubleshooting

### Check Application Status
```bash
# Check pods
kubectl get pods -n observability -l app.kubernetes.io/name=checkmate

# Check logs
kubectl logs -n observability -l app.kubernetes.io/name=checkmate -f

# Check database connectivity
kubectl exec -n observability -it <checkmate-pod> -- curl localhost:52345
```

### Check Database Status
```bash
# MongoDB
kubectl get pods -n observability -l app.kubernetes.io/name=mongodb
kubectl logs -n observability -l app.kubernetes.io/name=mongodb

# Redis
kubectl get pods -n observability -l app.kubernetes.io/name=redis
kubectl logs -n observability -l app.kubernetes.io/name=redis
```

### Common Issues

1. **Database Connection Errors**: Verify secrets and service names
2. **Frontend Not Loading**: Check `UPTIME_APP_API_BASE_URL` configuration
3. **Authentication Issues**: Verify `JWT_SECRET` is set correctly

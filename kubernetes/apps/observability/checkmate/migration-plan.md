# Migration Plan: Switch to Official Checkmate Helm Chart

## Current Issues with app-template Approach:
1. Complex environment variable substitution not working properly
2. Nginx configuration overrides required
3. initContainer patterns for file permissions
4. Manual service discovery setup
5. Complex volume mounting and file copying
6. Extensive customization that's hard to maintain

## Benefits of Official Helm Chart:
1. **Purpose-built**: Designed specifically for Checkmate
2. **Tested**: Pre-validated by the Checkmate team
3. **Simple**: Clean configuration with sensible defaults
4. **Complete**: Includes all necessary components
5. **Maintainable**: Updates from upstream automatically

## Migration Steps:

### 1. Create GitRepository for Checkmate Charts
```bash
kubectl apply -f /workspaces/home-ops/kubernetes/apps/observability/checkmate/app/gitrepository.yaml
```

### 2. Update ExternalSecret to match new requirements
- Keep existing 1Password integration
- Ensure all required secrets are mapped correctly

### 3. Create Gateway API Routes
- Replace current route configuration with simpler setup
- Use the natural service names from the official chart

### 4. Deploy with Official Chart
- Replace current helmrelease.yaml with helmrelease-official.yaml
- Monitor deployment and verify functionality

### 5. Cleanup
- Remove complex initContainer configurations
- Remove custom nginx configurations
- Simplify persistence setup

## Configuration Differences:

### Current (app-template):
- 200+ lines of complex YAML
- Custom initContainers for file copying
- Manual nginx configuration
- Complex environment variable handling
- Custom volume mounting

### Official Chart:
- ~50 lines of clean configuration
- Built-in service discovery
- Proper environment variable handling
- Tested deployment patterns
- Integrated ingress configuration

## Integration Points:

### External Secrets:
- Continue using 1Password integration
- Map secrets to the format expected by official chart

### Database:
- Use bundled MongoDB initially
- Can migrate to external MongoDB later if needed

### Redis:
- Disable bundled Redis
- Point to existing Dragonfly instance

### Ingress:
- Disable built-in ingress
- Use Gateway API routes as before

## Recommendation:
**Switch immediately** - the official chart will solve our current environment variable issues and provide a much more maintainable solution.

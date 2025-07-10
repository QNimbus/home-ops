# AI Agent Instructions for Home Operations Repository

This document provides comprehensive guidelines for AI coding assistants working with this FluxCD GitOps repository. Follow these instructions to generate appropriate code, configurations, and documentation that aligns with the established patterns and best practices.

## Repository Context

This is a Kubernetes homelab GitOps repository managed by FluxCD v2. The infrastructure follows enterprise-grade patterns adapted for home use, emphasizing:

- **Declarative configuration** - All cluster state defined in YAML manifests
- **GitOps workflow** - Git as the single source of truth for cluster configuration
- **Security-first approach** - External secrets management with 1Password Connect and SOPS encryption
- **Dependency management** - Explicit dependencies between applications using Flux Kustomizations
- **Infrastructure as Code** - Reproducible, version-controlled infrastructure

## Core Technologies and Patterns

### Primary Stack
- **Kubernetes**: Container orchestration platform
- **FluxCD v2**: GitOps continuous delivery operator
- **Kustomize**: Kubernetes native configuration management
- **Helm**: Package manager for complex applications
- **External Secrets Operator**: Kubernetes secrets injection from external systems
- **SOPS**: Secrets encryption for Git storage
- **Talos Linux**: Immutable Kubernetes-focused operating system

### Architecture Patterns
- **Namespace isolation**: Applications grouped by function/category
- **Dependency ordering**: Using Flux `dependsOn` for controlled deployment sequences
- **Split-horizon DNS**: Internal (.home.arpa) and external DNS management
- **Multi-source secrets**: SOPS-encrypted files and 1Password Connect integration

## Code Generation Guidelines

### YAML Manifest Standards

When generating Kubernetes or FluxCD YAML manifests:

```yaml
---
# yaml-language-server: $schema=<appropriate-schema-url>
apiVersion: <api-version>
kind: <resource-kind>
metadata:
  name: <resource-name>
  namespace: <target-namespace>
spec:
  # Use 2-space indentation consistently
  # Include all required fields
  # Follow Kubernetes naming conventions
```

**Key Requirements:**
- **Indentation**: Always use 2 spaces for YAML
- **Document separator**: Include `---` at the top of each YAML file
- **Schema validation**: Add appropriate `yaml-language-server` schema comments
- **Naming conventions**: Use kebab-case for resource names, lowercase for namespaces
- **Namespace specification**: Always specify target namespace explicitly

### FluxCD Resource Patterns

#### Kustomization Resources
```yaml
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: <app-name>
  namespace: flux-system
spec:
  interval: 10m
  path: ./kubernetes/apps/<namespace>/<app-name>
  prune: true
  sourceRef:
    kind: GitRepository
    name: home-ops
  # Include dependsOn when application requires other services
  dependsOn:
    - name: <dependency-kustomization>
  # Add postBuild for variable substitution if needed
  postBuild:
    substitute: {}
    substituteFrom: []
```

#### HelmRelease Resources
```yaml
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: <app-name>
spec:
  interval: 30m
  chart:
    spec:
      chart: <chart-name>
      version: <chart-version>
      sourceRef:
        kind: HelmRepository
        name: <repo-name>
        namespace: flux-system
  install:
    createNamespace: true
    remediation:
      retries: 3
  upgrade:
    cleanupOnFail: true
    remediation:
      retries: 3
  values:
    # Application-specific values
```

### Directory Structure Conventions

When creating new applications, follow this structure:

```
kubernetes/apps/<namespace>/<app-name>/
├── kustomization.yaml          # Namespace and flux kustomization
├── <app-name>/
│   ├── helmrelease.yaml       # or deployment.yaml for plain manifests
│   ├── externalsecret.yaml    # if secrets are required
│   └── kustomization.yaml     # application resources
```

### Secret Management Patterns

#### External Secrets (Preferred)
For secrets stored in 1Password:

```yaml
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: <app-name>-secret
spec:
  refreshInterval: 15m
  secretStoreRef:
    name: onepassword-connect
    kind: SecretStore
  target:
    name: <app-name>-secret
    creationPolicy: Owner
    template:
      engineVersion: v2
      data:
        KEY_NAME: "{{ .key_name }}"
  dataFrom:
    - extract:
        key: <1password-item-name>
```

#### SOPS Encryption
For secrets that must be stored in Git:
- Use `.sops.yaml` configuration file in repository root
- Encrypt with AGE keys only
- Follow naming pattern: `<resource-name>.sops.yaml`

### Commit Message Format

Use conventional commit format:
```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

**Types:**
- `feat`: New feature or capability
- `fix`: Bug fix or correction
- `docs`: Documentation changes
- `refactor`: Code restructuring without behavior change
- `chore`: Maintenance tasks
- `ci`: CI/CD pipeline changes

**Scopes (examples):**
- `apps`: Application deployments
- `infra`: Infrastructure components
- `security`: Security-related changes
- `monitoring`: Observability stack
- `network`: Networking configuration

### Testing and Validation

Before committing any changes:

1. **Validate YAML syntax**:
   ```bash
   find kubernetes/ -name "*.yaml" -exec yamllint {} \;
   ```

2. **Test Kustomize builds**:
   ```bash
   flux build kustomization <name> --path ./kubernetes/apps/<namespace>/<app>
   ```

3. **Preview changes**:
   ```bash
   flux diff kustomization <name> --path ./kubernetes/apps/<namespace>/<app>
   ```

4. **Verify dependencies**:
   - Ensure `dependsOn` references exist and are correct
   - Check that prerequisite resources are ready

## Application-Specific Guidelines

### New Application Deployment Checklist

When adding a new application:

1. **Namespace organization**: Place in appropriate category namespace
2. **Dependencies**: Identify and declare all dependencies using `dependsOn`
3. **Secrets**: Use External Secrets Operator for sensitive data
4. **Networking**: Configure appropriate ingress class (`internal` or `external`)
5. **Storage**: Use appropriate storage class for persistent volumes
6. **Resource limits**: Set appropriate CPU/memory requests and limits
7. **Health checks**: Configure readiness and liveness probes
8. **Backup strategy**: Include VolSync configuration if data persistence required

### Common Dependency Patterns

- **External Secrets**: Most applications depend on `onepassword-connect`
- **Database applications**: Often depend on `cloudnative-pg` or other database operators
- **Ingress**: Applications with ingress depend on `cilium` and `cert-manager`
- **Monitoring**: Observability components depend on `kube-prometheus-stack`

## Error Handling and Troubleshooting

### Common Issues and Solutions

1. **CRD Timing Issues**: Use separate Kustomizations for CRDs and applications
2. **Secret Not Found**: Ensure External Secret is ready before dependent applications
3. **Image Pull Errors**: Verify image registry and authentication
4. **Dependency Loops**: Check `dependsOn` chains for circular references

### Debugging Commands

Generate these commands for troubleshooting scenarios:

```bash
# Check Flux status
flux get all -A --status-selector ready=false

# View Kustomization events
kubectl describe kustomization <name> -n flux-system

# Check application logs
kubectl logs -l app.kubernetes.io/name=<app-name> -n <namespace>

# Validate secrets
kubectl get externalsecrets -A
kubectl describe externalsecret <name> -n <namespace>
```

## Markdown and Documentation Standards

### Formatting Rules
- **Indentation**: Use 4 spaces for nested lists
- **Line breaks**: Trailing whitespace allowed for explicit line breaks
- **Code blocks**: Specify language for syntax highlighting
- **Links**: Use descriptive text, avoid raw URLs in content

### Documentation Patterns
- Include purpose and context for any new components
- Provide troubleshooting steps for complex configurations
- Reference relevant official documentation
- Explain dependency relationships and timing requirements

## Pull Request Guidelines

When generating pull request content:

### Summary Format
```markdown
## Summary
Brief description of changes made.

## Changes
- List major modifications
- Include any new dependencies
- Note breaking changes

## Testing
- [ ] YAML validation passed
- [ ] Flux build successful
- [ ] Dependencies verified
- [ ] No conflicting resources

## Notes
Additional context or considerations.
```

### Pre-commit Verification
Always include this verification step:
```bash
git log -1 --stat
```

This shows the latest commit and affected files, confirming changes were committed correctly.

---

**Remember**: This repository prioritizes reliability and maintainability over complexity. When in doubt, choose the simpler, more explicit approach that clearly expresses intent and dependencies.



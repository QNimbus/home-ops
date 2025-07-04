# External Secrets Operator

This directory contains the External Secrets Operator (ESO) configuration for our GitOps setup using FluxCD. The External Secrets Operator allows us to manage secrets from external systems like 1Password, AWS Secrets Manager, Azure Key Vault, and others by syncing them into Kubernetes secrets.

## Architecture Overview

The External Secrets Operator consists of several key components:
- **External Secrets Controller**: Manages the synchronization of secrets from external stores
- **Custom Resource Definitions (CRDs)**: Defines `ExternalSecret`, `SecretStore`, `ClusterSecretStore`, and related resources
- **Webhook**: Validates External Secrets resources during creation/updates

## Configuration Structure

```
app/
├── README.md                   # This file
├── helmrelease.yaml            # FluxCD HelmRelease definition
├── kustomization.yaml          # Kustomize configuration
└── helm/
    ├── values.yaml             # Helm chart values (generated from upstream)
    └── kustomize-config.yaml   # Kustomize name reference configuration
```

## Helm Values Configuration

The `helm/values.yaml` file contains the default values from the upstream External Secrets Operator Helm chart. This file was generated using the following commands:

```bash
# Add the external-secrets Helm repository
helm repo add external-secrets https://charts.external-secrets.io

# Update repository cache
helm repo update

# Extract default values to local file
helm show values external-secrets/external-secrets > helm/values.yaml

# Clean up (remove repository after extracting values)
helm repo remove external-secrets
```

### Key Configuration Options

The current configuration uses mostly default values with the following notable settings:

- **CRDs Installation**: `installCRDs: true` - Installs CRDs through the Helm chart
- **Leader Election**: `leaderElect: false` - Single instance deployment
- **Image**: Uses the default distroless image from `oci.external-secrets.io/external-secrets/external-secrets`
- **Chart Version**: `0.18.0` as specified in `helmrelease.yaml`

### Customizing Values

To customize the External Secrets Operator configuration:

1. Edit `helm/values.yaml` to modify the desired settings
2. Commit changes to Git
3. FluxCD will automatically reconcile the changes

Common customizations include:
- Enabling specific external secret providers
- Configuring resource limits and requests
- Setting up node selectors or tolerations
- Enabling metrics and monitoring

### Using SOPS Secrets in Values

You can reference SOPS-encrypted secrets in your `helm/values.yaml` file using FluxCD's variable substitution feature:

#### Method 1: Variable Substitution (Recommended)

1. **Create a SOPS secret file** (e.g., `secret.sops.yaml`):
   ```yaml
   apiVersion: v1
   kind: Secret
   metadata:
     name: external-secrets-config
     namespace: external-secrets
   stringData:
     WEBHOOK_TLS_CERT: "LS0tLS1CRUdJTi..."
     CERT_ISSUER_NAME: "letsencrypt-prod"
     AWS_ROLE_ARN: "arn:aws:iam::123456789:role/external-secrets"
   ```

2. **Use variables in `helm/values.yaml`**:
   ```yaml
   webhook:
     extraEnv:
       - name: WEBHOOK_CERT
         value: "${WEBHOOK_TLS_CERT}"

   serviceAccount:
     annotations:
       eks.amazonaws.com/role-arn: "${AWS_ROLE_ARN}"
   ```

3. **Update your Kustomization** to reference the secret:
   ```yaml
   postBuild:
     substituteFrom:
       - name: cluster-secrets
         kind: Secret
       - name: external-secrets-config  # Your SOPS secret
         kind: Secret
   ```

#### Method 2: Direct Secret References

For charts that support `existingSecret` patterns, you can reference SOPS secrets directly:

```yaml
# In values.yaml
auth:
  existingSecret: "my-sops-secret"
  secretKeys:
    username: "username"
    password: "password"
```

The variables are substituted during the FluxCD reconciliation process, ensuring sensitive data remains encrypted in Git.

## FluxCD Integration

### HelmRelease Configuration

The `helmrelease.yaml` defines how FluxCD should deploy External Secrets Operator:

- **Chart Source**: References the `external-secrets` HelmRepository in the `flux-system` namespace
- **Values Source**: Loads values from the `external-secrets-helm-values` ConfigMap
- **Update Interval**: Checks for updates every hour (`interval: 1h`)

### Kustomize Configuration

The `kustomization.yaml` orchestrates the deployment by:

1. **ConfigMap Generation**: Creates a ConfigMap from `helm/values.yaml`
2. **Name References**: Uses `helm/kustomize-config.yaml` to link the ConfigMap to the HelmRelease
3. **Resource Management**: Includes the HelmRelease in the deployment

## Deployment Order and Dependencies

This External Secrets Operator deployment is part of a larger GitOps structure that follows FluxCD best practices:

1. **CRDs First**: The Helm chart installs CRDs automatically (`installCRDs: true`)
2. **Operator Deployment**: The main External Secrets Operator deployment
3. **Secret Stores**: `SecretStore` and `ClusterSecretStore` resources (deployed separately)
4. **External Secrets**: `ExternalSecret` resources that reference the stores (deployed in application namespaces)

## Usage

Once deployed, you can create `SecretStore` and `ExternalSecret` resources to sync secrets from external providers. Example:

```yaml
# SecretStore for 1Password
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: onepassword-store
  namespace: external-secrets
spec:
  provider:
    onepassword:
      connectHost: http://onepassword-connect.external-secrets.svc.cluster.local:8080
      vaults:
        Kubernetes: 1
      auth:
        secretRef:
          connectTokenSecretRef:
            name: onepassword-connect-secrets
            key: token

---
# ExternalSecret that syncs from 1Password
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: test-secret
  namespace: external-secrets
spec:
  refreshInterval: 15s
  secretStoreRef:
    name: onepassword-store
    kind: SecretStore
  target:
    name: my-secret
    creationPolicy: Owner
  data:
  - secretKey: password
    remoteRef:
      key: "AccountName"
      property: "password"
```

## Monitoring and Troubleshooting

To monitor External Secrets Operator:

```bash
# Check ESO pod status
kubectl get pods -n external-secrets

# View ESO logs
kubectl logs -n external-secrets deployment/external-secrets

# Check ExternalSecret status
kubectl get externalsecrets -A

# Describe a specific ExternalSecret for troubleshooting
kubectl describe externalsecret <name> -n <namespace>
```

## Related Documentation

- [External Secrets Operator Documentation](https://external-secrets.io/)
- [FluxCD Helm Controller](https://fluxcd.io/flux/components/helm/)
- [External Secrets with FluxCD GitOps Guide](https://external-secrets.io/latest/examples/gitops-using-fluxcd/)

## Security Considerations

- **RBAC**: The operator runs with minimal required permissions
- **Network Policies**: Consider implementing network policies to restrict ESO communication
- **Secret Encryption**: Ensure external secret stores use encryption in transit and at rest
- **Audit Logging**: Enable Kubernetes audit logging to track secret access

#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}INFO:${NC} $1"
}

log_success() {
    echo -e "${GREEN}SUCCESS:${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}WARNING:${NC} $1"
}

log_error() {
    echo -e "${RED}ERROR:${NC} $1"
}

# Check if required tools are installed
check_prerequisites() {
    log_info "Checking prerequisites..."

    local missing_tools=()

    if ! command -v op &> /dev/null; then
        missing_tools+=("1Password CLI (op)")
    fi

    if ! command -v sops &> /dev/null; then
        missing_tools+=("SOPS")
    fi

    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi

    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        echo "Please install the missing tools before running this script."
        exit 1
    fi

    log_success "All prerequisites found!"
}

# Setup 1Password Connect
setup_onepassword_connect() {
    log_info "Setting up 1Password Connect..."

    read -p "Enter your 1Password account URL (e.g., company.1password.com): " account_url
    read -p "Enter your email: " email
    read -p "Enter vault name or ID for Kubernetes secrets: " vault_name

    log_info "Adding 1Password account..."
    if ! op account add --address "$account_url" --email "$email"; then
        log_error "Failed to add 1Password account"
        exit 1
    fi

    log_info "Signing in to 1Password..."
    if ! op signin -f; then
        log_error "Failed to sign in to 1Password"
        exit 1
    fi

    log_info "Creating Connect server..."
    server_name="Kubernetes-Cluster-$(date +%Y%m%d)"
    if ! op connect server create "$server_name" --vaults "$vault_name"; then
        log_error "Failed to create Connect server"
        exit 1
    fi

    log_info "Creating Connect token..."
    token_name="External-Secrets-$(date +%Y%m%d)"
    connect_token=$(op connect token create "$token_name" --server "$server_name" --vaults "$vault_name")

    if [ -z "$connect_token" ]; then
        log_error "Failed to create Connect token"
        exit 1
    fi

    log_success "1Password Connect setup complete!"
    echo "Connect token: $connect_token"
    echo "Server name: $server_name"
    echo "Vault: $vault_name"

    # Save credentials for next step
    echo "$connect_token" > /tmp/op_connect_token
    echo "$vault_name" > /tmp/op_vault_name

    log_warning "Please save the Connect token securely - it won't be shown again!"
}

# Update SOPS secrets
update_secrets() {
    log_info "Updating SOPS encrypted secrets..."

    # Ensure we're in the repository root
    cd "$(git rev-parse --show-toplevel)" || {
        log_error "Not in a git repository"
        exit 1
    }

    if [ ! -f "/tmp/op_connect_token" ]; then
        read -p "Enter your 1Password Connect token: " connect_token
        echo "$connect_token" > /tmp/op_connect_token
    else
        connect_token=$(cat /tmp/op_connect_token)
    fi

    if [ ! -f "/tmp/op_vault_name" ]; then
        read -p "Enter your vault name or ID: " vault_name
        echo "$vault_name" > /tmp/op_vault_name
    else
        vault_name=$(cat /tmp/op_vault_name)
    fi

    # Check if credentials file exists
    if [ ! -f "1password-credentials.json" ]; then
        log_error "1password-credentials.json not found in current directory"
        log_info "The credentials file should have been created when you ran 'op connect server create'"
        log_info "Look for a file named '1password-credentials.json' in your current directory"
        log_info "If you can't find it, you may need to:"
        log_info "  1. Run 'op connect server create \"Kubernetes Cluster\" --vaults \"<vault-name>\"'"
        log_info "  2. Copy the generated 1password-credentials.json to $(pwd)"
        exit 1
    fi

    credentials_b64=$(base64 -w 0 1password-credentials.json)

    # Update 1Password Connect secret
    log_info "Updating 1Password Connect secret..."
    sops_file="kubernetes/apps/external-secrets/onepassword-connect/app/secret.sops.yaml"

    if [ -f "$sops_file" ]; then
        # Create temporary file in kubernetes directory so SOPS rules apply
        temp_file="kubernetes/temp-secret.sops.yaml"
        cat > "$temp_file" << EOF
---
apiVersion: v1
kind: Secret
metadata:
  name: onepassword-connect-credentials
type: Opaque
stringData:
  1password-credentials.json: "$credentials_b64"
---
apiVersion: v1
kind: Secret
metadata:
  name: onepassword-connect-token
type: Opaque
stringData:
  token: "$connect_token"
EOF

        # Encrypt with SOPS and copy to target location
        if sops --encrypt "$temp_file" > "$sops_file"; then
            log_success "Updated $sops_file"
            # Clean up temporary file
            rm -f "$temp_file"
        else
            log_error "Failed to encrypt secrets with SOPS"
            log_info "Make sure you have a valid .sops.yaml configuration file"
            log_info "Check that your Age key is properly configured"
            rm -f "$temp_file"
            exit 1
        fi
    else
        log_error "$sops_file not found"
    fi

    # Update External Secrets secret
    log_info "External Secrets uses ClusterSecretStore which references the same secret - no separate secret needed"

    # Update ClusterSecretStore vault configuration
    log_info "Updating ClusterSecretStore vault configuration..."
    secretstore_file="kubernetes/apps/external-secrets/external-secrets/app/clustersecretstore.yaml"

    if [ -f "$secretstore_file" ]; then
        # Update vault name in ClusterSecretStore
        sed -i "s/Kubernetes: 1/${vault_name}: 1/" "$secretstore_file"
        log_success "Updated vault name in $secretstore_file"
    else
        log_error "$secretstore_file not found"
    fi

    # Clean up temporary files
    rm -f /tmp/op_connect_token /tmp/op_vault_name

    log_success "All secrets updated successfully!"
}

# Verify deployment
verify_deployment() {
    log_info "Verifying deployment..."

    log_info "Checking if kubectl is configured..."
    if ! kubectl cluster-info &> /dev/null; then
        log_error "kubectl is not configured or cluster is not accessible"
        exit 1
    fi

    log_info "Checking 1Password Connect pods..."
    kubectl get pods -n external-secrets -l app.kubernetes.io/name=onepassword-connect || true

    log_info "Checking External Secrets pods..."
    kubectl get pods -n external-secrets -l app.kubernetes.io/name=external-secrets || true

    log_info "Checking ClusterSecretStore status..."
    kubectl get clustersecretstore onepassword-connect || true

    log_success "Verification complete!"
}

# Main function
main() {
    echo "1Password External Secrets Setup Script"
    echo "======================================"

    case "${1:-}" in
        "prereq")
            check_prerequisites
            ;;
        "setup")
            check_prerequisites
            setup_onepassword_connect
            ;;
        "secrets")
            update_secrets
            ;;
        "verify")
            verify_deployment
            ;;
        "all")
            check_prerequisites
            setup_onepassword_connect
            update_secrets
            log_info "Setup complete! Deploy with Flux and then run './setup-external-secrets.sh verify'"
            ;;
        *)
            echo "Usage: $0 {prereq|setup|secrets|verify|all}"
            echo ""
            echo "Commands:"
            echo "  prereq  - Check if required tools are installed"
            echo "  setup   - Set up 1Password Connect server and token"
            echo "  secrets - Update SOPS encrypted secrets with credentials"
            echo "  verify  - Verify the deployment in Kubernetes"
            echo "  all     - Run setup and secrets (full setup)"
            exit 1
            ;;
    esac
}

main "$@"

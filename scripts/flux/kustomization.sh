#!/usr/bin/env bash

################################################################################
# Flux Kustomization Management Script
################################################################################
#
# Description: Generic script for suspending and resuming Flux Kustomizations
#              Automatically discovers related kustomizations based on the script path.
#
# Author:      Generated for home-ops
# Version:     1.1.0
# Created:     2025-07-01
# Updated:     2025-07-01
#
# Features:    - Auto-discovery of related kustomizations (storage, secrets, etc.)
#              - Suspend/resume Flux Kustomizations
#              - Status checking
#              - Scale down workloads
#              - Verbose output option
#              - Clean, formatted output with progress indicators
#              - Error handling and validation
#
# Usage:       ./kustomization.sh <action> [options]
#
# Examples:    ./kustomization.sh suspend
#              ./kustomization.sh resume
#              ./kustomization.sh status
#              ./kustomization.sh scale
#              ./kustomization.sh suspend --verbose
#
################################################################################

# --- Script Configuration ---
SCRIPT_NAME=$(basename "$0")
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
SCRIPT_VERSION="1.1.0"

# --- Kustomization Configuration ---
# Extract app name and namespace from script path
SCRIPT_PATH_PARTS=(${SCRIPT_DIR//\// })
KUSTOMIZATION_BASE_NAME=""
KUSTOMIZATION_NAMESPACE=""

# Find the app name and namespace from the path structure
for i in "${!SCRIPT_PATH_PARTS[@]}"; do
    if [[ "${SCRIPT_PATH_PARTS[i]}" == "apps" && $((i+1)) < ${#SCRIPT_PATH_PARTS[@]} && $((i+2)) < ${#SCRIPT_PATH_PARTS[@]} ]]; then
        KUSTOMIZATION_NAMESPACE="${SCRIPT_PATH_PARTS[$((i+1))]}"
        KUSTOMIZATION_BASE_NAME="${SCRIPT_PATH_PARTS[$((i+2))]}"
        break
    fi
done

# Fallback values if path parsing fails
if [[ -z "$KUSTOMIZATION_NAMESPACE" || -z "$KUSTOMIZATION_BASE_NAME" ]]; then
    KUSTOMIZATION_NAMESPACE="security"
    KUSTOMIZATION_BASE_NAME="authentik"
fi

# Define all kustomizations to manage based on the app
# Check if there are related kustomizations (storage, secrets, etc.)
KUSTOMIZATIONS=("$KUSTOMIZATION_BASE_NAME")

# Function to discover related kustomizations (with basic caching)
discover_kustomizations() {
    local base_name="$1"
    local namespace="$2"
    local found_kustomizations=("$base_name")

    # Only discover if kubectl is available and we can connect quickly
    if command -v kubectl >/dev/null 2>&1; then
        # Common suffixes for related kustomizations
        local suffixes=("storage" "secrets" "config" "database" "redis" "postgres" "mysql")

        # Use a single kubectl call to list all kustomizations, then filter
        local all_kustomizations
        if all_kustomizations=$(kubectl get kustomization -n "$namespace" --no-headers -o name 2>/dev/null | sed 's|kustomization.kustomize.toolkit.fluxcd.io/||'); then
            for suffix in "${suffixes[@]}"; do
                if echo "$all_kustomizations" | grep -q "^$base_name-$suffix$"; then
                    found_kustomizations+=("$base_name-$suffix")
                fi
            done
        fi
    fi

    echo "${found_kustomizations[@]}"
}

# --- Global Flags ---
VERBOSE_FLAG="false"

# --- Logging Functions ---
log_info() { echo "ℹ️  $*"; }
log_success() { echo "✅ $*"; }
log_warning() { echo "⚠️  $*" >&2; }
log_error() { echo "❌ $*" >&2; }
log_verbose() { if [[ "$VERBOSE_FLAG" == "true" ]]; then echo "🔍 $*" >&2; fi; }

# --- Error Handling ---
_err_trap() {
    local exit_code=$?
    local line_no=${1:-$LINENO}
    local command_str="${BASH_COMMAND}"

    if [[ "$command_str" == "exit"* || "$command_str" == *"_err_trap"* || "$exit_code" -eq 0 || "$command_str" == "return"* ]]; then
        return
    fi

    echo
    log_error "ERROR in $SCRIPT_NAME: Script exited with status $exit_code."
    log_error "Failed command: '$command_str' on line $line_no."
}
trap '_err_trap "${LINENO}"' ERR

set -uo pipefail

# --- Usage Function ---
usage() {
    echo ""
    echo "Usage: $SCRIPT_NAME <action> [options]"
    echo ""
    echo "Description:"
    echo "  Manages Flux Kustomizations for '$KUSTOMIZATION_BASE_NAME' in namespace '$KUSTOMIZATION_NAMESPACE'"
    echo "  Kustomizations: ${KUSTOMIZATIONS[*]}"
    echo ""
    echo "Actions:"
    echo "  suspend                 Suspend the Kustomizations (stops reconciliation)"
    echo "  resume                  Resume the Kustomizations (enables reconciliation)"
    echo "  status                  Show current status of all Kustomizations"
    echo "  scale                   Scale down all deployments, statefulsets, and replicasets to 0 replicas"
    echo ""
    echo "Options:"
    echo "  --verbose               Show detailed output during operations"
    echo "  -h, --help             Show this help message"
    echo "  --version              Show script version"
    echo ""
    echo "Examples:"
    echo "  $SCRIPT_NAME suspend"
    echo "  $SCRIPT_NAME resume --verbose"
    echo "  $SCRIPT_NAME status"
    echo "  $SCRIPT_NAME scale"
    echo ""
}

# --- Dependency Checks ---
check_dependencies() {
    local missing_deps=()

    if ! command -v flux >/dev/null 2>&1; then
        missing_deps+=("flux")
    fi

    if ! command -v kubectl >/dev/null 2>&1; then
        missing_deps+=("kubectl")
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_error "Please install the missing tools and try again."
        exit 1
    fi

    log_verbose "Dependency check passed."
}

# --- Kustomization Functions ---
get_kustomization_status() {
    log_info "Checking status of all Kustomizations in namespace '$KUSTOMIZATION_NAMESPACE'..."

    local has_errors=false

    for kustomization in "${KUSTOMIZATIONS[@]}"; do
        log_verbose "Checking status of Kustomization '$kustomization'..."

        if ! kubectl get kustomization "$kustomization" -n "$KUSTOMIZATION_NAMESPACE" >/dev/null 2>&1; then
            log_error "Kustomization '$kustomization' not found in namespace '$KUSTOMIZATION_NAMESPACE'"
            has_errors=true
            continue
        fi

        local suspended=$(kubectl get kustomization "$kustomization" -n "$KUSTOMIZATION_NAMESPACE" -o jsonpath='{.spec.suspend}' 2>/dev/null || echo "")
        if [[ "$suspended" == "true" ]]; then
            suspended="true"
        else
            suspended="false"
        fi
        local ready=$(kubectl get kustomization "$kustomization" -n "$KUSTOMIZATION_NAMESPACE" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")
        local last_reconcile=$(kubectl get kustomization "$kustomization" -n "$KUSTOMIZATION_NAMESPACE" -o jsonpath='{.status.lastAttemptedRevision}' 2>/dev/null || echo "N/A")

        echo "┌─────────────────────────────────────────────────────────────────────────────────────────┐"
        printf "│ Kustomization Status: %-65s │\n" "$kustomization"
        echo "├─────────────────────────────────────────────────────────────────────────────────────────┤"
        printf "│ %-15s │ %-69s │\n" "Name:" "$kustomization"
        printf "│ %-15s │ %-69s │\n" "Namespace:" "$KUSTOMIZATION_NAMESPACE"
        printf "│ %-15s │ %-69s │\n" "Suspended:" "$suspended"
        printf "│ %-15s │ %-69s │\n" "Ready:" "$ready"
        printf "│ %-15s │ %-69s │\n" "Last Revision:" "$last_reconcile"
        echo "└─────────────────────────────────────────────────────────────────────────────────────────┘"
        echo
    done

    if [[ "$has_errors" == "true" ]]; then
        return 1
    fi
}

suspend_kustomization() {
    log_info "Suspending all Kustomizations in namespace '$KUSTOMIZATION_NAMESPACE'..."

    local has_errors=false
    local suspended_count=0
    local already_suspended_count=0

    for kustomization in "${KUSTOMIZATIONS[@]}"; do
        log_verbose "Processing Kustomization '$kustomization'..."

        if ! kubectl get kustomization "$kustomization" -n "$KUSTOMIZATION_NAMESPACE" >/dev/null 2>&1; then
            log_error "Kustomization '$kustomization' not found in namespace '$KUSTOMIZATION_NAMESPACE'"
            has_errors=true
            continue
        fi

        # Check if already suspended
        local suspended=$(kubectl get kustomization "$kustomization" -n "$KUSTOMIZATION_NAMESPACE" -o jsonpath='{.spec.suspend}' 2>/dev/null || echo "")
        if [[ "$suspended" == "true" ]]; then
            log_info "Kustomization '$kustomization' is already suspended."
            ((already_suspended_count++))
            continue
        fi

        log_verbose "Executing flux suspend command for '$kustomization'..."
        set +e  # Temporarily disable exit on error
        flux suspend kustomization "$kustomization" -n "$KUSTOMIZATION_NAMESPACE"
        local flux_exit_code=$?
        set -e  # Re-enable exit on error

        if [[ $flux_exit_code -eq 0 ]]; then
            log_success "Kustomization '$kustomization' suspended successfully."
            ((suspended_count++))
        else
            log_error "Failed to suspend Kustomization '$kustomization' (exit code: $flux_exit_code)."
            has_errors=true
        fi
        log_verbose "Completed processing '$kustomization', moving to next..."
    done

    # Summary
    if [[ $suspended_count -gt 0 ]]; then
        log_success "Successfully suspended $suspended_count Kustomization(s)."
    fi
    if [[ $already_suspended_count -gt 0 ]]; then
        log_info "$already_suspended_count Kustomization(s) were already suspended."
    fi

    if [[ "$has_errors" == "true" ]]; then
        return 1
    fi
}

resume_kustomization() {
    log_info "Resuming all Kustomizations in namespace '$KUSTOMIZATION_NAMESPACE'..."

    local has_errors=false
    local resumed_count=0
    local already_resumed_count=0

    for kustomization in "${KUSTOMIZATIONS[@]}"; do
        log_verbose "Processing Kustomization '$kustomization'..."

        if ! kubectl get kustomization "$kustomization" -n "$KUSTOMIZATION_NAMESPACE" >/dev/null 2>&1; then
            log_error "Kustomization '$kustomization' not found in namespace '$KUSTOMIZATION_NAMESPACE'"
            has_errors=true
            continue
        fi

        # Check if already resumed (not suspended)
        local suspended=$(kubectl get kustomization "$kustomization" -n "$KUSTOMIZATION_NAMESPACE" -o jsonpath='{.spec.suspend}' 2>/dev/null || echo "")
        if [[ "$suspended" != "true" ]]; then
            log_info "Kustomization '$kustomization' is already resumed (not suspended)."
            ((already_resumed_count++))
            continue
        fi

        log_verbose "Executing flux resume command for '$kustomization'..."
        set +e  # Temporarily disable exit on error
        flux resume kustomization "$kustomization" -n "$KUSTOMIZATION_NAMESPACE"
        local flux_exit_code=$?
        set -e  # Re-enable exit on error

        if [[ $flux_exit_code -eq 0 ]]; then
            log_success "Kustomization '$kustomization' resumed successfully."
            ((resumed_count++))
        else
            log_error "Failed to resume Kustomization '$kustomization' (exit code: $flux_exit_code)."
            has_errors=true
        fi
    done

    # Summary
    if [[ $resumed_count -gt 0 ]]; then
        log_success "Successfully resumed $resumed_count Kustomization(s)."
        log_info "Reconciliation will begin according to the configured intervals."
    fi
    if [[ $already_resumed_count -gt 0 ]]; then
        log_info "$already_resumed_count Kustomization(s) were already resumed."
    fi

    if [[ "$has_errors" == "true" ]]; then
        return 1
    fi
}

scale_down_workloads() {
    log_info "Scaling down workloads for '$KUSTOMIZATION_BASE_NAME' in namespace '$KUSTOMIZATION_NAMESPACE'..."

    # Get deployments, statefulsets, and replicasets that match the app name
    log_verbose "Finding deployments, statefulsets, and replicasets matching '$KUSTOMIZATION_BASE_NAME'..."

    local workloads
    if ! workloads=$(kubectl -n "$KUSTOMIZATION_NAMESPACE" get deploy,statefulset,replicaset -o name 2>/dev/null | grep "$KUSTOMIZATION_BASE_NAME"); then
        log_warning "No deployments, statefulsets, or replicasets found matching '$KUSTOMIZATION_BASE_NAME' in namespace '$KUSTOMIZATION_NAMESPACE'."
        return 0
    fi

    if [[ -z "$workloads" ]]; then
        log_warning "No workloads found to scale down."
        return 0
    fi

    log_info "Found workloads to scale down:"
    while IFS= read -r workload; do
        echo "  - $workload"
    done <<< "$workloads"

    log_verbose "Scaling workloads to 0 replicas..."
    local scale_failed=false

    while IFS= read -r workload; do
        if [[ -n "$workload" ]]; then
            log_verbose "Scaling $workload to 0 replicas..."
            if kubectl -n "$KUSTOMIZATION_NAMESPACE" scale --replicas=0 "$workload" 2>/dev/null; then
                log_success "Scaled $workload to 0 replicas."
            else
                log_error "Failed to scale $workload."
                scale_failed=true
            fi
        fi
    done <<< "$workloads"

    if [[ "$scale_failed" == "true" ]]; then
        log_error "Some workloads failed to scale down."
        return 1
    fi

    log_success "All '$KUSTOMIZATION_BASE_NAME' workloads scaled down to 0 replicas."
    log_info "Note: This only stops running pods. To prevent Flux from restarting them, use 'suspend' action."
}

# --- Main Script Logic ---
main() {
    # Parse global flags first
    local temp_args=()
    for arg in "$@"; do
        case "$arg" in
            --verbose)
                VERBOSE_FLAG="true"
                ;;
            *)
                temp_args+=("$arg")
                ;;
        esac
    done
    set -- "${temp_args[@]}"

    # Get action
    local action="${1:-}"

    # Handle help and version
    case "$action" in
        ""|"-h"|"--help")
            usage
            exit 0
            ;;
        "--version")
            echo "$SCRIPT_NAME version $SCRIPT_VERSION"
            # Discover kustomizations for version display
            local temp_kustomizations=($(discover_kustomizations "$KUSTOMIZATION_BASE_NAME" "$KUSTOMIZATION_NAMESPACE"))
            echo "Managing app: $KUSTOMIZATION_BASE_NAME (namespace: $KUSTOMIZATION_NAMESPACE)"
            echo "Discovered kustomizations: ${temp_kustomizations[*]}"
            exit 0
            ;;
    esac

    log_verbose "Script: $SCRIPT_NAME v$SCRIPT_VERSION"
    log_verbose "Target base app: $KUSTOMIZATION_BASE_NAME (namespace: $KUSTOMIZATION_NAMESPACE)"

    # Discover all related kustomizations
    KUSTOMIZATIONS=($(discover_kustomizations "$KUSTOMIZATION_BASE_NAME" "$KUSTOMIZATION_NAMESPACE"))
    log_verbose "Discovered kustomizations: ${KUSTOMIZATIONS[*]}"

    # Check dependencies
    check_dependencies

    # Execute action
    case "$action" in
        "suspend")
            suspend_kustomization
            ;;
        "resume")
            resume_kustomization
            ;;
        "status")
            get_kustomization_status
            ;;
        "scale")
            scale_down_workloads
            ;;
        *)
            log_error "Invalid action '$action'."
            echo
            usage
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"

exit 0

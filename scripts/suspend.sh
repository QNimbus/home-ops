#!/usr/bin/env bash
set -Eeuo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Script configuration
SCRIPT_NAME="suspend"
DEFAULT_NAMESPACE="flux-system"

function usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME}.sh [OPTIONS] <resource-name>

Suspend a Flux Kustomization and related HelmReleases, then scale down associated deployments, statefulsets, and suspend daemonsets.

ARGUMENTS:
    <resource-name>         Name of the Kustomization to suspend

OPTIONS:
    -n, --namespace         Namespace where the Kustomization exists (default: ${DEFAULT_NAMESPACE})
    -t, --target-namespace  Target namespace where deployments exist (auto-detected if not specified)
    -s, --scale-only        Only scale deployments/statefulsets and suspend daemonsets, don't suspend Flux resources
    -h, --help              Show this help message

EXAMPLES:
    ${SCRIPT_NAME}.sh immich
    ${SCRIPT_NAME}.sh -n tools -t tools immich
    ${SCRIPT_NAME}.sh --scale-only immich

EOF
}

function main() {
    local resource_name=""
    local namespace="${DEFAULT_NAMESPACE}"
    local target_namespace=""
    local scale_only=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
        -n | --namespace)
            namespace="$2"
            shift 2
            ;;
        -t | --target-namespace)
            target_namespace="$2"
            shift 2
            ;;
        -s | --scale-only)
            scale_only=true
            shift
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        -*)
            log error "Unknown option: $1"
            ;;
        *)
            if [[ -z "${resource_name}" ]]; then
                resource_name="$1"
            else
                log error "Too many arguments"
            fi
            shift
            ;;
        esac
    done

    # Validate required arguments
    if [[ -z "${resource_name}" ]]; then
        log error "Resource name is required"
    fi

    # Check required CLI tools
    check_cli "kubectl" "flux"

    # Auto-detect target namespace if not specified
    if [[ -z "${target_namespace}" ]]; then
        log info "Auto-detecting target namespace for resource" "name=${resource_name}" "namespace=${namespace}"
        if kubectl get kustomization "${resource_name}" -n "${namespace}" &>/dev/null; then
            target_namespace=$(kubectl get kustomization "${resource_name}" -n "${namespace}" -o jsonpath='{.spec.targetNamespace}' 2>/dev/null || echo "${namespace}")
            if [[ -z "${target_namespace}" ]]; then
                target_namespace="${namespace}"
            fi
        else
            target_namespace="${namespace}"
        fi
        log info "Using target namespace" "namespace=${target_namespace}"
    fi

    if [[ "${scale_only}" == "false" ]]; then
        # Suspend Kustomization
        log info "Suspending Kustomization" "name=${resource_name}" "namespace=${namespace}"
        if kubectl get kustomization "${resource_name}" -n "${namespace}" &>/dev/null; then
            if flux suspend kustomization "${resource_name}" -n "${namespace}"; then
                log info "Kustomization suspended successfully" "name=${resource_name}"
            else
                log warn "Failed to suspend Kustomization" "name=${resource_name}"
            fi
        else
            log warn "Kustomization not found" "name=${resource_name}" "namespace=${namespace}"
        fi

        # Suspend HelmRelease (check in target namespace)
        log info "Suspending HelmRelease" "name=${resource_name}" "namespace=${target_namespace}"
        if kubectl get helmrelease "${resource_name}" -n "${target_namespace}" &>/dev/null; then
            if flux suspend helmrelease "${resource_name}" -n "${target_namespace}"; then
                log info "HelmRelease suspended successfully" "name=${resource_name}"
            else
                log warn "Failed to suspend HelmRelease" "name=${resource_name}"
            fi
        else
            log warn "HelmRelease not found" "name=${resource_name}" "namespace=${target_namespace}"
        fi
    fi

    # Scale down deployments
    log info "Scaling down deployments" "pattern=${resource_name}*" "namespace=${target_namespace}"
    local deployments
    deployments=$(kubectl get deployments -n "${target_namespace}" -o name | grep -E "(^deployment.apps/${resource_name}$|^deployment.apps/${resource_name}-)" || true)

    if [[ -n "${deployments}" ]]; then
        local scaled_count=0
        while IFS= read -r deployment; do
            if [[ -n "${deployment}" ]]; then
                local deployment_name
                deployment_name=$(echo "${deployment}" | cut -d'/' -f2)

                # Store original replica count in annotation before scaling down
                local current_replicas
                current_replicas=$(kubectl get "${deployment}" -n "${target_namespace}" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")
                if [[ "${current_replicas}" -gt 0 ]]; then
                    log info "Storing original replica count" "name=${deployment_name}" "replicas=${current_replicas}"
                    kubectl annotate "${deployment}" -n "${target_namespace}" "app.vwn/original-replicas=${current_replicas}" --overwrite || true
                fi

                log info "Scaling down deployment" "name=${deployment_name}" "namespace=${target_namespace}"
                if kubectl scale "${deployment}" -n "${target_namespace}" --replicas=0; then
                    log info "Deployment scaled down successfully" "name=${deployment_name}"
                    scaled_count=$((scaled_count + 1))
                else
                    log warn "Failed to scale down deployment" "name=${deployment_name}"
                fi
            fi
        done <<< "${deployments}"
        log info "Scaling completed" "deployments_scaled=${scaled_count}"
    else
        log warn "No deployments found matching pattern" "pattern=${resource_name}*" "namespace=${target_namespace}"
    fi

    # Scale down statefulsets
    log info "Scaling down statefulsets" "pattern=${resource_name}*" "namespace=${target_namespace}"
    local statefulsets
    statefulsets=$(kubectl get statefulsets -n "${target_namespace}" -o name | grep -E "(^statefulset.apps/${resource_name}$|^statefulset.apps/${resource_name}-)" || true)

    if [[ -n "${statefulsets}" ]]; then
        local sts_scaled_count=0
        while IFS= read -r statefulset; do
            if [[ -n "${statefulset}" ]]; then
                local sts_name
                sts_name=$(echo "${statefulset}" | cut -d'/' -f2)

                # Store original replica count in annotation before scaling down
                local current_replicas
                current_replicas=$(kubectl get "${statefulset}" -n "${target_namespace}" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")
                if [[ "${current_replicas}" -gt 0 ]]; then
                    log info "Storing original replica count" "name=${sts_name}" "replicas=${current_replicas}"
                    kubectl annotate "${statefulset}" -n "${target_namespace}" "app.vwn/original-replicas=${current_replicas}" --overwrite || true
                fi

                log info "Scaling down statefulset" "name=${sts_name}" "namespace=${target_namespace}"
                if kubectl scale "${statefulset}" -n "${target_namespace}" --replicas=0; then
                    log info "StatefulSet scaled down successfully" "name=${sts_name}"
                    sts_scaled_count=$((sts_scaled_count + 1))
                else
                    log warn "Failed to scale down statefulset" "name=${sts_name}"
                fi
            fi
        done <<< "${statefulsets}"
        log info "StatefulSet scaling completed" "statefulsets_scaled=${sts_scaled_count}"
    else
        log info "No statefulsets found matching pattern" "pattern=${resource_name}*" "namespace=${target_namespace}"
    fi

    # Suspend daemonsets (they don't scale by replicas, but can be suspended via annotation)
    log info "Suspending daemonsets" "pattern=${resource_name}*" "namespace=${target_namespace}"
    local daemonsets
    daemonsets=$(kubectl get daemonsets -n "${target_namespace}" -o name | grep -E "(^daemonset.apps/${resource_name}$|^daemonset.apps/${resource_name}-)" || true)

    if [[ -n "${daemonsets}" ]]; then
        local ds_suspended_count=0
        while IFS= read -r daemonset; do
            if [[ -n "${daemonset}" ]]; then
                local ds_name
                ds_name=$(echo "${daemonset}" | cut -d'/' -f2)
                log info "Suspending daemonset" "name=${ds_name}" "namespace=${target_namespace}"
                if kubectl annotate "${daemonset}" -n "${target_namespace}" "app.vwn/suspended=true" --overwrite; then
                    log info "DaemonSet suspended successfully" "name=${ds_name}"
                    ds_suspended_count=$((ds_suspended_count + 1))
                else
                    log warn "Failed to suspend daemonset" "name=${ds_name}"
                fi
            fi
        done <<< "${daemonsets}"
        log info "DaemonSet suspension completed" "daemonsets_suspended=${ds_suspended_count}"
    else
        log info "No daemonsets found matching pattern" "pattern=${resource_name}*" "namespace=${target_namespace}"
    fi

    log info "Suspend operation completed" "resource=${resource_name}"
}

# Run main function with all arguments
main "$@"

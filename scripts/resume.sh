#!/usr/bin/env bash
set -Eeuo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Script configuration
SCRIPT_NAME="resume"
DEFAULT_NAMESPACE="flux-system"

function usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME}.sh [OPTIONS] <resource-name>

Resume a suspended Flux Kustomization and related HelmReleases, and resume associated daemonsets. Deployments and statefulsets will auto-scale based on configuration.

ARGUMENTS:
    <resource-name>         Name of the Kustomization to resume

OPTIONS:
    -n, --namespace         Namespace where the Kustomization exists (default: ${DEFAULT_NAMESPACE})
    -t, --target-namespace  Target namespace where deployments exist (auto-detected if not specified)
    -f, --force-reconcile   Force immediate reconciliation after resuming to restore scaling (default: false)
    -s, --auto-scale        Automatically scale deployments/statefulsets back to minimum replicas (default: false)
    -w, --wait              Wait for deployments to become ready after resuming (default: false)
    --wait-timeout          Timeout for waiting (default: 300s)
    -h, --help              Show this help message

EXAMPLES:
    ${SCRIPT_NAME}.sh immich
    ${SCRIPT_NAME}.sh -n tools -t tools immich
    ${SCRIPT_NAME}.sh --force-reconcile --auto-scale --wait immich
    ${SCRIPT_NAME}.sh --auto-scale immich

EOF
}

function wait_for_deployments() {
    local target_namespace="$1"
    local resource_name="$2"
    local timeout="$3"

    log info "Waiting for deployments to become ready" "timeout=${timeout}s"

    local deployments
    deployments=$(kubectl get deployments -n "${target_namespace}" -o name | grep -E "(^deployment.apps/${resource_name}$|^deployment.apps/${resource_name}-)" || true)

    if [[ -n "${deployments}" ]]; then
        while IFS= read -r deployment; do
            if [[ -n "${deployment}" ]]; then
                local deployment_name
                deployment_name=$(echo "${deployment}" | cut -d'/' -f2)
                log info "Waiting for deployment to be ready" "name=${deployment_name}"
                if kubectl wait --for=condition=available "${deployment}" -n "${target_namespace}" --timeout="${timeout}s"; then
                    log info "Deployment is ready" "name=${deployment_name}"
                else
                    log warn "Deployment did not become ready within timeout" "name=${deployment_name}" "timeout=${timeout}s"
                fi
            fi
        done <<< "${deployments}"
    else
        log warn "No deployments found to wait for" "pattern=${resource_name}*" "namespace=${target_namespace}"
    fi
}

function get_deployment_min_replicas() {
    local deployment_name="$1"
    local namespace="$2"

    # Try to get from HPA first (most reliable for autoscaled deployments)
    local hpa_min_replicas
    hpa_min_replicas=$(kubectl get hpa "${deployment_name}" -n "${namespace}" -o jsonpath='{.spec.minReplicas}' 2>/dev/null || echo "")

    if [[ -n "${hpa_min_replicas}" && "${hpa_min_replicas}" != "null" ]]; then
        echo "${hpa_min_replicas}"
        return
    fi

    # Try to get from stored annotation (if we set it during suspend)
    local annotation_replicas
    annotation_replicas=$(kubectl get deployment "${deployment_name}" -n "${namespace}" -o jsonpath='{.metadata.annotations.app\.vwn/original-replicas}' 2>/dev/null || echo "")

    if [[ -n "${annotation_replicas}" && "${annotation_replicas}" != "null" ]]; then
        echo "${annotation_replicas}"
        return
    fi

    # Fall back to current spec.replicas if > 0, otherwise default to 1
    local spec_replicas
    spec_replicas=$(kubectl get deployment "${deployment_name}" -n "${namespace}" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")

    if [[ "${spec_replicas}" -gt 0 ]]; then
        echo "${spec_replicas}"
    else
        echo "1"
    fi
}

function get_statefulset_min_replicas() {
    local statefulset_name="$1"
    local namespace="$2"

    # Try to get from stored annotation first
    local annotation_replicas
    annotation_replicas=$(kubectl get statefulset "${statefulset_name}" -n "${namespace}" -o jsonpath='{.metadata.annotations.app\.vwn/original-replicas}' 2>/dev/null || echo "")

    if [[ -n "${annotation_replicas}" && "${annotation_replicas}" != "null" ]]; then
        echo "${annotation_replicas}"
        return
    fi

    # Fall back to current spec.replicas if > 0, otherwise default to 1
    local spec_replicas
    spec_replicas=$(kubectl get statefulset "${statefulset_name}" -n "${namespace}" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")

    if [[ "${spec_replicas}" -gt 0 ]]; then
        echo "${spec_replicas}"
    else
        echo "1"
    fi
}

function auto_scale_workloads() {
    local target_namespace="$1"
    local resource_name="$2"

    log info "Auto-scaling workloads to minimum replicas"

    # Scale deployments
    local deployments
    deployments=$(kubectl get deployments -n "${target_namespace}" -o name | grep -E "(^deployment.apps/${resource_name}$|^deployment.apps/${resource_name}-)" || true)

    if [[ -n "${deployments}" ]]; then
        while IFS= read -r deployment; do
            if [[ -n "${deployment}" ]]; then
                local deployment_name
                deployment_name=$(echo "${deployment}" | cut -d'/' -f2)
                local current_replicas
                current_replicas=$(kubectl get "${deployment}" -n "${target_namespace}" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")

                if [[ "${current_replicas}" -eq 0 ]]; then
                    local min_replicas
                    min_replicas=$(get_deployment_min_replicas "${deployment_name}" "${target_namespace}")
                    log info "Scaling deployment to minimum replicas" "name=${deployment_name}" "replicas=${min_replicas}"

                    if kubectl scale "${deployment}" -n "${target_namespace}" --replicas="${min_replicas}"; then
                        log info "Deployment scaled successfully" "name=${deployment_name}" "replicas=${min_replicas}"

                        # Remove the original-replicas annotation after successful scaling
                        kubectl annotate "${deployment}" -n "${target_namespace}" "app.vwn/original-replicas-" || true
                    else
                        log warn "Failed to scale deployment" "name=${deployment_name}"
                    fi
                else
                    log info "Deployment already scaled" "name=${deployment_name}" "replicas=${current_replicas}"
                fi
            fi
        done <<< "${deployments}"
    fi

    # Scale statefulsets
    local statefulsets
    statefulsets=$(kubectl get statefulsets -n "${target_namespace}" -o name | grep -E "(^statefulset.apps/${resource_name}$|^statefulset.apps/${resource_name}-)" || true)

    if [[ -n "${statefulsets}" ]]; then
        while IFS= read -r statefulset; do
            if [[ -n "${statefulset}" ]]; then
                local sts_name
                sts_name=$(echo "${statefulset}" | cut -d'/' -f2)
                local current_replicas
                current_replicas=$(kubectl get "${statefulset}" -n "${target_namespace}" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")

                if [[ "${current_replicas}" -eq 0 ]]; then
                    local min_replicas
                    min_replicas=$(get_statefulset_min_replicas "${sts_name}" "${target_namespace}")
                    log info "Scaling statefulset to minimum replicas" "name=${sts_name}" "replicas=${min_replicas}"

                    if kubectl scale "${statefulset}" -n "${target_namespace}" --replicas="${min_replicas}"; then
                        log info "StatefulSet scaled successfully" "name=${sts_name}" "replicas=${min_replicas}"

                        # Remove the original-replicas annotation after successful scaling
                        kubectl annotate "${statefulset}" -n "${target_namespace}" "app.vwn/original-replicas-" || true
                    else
                        log warn "Failed to scale statefulset" "name=${sts_name}"
                    fi
                else
                    log info "StatefulSet already scaled" "name=${sts_name}" "replicas=${current_replicas}"
                fi
            fi
        done <<< "${statefulsets}"
    fi
}

function main() {
    local resource_name=""
    local namespace="${DEFAULT_NAMESPACE}"
    local target_namespace=""
    local wait_for_ready=false
    local wait_timeout=300
    local force_reconcile=false
    local auto_scale=false

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
        -f | --force-reconcile)
            force_reconcile=true
            shift
            ;;
        -s | --auto-scale)
            auto_scale=true
            shift
            ;;
        -w | --wait)
            wait_for_ready=true
            shift
            ;;
        --wait-timeout)
            wait_timeout="$2"
            shift 2
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

    # Resume HelmRelease first (so it can manage deployments)
    log info "Resuming HelmRelease" "name=${resource_name}" "namespace=${target_namespace}"
    if kubectl get helmrelease "${resource_name}" -n "${target_namespace}" &>/dev/null; then
        # Check if it's actually suspended
        local hr_suspended
        hr_suspended=$(kubectl get helmrelease "${resource_name}" -n "${target_namespace}" -o jsonpath='{.spec.suspend}' 2>/dev/null || echo "false")
        if [[ "${hr_suspended}" == "true" ]]; then
            if flux resume helmrelease "${resource_name}" -n "${target_namespace}"; then
                log info "HelmRelease resumed successfully" "name=${resource_name}"
            else
                log warn "Failed to resume HelmRelease" "name=${resource_name}"
            fi
        else
            log info "HelmRelease is not suspended" "name=${resource_name}"
        fi
    else
        log warn "HelmRelease not found" "name=${resource_name}" "namespace=${target_namespace}"
    fi

    # Resume Kustomization
    log info "Resuming Kustomization" "name=${resource_name}" "namespace=${namespace}"
    if kubectl get kustomization "${resource_name}" -n "${namespace}" &>/dev/null; then
        # Check if it's actually suspended
        local ks_suspended
        ks_suspended=$(kubectl get kustomization "${resource_name}" -n "${namespace}" -o jsonpath='{.spec.suspend}' 2>/dev/null || echo "false")
        if [[ "${ks_suspended}" == "true" ]]; then
            if flux resume kustomization "${resource_name}" -n "${namespace}"; then
                log info "Kustomization resumed successfully" "name=${resource_name}"
            else
                log warn "Failed to resume Kustomization" "name=${resource_name}"
            fi
        else
            log info "Kustomization is not suspended" "name=${resource_name}"
        fi
    else
        log warn "Kustomization not found" "name=${resource_name}" "namespace=${namespace}"
    fi

    # Force reconciliation if requested
    if [[ "${force_reconcile}" == "true" ]]; then
        log info "Forcing reconciliation to restore deployment scaling"

        # Force reconcile the HelmRelease first
        if kubectl get helmrelease "${resource_name}" -n "${target_namespace}" &>/dev/null; then
            log info "Force reconciling HelmRelease" "name=${resource_name}" "namespace=${target_namespace}"
            if flux reconcile helmrelease "${resource_name}" -n "${target_namespace}"; then
                log info "HelmRelease reconciliation completed" "name=${resource_name}"
            else
                log warn "Failed to force reconcile HelmRelease" "name=${resource_name}"
            fi
        fi

        # Force reconcile the Kustomization
        if kubectl get kustomization "${resource_name}" -n "${namespace}" &>/dev/null; then
            log info "Force reconciling Kustomization" "name=${resource_name}" "namespace=${namespace}"
            if flux reconcile kustomization "${resource_name}" -n "${namespace}"; then
                log info "Kustomization reconciliation completed" "name=${resource_name}"
            else
                log warn "Failed to force reconcile Kustomization" "name=${resource_name}"
            fi
        fi

        # Give a moment for the reconciliation to take effect
        log info "Waiting for reconciliation to take effect"
        sleep 5
    fi

    # Auto-scale workloads if requested
    if [[ "${auto_scale}" == "true" ]]; then
        auto_scale_workloads "${target_namespace}" "${resource_name}"

        # Give a moment for scaling to take effect
        sleep 3
    fi

    # Show current deployment status
    log info "Checking deployment status" "namespace=${target_namespace}"
    local deployments
    deployments=$(kubectl get deployments -n "${target_namespace}" -o name | grep -E "(^deployment.apps/${resource_name}$|^deployment.apps/${resource_name}-)" || true)

    if [[ -n "${deployments}" ]]; then
        while IFS= read -r deployment; do
            if [[ -n "${deployment}" ]]; then
                local deployment_name
                deployment_name=$(echo "${deployment}" | cut -d'/' -f2)
                local replicas
                replicas=$(kubectl get "${deployment}" -n "${target_namespace}" -o jsonpath='{.status.replicas}' 2>/dev/null || echo "0")
                local ready_replicas
                ready_replicas=$(kubectl get "${deployment}" -n "${target_namespace}" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
                log info "Deployment status" "name=${deployment_name}" "replicas=${replicas}" "ready=${ready_replicas}"
            fi
        done <<< "${deployments}"
    else
        log info "No deployments found" "pattern=${resource_name}*" "namespace=${target_namespace}"
    fi

    # Show current statefulset status
    log info "Checking statefulset status" "namespace=${target_namespace}"
    local statefulsets
    statefulsets=$(kubectl get statefulsets -n "${target_namespace}" -o name | grep -E "(^statefulset.apps/${resource_name}$|^statefulset.apps/${resource_name}-)" || true)

    if [[ -n "${statefulsets}" ]]; then
        while IFS= read -r statefulset; do
            if [[ -n "${statefulset}" ]]; then
                local sts_name
                sts_name=$(echo "${statefulset}" | cut -d'/' -f2)
                local sts_replicas
                sts_replicas=$(kubectl get "${statefulset}" -n "${target_namespace}" -o jsonpath='{.status.replicas}' 2>/dev/null || echo "0")
                local sts_ready_replicas
                sts_ready_replicas=$(kubectl get "${statefulset}" -n "${target_namespace}" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
                log info "StatefulSet status" "name=${sts_name}" "replicas=${sts_replicas}" "ready=${sts_ready_replicas}"
            fi
        done <<< "${statefulsets}"
    else
        log info "No statefulsets found" "pattern=${resource_name}*" "namespace=${target_namespace}"
    fi

    # Resume daemonsets (remove suspension annotation)
    log info "Resuming daemonsets" "pattern=${resource_name}*" "namespace=${target_namespace}"
    local daemonsets
    daemonsets=$(kubectl get daemonsets -n "${target_namespace}" -o name | grep -E "(^daemonset.apps/${resource_name}$|^daemonset.apps/${resource_name}-)" || true)

    if [[ -n "${daemonsets}" ]]; then
        local ds_resumed_count=0
        while IFS= read -r daemonset; do
            if [[ -n "${daemonset}" ]]; then
                local ds_name
                ds_name=$(echo "${daemonset}" | cut -d'/' -f2)
                # Check if it has the suspension annotation
                local suspended_annotation
                suspended_annotation=$(kubectl get "${daemonset}" -n "${target_namespace}" -o jsonpath='{.metadata.annotations.app\.vwn/suspended}' 2>/dev/null || echo "")
                if [[ "${suspended_annotation}" == "true" ]]; then
                    log info "Resuming daemonset" "name=${ds_name}" "namespace=${target_namespace}"
                    if kubectl annotate "${daemonset}" -n "${target_namespace}" "app.vwn/suspended-"; then
                        log info "DaemonSet resumed successfully" "name=${ds_name}"
                        ds_resumed_count=$((ds_resumed_count + 1))
                    else
                        log warn "Failed to resume daemonset" "name=${ds_name}"
                    fi
                else
                    log info "DaemonSet is not suspended" "name=${ds_name}"
                fi
            fi
        done <<< "${daemonsets}"
        log info "DaemonSet resume completed" "daemonsets_resumed=${ds_resumed_count}"
    else
        log info "No daemonsets found" "pattern=${resource_name}*" "namespace=${target_namespace}"
    fi

    # Wait for deployments if requested
    if [[ "${wait_for_ready}" == "true" ]]; then
        wait_for_deployments "${target_namespace}" "${resource_name}" "${wait_timeout}"
    fi

    log info "Resume operation completed" "resource=${resource_name}"

    # Provide helpful next steps
    cat <<EOF

Next steps:
- Monitor Flux reconciliation: flux get all -n ${target_namespace} | grep ${resource_name}
- Check deployment status: kubectl get deployments -n ${target_namespace} | grep ${resource_name}
- View logs if issues: kubectl logs -l app.kubernetes.io/name=${resource_name} -n ${target_namespace}

Note: If deployments are still at 0 replicas, you may need to:
- Use --force-reconcile flag to trigger immediate scaling restoration
- Wait for the next reconciliation cycle (interval: $(kubectl get helmrelease ${resource_name} -n ${target_namespace} -o jsonpath='{.spec.interval}' 2>/dev/null || echo "unknown"))
- Manually trigger: flux reconcile helmrelease ${resource_name} -n ${target_namespace}

EOF
}

# Run main function with all arguments
main "$@"

# Application Suspension and Resumption Scripts

This document describes the `suspend.sh` and `resume.sh` scripts, which are designed to temporarily "turn off" and "turn on" applications managed by FluxCD in a Kubernetes cluster. This is useful for saving resources for applications that are not always needed, without removing them from Git.

## Overview

The core idea is to manage the lifecycle of an application by:
1.  **Suspending**: Stopping Flux from reconciling the application and scaling its running workloads (Deployments, StatefulSets) down to zero replicas.
2.  **Resuming**: Allowing Flux to reconcile the application again and scaling the workloads back up to their original replica counts.

State is preserved between suspension and resumption using a Kubernetes annotation (`app.vwn/original-replicas`) on the workload resources.

---

## `suspend.sh`

This script handles the "turning off" of an application.

### Purpose

- Suspends the corresponding Flux `Kustomization` and `HelmRelease` to prevent GitOps reconciliations.
- Finds all `Deployments`, `StatefulSets`, and `DaemonSets` associated with the application.
- Stores the current number of replicas for each `Deployment` and `StatefulSet` in the `app.vwn/original-replicas` annotation.
- Scales `Deployments` and `StatefulSets` down to `0` replicas.
- Adds a `app.vwn/suspended: "true"` node selector annotation to `DaemonSets` to prevent them from being scheduled.

### Usage

```bash
./scripts/suspend.sh [OPTIONS] <resource-name>
```

**Arguments:**
- `<resource-name>`: The name of the Flux Kustomization to suspend (e.g., `immich`).

**Options:**
- `-n, --namespace`: The namespace where the Flux Kustomization resource exists (default: `flux-system`).
- `-t, --target-namespace`: The namespace where the application's workloads are running. If not provided, the script will attempt to auto-detect it.

### Example

To suspend the `immich` application located in the `tools` namespace:
```bash
./scripts/suspend.sh -n tools immich
```

---

## `resume.sh`

This script handles the "turning on" of a previously suspended application.

### Purpose

- Resumes the corresponding Flux `Kustomization` and `HelmRelease`.
- Finds all associated `Deployments`, `StatefulSets`, and `DaemonSets`.
- **Intelligently scales up** `Deployments` and `StatefulSets` by reading the original replica count from the `app.vwn/original-replicas` annotation. If a HorizontalPodAutoscaler (HPA) is present, it uses the `minReplicas` value.
- After a successful scale-up, it **removes the temporary `app.vwn/original-replicas` annotation** to keep the cluster state clean.
- Removes the suspension annotation from `DaemonSets`, allowing them to be scheduled again.

### Usage

```bash
./scripts/resume.sh [OPTIONS] <resource-name>
```

**Arguments:**
- `<resource-name>`: The name of the Flux Kustomization to resume.

**Options:**
- `-n, --namespace`: The namespace of the Flux Kustomization (default: `flux-system`).
- `-t, --target-namespace`: The namespace of the application's workloads.
- `-s, --auto-scale`: **(Recommended)** Automatically scales workloads back to their original replica counts.
- `-f, --force-reconcile`: Forces an immediate Flux reconciliation after resuming.
- `-w, --wait`: Waits for the workloads to become ready after resuming.

### Example

To resume the `immich` application and automatically scale its workloads:
```bash
./scripts/resume.sh -n tools --auto-scale immich
```

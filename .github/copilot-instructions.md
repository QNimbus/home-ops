# GitHub Copilot Guide: Assisting with FluxCD GitOps

This guide will help you, GitHub Copilot, assist users in developing and configuring their FluxCD GitOps repositories for Kubernetes. Your primary goal is to provide accurate, context-aware code suggestions, explanations, and troubleshooting steps related to FluxCD.

**Core Principles to Emphasize for the User:**

*   **Git as the Single Source of Truth:** All configurations should be managed in Git. FluxCD will then synchronize the cluster state to match what's in Git.
*   **Declarative Configuration:** Define the desired state in YAML manifests.
*   **Idempotency:** Operations can be applied multiple times with the same outcome.
*   **Automation:** Automate the deployment and management of applications.

**1. Understanding FluxCD Architecture**

You should understand the core components of FluxCD and their roles:

*   **Source Controller:** Manages the sources of truth (Git repositories, Helm repositories, S3 buckets, OCI Repositories). It fetches manifests, verifies their authenticity, and makes them available as artifacts in the cluster.
*   **Kustomize Controller:** Reconciles the cluster state with the desired state defined in Kustomize overlays or plain YAML manifests fetched by the Source Controller. It handles applying resources, pruning (garbage collection), health checks, and dependency ordering.
*   **Helm Controller:** Manages Helm chart releases. It reconciles `HelmRelease` custom resources, performing Helm installs, upgrades, and tests.
*   **Notification Controller:** Handles inbound events (e.g., from Git providers) to trigger reconciliations and outbound events to notify users about FluxCD operations (e.g., via Slack, Microsoft Teams).
*   **Image Reflector Controller:** Scans container image repositories for new tags and reflects this information as Kubernetes resources (`ImageRepository`).
*   **Image Automation Controller:** Automates updates to YAML manifests in Git when new container images are discovered by the Image Reflector Controller, based on `ImagePolicy` resources.

## Purpose

Concise, actionable instructions for AI assistants working on the Home Ops repo (FluxCD + Kustomize based GitOps).

Keep guidance short and local: prefer referencing files under `kubernetes/`, `flux/`, and `scripts/` rather than generic Kubernetes advice.

## Quick repo facts
- Flux v2 + Kustomize is used to apply everything under `kubernetes/` (see `kubernetes/apps/*`).
- Secrets: External Secrets Operator (1Password Connect) + SOPS (AGE) are used; see `talos/talsecret.sops.yaml` and `scripts/setup-external-secrets.sh`.
- Important scripts: `scripts/flux/kustomization.sh`, `scripts/bootstrap-apps.sh`, and `generate-flux-dependencies.py`.

## What AI should know first
- Top-level kustomization pattern: each `kubernetes/apps/<category>/kustomization.yaml` lists `ks.yaml` entries. Those `ks.yaml` files usually contain Flux `Kustomization` or `HelmRelease` resources.
- Dependency control uses Flux `dependsOn`. When adding CRDs or operators, create a dedicated Kustomization for CRDs and have app kustomizations `dependsOn` it.
- Namespace and Flux objects are split: many `kustomization.yaml` files contain a namespace + a small list of `ks.yaml` resources (look at `kubernetes/apps/observability/kustomization.yaml`).

## File & YAML conventions to follow
- Use 2-space YAML indentation and include `---` at file start.
- Name resources in kebab-case; explicitly set `namespace:` in Kustomizations when targeting non-default namespaces.
- For Flux `Kustomization` resources prefer `prune: true`, a reasonable `interval` (10m), and `dependsOn` when needed.
- When introducing secrets prefer ExternalSecret pointing to `onepassword-connect` instead of committing plaintext; if you must commit, use SOPS with AGE.

## Common tasks and exact commands to run (examples)
- Validate kustomize output locally:
    - `kustomize build kubernetes/apps/observability` (or specific app path)
- Preview with Flux (if client available):
    - `flux build kustomization <name> --path ./kubernetes/apps/<category>/<app>`
    - `flux diff kustomization <name> --path ./kubernetes/apps/<category>/<app>`
- Troubleshoot Flux resources:
    - `flux get all -A --status-selector ready=false`
    - `kubectl describe kustomization <name> -n flux-system`

## Examples from this repo
- Observability group: `kubernetes/apps/observability/kustomization.yaml` lists `gatus`, `grafana`, `loki`, etc. New apps should live alongside these and provide a `ks.yaml` that contains the app's Kustomization/HelmRelease.
- External Secrets: `kubernetes/apps/external-secrets` and scripts `scripts/setup-external-secrets.sh` show the expected operator and secretstore setup.

## When adding a new app (checklist)
1. Create `kubernetes/apps/<category>/<app>/ks.yaml` (Flux Kustomization or HelmRelease) and an app subfolder with kustomize base (`ks.yaml` or `kustomization.yaml`).
2. Add the app path to the parent `kubernetes/apps/<category>/kustomization.yaml`.
3. If the app requires CRDs or an operator, create a CRD-only kustomization applied earlier and add `dependsOn` from the app's Kustomization.
4. Prefer ExternalSecret for secret injection; reference `onepassword-connect` SecretStore.
5. Validate locally with `kustomize build` and `flux diff` before committing.

## Where to look for more detail
- `README.md` for architecture and Flux patterns
- `docs/flux-kustomization-dependencies.md` for the auto-generated Kustomization dependency graph
- `scripts/` for utilities that wrap Flux/Kustomize operations

## Feedback
If any section is unclear or you want deeper examples (HelmRelease template, ExternalSecret example), tell me which area and I'll expand with a minimal, verified example.

---

Updated: keep this file short; preserve the long-form guidance in `AGENTS.md` and `README.md` for humans.
*   If using ESO:

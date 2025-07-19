# Flux Kustomization Dependencies

This document shows the dependency relationships between all Flux Kustomizations in the cluster.

**Total Kustomizations:** 40

## Table of Contents

1. [Summary by Namespace](#summary-by-namespace)
2. [Complete Dependency Overview](#complete-dependency-overview)
3. [Deployment Order (Dependency Hierarchy)](#deployment-order-dependency-hierarchy)
4. [Detailed Dependency Matrix](#detailed-dependency-matrix)
5. [File Locations](#file-locations)

## Summary by Namespace

| Namespace | Kustomizations | Count |
|-----------|----------------|-------|
| `cert-manager` | cert-manager | 1 |
| `database` | cloudnative-pg-backup, cloudnative-pg-cluster, cloudnative-pg-operator, dragonfly-cluster, dragonfly-operator | 5 |
| `default` | echo | 1 |
| `external-secrets` | external-secrets, onepassword-connect, onepassword-store | 3 |
| `flux-system` | cluster-apps, cluster-meta, flux-instance, flux-operator, tailscale-operator | 5 |
| `kube-system` | cilium, cilium-gateway, coredns, csi-driver-nfs, csi-driver-smb, metrics-server, reloader, spegel | 8 |
| `longhorn-system` | longhorn | 1 |
| `network` | cloudflare-dns, cloudflare-tunnel, k8s-gateway, unifi-dns | 4 |
| `observability` | gatus, keda, kube-prometheus-stack | 3 |
| `security` | authentik, authentik-secrets | 2 |
| `system-upgrade` | system-upgrade-controller, system-upgrade-controller-plans | 2 |
| `tools` | it-tools, pgadmin | 2 |
| `volsync-system` | openebs, snapshot-controller, volsync | 3 |

## Complete Dependency Overview

This section shows all dependencies (direct and indirect) for each kustomization.

### cert-manager/cert-manager

**Dependencies:** *None (root level)*

### database/cloudnative-pg-backup

**Total Dependencies:** 6

**Dependency Chain:**

- **Direct:** `database/cloudnative-pg-cluster`, `external-secrets/onepassword-store`
- **Level 2:** `database/cloudnative-pg-operator`, `longhorn-system/longhorn`, `external-secrets/external-secrets`, `external-secrets/onepassword-connect`

**All Dependencies (flat list):**
`database/cloudnative-pg-cluster`, `database/cloudnative-pg-operator`, `external-secrets/external-secrets`, `external-secrets/onepassword-connect`, `external-secrets/onepassword-store`, `longhorn-system/longhorn`


### database/cloudnative-pg-cluster

**Total Dependencies:** 5

**Dependency Chain:**

- **Direct:** `database/cloudnative-pg-operator`, `external-secrets/onepassword-store`, `longhorn-system/longhorn`
- **Level 2:** `external-secrets/external-secrets`, `external-secrets/onepassword-connect`

**All Dependencies (flat list):**
`database/cloudnative-pg-operator`, `external-secrets/external-secrets`, `external-secrets/onepassword-connect`, `external-secrets/onepassword-store`, `longhorn-system/longhorn`


### database/cloudnative-pg-operator

**Dependencies:** *None (root level)*

### database/dragonfly-cluster

**Total Dependencies:** 4

**Dependency Chain:**

- **Direct:** `database/dragonfly-operator`
- **Level 2:** `external-secrets/onepassword-store`
- **Level 3:** `external-secrets/external-secrets`, `external-secrets/onepassword-connect`

**All Dependencies (flat list):**
`database/dragonfly-operator`, `external-secrets/external-secrets`, `external-secrets/onepassword-connect`, `external-secrets/onepassword-store`


### database/dragonfly-operator

**Total Dependencies:** 3

**Dependency Chain:**

- **Direct:** `external-secrets/onepassword-store`
- **Level 2:** `external-secrets/external-secrets`, `external-secrets/onepassword-connect`

**All Dependencies (flat list):**
`external-secrets/external-secrets`, `external-secrets/onepassword-connect`, `external-secrets/onepassword-store`


### default/echo

**Dependencies:** *None (root level)*

### external-secrets/external-secrets

**Dependencies:** *None (root level)*

### external-secrets/onepassword-connect

**Total Dependencies:** 1

**Dependency Chain:**

- **Direct:** `external-secrets/external-secrets`

**All Dependencies (flat list):**
`external-secrets/external-secrets`


### external-secrets/onepassword-store

**Total Dependencies:** 2

**Dependency Chain:**

- **Direct:** `external-secrets/external-secrets`, `external-secrets/onepassword-connect`

**All Dependencies (flat list):**
`external-secrets/external-secrets`, `external-secrets/onepassword-connect`


### flux-system/cluster-apps

**Total Dependencies:** 1

**Dependency Chain:**

- **Direct:** `flux-system/cluster-meta`

**All Dependencies (flat list):**
`flux-system/cluster-meta`


### flux-system/cluster-meta

**Dependencies:** *None (root level)*

### flux-system/flux-instance

**Total Dependencies:** 1

**Dependency Chain:**

- **Direct:** `flux-system/flux-operator`

**All Dependencies (flat list):**
`flux-system/flux-operator`


### flux-system/flux-operator

**Dependencies:** *None (root level)*

### flux-system/tailscale-operator

**Total Dependencies:** 2

**Dependency Chain:**

- **Direct:** `external-secrets/onepassword-connect`
- **Level 2:** `external-secrets/external-secrets`

**All Dependencies (flat list):**
`external-secrets/external-secrets`, `external-secrets/onepassword-connect`


### kube-system/cilium

**Dependencies:** *None (root level)*

### kube-system/cilium-gateway

**Total Dependencies:** 1

**Dependency Chain:**

- **Direct:** `cert-manager/cert-manager`

**All Dependencies (flat list):**
`cert-manager/cert-manager`


### kube-system/coredns

**Dependencies:** *None (root level)*

### kube-system/csi-driver-nfs

**Dependencies:** *None (root level)*

### kube-system/csi-driver-smb

**Dependencies:** *None (root level)*

### kube-system/metrics-server

**Dependencies:** *None (root level)*

### kube-system/reloader

**Dependencies:** *None (root level)*

### kube-system/spegel

**Dependencies:** *None (root level)*

### longhorn-system/longhorn

**Total Dependencies:** 2

**Dependency Chain:**

- **Direct:** `external-secrets/onepassword-connect`
- **Level 2:** `external-secrets/external-secrets`

**All Dependencies (flat list):**
`external-secrets/external-secrets`, `external-secrets/onepassword-connect`


### network/cloudflare-dns

**Dependencies:** *None (root level)*

### network/cloudflare-tunnel

**Total Dependencies:** 3

**Dependency Chain:**

- **Direct:** `external-secrets/onepassword-store`
- **Level 2:** `external-secrets/external-secrets`, `external-secrets/onepassword-connect`

**All Dependencies (flat list):**
`external-secrets/external-secrets`, `external-secrets/onepassword-connect`, `external-secrets/onepassword-store`


### network/k8s-gateway

**Dependencies:** *None (root level)*

### network/unifi-dns

**Total Dependencies:** 2

**Dependency Chain:**

- **Direct:** `external-secrets/onepassword-connect`
- **Level 2:** `external-secrets/external-secrets`

**All Dependencies (flat list):**
`external-secrets/external-secrets`, `external-secrets/onepassword-connect`


### observability/gatus

**Total Dependencies:** 3

**Dependency Chain:**

- **Direct:** `longhorn-system/longhorn`
- **Level 2:** `external-secrets/onepassword-connect`
- **Level 3:** `external-secrets/external-secrets`

**All Dependencies (flat list):**
`external-secrets/external-secrets`, `external-secrets/onepassword-connect`, `longhorn-system/longhorn`


### observability/keda

**Dependencies:** *None (root level)*

### observability/kube-prometheus-stack

**Total Dependencies:** 4

**Dependency Chain:**

- **Direct:** `external-secrets/onepassword-store`, `longhorn-system/longhorn`
- **Level 2:** `external-secrets/external-secrets`, `external-secrets/onepassword-connect`

**All Dependencies (flat list):**
`external-secrets/external-secrets`, `external-secrets/onepassword-connect`, `external-secrets/onepassword-store`, `longhorn-system/longhorn`


### security/authentik

**Total Dependencies:** 12

**Dependency Chain:**

- **Direct:** `security/authentik-secrets`, `volsync-system/volsync`, `database/cloudnative-pg-cluster`, `database/dragonfly-cluster`
- **Level 2:** `external-secrets/onepassword-connect`, `volsync-system/snapshot-controller`, `volsync-system/openebs`, `longhorn-system/longhorn`, `database/cloudnative-pg-operator`, `external-secrets/onepassword-store`, `database/dragonfly-operator`
- **Level 3:** `external-secrets/external-secrets`

**All Dependencies (flat list):**
`database/cloudnative-pg-cluster`, `database/cloudnative-pg-operator`, `database/dragonfly-cluster`, `database/dragonfly-operator`, `external-secrets/external-secrets`, `external-secrets/onepassword-connect`, `external-secrets/onepassword-store`, `longhorn-system/longhorn`, `security/authentik-secrets`, `volsync-system/openebs`, `volsync-system/snapshot-controller`, `volsync-system/volsync`


### security/authentik-secrets

**Total Dependencies:** 2

**Dependency Chain:**

- **Direct:** `external-secrets/onepassword-connect`
- **Level 2:** `external-secrets/external-secrets`

**All Dependencies (flat list):**
`external-secrets/external-secrets`, `external-secrets/onepassword-connect`


### system-upgrade/system-upgrade-controller

**Dependencies:** *None (root level)*

### system-upgrade/system-upgrade-controller-plans

**Total Dependencies:** 1

**Dependency Chain:**

- **Direct:** `system-upgrade/system-upgrade-controller`

**All Dependencies (flat list):**
`system-upgrade/system-upgrade-controller`


### tools/it-tools

**Dependencies:** *None (root level)*

### tools/pgadmin

**Total Dependencies:** 9

**Dependency Chain:**

- **Direct:** `external-secrets/onepassword-store`, `database/cloudnative-pg-cluster`, `volsync-system/volsync`
- **Level 2:** `external-secrets/external-secrets`, `external-secrets/onepassword-connect`, `database/cloudnative-pg-operator`, `longhorn-system/longhorn`, `volsync-system/snapshot-controller`, `volsync-system/openebs`

**All Dependencies (flat list):**
`database/cloudnative-pg-cluster`, `database/cloudnative-pg-operator`, `external-secrets/external-secrets`, `external-secrets/onepassword-connect`, `external-secrets/onepassword-store`, `longhorn-system/longhorn`, `volsync-system/openebs`, `volsync-system/snapshot-controller`, `volsync-system/volsync`


### volsync-system/openebs

**Dependencies:** *None (root level)*

### volsync-system/snapshot-controller

**Dependencies:** *None (root level)*

### volsync-system/volsync

**Total Dependencies:** 5

**Dependency Chain:**

- **Direct:** `volsync-system/snapshot-controller`, `volsync-system/openebs`, `longhorn-system/longhorn`
- **Level 2:** `external-secrets/onepassword-connect`
- **Level 3:** `external-secrets/external-secrets`

**All Dependencies (flat list):**
`external-secrets/external-secrets`, `external-secrets/onepassword-connect`, `longhorn-system/longhorn`, `volsync-system/openebs`, `volsync-system/snapshot-controller`


## Deployment Order (Dependency Hierarchy)

This shows the deployment order based on dependencies. Items at the top are deployed first.

### Level 0
*Root level - no dependencies*

- **cert-manager/cert-manager**
  - *File:* `kubernetes/apps/cert-manager/cert-manager/ks.yaml`
  - *Path:* `./kubernetes/apps/cert-manager/cert-manager/app`
- **database/cloudnative-pg-operator**
  - *File:* `kubernetes/apps/database/cloudnative-pg/ks.yaml`
  - *Path:* `./kubernetes/apps/database/cloudnative-pg/operator`
- **default/echo**
  - *File:* `kubernetes/apps/default/echo/ks.yaml`
  - *Path:* `./kubernetes/apps/default/echo/app`
- **external-secrets/external-secrets**
  - *File:* `kubernetes/apps/external-secrets/external-secrets/ks.yaml`
  - *Path:* `./kubernetes/apps/external-secrets/external-secrets/app`
- **flux-system/cluster-meta**
  - *File:* `kubernetes/flux/cluster/ks.yaml`
  - *Path:* `./kubernetes/flux/meta`
- **flux-system/flux-operator**
  - *File:* `kubernetes/apps/flux-system/flux-operator/ks.yaml`
  - *Path:* `./kubernetes/apps/flux-system/flux-operator/app`
- **kube-system/cilium**
  - *File:* `kubernetes/apps/kube-system/cilium/ks.yaml`
  - *Path:* `./kubernetes/apps/kube-system/cilium/app`
- **kube-system/coredns**
  - *File:* `kubernetes/apps/kube-system/coredns/ks.yaml`
  - *Path:* `./kubernetes/apps/kube-system/coredns/app`
- **kube-system/csi-driver-nfs**
  - *File:* `kubernetes/apps/kube-system/csi-driver-nfs/ks.yaml`
  - *Path:* `./kubernetes/apps/kube-system/csi-driver-nfs/app`
- **kube-system/csi-driver-smb**
  - *File:* `kubernetes/apps/kube-system/csi-driver-smb/ks.yaml`
  - *Path:* `./kubernetes/apps/kube-system/csi-driver-smb/app`
- **kube-system/metrics-server**
  - *File:* `kubernetes/apps/kube-system/metrics-server/ks.yaml`
  - *Path:* `./kubernetes/apps/kube-system/metrics-server/app`
- **kube-system/reloader**
  - *File:* `kubernetes/apps/kube-system/reloader/ks.yaml`
  - *Path:* `./kubernetes/apps/kube-system/reloader/app`
- **kube-system/spegel**
  - *File:* `kubernetes/apps/kube-system/spegel/ks.yaml`
  - *Path:* `./kubernetes/apps/kube-system/spegel/app`
- **network/cloudflare-dns**
  - *File:* `kubernetes/apps/network/cloudflare-dns/ks.yaml`
  - *Path:* `./kubernetes/apps/network/cloudflare-dns`
- **network/k8s-gateway**
  - *File:* `kubernetes/apps/network/k8s-gateway/ks.yaml`
  - *Path:* `./kubernetes/apps/network/k8s-gateway`
- **observability/keda**
  - *File:* `kubernetes/apps/observability/keda/ks.yaml`
  - *Path:* `./kubernetes/apps/observability/keda/app`
- **system-upgrade/system-upgrade-controller**
  - *File:* `kubernetes/apps/system-upgrade/system-upgrade-controller/ks.yaml`
  - *Path:* `./kubernetes/apps/system-upgrade/system-upgrade-controller/app`
- **tools/it-tools**
  - *File:* `kubernetes/apps/tools/it-tools/ks.yaml`
  - *Path:* `./kubernetes/apps/tools/it-tools/app`
- **volsync-system/openebs**
  - *File:* `kubernetes/apps/volsync-system/openebs/ks.yaml`
  - *Path:* `./kubernetes/apps/volsync-system/openebs/app`
- **volsync-system/snapshot-controller**
  - *File:* `kubernetes/apps/volsync-system/snapshot-controller/ks.yaml`
  - *Path:* `./kubernetes/apps/volsync-system/snapshot-controller/app`

### Level 1
*Depends on items from level 0 and below*

- **external-secrets/onepassword-connect**
  - *File:* `kubernetes/apps/external-secrets/onepassword-connect/ks.yaml`
  - *Path:* `./kubernetes/apps/external-secrets/onepassword-connect/app`
  - *Dependencies:* `external-secrets/external-secrets`
- **flux-system/cluster-apps**
  - *File:* `kubernetes/flux/cluster/ks.yaml`
  - *Path:* `./kubernetes/apps`
  - *Dependencies:* `flux-system/cluster-meta`
- **flux-system/flux-instance**
  - *File:* `kubernetes/apps/flux-system/flux-instance/ks.yaml`
  - *Path:* `./kubernetes/apps/flux-system/flux-instance/app`
  - *Dependencies:* `flux-system/flux-operator`
- **kube-system/cilium-gateway**
  - *File:* `kubernetes/apps/kube-system/cilium/ks.yaml`
  - *Path:* `./kubernetes/apps/kube-system/cilium/gateway`
  - *Dependencies:* `cert-manager/cert-manager`
- **system-upgrade/system-upgrade-controller-plans**
  - *File:* `kubernetes/apps/system-upgrade/system-upgrade-controller/ks.yaml`
  - *Path:* `./kubernetes/apps/system-upgrade/system-upgrade-controller/plans`
  - *Dependencies:* `system-upgrade/system-upgrade-controller`

### Level 2
*Depends on items from level 1 and below*

- **external-secrets/onepassword-store**
  - *File:* `kubernetes/apps/external-secrets/external-secrets/ks.yaml`
  - *Path:* `./kubernetes/apps/external-secrets/external-secrets/stores/onepassword`
  - *Dependencies:* `external-secrets/external-secrets`, `external-secrets/onepassword-connect`
- **flux-system/tailscale-operator**
  - *File:* `kubernetes/apps/network/tailscale/ks.yaml`
  - *Path:* `./kubernetes/apps/network/tailscale/operator`
  - *Dependencies:* `external-secrets/onepassword-connect`
- **longhorn-system/longhorn**
  - *File:* `kubernetes/apps/storage/longhorn/ks.yaml`
  - *Path:* `./kubernetes/apps/storage/longhorn/app`
  - *Dependencies:* `external-secrets/onepassword-connect`
- **network/unifi-dns**
  - *File:* `kubernetes/apps/network/unifi-dns/ks.yaml`
  - *Path:* `./kubernetes/apps/network/unifi-dns/app`
  - *Dependencies:* `external-secrets/onepassword-connect`
- **security/authentik-secrets**
  - *File:* `kubernetes/apps/security/authentik/ks.yaml`
  - *Path:* `./kubernetes/apps/security/authentik/secrets`
  - *Dependencies:* `external-secrets/onepassword-connect`

### Level 3
*Depends on items from level 2 and below*

- **database/cloudnative-pg-cluster**
  - *File:* `kubernetes/apps/database/cloudnative-pg/ks.yaml`
  - *Path:* `./kubernetes/apps/database/cloudnative-pg/cluster`
  - *Dependencies:* `database/cloudnative-pg-operator`, `external-secrets/onepassword-store`, `longhorn-system/longhorn`
- **database/dragonfly-operator**
  - *File:* `kubernetes/apps/database/dragonfly/ks.yaml`
  - *Path:* `./kubernetes/apps/database/dragonfly/operator`
  - *Dependencies:* `external-secrets/onepassword-store`
- **network/cloudflare-tunnel**
  - *File:* `kubernetes/apps/network/cloudflare-tunnel/ks.yaml`
  - *Path:* `./kubernetes/apps/network/cloudflare-tunnel/app`
  - *Dependencies:* `external-secrets/onepassword-store`
- **observability/gatus**
  - *File:* `kubernetes/apps/observability/gatus/ks.yaml`
  - *Path:* `./kubernetes/apps/observability/gatus/app`
  - *Dependencies:* `longhorn-system/longhorn`
- **observability/kube-prometheus-stack**
  - *File:* `kubernetes/apps/observability/kube-prometheus-stack/ks.yaml`
  - *Path:* `./kubernetes/apps/observability/kube-prometheus-stack/app`
  - *Dependencies:* `external-secrets/onepassword-store`, `longhorn-system/longhorn`
- **volsync-system/volsync**
  - *File:* `kubernetes/apps/volsync-system/volsync/ks.yaml`
  - *Path:* `./kubernetes/apps/volsync-system/volsync/app`
  - *Dependencies:* `volsync-system/snapshot-controller`, `volsync-system/openebs`, `longhorn-system/longhorn`

### Level 4
*Depends on items from level 3 and below*

- **database/cloudnative-pg-backup**
  - *File:* `kubernetes/apps/database/cloudnative-pg/ks.yaml`
  - *Path:* `./kubernetes/apps/database/cloudnative-pg/backup`
  - *Dependencies:* `database/cloudnative-pg-cluster`, `external-secrets/onepassword-store`
- **database/dragonfly-cluster**
  - *File:* `kubernetes/apps/database/dragonfly/ks.yaml`
  - *Path:* `./kubernetes/apps/database/dragonfly/cluster`
  - *Dependencies:* `database/dragonfly-operator`
- **tools/pgadmin**
  - *File:* `kubernetes/apps/tools/pgadmin/ks.yaml`
  - *Path:* `./kubernetes/apps/tools/pgadmin/app`
  - *Dependencies:* `external-secrets/onepassword-store`, `database/cloudnative-pg-cluster`, `volsync-system/volsync`

### Level 5
*Depends on items from level 4 and below*

- **security/authentik**
  - *File:* `kubernetes/apps/security/authentik/ks.yaml`
  - *Path:* `./kubernetes/apps/security/authentik/app`
  - *Dependencies:* `security/authentik-secrets`, `volsync-system/volsync`, `database/cloudnative-pg-cluster`, `database/dragonfly-cluster`

## Detailed Dependency Matrix

| Kustomization | Namespace | Dependencies | Dependents |
|---------------|-----------|--------------|------------|
| `cert-manager` | `cert-manager` | *None* | `kube-system/cilium-gateway` |
| `cloudnative-pg-backup` | `database` | `database/cloudnative-pg-cluster`<br>`external-secrets/onepassword-store` | *None* |
| `cloudnative-pg-cluster` | `database` | `database/cloudnative-pg-operator`<br>`external-secrets/onepassword-store`<br>`longhorn-system/longhorn` | `tools/pgadmin`<br>`database/cloudnative-pg-backup`<br>`security/authentik` |
| `cloudnative-pg-operator` | `database` | *None* | `database/cloudnative-pg-cluster` |
| `dragonfly-cluster` | `database` | `database/dragonfly-operator` | `security/authentik` |
| `dragonfly-operator` | `database` | `external-secrets/onepassword-store` | `database/dragonfly-cluster` |
| `echo` | `default` | *None* | *None* |
| `external-secrets` | `external-secrets` | *None* | `external-secrets/onepassword-store`<br>`external-secrets/onepassword-connect` |
| `onepassword-connect` | `external-secrets` | `external-secrets/external-secrets` | `network/unifi-dns`<br>`flux-system/tailscale-operator`<br>`external-secrets/onepassword-store`<br>`security/authentik-secrets`<br>`longhorn-system/longhorn` |
| `onepassword-store` | `external-secrets` | `external-secrets/external-secrets`<br>`external-secrets/onepassword-connect` | `tools/pgadmin`<br>`observability/kube-prometheus-stack`<br>`database/cloudnative-pg-cluster`<br>`database/cloudnative-pg-backup`<br>`database/dragonfly-operator`<br>`network/cloudflare-tunnel` |
| `cluster-apps` | `flux-system` | `flux-system/cluster-meta` | *None* |
| `cluster-meta` | `flux-system` | *None* | `flux-system/cluster-apps` |
| `flux-instance` | `flux-system` | `flux-system/flux-operator` | *None* |
| `flux-operator` | `flux-system` | *None* | `flux-system/flux-instance` |
| `tailscale-operator` | `flux-system` | `external-secrets/onepassword-connect` | *None* |
| `cilium` | `kube-system` | *None* | *None* |
| `cilium-gateway` | `kube-system` | `cert-manager/cert-manager` | *None* |
| `coredns` | `kube-system` | *None* | *None* |
| `csi-driver-nfs` | `kube-system` | *None* | *None* |
| `csi-driver-smb` | `kube-system` | *None* | *None* |
| `metrics-server` | `kube-system` | *None* | *None* |
| `reloader` | `kube-system` | *None* | *None* |
| `spegel` | `kube-system` | *None* | *None* |
| `longhorn` | `longhorn-system` | `external-secrets/onepassword-connect` | `volsync-system/volsync`<br>`observability/kube-prometheus-stack`<br>`observability/gatus`<br>`database/cloudnative-pg-cluster` |
| `cloudflare-dns` | `network` | *None* | *None* |
| `cloudflare-tunnel` | `network` | `external-secrets/onepassword-store` | *None* |
| `k8s-gateway` | `network` | *None* | *None* |
| `unifi-dns` | `network` | `external-secrets/onepassword-connect` | *None* |
| `gatus` | `observability` | `longhorn-system/longhorn` | *None* |
| `keda` | `observability` | *None* | *None* |
| `kube-prometheus-stack` | `observability` | `external-secrets/onepassword-store`<br>`longhorn-system/longhorn` | *None* |
| `authentik` | `security` | `security/authentik-secrets`<br>`volsync-system/volsync`<br>`database/cloudnative-pg-cluster`<br>`database/dragonfly-cluster` | *None* |
| `authentik-secrets` | `security` | `external-secrets/onepassword-connect` | `security/authentik` |
| `system-upgrade-controller` | `system-upgrade` | *None* | `system-upgrade/system-upgrade-controller-plans` |
| `system-upgrade-controller-plans` | `system-upgrade` | `system-upgrade/system-upgrade-controller` | *None* |
| `it-tools` | `tools` | *None* | *None* |
| `pgadmin` | `tools` | `external-secrets/onepassword-store`<br>`database/cloudnative-pg-cluster`<br>`volsync-system/volsync` | *None* |
| `openebs` | `volsync-system` | *None* | `volsync-system/volsync` |
| `snapshot-controller` | `volsync-system` | *None* | `volsync-system/volsync` |
| `volsync` | `volsync-system` | `volsync-system/snapshot-controller`<br>`volsync-system/openebs`<br>`longhorn-system/longhorn` | `tools/pgadmin`<br>`security/authentik` |

## File Locations

| Kustomization | File Path |
|---------------|-----------|
| `cert-manager/cert-manager` | `kubernetes/apps/cert-manager/cert-manager/ks.yaml` |
| `database/cloudnative-pg-backup` | `kubernetes/apps/database/cloudnative-pg/ks.yaml` |
| `database/cloudnative-pg-cluster` | `kubernetes/apps/database/cloudnative-pg/ks.yaml` |
| `database/cloudnative-pg-operator` | `kubernetes/apps/database/cloudnative-pg/ks.yaml` |
| `database/dragonfly-cluster` | `kubernetes/apps/database/dragonfly/ks.yaml` |
| `database/dragonfly-operator` | `kubernetes/apps/database/dragonfly/ks.yaml` |
| `default/echo` | `kubernetes/apps/default/echo/ks.yaml` |
| `external-secrets/external-secrets` | `kubernetes/apps/external-secrets/external-secrets/ks.yaml` |
| `external-secrets/onepassword-connect` | `kubernetes/apps/external-secrets/onepassword-connect/ks.yaml` |
| `external-secrets/onepassword-store` | `kubernetes/apps/external-secrets/external-secrets/ks.yaml` |
| `flux-system/cluster-apps` | `kubernetes/flux/cluster/ks.yaml` |
| `flux-system/cluster-meta` | `kubernetes/flux/cluster/ks.yaml` |
| `flux-system/flux-instance` | `kubernetes/apps/flux-system/flux-instance/ks.yaml` |
| `flux-system/flux-operator` | `kubernetes/apps/flux-system/flux-operator/ks.yaml` |
| `flux-system/tailscale-operator` | `kubernetes/apps/network/tailscale/ks.yaml` |
| `kube-system/cilium` | `kubernetes/apps/kube-system/cilium/ks.yaml` |
| `kube-system/cilium-gateway` | `kubernetes/apps/kube-system/cilium/ks.yaml` |
| `kube-system/coredns` | `kubernetes/apps/kube-system/coredns/ks.yaml` |
| `kube-system/csi-driver-nfs` | `kubernetes/apps/kube-system/csi-driver-nfs/ks.yaml` |
| `kube-system/csi-driver-smb` | `kubernetes/apps/kube-system/csi-driver-smb/ks.yaml` |
| `kube-system/metrics-server` | `kubernetes/apps/kube-system/metrics-server/ks.yaml` |
| `kube-system/reloader` | `kubernetes/apps/kube-system/reloader/ks.yaml` |
| `kube-system/spegel` | `kubernetes/apps/kube-system/spegel/ks.yaml` |
| `longhorn-system/longhorn` | `kubernetes/apps/storage/longhorn/ks.yaml` |
| `network/cloudflare-dns` | `kubernetes/apps/network/cloudflare-dns/ks.yaml` |
| `network/cloudflare-tunnel` | `kubernetes/apps/network/cloudflare-tunnel/ks.yaml` |
| `network/k8s-gateway` | `kubernetes/apps/network/k8s-gateway/ks.yaml` |
| `network/unifi-dns` | `kubernetes/apps/network/unifi-dns/ks.yaml` |
| `observability/gatus` | `kubernetes/apps/observability/gatus/ks.yaml` |
| `observability/keda` | `kubernetes/apps/observability/keda/ks.yaml` |
| `observability/kube-prometheus-stack` | `kubernetes/apps/observability/kube-prometheus-stack/ks.yaml` |
| `security/authentik` | `kubernetes/apps/security/authentik/ks.yaml` |
| `security/authentik-secrets` | `kubernetes/apps/security/authentik/ks.yaml` |
| `system-upgrade/system-upgrade-controller` | `kubernetes/apps/system-upgrade/system-upgrade-controller/ks.yaml` |
| `system-upgrade/system-upgrade-controller-plans` | `kubernetes/apps/system-upgrade/system-upgrade-controller/ks.yaml` |
| `tools/it-tools` | `kubernetes/apps/tools/it-tools/ks.yaml` |
| `tools/pgadmin` | `kubernetes/apps/tools/pgadmin/ks.yaml` |
| `volsync-system/openebs` | `kubernetes/apps/volsync-system/openebs/ks.yaml` |
| `volsync-system/snapshot-controller` | `kubernetes/apps/volsync-system/snapshot-controller/ks.yaml` |
| `volsync-system/volsync` | `kubernetes/apps/volsync-system/volsync/ks.yaml` |

---
*Generated automatically by the Flux Kustomization Dependency Visualizer*
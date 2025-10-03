# Flux Kustomization Dependencies

This document shows the dependency relationships between all Flux Kustomizations in the cluster.

**Total Kustomizations:** 52

## Table of Contents

1. [Summary by Namespace](#summary-by-namespace)
2. [Complete Dependency Overview](#complete-dependency-overview)
3. [Deployment Order (Dependency Hierarchy)](#deployment-order-dependency-hierarchy)
4. [Detailed Dependency Matrix](#detailed-dependency-matrix)
5. [File Locations](#file-locations)

## Summary by Namespace

| Namespace | Kustomizations | Count |
|-----------|----------------|-------|
| `actions-runner-system` | actions-runner-controller, actions-runner-controller-runners | 2 |
| `cert-manager` | cert-manager | 1 |
| `database` | cloudnative-pg-backup, cloudnative-pg-barman-cloud, cloudnative-pg-cluster, cloudnative-pg-operator, dragonfly-cluster, dragonfly-operator | 6 |
| `default` | echo, whoami | 2 |
| `external` | kvm-pve1, kvm-pve2, kvm-pve4, nas, proxmox-ve | 5 |
| `external-secrets` | external-secrets, onepassword-connect, onepassword-store | 3 |
| `flux-system` | cluster-apps, cluster-meta, flux-instance, flux-operator | 4 |
| `kube-system` | cilium, cilium-gateway, coredns, csi-driver-nfs, csi-driver-smb, metrics-server, reloader, spegel | 8 |
| `longhorn-system` | longhorn | 1 |
| `network` | cloudflare-dns, cloudflare-tunnel, k8s-gateway, unifi-dns | 4 |
| `observability` | gatus, keda, kube-prometheus-stack | 3 |
| `security` | authentik | 1 |
| `system-upgrade` | system-upgrade-controller, system-upgrade-controller-plans | 2 |
| `tailscale` | tailscale-configs, tailscale-operator | 2 |
| `tools` | it-tools, n8n, paperless, persistence-smb-volumes, pgadmin | 5 |
| `volsync-system` | openebs, snapshot-controller, volsync | 3 |

## Complete Dependency Overview

This section shows all dependencies (direct and indirect) for each kustomization.

### actions-runner-system/actions-runner-controller

**Dependencies:** *None (root level)*

### actions-runner-system/actions-runner-controller-runners

**Total Dependencies:** 5

**Dependency Chain:**

- **Direct:** `actions-runner-system/actions-runner-controller`, `external-secrets/onepassword-store`, `volsync-system/openebs`
- **Level 2:** `external-secrets/external-secrets`, `external-secrets/onepassword-connect`

**All Dependencies (flat list):**
`actions-runner-system/actions-runner-controller`, `external-secrets/external-secrets`, `external-secrets/onepassword-connect`, `external-secrets/onepassword-store`, `volsync-system/openebs`


### cert-manager/cert-manager

**Dependencies:** *None (root level)*

### database/cloudnative-pg-backup

**Total Dependencies:** 8

**Dependency Chain:**

- **Direct:** `database/cloudnative-pg-cluster`, `external-secrets/onepassword-store`
- **Level 2:** `database/cloudnative-pg-operator`, `database/cloudnative-pg-barman-cloud`, `longhorn-system/longhorn`, `external-secrets/external-secrets`, `external-secrets/onepassword-connect`
- **Level 3:** `cert-manager/cert-manager`

**All Dependencies (flat list):**
`cert-manager/cert-manager`, `database/cloudnative-pg-barman-cloud`, `database/cloudnative-pg-cluster`, `database/cloudnative-pg-operator`, `external-secrets/external-secrets`, `external-secrets/onepassword-connect`, `external-secrets/onepassword-store`, `longhorn-system/longhorn`


### database/cloudnative-pg-barman-cloud

**Total Dependencies:** 2

**Dependency Chain:**

- **Direct:** `cert-manager/cert-manager`, `database/cloudnative-pg-operator`

**All Dependencies (flat list):**
`cert-manager/cert-manager`, `database/cloudnative-pg-operator`


### database/cloudnative-pg-cluster

**Total Dependencies:** 7

**Dependency Chain:**

- **Direct:** `database/cloudnative-pg-operator`, `database/cloudnative-pg-barman-cloud`, `external-secrets/onepassword-store`, `longhorn-system/longhorn`
- **Level 2:** `cert-manager/cert-manager`, `external-secrets/external-secrets`, `external-secrets/onepassword-connect`

**All Dependencies (flat list):**
`cert-manager/cert-manager`, `database/cloudnative-pg-barman-cloud`, `database/cloudnative-pg-operator`, `external-secrets/external-secrets`, `external-secrets/onepassword-connect`, `external-secrets/onepassword-store`, `longhorn-system/longhorn`


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

### default/whoami

**Dependencies:** *None (root level)*

### external/kvm-pve1

**Total Dependencies:** 1

**Dependency Chain:**

- **Direct:** `network/k8s-gateway`

**All Dependencies (flat list):**
`network/k8s-gateway`


### external/kvm-pve2

**Total Dependencies:** 1

**Dependency Chain:**

- **Direct:** `network/k8s-gateway`

**All Dependencies (flat list):**
`network/k8s-gateway`


### external/kvm-pve4

**Total Dependencies:** 1

**Dependency Chain:**

- **Direct:** `network/k8s-gateway`

**All Dependencies (flat list):**
`network/k8s-gateway`


### external/nas

**Total Dependencies:** 1

**Dependency Chain:**

- **Direct:** `network/k8s-gateway`

**All Dependencies (flat list):**
`network/k8s-gateway`


### external/proxmox-ve

**Total Dependencies:** 1

**Dependency Chain:**

- **Direct:** `network/k8s-gateway`

**All Dependencies (flat list):**
`network/k8s-gateway`


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

**Total Dependencies:** 6

**Dependency Chain:**

- **Direct:** `volsync-system/volsync`
- **Level 2:** `volsync-system/snapshot-controller`, `volsync-system/openebs`, `longhorn-system/longhorn`
- **Level 3:** `external-secrets/onepassword-connect`
- **Level 4:** `external-secrets/external-secrets`

**All Dependencies (flat list):**
`external-secrets/external-secrets`, `external-secrets/onepassword-connect`, `longhorn-system/longhorn`, `volsync-system/openebs`, `volsync-system/snapshot-controller`, `volsync-system/volsync`


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

**Total Dependencies:** 13

**Dependency Chain:**

- **Direct:** `external-secrets/onepassword-store`, `volsync-system/volsync`, `database/cloudnative-pg-cluster`, `database/dragonfly-cluster`
- **Level 2:** `external-secrets/external-secrets`, `external-secrets/onepassword-connect`, `volsync-system/snapshot-controller`, `volsync-system/openebs`, `longhorn-system/longhorn`, `database/cloudnative-pg-operator`, `database/cloudnative-pg-barman-cloud`, `database/dragonfly-operator`
- **Level 3:** `cert-manager/cert-manager`

**All Dependencies (flat list):**
`cert-manager/cert-manager`, `database/cloudnative-pg-barman-cloud`, `database/cloudnative-pg-cluster`, `database/cloudnative-pg-operator`, `database/dragonfly-cluster`, `database/dragonfly-operator`, `external-secrets/external-secrets`, `external-secrets/onepassword-connect`, `external-secrets/onepassword-store`, `longhorn-system/longhorn`, `volsync-system/openebs`, `volsync-system/snapshot-controller`, `volsync-system/volsync`


### system-upgrade/system-upgrade-controller

**Dependencies:** *None (root level)*

### system-upgrade/system-upgrade-controller-plans

**Total Dependencies:** 1

**Dependency Chain:**

- **Direct:** `system-upgrade/system-upgrade-controller`

**All Dependencies (flat list):**
`system-upgrade/system-upgrade-controller`


### tailscale/tailscale-configs

**Total Dependencies:** 1

**Dependency Chain:**

- **Direct:** `tailscale/tailscale-operator`

**All Dependencies (flat list):**
`tailscale/tailscale-operator`


### tailscale/tailscale-operator

**Dependencies:** *None (root level)*

### tools/it-tools

**Dependencies:** *None (root level)*

### tools/n8n

**Total Dependencies:** 7

**Dependency Chain:**

- **Direct:** `external-secrets/onepassword-store`, `volsync-system/volsync`
- **Level 2:** `external-secrets/external-secrets`, `external-secrets/onepassword-connect`, `volsync-system/snapshot-controller`, `volsync-system/openebs`, `longhorn-system/longhorn`

**All Dependencies (flat list):**
`external-secrets/external-secrets`, `external-secrets/onepassword-connect`, `external-secrets/onepassword-store`, `longhorn-system/longhorn`, `volsync-system/openebs`, `volsync-system/snapshot-controller`, `volsync-system/volsync`


### tools/paperless

**Total Dependencies:** 11

**Dependency Chain:**

- **Direct:** `external-secrets/onepassword-store`, `database/cloudnative-pg-cluster`, `volsync-system/volsync`
- **Level 2:** `external-secrets/external-secrets`, `external-secrets/onepassword-connect`, `database/cloudnative-pg-operator`, `database/cloudnative-pg-barman-cloud`, `longhorn-system/longhorn`, `volsync-system/snapshot-controller`, `volsync-system/openebs`
- **Level 3:** `cert-manager/cert-manager`

**All Dependencies (flat list):**
`cert-manager/cert-manager`, `database/cloudnative-pg-barman-cloud`, `database/cloudnative-pg-cluster`, `database/cloudnative-pg-operator`, `external-secrets/external-secrets`, `external-secrets/onepassword-connect`, `external-secrets/onepassword-store`, `longhorn-system/longhorn`, `volsync-system/openebs`, `volsync-system/snapshot-controller`, `volsync-system/volsync`


### tools/persistence-smb-volumes

**Total Dependencies:** 1

**Dependency Chain:**

- **Direct:** `kube-system/csi-driver-smb`

**All Dependencies (flat list):**
`kube-system/csi-driver-smb`


### tools/pgadmin

**Total Dependencies:** 11

**Dependency Chain:**

- **Direct:** `external-secrets/onepassword-store`, `database/cloudnative-pg-cluster`, `volsync-system/volsync`
- **Level 2:** `external-secrets/external-secrets`, `external-secrets/onepassword-connect`, `database/cloudnative-pg-operator`, `database/cloudnative-pg-barman-cloud`, `longhorn-system/longhorn`, `volsync-system/snapshot-controller`, `volsync-system/openebs`
- **Level 3:** `cert-manager/cert-manager`

**All Dependencies (flat list):**
`cert-manager/cert-manager`, `database/cloudnative-pg-barman-cloud`, `database/cloudnative-pg-cluster`, `database/cloudnative-pg-operator`, `external-secrets/external-secrets`, `external-secrets/onepassword-connect`, `external-secrets/onepassword-store`, `longhorn-system/longhorn`, `volsync-system/openebs`, `volsync-system/snapshot-controller`, `volsync-system/volsync`


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

- **actions-runner-system/actions-runner-controller**
  - *File:* `kubernetes/apps/actions-runner-system/actions-runner-controller/ks.yaml`
  - *Path:* `./kubernetes/apps/actions-runner-system/actions-runner-controller/app`
- **cert-manager/cert-manager**
  - *File:* `kubernetes/apps/cert-manager/cert-manager/ks.yaml`
  - *Path:* `./kubernetes/apps/cert-manager/cert-manager/app`
- **database/cloudnative-pg-operator**
  - *File:* `kubernetes/apps/database/cloudnative-pg/ks.yaml`
  - *Path:* `./kubernetes/apps/database/cloudnative-pg/operator`
- **default/echo**
  - *File:* `kubernetes/apps/default/echo/ks.yaml`
  - *Path:* `./kubernetes/apps/default/echo/app`
- **default/whoami**
  - *File:* `kubernetes/apps/default/whoami/ks.yaml`
  - *Path:* `./kubernetes/apps/default/whoami/app`
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
  - *Path:* `./kubernetes/apps/network/k8s-gateway/app`
- **observability/keda**
  - *File:* `kubernetes/apps/observability/keda/ks.yaml`
  - *Path:* `./kubernetes/apps/observability/keda/app`
- **system-upgrade/system-upgrade-controller**
  - *File:* `kubernetes/apps/system-upgrade/system-upgrade-controller/ks.yaml`
  - *Path:* `./kubernetes/apps/system-upgrade/system-upgrade-controller/app`
- **tailscale/tailscale-operator**
  - *File:* `kubernetes/apps/tailscale/tailscale/ks.yaml`
  - *Path:* `./kubernetes/apps/tailscale/tailscale/operator`
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

- **database/cloudnative-pg-barman-cloud**
  - *File:* `kubernetes/apps/database/cloudnative-pg/ks.yaml`
  - *Path:* `./kubernetes/apps/database/cloudnative-pg/barman-cloud`
  - *Dependencies:* `cert-manager/cert-manager`, `database/cloudnative-pg-operator`
- **external/kvm-pve1**
  - *File:* `kubernetes/apps/external/kvm-pve1/ks.yaml`
  - *Path:* `./kubernetes/apps/external/kvm-pve1/resources`
  - *Dependencies:* `network/k8s-gateway`
- **external/kvm-pve2**
  - *File:* `kubernetes/apps/external/kvm-pve2/ks.yaml`
  - *Path:* `./kubernetes/apps/external/kvm-pve2/resources`
  - *Dependencies:* `network/k8s-gateway`
- **external/kvm-pve4**
  - *File:* `kubernetes/apps/external/kvm-pve4/ks.yaml`
  - *Path:* `./kubernetes/apps/external/kvm-pve4/resources`
  - *Dependencies:* `network/k8s-gateway`
- **external/nas**
  - *File:* `kubernetes/apps/external/nas/ks.yaml`
  - *Path:* `./kubernetes/apps/external/nas/resources`
  - *Dependencies:* `network/k8s-gateway`
- **external/proxmox-ve**
  - *File:* `kubernetes/apps/external/proxmox-ve/ks.yaml`
  - *Path:* `./kubernetes/apps/external/proxmox-ve/resources`
  - *Dependencies:* `network/k8s-gateway`
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
- **tailscale/tailscale-configs**
  - *File:* `kubernetes/apps/tailscale/tailscale/ks.yaml`
  - *Path:* `./kubernetes/apps/tailscale/tailscale/configs`
  - *Dependencies:* `tailscale/tailscale-operator`
- **tools/persistence-smb-volumes**
  - *File:* `kubernetes/apps/tools/persistence/ks.yaml`
  - *Path:* `./kubernetes/apps/tools/persistence/smb-volumes`
  - *Dependencies:* `kube-system/csi-driver-smb`

### Level 2
*Depends on items from level 1 and below*

- **external-secrets/onepassword-store**
  - *File:* `kubernetes/apps/external-secrets/external-secrets/ks.yaml`
  - *Path:* `./kubernetes/apps/external-secrets/external-secrets/stores/onepassword`
  - *Dependencies:* `external-secrets/external-secrets`, `external-secrets/onepassword-connect`
- **longhorn-system/longhorn**
  - *File:* `kubernetes/apps/storage/longhorn/ks.yaml`
  - *Path:* `./kubernetes/apps/storage/longhorn/app`
  - *Dependencies:* `external-secrets/onepassword-connect`
- **network/unifi-dns**
  - *File:* `kubernetes/apps/network/unifi-dns/ks.yaml`
  - *Path:* `./kubernetes/apps/network/unifi-dns/app`
  - *Dependencies:* `external-secrets/onepassword-connect`

### Level 3
*Depends on items from level 2 and below*

- **actions-runner-system/actions-runner-controller-runners**
  - *File:* `kubernetes/apps/actions-runner-system/actions-runner-controller/ks.yaml`
  - *Path:* `./kubernetes/apps/actions-runner-system/actions-runner-controller/runners`
  - *Dependencies:* `actions-runner-system/actions-runner-controller`, `external-secrets/onepassword-store`, `volsync-system/openebs`
- **database/cloudnative-pg-cluster**
  - *File:* `kubernetes/apps/database/cloudnative-pg/ks.yaml`
  - *Path:* `./kubernetes/apps/database/cloudnative-pg/cluster`
  - *Dependencies:* `database/cloudnative-pg-operator`, `database/cloudnative-pg-barman-cloud`, `external-secrets/onepassword-store`, `longhorn-system/longhorn`
- **database/dragonfly-operator**
  - *File:* `kubernetes/apps/database/dragonfly/ks.yaml`
  - *Path:* `./kubernetes/apps/database/dragonfly/operator`
  - *Dependencies:* `external-secrets/onepassword-store`
- **network/cloudflare-tunnel**
  - *File:* `kubernetes/apps/network/cloudflare-tunnel/ks.yaml`
  - *Path:* `./kubernetes/apps/network/cloudflare-tunnel/app`
  - *Dependencies:* `external-secrets/onepassword-store`
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
- **observability/gatus**
  - *File:* `kubernetes/apps/observability/gatus/ks.yaml`
  - *Path:* `./kubernetes/apps/observability/gatus/app`
  - *Dependencies:* `volsync-system/volsync`
- **tools/n8n**
  - *File:* `kubernetes/apps/tools/n8n/ks.yaml`
  - *Path:* `./kubernetes/apps/tools/n8n/app`
  - *Dependencies:* `external-secrets/onepassword-store`, `volsync-system/volsync`
- **tools/paperless**
  - *File:* `kubernetes/apps/tools/paperless/ks.yaml`
  - *Path:* `./kubernetes/apps/tools/paperless/app`
  - *Dependencies:* `external-secrets/onepassword-store`, `database/cloudnative-pg-cluster`, `volsync-system/volsync`
- **tools/pgadmin**
  - *File:* `kubernetes/apps/tools/pgadmin/ks.yaml`
  - *Path:* `./kubernetes/apps/tools/pgadmin/app`
  - *Dependencies:* `external-secrets/onepassword-store`, `database/cloudnative-pg-cluster`, `volsync-system/volsync`

### Level 5
*Depends on items from level 4 and below*

- **security/authentik**
  - *File:* `kubernetes/apps/security/authentik/ks.yaml`
  - *Path:* `./kubernetes/apps/security/authentik/app`
  - *Dependencies:* `external-secrets/onepassword-store`, `volsync-system/volsync`, `database/cloudnative-pg-cluster`, `database/dragonfly-cluster`

## Detailed Dependency Matrix

| Kustomization | Namespace | Dependencies | Dependents |
|---------------|-----------|--------------|------------|
| `actions-runner-controller` | `actions-runner-system` | *None* | `actions-runner-system/actions-runner-controller-runners` |
| `actions-runner-controller-runners` | `actions-runner-system` | `actions-runner-system/actions-runner-controller`<br>`external-secrets/onepassword-store`<br>`volsync-system/openebs` | *None* |
| `cert-manager` | `cert-manager` | *None* | `kube-system/cilium-gateway`<br>`database/cloudnative-pg-barman-cloud` |
| `cloudnative-pg-backup` | `database` | `database/cloudnative-pg-cluster`<br>`external-secrets/onepassword-store` | *None* |
| `cloudnative-pg-barman-cloud` | `database` | `cert-manager/cert-manager`<br>`database/cloudnative-pg-operator` | `database/cloudnative-pg-cluster` |
| `cloudnative-pg-cluster` | `database` | `database/cloudnative-pg-operator`<br>`database/cloudnative-pg-barman-cloud`<br>`external-secrets/onepassword-store`<br>`longhorn-system/longhorn` | `tools/paperless`<br>`tools/pgadmin`<br>`database/cloudnative-pg-backup`<br>`security/authentik` |
| `cloudnative-pg-operator` | `database` | *None* | `database/cloudnative-pg-barman-cloud`<br>`database/cloudnative-pg-cluster` |
| `dragonfly-cluster` | `database` | `database/dragonfly-operator` | `security/authentik` |
| `dragonfly-operator` | `database` | `external-secrets/onepassword-store` | `database/dragonfly-cluster` |
| `echo` | `default` | *None* | *None* |
| `whoami` | `default` | *None* | *None* |
| `kvm-pve1` | `external` | `network/k8s-gateway` | *None* |
| `kvm-pve2` | `external` | `network/k8s-gateway` | *None* |
| `kvm-pve4` | `external` | `network/k8s-gateway` | *None* |
| `nas` | `external` | `network/k8s-gateway` | *None* |
| `proxmox-ve` | `external` | `network/k8s-gateway` | *None* |
| `external-secrets` | `external-secrets` | *None* | `external-secrets/onepassword-store`<br>`external-secrets/onepassword-connect` |
| `onepassword-connect` | `external-secrets` | `external-secrets/external-secrets` | `network/unifi-dns`<br>`external-secrets/onepassword-store`<br>`longhorn-system/longhorn` |
| `onepassword-store` | `external-secrets` | `external-secrets/external-secrets`<br>`external-secrets/onepassword-connect` | `tools/n8n`<br>`tools/paperless`<br>`tools/pgadmin`<br>`actions-runner-system/actions-runner-controller-runners`<br>`observability/kube-prometheus-stack`<br>`database/cloudnative-pg-cluster`<br>`database/cloudnative-pg-backup`<br>`database/dragonfly-operator`<br>`network/cloudflare-tunnel`<br>`security/authentik` |
| `cluster-apps` | `flux-system` | `flux-system/cluster-meta` | *None* |
| `cluster-meta` | `flux-system` | *None* | `flux-system/cluster-apps` |
| `flux-instance` | `flux-system` | `flux-system/flux-operator` | *None* |
| `flux-operator` | `flux-system` | *None* | `flux-system/flux-instance` |
| `cilium` | `kube-system` | *None* | *None* |
| `cilium-gateway` | `kube-system` | `cert-manager/cert-manager` | *None* |
| `coredns` | `kube-system` | *None* | *None* |
| `csi-driver-nfs` | `kube-system` | *None* | *None* |
| `csi-driver-smb` | `kube-system` | *None* | `tools/persistence-smb-volumes` |
| `metrics-server` | `kube-system` | *None* | *None* |
| `reloader` | `kube-system` | *None* | *None* |
| `spegel` | `kube-system` | *None* | *None* |
| `longhorn` | `longhorn-system` | `external-secrets/onepassword-connect` | `volsync-system/volsync`<br>`observability/kube-prometheus-stack`<br>`database/cloudnative-pg-cluster` |
| `cloudflare-dns` | `network` | *None* | *None* |
| `cloudflare-tunnel` | `network` | `external-secrets/onepassword-store` | *None* |
| `k8s-gateway` | `network` | *None* | `external/kvm-pve1`<br>`external/nas`<br>`external/kvm-pve2`<br>`external/kvm-pve4`<br>`external/proxmox-ve` |
| `unifi-dns` | `network` | `external-secrets/onepassword-connect` | *None* |
| `gatus` | `observability` | `volsync-system/volsync` | *None* |
| `keda` | `observability` | *None* | *None* |
| `kube-prometheus-stack` | `observability` | `external-secrets/onepassword-store`<br>`longhorn-system/longhorn` | *None* |
| `authentik` | `security` | `external-secrets/onepassword-store`<br>`volsync-system/volsync`<br>`database/cloudnative-pg-cluster`<br>`database/dragonfly-cluster` | *None* |
| `system-upgrade-controller` | `system-upgrade` | *None* | `system-upgrade/system-upgrade-controller-plans` |
| `system-upgrade-controller-plans` | `system-upgrade` | `system-upgrade/system-upgrade-controller` | *None* |
| `tailscale-configs` | `tailscale` | `tailscale/tailscale-operator` | *None* |
| `tailscale-operator` | `tailscale` | *None* | `tailscale/tailscale-configs` |
| `it-tools` | `tools` | *None* | *None* |
| `n8n` | `tools` | `external-secrets/onepassword-store`<br>`volsync-system/volsync` | *None* |
| `paperless` | `tools` | `external-secrets/onepassword-store`<br>`database/cloudnative-pg-cluster`<br>`volsync-system/volsync` | *None* |
| `persistence-smb-volumes` | `tools` | `kube-system/csi-driver-smb` | *None* |
| `pgadmin` | `tools` | `external-secrets/onepassword-store`<br>`database/cloudnative-pg-cluster`<br>`volsync-system/volsync` | *None* |
| `openebs` | `volsync-system` | *None* | `actions-runner-system/actions-runner-controller-runners`<br>`volsync-system/volsync` |
| `snapshot-controller` | `volsync-system` | *None* | `volsync-system/volsync` |
| `volsync` | `volsync-system` | `volsync-system/snapshot-controller`<br>`volsync-system/openebs`<br>`longhorn-system/longhorn` | `tools/n8n`<br>`tools/paperless`<br>`tools/pgadmin`<br>`observability/gatus`<br>`security/authentik` |

## File Locations

| Kustomization | File Path |
|---------------|-----------|
| `actions-runner-system/actions-runner-controller` | `kubernetes/apps/actions-runner-system/actions-runner-controller/ks.yaml` |
| `actions-runner-system/actions-runner-controller-runners` | `kubernetes/apps/actions-runner-system/actions-runner-controller/ks.yaml` |
| `cert-manager/cert-manager` | `kubernetes/apps/cert-manager/cert-manager/ks.yaml` |
| `database/cloudnative-pg-backup` | `kubernetes/apps/database/cloudnative-pg/ks.yaml` |
| `database/cloudnative-pg-barman-cloud` | `kubernetes/apps/database/cloudnative-pg/ks.yaml` |
| `database/cloudnative-pg-cluster` | `kubernetes/apps/database/cloudnative-pg/ks.yaml` |
| `database/cloudnative-pg-operator` | `kubernetes/apps/database/cloudnative-pg/ks.yaml` |
| `database/dragonfly-cluster` | `kubernetes/apps/database/dragonfly/ks.yaml` |
| `database/dragonfly-operator` | `kubernetes/apps/database/dragonfly/ks.yaml` |
| `default/echo` | `kubernetes/apps/default/echo/ks.yaml` |
| `default/whoami` | `kubernetes/apps/default/whoami/ks.yaml` |
| `external/kvm-pve1` | `kubernetes/apps/external/kvm-pve1/ks.yaml` |
| `external/kvm-pve2` | `kubernetes/apps/external/kvm-pve2/ks.yaml` |
| `external/kvm-pve4` | `kubernetes/apps/external/kvm-pve4/ks.yaml` |
| `external/nas` | `kubernetes/apps/external/nas/ks.yaml` |
| `external/proxmox-ve` | `kubernetes/apps/external/proxmox-ve/ks.yaml` |
| `external-secrets/external-secrets` | `kubernetes/apps/external-secrets/external-secrets/ks.yaml` |
| `external-secrets/onepassword-connect` | `kubernetes/apps/external-secrets/onepassword-connect/ks.yaml` |
| `external-secrets/onepassword-store` | `kubernetes/apps/external-secrets/external-secrets/ks.yaml` |
| `flux-system/cluster-apps` | `kubernetes/flux/cluster/ks.yaml` |
| `flux-system/cluster-meta` | `kubernetes/flux/cluster/ks.yaml` |
| `flux-system/flux-instance` | `kubernetes/apps/flux-system/flux-instance/ks.yaml` |
| `flux-system/flux-operator` | `kubernetes/apps/flux-system/flux-operator/ks.yaml` |
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
| `system-upgrade/system-upgrade-controller` | `kubernetes/apps/system-upgrade/system-upgrade-controller/ks.yaml` |
| `system-upgrade/system-upgrade-controller-plans` | `kubernetes/apps/system-upgrade/system-upgrade-controller/ks.yaml` |
| `tailscale/tailscale-configs` | `kubernetes/apps/tailscale/tailscale/ks.yaml` |
| `tailscale/tailscale-operator` | `kubernetes/apps/tailscale/tailscale/ks.yaml` |
| `tools/it-tools` | `kubernetes/apps/tools/it-tools/ks.yaml` |
| `tools/n8n` | `kubernetes/apps/tools/n8n/ks.yaml` |
| `tools/paperless` | `kubernetes/apps/tools/paperless/ks.yaml` |
| `tools/persistence-smb-volumes` | `kubernetes/apps/tools/persistence/ks.yaml` |
| `tools/pgadmin` | `kubernetes/apps/tools/pgadmin/ks.yaml` |
| `volsync-system/openebs` | `kubernetes/apps/volsync-system/openebs/ks.yaml` |
| `volsync-system/snapshot-controller` | `kubernetes/apps/volsync-system/snapshot-controller/ks.yaml` |
| `volsync-system/volsync` | `kubernetes/apps/volsync-system/volsync/ks.yaml` |

---
*Generated automatically by the Flux Kustomization Dependency Visualizer*
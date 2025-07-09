# VolSync Template

## Flux Kustomization

This requires `components` and `postBuild` configured on the Flux Kustomization

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: &app plex
  namespace: flux-system
spec:
  # ...
  components:
    - ../../../../components/volsync
  # ...
  postBuild:
    substitute:
      APP: *app
      VOLSYNC_CAPACITY: 5Gi
```

## Required `postBuild` vars:

- `APP`: The application name
- `VOLSYNC_CAPACITY`: The PVC size

## Optional `postBuild` vars:

- `VOLSYNC_UID`: Defaults to `65534`
- `VOLSYNC_GID`: Defaults to `65534`
- `VOLSYNC_CLAIM`: Defaults to `${APP}`
- `VOLSYNC_COPYMETHOD`: Defaults to `Snapshot`
- `VOLSYNC_ACCESSMODES`: Defaults to `ReadWriteOnce`
- `VOLSYNC_SNAP_ACCESSMODES`: Defaults to `ReadWriteOnce`
- `VOLSYNC_CACHE_ACCESSMODES`: Defaults to `ReadWriteOnce`
- `VOLSYNC_SNAPSHOTCLASS`: Defaults to `longhorn-snapclass`
- `VOLSYNC_CACHE_CAPACITY`: Defaults to `8Gi`
- `VOLSYNC_CACHE_SNAPSHOTCLASS`: Defaults to `openebs-hostpath`

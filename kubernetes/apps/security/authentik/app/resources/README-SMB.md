# Authentik SMB Media Share

This setup provides an SMB share mounted at `/media/smb` in your Authentik pods for easy file management.

## SMB Share Configuration

The SMB share is mounted using the SMB CSI driver with the following configuration:
- **Mount point in pod**: `/media/smb`
- **SMB server**: `${SMB_SERVER}`
- **SMB path**: `/authentik-media` (adjust in `media-smb-pvc.yaml` if needed)
- **Storage**: 10Gi (adjust as needed)

## Usage

### Copying Files to Authentik

1. **Access the Authentik server pod**:
   ```bash
   kubectl exec -it deployment/authentik-server -n security -- bash
   ```

2. **Navigate to the SMB mount**:
   ```bash
   cd /media/smb
   ```

3. **Copy files from SMB to Authentik media directories**:
   ```bash
   # Copy flow backgrounds
   cp /media/smb/backgrounds/* /media/public/flow-backgrounds/

   # Copy custom icons
   cp /media/smb/icons/* /web/dist/assets/icons/custom/

   # Set proper permissions
   chown -R 1000:1000 /media/public/flow-backgrounds/
   chown -R 1000:1000 /web/dist/assets/icons/custom/
   ```

### Adding Files to SMB Share

1. **From your workstation**, access the SMB share at:
   ```
   \\${SMB_SERVER}\authentik-media
   ```

2. **Create subdirectories for organization**:
   ```
   authentik-media/
   ├── backgrounds/     # Flow background images
   ├── icons/          # Custom brand icons
   ├── templates/      # Custom templates
   └── css/           # Custom CSS files
   ```

3. **Upload your files** to the appropriate directories

### File Paths in Authentik Configuration

After copying files, reference them in Authentik as:
- **Flow backgrounds**: `/media/public/flow-backgrounds/<filename>`
- **Custom icons**: `/web/dist/assets/icons/custom/<filename>`

## Automation with Init Container (Optional)

For automatic file synchronization, you could add an init container that copies files from SMB to the appropriate locations on pod startup.

## Troubleshooting

### Check SMB Mount
```bash
kubectl exec -it deployment/authentik-server -n security -- ls -la /media/smb
```

### Check SMB Credentials
```bash
kubectl get secret smb-credentials -n kube-system
```

### View PVC Status
```bash
kubectl get pvc authentik-media-smb -n security
kubectl describe pvc authentik-media-smb -n security
```

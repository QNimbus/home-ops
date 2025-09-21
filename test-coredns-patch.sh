#!/bin/bash
set -e

echo "=== Testing CoreDNS patch logic ==="

# Simulate getting the Tailscale DNS IP
TAILSCALE_DNS_IP="10.43.123.159"
echo "Found Tailscale DNS server at: $TAILSCALE_DNS_IP"

# Get the current CoreDNS Corefile (this is the real one from your cluster)
kubectl get configmap coredns -n kube-system -o jsonpath='{.data.Corefile}' > /tmp/current-corefile

echo "=== Current Corefile ==="
cat /tmp/current-corefile

# Check if ts.net section already exists and remove it
if grep -q "ts\.net:53" /tmp/current-corefile; then
  echo "=== Removing existing ts.net section ==="
  sed -i '/ts\.net:53/,/^}/d' /tmp/current-corefile
fi

# Append the ts.net section
cat >> /tmp/current-corefile << EOF
ts.net:53 {
    errors
    cache 30
    forward . $TAILSCALE_DNS_IP
}
EOF

echo "=== New Corefile with ts.net section ==="
cat /tmp/current-corefile

# Test JSON escaping
echo "=== Testing JSON escaping ==="
ESCAPED_COREFILE=$(cat /tmp/current-corefile | jq -Rs .)
echo "Escaped for JSON: $ESCAPED_COREFILE"

# Show what the patch would look like (but don't apply it)
echo "=== Would apply this patch ==="
echo "{\"data\":{\"Corefile\":$ESCAPED_COREFILE}}"

echo "=== Test completed successfully ==="

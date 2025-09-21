#!/bin/bash
set -e

echo "=== Testing CoreDNS patch logic with existing ts.net section ==="

# Create a mock Corefile with existing ts.net section
cat > /tmp/mock-corefile << 'EOF'
dns://.:53 {
    errors
    health {
        lameduck 5s
    }
    ready
    kubernetes cluster.local in-addr.arpa ip6.arpa {
        pods verified
        fallthrough in-addr.arpa ip6.arpa
    }
    autopath @kubernetes
    forward . /etc/resolv.conf
    cache {
        prefetch 20
        serve_stale
    }
    loop
    reload
    loadbalance
    prometheus 0.0.0.0:9153
    log {
        class error
    }
}
ts.net:53 {
    errors
    cache 30
    forward . 10.43.123.100
}
EOF

echo "=== Mock Corefile with existing ts.net section ==="
cat /tmp/mock-corefile

# Simulate the job logic
TAILSCALE_DNS_IP="10.43.123.159"
echo "Found Tailscale DNS server at: $TAILSCALE_DNS_IP"

cp /tmp/mock-corefile /tmp/current-corefile

# Check if ts.net section already exists and remove it
if grep -q "ts\.net:53" /tmp/current-corefile; then
  echo "=== Removing existing ts.net section ==="
  sed -i '/ts\.net:53/,/^}/d' /tmp/current-corefile
  echo "After removal:"
  cat /tmp/current-corefile
fi

# Append the new ts.net section
cat >> /tmp/current-corefile << EOF
ts.net:53 {
    errors
    cache 30
    forward . $TAILSCALE_DNS_IP
}
EOF

echo "=== Final Corefile with updated ts.net section ==="
cat /tmp/current-corefile

echo "=== Test completed successfully ==="

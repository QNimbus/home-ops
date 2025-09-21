#!/bin/bash

# Check if cloudflare-tunnel.json exists
if [ ! -f "cloudflare-tunnel.json" ]; then
    echo "Error: cloudflare-tunnel.json not found!"
    exit 1
fi

# Read the existing cloudflare-tunnel.json file
CF_JSON=$(cat cloudflare-tunnel.json)

# Extract components from the JSON
ACCOUNT_TAG=$(echo "$CF_JSON" | grep -o '"AccountTag":"[^"]*"' | cut -d'"' -f4)
TUNNEL_SECRET=$(echo "$CF_JSON" | grep -o '"TunnelSecret":"[^"]*"' | cut -d'"' -f4)
TUNNEL_ID=$(echo "$CF_JSON" | grep -o '"TunnelID":"[^"]*"' | cut -d'"' -f4)

# Create the token in the format expected by Cloudflare
TOKEN="{\"a\":\"$ACCOUNT_TAG\",\"s\":\"$TUNNEL_SECRET\",\"t\":\"$TUNNEL_ID\"}"

# Generate base64 encoded token for Kubernetes secret (URL-safe)
B64_TOKEN=$(echo -n "$TOKEN" | base64 -w 0 | tr '+/' '-_' | tr -d '=')

echo "Generated token from cloudflare-tunnel.json:"
echo "$TOKEN"
echo
echo "Base64 encoded token for Kubernetes secret (URL-safe):"
echo "$B64_TOKEN"
echo
echo "Update your Kubernetes secret with:"
echo "TUNNEL_TOKEN: $B64_TOKEN"

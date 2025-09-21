#!/bin/bash

# Set up environment explicitly
export PATH="/usr/bin:/usr/local/share/nvm/versions/node/v22.18.0/bin:$PATH"
export NODE_PATH="/usr/local/share/nvm/versions/node/v22.18.0/lib/node_modules"

# Debug information
echo "PATH: $PATH" > /tmp/mcp-kubernetes-debug.log
echo "NODE_PATH: $NODE_PATH" >> /tmp/mcp-kubernetes-debug.log
echo "node location: $(which node)" >> /tmp/mcp-kubernetes-debug.log
echo "npx location: $(which npx)" >> /tmp/mcp-kubernetes-debug.log

# Execute the actual command
exec /usr/bin/npx -y mcp-server-kubernetes

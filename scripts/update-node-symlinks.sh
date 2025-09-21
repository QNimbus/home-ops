#!/bin/bash
# This script creates symlinks to the current node and npx executables
# Run this script whenever you change your Node.js version

mkdir -p $HOME/.local/bin

# Create symlinks for node and npx
ln -sf "$(which node)" $HOME/.local/bin/node
ln -sf "$(which npx)" $HOME/.local/bin/npx

# Display info
echo "Symlinks created:"
ls -la $HOME/.local/bin/node $HOME/.local/bin/npx
echo ""
echo "Node version: $(/usr/bin/env node --version)"
echo "NPX version: $(/usr/bin/env npx --version)"

#!/bin/bash

# This script ensures that node and npx are available in a common location
# that doesn't depend on environment variables

NODE_PATH=$(which node)
NPX_PATH=$(which npx)

echo "Node found at: $NODE_PATH"
echo "NPX found at: $NPX_PATH"

# Check if node exists in /usr/bin
if [ ! -f "/usr/bin/node" ]; then
  echo "Creating symlink for node in /usr/bin"
  sudo ln -sf "$NODE_PATH" /usr/bin/node
fi

# Check if npx exists in /usr/bin
if [ ! -f "/usr/bin/npx" ]; then
  echo "Creating symlink for npx in /usr/bin"
  sudo ln -sf "$NPX_PATH" /usr/bin/npx
fi

echo "Node symlinks:"
ls -la /usr/bin/node
echo "NPX symlinks:"
ls -la /usr/bin/npx

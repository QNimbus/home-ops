#!/bin/bash
set -e

# Update package lists
sudo apt-get update

# Install required packages
sudo apt-get install -y gnupg ca-certificates iputils-ping dnsutils trash-cli tree libgtk2.0-0 libgtk-3-0 libgbm-dev libnotify-dev libnss3 libxss1 libasound2 libxtst6 xauth xvfb nmap

# Install 1Password-cli
curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg && \
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
sudo tee /etc/apt/sources.list.d/1password.list && \
sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/ && \
curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | \
sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol && \
sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22 && \
curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg && \
sudo apt update && sudo apt install -y 1password-cli

# Download and install mise
curl -L https://mise.jdx.dev/install.sh | bash

# Change ownership of the workspace folder
sudo chown -R 1000:1000 ${WORKSPACE_FOLDER}

# Make the workspace folder the current directory
cd ${WORKSPACE_FOLDER}

# Ensure .bashrc sources .bash_aliases
if ! grep -q "bash_aliases" /home/vscode/.bashrc; then
    echo -e "\n# Source user aliases\nif [ -f ~/.bash_aliases ]; then\n  . ~/.bash_aliases\nfi" >> /home/vscode/.bashrc
fi

echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc

# Source bashrc to apply changes immediately
source ~/.bashrc

mise trust
pip install pipx
mise install

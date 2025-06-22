#!/bin/bash
set -e

# Update package lists
sudo apt-get update

# Install required packages
sudo apt-get install -y iputils-ping dnsutils trash-cli tree libgtk2.0-0 libgtk-3-0 libgbm-dev libnotify-dev libnss3 libxss1 libasound2 libxtst6 xauth xvfb nmap

# Download and extract jujutsu
curl -L https://github.com/jj-vcs/jj/releases/download/v0.29.0/jj-v0.29.0-x86_64-unknown-linux-musl.tar.gz | sudo tar xz -C /usr/local/bin

# Download and install mise
curl -L https://mise.jdx.dev/install.sh | bash

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

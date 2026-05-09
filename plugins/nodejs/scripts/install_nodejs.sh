#!/bin/bash

# Node.js Automation Install Script (v20.x LTS)
# Supports: Ubuntu, CentOS

set -e

# Detect OS
if [ -f /etc/os-release ]; then
    OS_ID=$(grep -E '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
else
    echo "Unsupported OS"
    exit 1
fi

echo "Detected OS: $OS_ID"
echo "Installing Node.js v20.x (LTS) via NodeSource..."

case $OS_ID in
    ubuntu|debian)
        apt-get update -y
        apt-get install -y ca-certificates curl gnupg
        
        # Cleanup old nodesource if exists
        rm -f /etc/apt/sources.list.d/nodesource.list
        
        mkdir -p /etc/apt/keyrings
        curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg || true
        
        NODE_MAJOR=20
        echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
        
        apt-get update -y
        apt-get install nodejs -y
        ;;
    centos|rhel|fedora|almalinux|rocky)
        # Use NodeSource setup script for RPM
        curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
        
        if command -v dnf >/dev/null 2>&1; then
            dnf install -y nodejs
        else
            yum install -y nodejs
        fi
        ;;
    *)
        echo "Unsupported OS ID: $OS_ID"
        exit 1
        ;;
esac

echo "Node.js installation completed!"
node -v
npm -v

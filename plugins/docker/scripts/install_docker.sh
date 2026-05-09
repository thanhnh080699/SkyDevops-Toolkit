#!/bin/bash

# Docker Automation Install Script
# Supports: Ubuntu, CentOS
# Includes: Docker CE, Docker Compose Plugin, Buildx

set -e

TARGET_VERSION=""
UNINSTALL=false

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --version) TARGET_VERSION="$2"; shift ;;
        --uninstall) UNINSTALL=true ;;
        --help) echo "Usage: $0 [--version VERSION] [--uninstall]"; exit 0 ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Detect OS
if [ -f /etc/os-release ]; then
    OS_ID=$(grep -E '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
    CODENAME=$(grep -E '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
    [ -z "$CODENAME" ] && CODENAME=$(grep -E '^UBUNTU_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
elif [ -f /etc/redhat-release ]; then
    OS_ID="centos"
    CODENAME="rhel"
else
    echo "Unsupported OS"
    exit 1
fi

echo "Detected OS: $OS_ID ($CODENAME)"
echo "Target Docker Version: ${TARGET_VERSION:-Latest}"

pre_install_checks() {
    echo "Checking and installing basic dependencies..."
    case $OS_ID in
        ubuntu|debian)
            # Cleanup any broken nginx list that might have the wrong URL if it exists
            grep -l "nginx.org/packages/packages" /etc/apt/sources.list.d/* 2>/dev/null | xargs rm -f || true
            apt-get update -y
            apt-get install -y curl gnupg ca-certificates lsb-release
            ;;
        centos|rhel|fedora|almalinux|rocky)
            yum install -y curl yum-utils
            ;;
    esac
}

perform_uninstall() {
    echo "Removing existing Docker installation..."
    case $OS_ID in
        ubuntu|debian)
            systemctl stop docker || true
            apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker.io docker-doc docker-compose podman-docker containerd runc || true
            apt-get autoremove -y || true
            rm -rf /var/lib/docker
            ;;
        centos|rhel|fedora|almalinux|rocky)
            systemctl stop docker || true
            yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine || true
            rm -rf /var/lib/docker
            ;;
    esac
}

install_ubuntu() {
    echo "Setting up Docker official repository on Ubuntu ($CODENAME)..."
    
    # 1. Add GPG Key
    install -m 0755 -d /etc/apt/keyrings
    rm -f /etc/apt/keyrings/docker.gpg
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # 2. Add Repo
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $CODENAME stable" \
        | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update -y

    # 3. Handle Versioning
    if [ -n "$TARGET_VERSION" ]; then
        echo "Searching for specific Docker version: $TARGET_VERSION"
        local version_match=$(apt-cache madison docker-ce | grep "$TARGET_VERSION" | head -n 1 | awk '{print $3}')
        local cli_match=$(apt-cache madison docker-ce-cli | grep "$TARGET_VERSION" | head -n 1 | awk '{print $3}')
        
        if [ -n "$version_match" ]; then
            echo "Match found: $version_match"
            apt-get install -y docker-ce="$version_match" docker-ce-cli="$cli_match" containerd.io docker-buildx-plugin docker-compose-plugin
        else
            echo "Warning: Version $TARGET_VERSION not found in repository. Installing latest stable."
            apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        fi
    else
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    fi
}

install_centos() {
    echo "Setting up Docker official repository on CentOS..."
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    
    if [ -n "$TARGET_VERSION" ]; then
        # On CentOS, version match is usually just the version string
        yum install -y docker-ce-"$TARGET_VERSION" docker-ce-cli-"$TARGET_VERSION" containerd.io docker-buildx-plugin docker-compose-plugin || \
        yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    else
        yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    fi
}

# Main Execution
pre_install_checks

if [ "$UNINSTALL" = true ]; then
    perform_uninstall
fi

case $OS_ID in
    ubuntu|debian) install_ubuntu ;;
    *) install_centos ;;
esac

# Start and Enable Service
if command -v systemctl >/dev/null 2>&1; then
    systemctl enable docker || true
    systemctl start docker || true
    
    # Verification check
    if systemctl is-active --quiet docker; then
        echo "✔ Docker service is active and running."
    else
        echo "✘ ERROR: Docker service failed to start. Please check logs: journalctl -u docker"
        exit 1
    fi
else
    echo "WARNING: 'systemctl' not found. Please start Docker manually."
fi

echo "Docker installation completed!"
docker version --format '{{.Server.Version}}' 2>/dev/null || docker version
docker compose version

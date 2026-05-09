#!/bin/bash

# Nginx Automation Install Script
# Supports: Ubuntu, CentOS
# Versions: Stable, Mainline

set -e

VERSION="stable"
OS=""
CODENAME=""

# Function to display help
show_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --version [stable|mainline]  Select Nginx version (default: stable)"
    echo "  --help                       Show this help message"
}

# Parse arguments
TARGET_VERSION="stable"
UNINSTALL=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --version) TARGET_VERSION="$2"; shift ;;
        --uninstall) UNINSTALL=true ;;
        --help) show_help; exit 0 ;;
        *) echo "Unknown parameter passed: $1"; show_help; exit 1 ;;
    esac
    shift
done

# Detect OS
if [ -f /etc/os-release ]; then
    # Source into subshell or local variables to avoid clobbering
    OS_ID=$(grep -E '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
    CODENAME=$(grep -E '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
    [ -z "$CODENAME" ] && CODENAME=$(grep -E '^UBUNTU_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
elif [ -f /etc/redhat-release ]; then
    OS_ID="centos"
else
    echo "Unsupported OS"
    exit 1
fi

echo "Detected OS: $OS_ID ($CODENAME)"
echo "Target Nginx Version: $TARGET_VERSION"

# Function to ensure basic dependencies are installed
pre_install_checks() {
    echo "Checking and installing basic dependencies..."
    case $OS_ID in
        ubuntu|debian)
            # Cleanup any broken nginx list that might have the wrong URL
            grep -l "nginx.org/packages/packages" /etc/apt/sources.list.d/* 2>/dev/null | xargs rm -f || true
            
            apt-get update -y
            apt-get install -y curl gnupg2 ca-certificates lsb-release ubuntu-keyring
            ;;
        centos|rhel|fedora|almalinux|rocky)
            yum install -y curl yum-utils
            ;;
    esac
}

perform_uninstall() {
    echo "Removing existing Nginx installation..."
    case $OS_ID in
        ubuntu|debian)
            apt-get remove -y nginx nginx-common nginx-full || true
            apt-get purge -y nginx nginx-common nginx-full || true
            apt-get autoremove -y || true
            ;;
        centos|rhel|fedora|almalinux|rocky)
            yum remove -y nginx || true
            ;;
    esac
}

install_ubuntu() {
    echo "Installing Nginx v$TARGET_VERSION on Ubuntu..."
    
    # Setup Repo - ALWAYS cleanup broken Nginx lists before update
    rm -f /etc/apt/sources.list.d/nginx.list
    rm -f /etc/apt/sources.list.d/nginx-mainline.list # Potential old name

    # Check architecture - nginx.org doesn't support ARM via this repo
    local arch=$(dpkg --print-architecture)
    if [[ "$arch" != "amd64" && "$arch" != "i386" ]]; then
        echo "WARNING: $arch architecture detected. Official nginx.org repo only supports amd64/i386."
        echo "Falling back to default Ubuntu repository packages..."
        apt-get update
        apt-get install -y nginx
        return
    fi

    apt-get update
    apt-get install -y curl gnupg2 ca-certificates lsb-release ubuntu-keyring

    curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
        | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null

    # Build repo URL
    local repo_url="http://nginx.org/packages/ubuntu"
    if [[ "$TARGET_VERSION" == "mainline" ]]; then
        repo_url="http://nginx.org/packages/mainline/ubuntu"
    elif [[ "$TARGET_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        local second_digit=$(echo $TARGET_VERSION | cut -d. -f2)
        if (( second_digit % 2 != 0 )); then
            repo_url="http://nginx.org/packages/mainline/ubuntu"
        fi
    fi

    # Write source list
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] $repo_url $(lsb_release -cs) nginx" \
        | tee /etc/apt/sources.list.d/nginx.list

    echo -e "Package: *\nPin: origin nginx.org\nPin-Priority: 900\n" | tee /etc/apt/preferences.d/99nginx

    apt-get update
    
    if [[ "$TARGET_VERSION" =~ ^[0-9] ]]; then
        apt-get install -y nginx=$TARGET_VERSION-1~$(lsb_release -cs) || apt-get install -y nginx
    else
        apt-get install -y nginx
    fi
}

install_centos() {
    echo "Installing Nginx v$TARGET_VERSION on CentOS..."
    yum install -y yum-utils
    
    local repo_status=0
    [[ "$TARGET_VERSION" == "mainline" ]] && repo_status=1
    
    cat <<EOF | tee /etc/yum.repos.d/nginx.repo
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=$((1 - repo_status))
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=$repo_status
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
EOF

    if [[ "$TARGET_VERSION" =~ ^[0-9] ]]; then
        yum install -y nginx-$TARGET_VERSION || yum install -y nginx
    else
        yum install -y nginx
    fi
}

# Execution logic
pre_install_checks

[ "$UNINSTALL" = true ] && perform_uninstall

case $OS_ID in
    ubuntu|debian) install_ubuntu ;;
    *) install_centos ;;
esac

if command -v systemctl >/dev/null 2>&1; then
    systemctl enable nginx || true
    systemctl start nginx || true
    
    # Verification check
    if systemctl is-active --quiet nginx; then
        echo "✔ Nginx service is active and running."
    else
        echo "✘ ERROR: Nginx service failed to start. Please check logs: journalctl -u nginx"
        exit 1
    fi
else
    echo "WARNING: 'systemctl' not found. Skipping service initialization."
    echo "You can start Nginx manually using: nginx"
fi

echo "Nginx v$TARGET_VERSION installation completed!"
nginx -v 2>&1

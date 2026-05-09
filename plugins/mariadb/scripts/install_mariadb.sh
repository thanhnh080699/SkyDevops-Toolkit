#!/bin/bash

# MariaDB Automation Install Script
# Supports: Ubuntu, CentOS, Debian, RHEL
# Using official MariaDB Foundation repository setup

set -e

TARGET_VERSION="11.4"
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
elif [ -f /etc/redhat-release ]; then
    OS_ID="centos"
else
    echo "Unsupported OS"
    exit 1
fi

echo "Detected OS: $OS_ID"
echo "Target MariaDB Version: $TARGET_VERSION"

pre_install_checks() {
    echo "Checking and installing basic dependencies..."
    case $OS_ID in
        ubuntu|debian)
            apt-get update -y
            apt-get install -y curl ca-certificates apt-transport-https
            ;;
        centos|rhel|fedora|almalinux|rocky)
            yum install -y curl
            ;;
    esac
}

perform_uninstall() {
    echo "Preparing for update/re-install (Data safe mode)..."
    case $OS_ID in
        ubuntu|debian)
            systemctl stop mariadb || systemctl stop mysql || true
            # Backup data before any major changes
            echo "Creating a snapshot of /var/lib/mysql in /var/lib/mysql_snapshot_$(date +%s)..."
            cp -ra /var/lib/mysql /var/lib/mysql_snapshot_$(date +%s) || true
            
            # Remove packages but NOT the data
            # Note: We do NOT use 'purge' here to keep config and databases
            apt-get remove -y mariadb-server mariadb-client mariadb-common || true
            apt-get autoremove -y || true
            ;;
        centos|rhel|fedora|almalinux|rocky)
            systemctl stop mariadb || systemctl stop mysqld || true
            # Backup data
            echo "Creating a snapshot of /var/lib/mysql in /var/lib/mysql_snapshot_$(date +%s)..."
            cp -ra /var/lib/mysql /var/lib/mysql_snapshot_$(date +%s) || true
            
            yum remove -y MariaDB-server MariaDB-client || true
            ;;
    esac
}

install_mariadb() {
    echo "Setting up MariaDB $TARGET_VERSION repository..."
    # Always include the version in the repo setup script
    curl -LsS https://r.mariadb.com/downloads/mariadb_repo_setup | bash -s -- --mariadb-server-version="$TARGET_VERSION"

    echo "Updating and installing MariaDB Server..."
    case $OS_ID in
        ubuntu|debian)
            apt-get update
            # Use --no-install-recommends to keep it lean
            # Use 'install' which handles upgrades gracefully if already partially present
            apt-get install -y mariadb-server
            ;;
        centos|rhel|fedora|almalinux|rocky)
            yum install -y MariaDB-server MariaDB-client
            ;;
    esac
}

# Main Execution
pre_install_checks

if [ "$UNINSTALL" = true ]; then
    perform_uninstall
fi

install_mariadb

# Start and Enable Service
if command -v systemctl >/dev/null 2>&1; then
    systemctl enable mariadb || true
    systemctl start mariadb || true
    
    # Schema upgrade for system tables (only if already installed/upgrading)
    echo "Checking for schema upgrades..."
    mariadb-upgrade --user=root --password="" || echo "No schema upgrade needed or password required."
    
    # Final restart
    systemctl restart mariadb || true
    
    # Verification check
    if systemctl is-active --quiet mariadb || systemctl is-active --quiet mysql; then
        echo "✔ MariaDB service is active and running."
    else
        echo "✘ ERROR: MariaDB service failed to start. Please check logs: journalctl -u mariadb"
        exit 1
    fi
else
    echo "WARNING: 'systemctl' not found. Please start MariaDB manually."
fi

echo "MariaDB $TARGET_VERSION installation completed!"
mariadb --version 2>&1

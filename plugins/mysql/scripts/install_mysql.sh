#!/bin/bash

# MySQL Automation Install Script
# Supports: Ubuntu, CentOS

set -e

VERSION="8.0"
OS_ID=""
OS_CODENAME=""
MYSQL_GPG_KEY_ID="B7B3B788A8D3785C"
MYSQL_KEYRING="/etc/apt/keyrings/mysql.gpg"

# Function to display help
show_help() {
    echo "Usage: $0 --version [8.0|8.4]"
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --version) VERSION="$2"; shift ;;
        --help) show_help; exit 0 ;;
        *) echo "Unknown parameter: $1"; show_help; exit 1 ;;
    esac
    shift
done

case "$VERSION" in
    8.0|8.4) ;;
    *) echo "Unsupported MySQL version: $VERSION"; show_help; exit 1 ;;
esac

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID="$ID"
    OS_CODENAME="${VERSION_CODENAME:-}"
else
    echo "Unsupported OS"
    exit 1
fi

if [ -z "$OS_CODENAME" ] && command -v lsb_release >/dev/null 2>&1; then
    OS_CODENAME=$(lsb_release -sc)
fi

echo "Detected OS: $OS_ID"
echo "Target MySQL Version: $VERSION"

case $OS_ID in
    ubuntu|debian)
        if [ -z "$OS_CODENAME" ]; then
            echo "Cannot detect OS codename for MySQL APT repository"
            exit 1
        fi

        repo_component="mysql-8.0"
        if [[ "$VERSION" == "8.4" ]]; then
            repo_component="mysql-8.4-lts"
        fi

        echo "Cleaning up old MySQL GPG keys and repositories..."
        rm -f /etc/apt/trusted.gpg.d/mysql.gpg
        rm -f /usr/share/keyrings/mysql-apt-config.gpg
        rm -f /etc/apt/sources.list.d/mysql.list

        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        apt-get install -y ca-certificates curl gnupg dirmngr

        echo "Importing latest MySQL GPG key ($MYSQL_GPG_KEY_ID)..."
        mkdir -p /etc/apt/keyrings
        tmp_gnupg=$(mktemp -d)
        chmod 700 "$tmp_gnupg"
        GNUPGHOME="$tmp_gnupg" gpg --batch --keyserver hkps://keyserver.ubuntu.com --recv-keys "$MYSQL_GPG_KEY_ID"
        GNUPGHOME="$tmp_gnupg" gpg --batch --export "$MYSQL_GPG_KEY_ID" | gpg --dearmor --yes -o "$MYSQL_KEYRING"
        rm -rf "$tmp_gnupg"
        chmod 644 "$MYSQL_KEYRING"

        if ! gpg --show-keys --with-colons "$MYSQL_KEYRING" | grep -q "$MYSQL_GPG_KEY_ID"; then
            echo "Failed to verify MySQL GPG key: $MYSQL_GPG_KEY_ID"
            exit 1
        fi

        cat >/etc/apt/sources.list.d/mysql.list <<EOF
deb [signed-by=$MYSQL_KEYRING] http://repo.mysql.com/apt/$OS_ID/ $OS_CODENAME $repo_component
deb [signed-by=$MYSQL_KEYRING] http://repo.mysql.com/apt/$OS_ID/ $OS_CODENAME mysql-tools
EOF

        apt-get update -y
        apt-get install -y mysql-server
        ;;
    centos|rhel|fedora|almalinux|rocky)
        el_ver=$(rpm -E %rhel)
        # Use appropriate repo package based on version
        if [[ "$VERSION" == "8.4" ]]; then
            yum install -y "https://dev.mysql.com/get/mysql84-community-release-el$el_ver-1.noarch.rpm"
        else
            yum install -y "https://dev.mysql.com/get/mysql80-community-release-el$el_ver-1.noarch.rpm"
        fi
        
        # Disable GPG check temporarily if needed or import key
        rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023
        
        yum install -y mysql-community-server
        ;;
esac

# Start and enable service
if command -v systemctl >/dev/null 2>&1; then
    systemctl enable mysqld || systemctl enable mysql || true
    systemctl start mysqld || systemctl start mysql || true
    
    # Verification check
    if systemctl is-active --quiet mysqld || systemctl is-active --quiet mysql; then
        echo "✔ MySQL service is active and running."
    else
        echo "✘ ERROR: MySQL service failed to start. Please check logs: journalctl -u mysql"
        exit 1
    fi
fi

echo "MySQL $VERSION installation completed!"
mysql -V

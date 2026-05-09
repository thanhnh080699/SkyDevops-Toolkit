#!/bin/bash

# PHP Automation Install Script
# Supports: Ubuntu, CentOS

set -e

VERSION=""
OS_ID=""

# Function to display help
show_help() {
    echo "Usage: $0 --version [7.2|7.4|8.0|8.1|8.2|8.3]"
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

if [ -z "$VERSION" ]; then
    echo "Error: Version is required."
    show_help
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    OS_ID=$(grep -E '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
else
    echo "Unsupported OS"
    exit 1
fi

echo "Detected OS: $OS_ID"
echo "Target PHP Version: $VERSION"

pre_install_checks() {
    case $OS_ID in
        ubuntu|debian)
            apt-get update -y
            apt-get install -y software-properties-common curl gnupg2 ca-certificates lsb-release
            ;;
        centos|rhel|fedora|almalinux|rocky)
            yum install -y curl yum-utils epel-release
            ;;
    esac
}

install_ubuntu() {
    echo "Configuring PHP PPA for Ubuntu..."
    add-apt-repository ppa:ondrej/php -y
    apt-get update -y
    
    echo "Installing PHP $VERSION and common extensions..."
    local pkgs=(
        "php$VERSION"
        "php$VERSION-fpm"
        "php$VERSION-cli"
        "php$VERSION-common"
        "php$VERSION-mysql"
        "php$VERSION-xml"
        "php$VERSION-curl"
        "php$VERSION-gd"
        "php$VERSION-mbstring"
        "php$VERSION-zip"
        "php$VERSION-bcmath"
        "php$VERSION-intl"
        "php$VERSION-soap"
        "php$VERSION-readline"
    )
    
    apt-get install -y "${pkgs[@]}"
    
    # Start and enable FPM
    systemctl enable "php$VERSION-fpm" || true
    systemctl start "php$VERSION-fpm" || true
    
    # Verification
    if systemctl is-active --quiet "php$VERSION-fpm"; then
        echo "✔ PHP$VERSION-FPM service is active and running."
    else
        echo "✘ ERROR: PHP$VERSION-FPM service failed to start."
        exit 1
    fi
}

install_centos() {
    echo "Configuring Remi Repository for CentOS..."
    local el_ver=$(rpm -E %rhel)
    
    if [ "$el_ver" == "7" ]; then
        yum install -y https://rpms.remirepo.net/enterprise/remi-release-7.rpm
        yum-config-manager --disable 'remi-php*'
        yum-config-manager --enable "remi-php${VERSION//./}"
    else
        dnf install -y https://rpms.remirepo.net/enterprise/remi-release-$el_ver.rpm
        dnf module reset php -y
        dnf module enable "php:remi-$VERSION" -y
    fi
    
    echo "Installing PHP $VERSION and common extensions..."
    local pkgs=(
        "php"
        "php-fpm"
        "php-cli"
        "php-common"
        "php-mysqlnd"
        "php-xml"
        "php-curl"
        "php-gd"
        "php-mbstring"
        "php-zip"
        "php-bcmath"
        "php-intl"
        "php-soap"
    )
    
    if [ "$el_ver" == "7" ]; then
        yum install -y "${pkgs[@]}"
    else
        dnf install -y "${pkgs[@]}"
    fi
    
    # Start and enable FPM
    systemctl enable php-fpm || true
    systemctl start php-fpm || true
    
    # Verification
    if systemctl is-active --quiet php-fpm; then
        echo "✔ PHP-FPM service is active and running."
    else
        echo "✘ ERROR: PHP-FPM service failed to start."
        exit 1
    fi
}

# Execution
pre_install_checks

case $OS_ID in
    ubuntu|debian) install_ubuntu ;;
    centos|rhel|fedora|almalinux|rocky) install_centos ;;
    *) echo "Unsupported OS ID: $OS_ID"; exit 1 ;;
esac

echo "PHP $VERSION installation completed!"
php -v

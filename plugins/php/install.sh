#!/bin/bash

# ==============================
# PHP INSTALL PLUGIN
# ==============================

. core/ui.sh
. core/os.sh
. core/utils.sh

# Function to run PHP install logic
install_php() {
    local version=$1
    detect_os
    
    # Check current installed version
    local current_version=""
    if command -v php >/dev/null 2>&1; then
        current_version=$(php -v 2>&1 | head -n 1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "")
    fi
    
    local action_text="Cài đặt mới"
    if [ -n "$current_version" ]; then
        if [[ "$current_version" == "$version"* ]]; then
            action_text="Re-install (Đang chạy v$current_version)"
        else
            action_text="Cài thêm bản v$version (Hiện tại v$current_version)"
        fi
    else
        action_text="Cài đặt mới (Chưa cài đặt)"
    fi
    
    # Confirmation Step
    clear
    ui_init
    
    ui_border_top
    ui_title "${BOLD}XÁC NHẬN CÀI ĐẶT PHP${RESET}"
    ui_border_mid
    ui_line "Tổng quan thông tin:"
    ui_line "- Hệ điều hành: $OS_NAME $OS_VER ($OS_ID)"
    ui_line "- Phiên bản:    PHP $version"
    ui_line "- Hành động:    $action_text"
    ui_empty
    ui_line "Lưu ý: Hệ thống sẽ tự động cài đặt các extension phổ biến"
    ui_line "(fpm, cli, mysql, gd, mbstring, xml, curl, zip, ...)"
    ui_border_bottom
    
    echo -ne "\n${BOLD}➜ Xác nhận (Y/n):${RESET} "
    read -r confirm
    
    if [[ -z "$confirm" ]]; then confirm="y"; fi
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "\n  ${YELLOW}Đã hủy thao tác cài đặt.${RESET}"
        sleep 1
        return
    fi
    
    echo -e "\n${GREEN}  Bắt đầu quy trình cài đặt PHP $version...${RESET}"
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if ! $SUDO bash plugins/php/scripts/install_php.sh --version "$version"; then
            echo -e "\n  ${RED}✘ Lỗi: Quá trình cài đặt PHP thất bại.${RESET}"
            echo -n "  Nhấn Enter để quay lại... "
            read
            return 1
        fi
    else
        # Simulation for non-linux environments
        simulate_progress "Đang thêm Repository cho PHP $version"
        simulate_progress "Đang tải xuống PHP $version & Extensions"
        simulate_progress "Đang thiết lập PHP-FPM Service"
    fi
    
    echo -e "  ${GREEN}✔ PHP $version đã được cài đặt thành công!${RESET}"
    echo -n "  Nhấn Enter để quay lại... "
    read
}

# Function to check if a specific PHP version is installed
get_php_ver_status() {
    local ver=$1
    local status=""
    
    # Check for phpX.Y (Ubuntu style)
    if command -v "php$ver" >/dev/null 2>&1; then
        status="${GREEN}✔ Đã cài đặt${RESET}"
    # Check for phpXY (CentOS/Remi style)
    elif command -v "php${ver//./}" >/dev/null 2>&1; then
        status="${GREEN}✔ Đã cài đặt${RESET}"
    else
        # Check current default php version
        local current_v=$(php -v 2>&1 | head -n 1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
        if [ "$current_v" == "$ver" ]; then
            status="${GREEN}✔ Đã cài đặt${RESET}"
        fi
    fi
    echo "$status"
}

# Function to check Composer status
get_composer_status() {
    if command -v composer >/dev/null 2>&1; then
        local ver=$(composer -V 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        echo -e "${GREEN}✔ v$ver${RESET}"
    else
        echo ""
    fi
}

# Function to install Composer
install_composer() {
    # Check if PHP is installed
    if ! command -v php >/dev/null 2>&1; then
        echo -e "\n  ${RED}✘ Lỗi: Bạn cần cài đặt ít nhất một phiên bản PHP trước khi cài đặt Composer.${RESET}"
        echo -n "  Nhấn Enter để quay lại... "
        read
        return
    fi

    local current_composer=""
    if command -v composer >/dev/null 2>&1; then
        current_composer=$(composer -V 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    fi

    clear
    ui_init
    ui_border_top
    ui_title "${BOLD}XÁC NHẬN CÀI ĐẶT COMPOSER${RESET}"
    ui_border_mid
    ui_line "Thông tin hệ thống:"
    ui_line "- PHP: $(php -v | head -n 1)"
    if [ -n "$current_composer" ]; then
        ui_line "- Trạng thái: Đã cài đặt (v$current_composer)"
        ui_line "- Hành động: Cập nhật lên bản mới nhất"
    else
        ui_line "- Trạng thái: Chưa cài đặt"
        ui_line "- Hành động: Cài đặt mới"
    fi
    ui_border_bottom

    echo -ne "\n${BOLD}➜ Xác nhận cài đặt (Y/n):${RESET} "
    read -r confirm
    if [[ -z "$confirm" ]]; then confirm="y"; fi
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "\n  ${YELLOW}Đã hủy thao tác.${RESET}"
        sleep 1
        return
    fi

    echo -e "\n${GREEN}  Đang tiến hành cài đặt Composer...${RESET}"
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Detect current PHP version to install matching extensions
        local php_v=$(php -v 2>&1 | head -n 1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
        
        # Install dependencies for composer using the matched PHP version
        if [ -n "$php_v" ]; then
            $SUDO apt-get install -y curl "php$php_v-cli" "php$php_v-mbstring" "php$php_v-zip" unzip 2>/dev/null || \
            $SUDO apt-get install -y curl php-cli php-mbstring unzip 2>/dev/null || true
            
            $SUDO yum install -y curl php-cli php-mbstring unzip 2>/dev/null || true
        fi

        # Official installation method
        curl -sS https://getcomposer.org/installer -o composer-setup.php
        $SUDO php composer-setup.php --install-dir=/usr/local/bin --filename=composer
        rm -f composer-setup.php
    else
        simulate_progress "Đang tải xuống Composer Installer"
        simulate_progress "Đang di chuyển vào /usr/local/bin"
    fi

    echo -e "\n  ${GREEN}✔ Composer đã được cài đặt/cập nhật thành công!${RESET}"
    composer -V
    echo -n "  Nhấn Enter để quay lại... "
    read
}

# Nested Menu for PHP
php_menu() {
    while true; do
        clear
        ui_init
        
        local s72=$(get_php_ver_status "7.2")
        local s74=$(get_php_ver_status "7.4")
        local s80=$(get_php_ver_status "8.0")
        local s81=$(get_php_ver_status "8.1")
        local s82=$(get_php_ver_status "8.2")
        local s83=$(get_php_ver_status "8.3")
        local s_comp=$(get_composer_status)

        ui_border_top
        ui_title "${BOLD}CÀI ĐẶT PHP MULTI-VERSION${RESET}"
        ui_border_mid
        ui_line "Lựa chọn phiên bản PHP để cài đặt:"
        ui_empty
        ui_line "1. PHP 7.2                  $s72"
        ui_line "2. PHP 7.4                  $s74"
        ui_line "3. PHP 8.0                  $s80"
        ui_line "4. PHP 8.1                  $s81"
        ui_line "5. PHP 8.2 (Khuyên dùng)    $s82"
        ui_line "6. PHP 8.3 (Mới nhất)       $s83"
        ui_empty
        ui_line "7. CÀI ĐẶT COMPOSER          $s_comp"
        ui_empty
        ui_line "0. Quay lại menu chính"
        ui_border_bottom
        
        ui_input
        read p_choice
        
        case $p_choice in
            1) install_php "7.2" ;;
            2) install_php "7.4" ;;
            3) install_php "8.0" ;;
            4) install_php "8.1" ;;
            5) install_php "8.2" ;;
            6) install_php "8.3" ;;
            7) install_composer ;;
            0) return ;;
            *) echo -e "${RED} Sai lựa chọn ${RESET}"; sleep 1 ;;
        esac
    done
}

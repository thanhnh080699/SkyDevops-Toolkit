#!/bin/bash

# ==============================
# DEVOPS AUTOMATION TOOL - RESPONSIVE
# ==============================

. core/ui.sh
. core/os.sh
. core/utils.sh
. plugins/nginx/install.sh
. plugins/nginx/optimize.sh
. plugins/apache2/install.sh
. plugins/mariadb/install.sh
. plugins/mysql/install.sh
. plugins/docker/install.sh
. plugins/php/install.sh
. plugins/nodejs/install.sh

# Global SUDO handling
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        echo -e "${RED}✘ Error: This toolkit requires root or 'sudo' privileges.${RESET}"
        exit 1
    fi
fi

# Function to catch window resize
on_resize() {
    ui_init
    show_main_menu
}

# Trap the SIGWINCH signal (Window Size Change)
trap on_resize SIGWINCH

show_main_menu() {
    ui_init
    if [ "$IS_TOO_SMALL" -eq 1 ]; then
        ui_too_small
        return
    fi
    
    clear
    M1=$(get_status nginx)
    M2=$(get_status apache2)
    M3=$(get_status mariadb)
    M4=$(get_status mysql)
    M5=$(get_status docker)
    M6=$(get_status php)
    M7=$(get_status node)

    ui_border_top
    ui_title "${BOLD}SKYDEVOPS TOOLKIT v1.0.0${RESET}"
    ui_border_mid
    ui_line "${YELLOW}Giới thiệu:${RESET} Công cụ cài đặt & quản trị (Multi-OS: Ubuntu/CentOS)"
    ui_line "Hệ quản trị DevOps & SysAdmin chuyên nghiệp"
    ui_empty
    ui_row_3col "${BOLD}CÀI ĐẶT${RESET}" "${BOLD}TỐI ƯU${RESET}" "${BOLD}KIỂM TRA${RESET}"
    ui_row_3col "1. NGINX          [$M1]" "8. Tối ưu Nginx" "12. Check Log Nginx"
    ui_row_3col "2. APACHE2        [$M2]" "9. Tối ưu MariaDB" "13. Check MariaDB"
    ui_row_3col "3. MARIADB        [$M3]" "10. Tối ưu System" "14. System Status"
    ui_row_3col "4. MYSQL          [$M4]" "11. Tối ưu Network" "15. Port Listening"
    ui_row_3col "5. DOCKER         [$M5]" "" ""
    ui_row_3col "6. PHP            [$M6]" "" ""
    ui_row_3col "7. NODEJS/NPM     [$M7]" "" ""
    ui_empty
    ui_line "[0] Thoát"
    ui_border_mid
    ui_line "By thanhnh | https://thanhnh.id.vn"
    ui_border_bottom
    ui_input
}

handle_choice() {
    [ -z "$1" ] && return
    case $1 in
        1) nginx_menu ;;
        2) apache2_menu ;;
        3) mariadb_menu ;;
        4) mysql_menu ;;
        5) docker_menu ;;
        6) php_menu ;;
        7) nodejs_menu ;;
        8) optimize_nginx ;;
        9|10|11|12|13|14|15)
            echo -e "${YELLOW}Tính năng này sẽ sớm được hoàn thiện...${RESET}"
            sleep 1
            ;;
        0)
            echo -e "${CYAN}Cảm ơn bạn đã sử dụng. Hẹn gặp lại!${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}Lựa chọn không hợp lệ!${RESET}"
            sleep 0.5
            ;;
    esac
}

# Main Loop
detect_os
while true; do
    show_main_menu
    # Loop read if input is empty (e.g. after a signal)
    choice=""
    read -r choice
    handle_choice "$choice"
done

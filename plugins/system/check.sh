#!/bin/bash

# ==============================
# SYSTEM CHECK TOOLS
# ==============================

. core/ui.sh
. core/os.sh
. core/utils.sh

pause_check_menu() {
    echo
    echo -n "  $(tr_ui "Bấm phím bất kỳ để quay lại menu chính")... "
    read -n 1 -s -r
    echo
}

section_title() {
    echo
    echo -e "${CYAN}${BOLD}==> $(tr_ui "$1")${RESET}"
}

run_check_cmd() {
    local title="$1"
    shift
    section_title "$title"
    if "$@"; then
        return 0
    fi
    echo -e "${YELLOW}$(tr_ui "Không thể") $(tr_ui "lấy thông tin"): $(tr_ui "$title")${RESET}"
}

check_system_overview() {
    clear
    ui_init
    ui_border_top
    ui_title "${BOLD}KIỂM TRA TỔNG QUAN HỆ THỐNG${RESET}"
    ui_border_bottom

    detect_os
    section_title "Thông tin OS"
    echo "OS:        $OS_NAME $OS_VER ($OS_ID)"
    echo "Kernel:    $(uname -r 2>/dev/null)"
    echo "Hostname:  $(hostname 2>/dev/null)"
    echo "Uptime:    $(uptime -p 2>/dev/null || uptime 2>/dev/null)"

    section_title "CPU / RAM"
    local vcpu
    vcpu=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo N/A)
    echo "vCPU:      $vcpu"
    if command -v free >/dev/null 2>&1; then
        free -h
    elif command -v vm_stat >/dev/null 2>&1; then
        vm_stat
    else
        grep -E 'MemTotal|MemAvailable|SwapTotal|SwapFree' /proc/meminfo 2>/dev/null || true
    fi

    section_title "Load trung bình"
    uptime 2>/dev/null || true
    pause_check_menu
}

check_resources() {
    clear
    ui_init
    ui_border_top
    ui_title "${BOLD}KIỂM TRA TÀI NGUYÊN CPU/RAM${RESET}"
    ui_border_bottom

    if command -v free >/dev/null 2>&1; then
        run_check_cmd "RAM / Swap" free -h
    elif command -v vm_stat >/dev/null 2>&1; then
        run_check_cmd "RAM" vm_stat
    fi
    section_title "Top process theo CPU"
    ps -eo pid,ppid,comm,%cpu,%mem --sort=-%cpu 2>/dev/null | head -11 || true
    section_title "Top process theo RAM"
    ps -eo pid,ppid,comm,%cpu,%mem --sort=-%mem 2>/dev/null | head -11 || true
    pause_check_menu
}

check_disk() {
    clear
    ui_init
    ui_border_top
    ui_title "${BOLD}KIỂM TRA Ổ ĐĨA & INODE${RESET}"
    ui_border_bottom

    run_check_cmd "Dung lượng filesystem" df -hT
    run_check_cmd "Inode filesystem" df -ih
    section_title "Block devices"
    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,ROTA 2>/dev/null || true
    section_title "Thư mục lớn trong /"
    $SUDO du -xh / --max-depth=1 2>/dev/null | sort -h | tail -12 || true
    pause_check_menu
}

check_network_ports() {
    clear
    ui_init
    ui_border_top
    ui_title "${BOLD}KIỂM TRA NETWORK & PORTS${RESET}"
    ui_border_bottom

    section_title "IP address"
    ip -br addr 2>/dev/null || ifconfig 2>/dev/null || true
    section_title "Default route"
    ip route show default 2>/dev/null || route -n 2>/dev/null || true
    section_title "DNS resolver"
    cat /etc/resolv.conf 2>/dev/null || true
    section_title "Port đang listen"
    if command -v ss >/dev/null 2>&1; then
        ss -tulpen 2>/dev/null || ss -tulpn 2>/dev/null
    elif command -v netstat >/dev/null 2>&1; then
        netstat -tulpen 2>/dev/null || netstat -tulpn 2>/dev/null
    else
        echo "Không tìm thấy ss/netstat."
    fi
    pause_check_menu
}

check_services() {
    clear
    ui_init
    ui_border_top
    ui_title "${BOLD}KIỂM TRA SERVICES QUAN TRỌNG${RESET}"
    ui_border_bottom

    local services=(nginx apache2 httpd mariadb mysql mysqld php-fpm docker ssh sshd)
    section_title "Trạng thái service"
    if command -v systemctl >/dev/null 2>&1; then
        local svc
        for svc in "${services[@]}"; do
            if systemctl list-unit-files "$svc.service" >/dev/null 2>&1; then
                printf "%-14s " "$svc"
                systemctl is-active "$svc" 2>/dev/null || true
            fi
        done
        section_title "Service đang failed"
        systemctl --failed --no-pager 2>/dev/null || true
    else
        service --status-all 2>/dev/null || true
    fi
    pause_check_menu
}

check_firewall() {
    clear
    ui_init
    ui_border_top
    ui_title "${BOLD}KIỂM TRA FIREWALL${RESET}"
    ui_border_bottom

    section_title "UFW"
    if command -v ufw >/dev/null 2>&1; then
        $SUDO ufw status verbose || true
    else
        echo "UFW chưa cài đặt."
    fi

    section_title "Firewalld"
    if command -v firewall-cmd >/dev/null 2>&1; then
        $SUDO firewall-cmd --state || true
        $SUDO firewall-cmd --list-all || true
    else
        echo "firewalld chưa cài đặt."
    fi

    section_title "iptables rules summary"
    if command -v iptables >/dev/null 2>&1; then
        $SUDO iptables -S 2>/dev/null | head -80 || true
    else
        echo "iptables chưa cài đặt."
    fi
    pause_check_menu
}

check_security_updates() {
    clear
    ui_init
    ui_border_top
    ui_title "${BOLD}KIỂM TRA CẬP NHẬT & BẢO MẬT${RESET}"
    ui_border_bottom

    detect_os
    section_title "User có quyền sudo/root"
    id
    [ -n "$SUDO" ] && echo "SUDO: enabled" || echo "SUDO: running as root"

    if is_ubuntu; then
        section_title "APT updates có thể cài"
        apt list --upgradable 2>/dev/null | sed -n '1,40p' || true
        section_title "Security updates"
        apt list --upgradable 2>/dev/null | grep -i security | sed -n '1,40p' || echo "Không phát hiện security update trong apt list."
    elif is_centos; then
        section_title "YUM/DNF updates có thể cài"
        if command -v dnf >/dev/null 2>&1; then
            $SUDO dnf check-update || true
        else
            $SUDO yum check-update || true
        fi
    else
        echo "OS chưa hỗ trợ kiểm tra update tự động."
    fi
    pause_check_menu
}

check_runtime_stack() {
    clear
    ui_init
    ui_border_top
    ui_title "${BOLD}KIỂM TRA RUNTIME STACK${RESET}"
    ui_border_bottom

    section_title "Web / DB / PHP / Node versions"
    command -v nginx >/dev/null 2>&1 && nginx -v 2>&1 || echo "Nginx: not installed"
    command -v apache2 >/dev/null 2>&1 && apache2 -v 2>&1 | head -2 || true
    command -v httpd >/dev/null 2>&1 && httpd -v 2>&1 | head -2 || true
    command -v mariadb >/dev/null 2>&1 && mariadb -V || echo "MariaDB client: not installed"
    command -v mysql >/dev/null 2>&1 && mysql -V || echo "MySQL client: not installed"
    command -v php >/dev/null 2>&1 && php -v | head -2 || echo "PHP: not installed"
    command -v node >/dev/null 2>&1 && node -v || echo "Node.js: not installed"
    command -v npm >/dev/null 2>&1 && npm -v || echo "NPM: not installed"

    section_title "Docker"
    if command -v docker >/dev/null 2>&1; then
        docker --version
        docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || true
    else
        echo "Docker: not installed"
    fi
    pause_check_menu
}

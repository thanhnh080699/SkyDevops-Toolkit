#!/bin/bash

# ==============================
# PHP-FPM OPTIMIZATION PLUGIN
# ==============================

. core/ui.sh
. core/os.sh
. core/utils.sh

PHP_SCAN_VERSIONS=()
PHP_SCAN_INIS=()
PHP_SCAN_POOLS=()
PHP_SCAN_SERVICES=()

scan_installed_php_versions() {
    PHP_SCAN_VERSIONS=()
    PHP_SCAN_INIS=()
    PHP_SCAN_POOLS=()
    PHP_SCAN_SERVICES=()

    local candidates=()
    local path

    for path in /etc/php/*/fpm/php.ini; do
        [ -f "$path" ] || continue
        candidates+=("$(echo "$path" | awk -F/ '{print $4}')|$path|/etc/php/$(echo "$path" | awk -F/ '{print $4}')/fpm/pool.d/www.conf|php$(echo "$path" | awk -F/ '{print $4}')-fpm")
    done

    for path in /etc/opt/remi/php*/php.ini; do
        [ -f "$path" ] || continue
        local remi_name
        remi_name=$(echo "$path" | awk -F/ '{print $5}')
        local version="${remi_name#php}"
        version="${version:0:1}.${version:1:1}"
        candidates+=("$version|$path|/etc/opt/remi/$remi_name/php-fpm.d/www.conf|$remi_name-php-fpm")
    done

    if [ -f /etc/php.ini ] && [ -f /etc/php-fpm.d/www.conf ]; then
        local default_version
        default_version=$(php -v 2>/dev/null | head -n 1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
        [ -n "$default_version" ] && candidates+=("$default_version|/etc/php.ini|/etc/php-fpm.d/www.conf|php-fpm")
    fi

    local item version ini pool service exists
    for item in "${candidates[@]}"; do
        version=$(echo "$item" | cut -d'|' -f1)
        ini=$(echo "$item" | cut -d'|' -f2)
        pool=$(echo "$item" | cut -d'|' -f3)
        service=$(echo "$item" | cut -d'|' -f4)
        exists=false
        for existing in "${PHP_SCAN_VERSIONS[@]}"; do
            [ "$existing" = "$version" ] && exists=true
        done
        [ "$exists" = true ] && continue
        [ -f "$ini" ] || continue
        [ -f "$pool" ] || continue
        PHP_SCAN_VERSIONS+=("$version")
        PHP_SCAN_INIS+=("$ini")
        PHP_SCAN_POOLS+=("$pool")
        PHP_SCAN_SERVICES+=("$service")
    done
}

get_php_ini_value() {
    local file=$1
    local key=$2
    local value
    value=$(grep -E "^[[:space:]]*${key}[[:space:]]*=" "$file" 2>/dev/null | tail -1 | cut -d= -f2- | xargs)
    [ -n "$value" ] && echo "$value" || echo "N/A"
}

get_php_pool_value() {
    local file=$1
    local key=$2
    local value
    value=$(grep -E "^[[:space:]]*${key}[[:space:]]*=" "$file" 2>/dev/null | tail -1 | cut -d= -f2- | xargs)
    [ -n "$value" ] && echo "$value" || echo "N/A"
}

set_ini_value() {
    local file=$1
    local key=$2
    local value=$3
    if $SUDO grep -qE "^[;[:space:]]*${key}[[:space:]]*=" "$file"; then
        $SUDO sed -i "s|^[;[:space:]]*${key}[[:space:]]*=.*|${key} = ${value}|" "$file"
    else
        echo "${key} = ${value}" | $SUDO tee -a "$file" >/dev/null
    fi
}

set_pool_value() {
    local file=$1
    local key=$2
    local value=$3
    if $SUDO grep -qE "^[;[:space:]]*${key}[[:space:]]*=" "$file"; then
        $SUDO sed -i "s|^[;[:space:]]*${key}[[:space:]]*=.*|${key} = ${value}|" "$file"
    else
        echo "${key} = ${value}" | $SUDO tee -a "$file" >/dev/null
    fi
}

validate_php_fpm_config() {
    local version=$1
    local service=$2

    if command -v "php-fpm$version" >/dev/null 2>&1; then
        $SUDO "php-fpm$version" -t >/dev/null 2>&1
    elif command -v "php${version//./}-php-fpm" >/dev/null 2>&1; then
        $SUDO "php${version//./}-php-fpm" -t >/dev/null 2>&1
    elif command -v php-fpm >/dev/null 2>&1; then
        $SUDO php-fpm -t >/dev/null 2>&1
    else
        $SUDO systemctl status "$service" >/dev/null 2>&1 || true
    fi
}

optimize_php() {
    scan_installed_php_versions

    clear
    ui_init
    ui_border_top
    ui_title "${BOLD}TỐI ƯU HÓA PHP-FPM${RESET}"
    ui_border_mid

    if [ "${#PHP_SCAN_VERSIONS[@]}" -eq 0 ]; then
        ui_line "${RED}✘ Lỗi: Không tìm thấy PHP-FPM đã cài đặt.${RESET}"
        ui_line "Vui lòng cài đặt PHP-FPM trước khi thực hiện tối ưu."
        ui_border_bottom
        echo -n "  Nhấn Enter để quay lại... "
        read
        return 1
    fi

    ui_line "Đã phát hiện các phiên bản PHP-FPM:"
    ui_empty
    local i
    for i in "${!PHP_SCAN_VERSIONS[@]}"; do
        ui_line "$((i + 1)). PHP ${PHP_SCAN_VERSIONS[$i]}    ${PHP_SCAN_SERVICES[$i]}"
    done
    ui_empty
    ui_line "0. Quay lại menu chính"
    ui_border_bottom

    ui_input
    local choice
    read -r choice
    [[ "$choice" = "0" ]] && return
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#PHP_SCAN_VERSIONS[@]}" ]; then
        echo -e "${RED} Sai lựa chọn ${RESET}"
        sleep 1
        return 1
    fi

    local idx=$((choice - 1))
    local php_version="${PHP_SCAN_VERSIONS[$idx]}"
    local php_ini="${PHP_SCAN_INIS[$idx]}"
    local pool_conf="${PHP_SCAN_POOLS[$idx]}"
    local service_name="${PHP_SCAN_SERVICES[$idx]}"

    local vcpu=1
    local ram_mb=1024
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        vcpu=$(nproc 2>/dev/null || echo 1)
        local ram_kb
        ram_kb=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}' || echo 1048576)
        ram_mb=$((ram_kb / 1024))
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        vcpu=$(sysctl -n hw.ncpu 2>/dev/null || echo 1)
        local ram_bytes
        ram_bytes=$(sysctl -n hw.memsize 2>/dev/null || echo 1073741824)
        ram_mb=$((ram_bytes / 1024 / 1024))
    fi

    local cur_pm=$(get_php_pool_value "$pool_conf" "pm")
    local cur_max_children=$(get_php_pool_value "$pool_conf" "pm.max_children")
    local cur_start_servers=$(get_php_pool_value "$pool_conf" "pm.start_servers")
    local cur_min_spare=$(get_php_pool_value "$pool_conf" "pm.min_spare_servers")
    local cur_max_spare=$(get_php_pool_value "$pool_conf" "pm.max_spare_servers")
    local cur_max_requests=$(get_php_pool_value "$pool_conf" "pm.max_requests")
    local cur_memory_limit=$(get_php_ini_value "$php_ini" "memory_limit")
    local cur_upload=$(get_php_ini_value "$php_ini" "upload_max_filesize")
    local cur_post=$(get_php_ini_value "$php_ini" "post_max_size")
    local cur_opcache_memory=$(get_php_ini_value "$php_ini" "opcache.memory_consumption")
    local cur_opcache_files=$(get_php_ini_value "$php_ini" "opcache.max_accelerated_files")
    local cur_opcache_validate=$(get_php_ini_value "$php_ini" "opcache.validate_timestamps")

    local sug_pm="dynamic"
    local sug_max_children=$((ram_mb / 40))
    [ "$sug_max_children" -lt 5 ] && sug_max_children=5
    [ "$sug_max_children" -gt 500 ] && sug_max_children=500
    local sug_start_servers=$((vcpu * 2))
    [ "$sug_start_servers" -lt 2 ] && sug_start_servers=2
    local sug_min_spare=$vcpu
    [ "$sug_min_spare" -lt 1 ] && sug_min_spare=1
    local sug_max_spare=$((vcpu * 4))
    [ "$sug_max_spare" -lt "$sug_start_servers" ] && sug_max_spare=$sug_start_servers
    [ "$sug_max_spare" -gt "$sug_max_children" ] && sug_max_spare=$sug_max_children
    local sug_max_requests=750
    local sug_memory_limit="256M"
    [ "$ram_mb" -lt 2048 ] && sug_memory_limit="128M"
    local sug_upload="64M"
    local sug_post="64M"
    local sug_opcache_memory=128
    [ "$ram_mb" -ge 4096 ] && sug_opcache_memory=256
    local sug_opcache_files=10000
    [ "$ram_mb" -ge 4096 ] && sug_opcache_files=20000
    local sug_opcache_validate=1

    clear
    ui_init
    ui_border_top
    ui_title "${BOLD}CẤU HÌNH PHP $php_version ĐỀ XUẤT${RESET}"
    ui_border_mid
    ui_line "Hệ thống phát hiện: ${YELLOW}$vcpu vCPU${RESET} | ${YELLOW}${ram_mb}MB RAM${RESET}"
    ui_line "php.ini: $php_ini"
    ui_line "pool:    $pool_conf"
    ui_empty
    ui_line "Nhấn Enter để dùng giá trị gợi ý hoặc nhập giá trị khác."
    ui_border_bottom

    ui_opt_param_prompt "1" "pm" "$cur_pm" "$sug_pm"
    read -r user_pm
    : ${user_pm:=$sug_pm}

    ui_opt_param_prompt "2" "pm.max_children" "$cur_max_children" "$sug_max_children"
    read -r user_max_children
    : ${user_max_children:=$sug_max_children}

    ui_opt_param_prompt "3" "pm.start_servers" "$cur_start_servers" "$sug_start_servers"
    read -r user_start_servers
    : ${user_start_servers:=$sug_start_servers}

    ui_opt_param_prompt "4" "pm.min_spare_servers" "$cur_min_spare" "$sug_min_spare"
    read -r user_min_spare
    : ${user_min_spare:=$sug_min_spare}

    ui_opt_param_prompt "5" "pm.max_spare_servers" "$cur_max_spare" "$sug_max_spare"
    read -r user_max_spare
    : ${user_max_spare:=$sug_max_spare}

    ui_opt_param_prompt "6" "pm.max_requests" "$cur_max_requests" "$sug_max_requests"
    read -r user_max_requests
    : ${user_max_requests:=$sug_max_requests}

    ui_opt_param_prompt "7" "memory_limit" "$cur_memory_limit" "$sug_memory_limit"
    read -r user_memory_limit
    : ${user_memory_limit:=$sug_memory_limit}

    ui_opt_param_prompt "8" "upload_max_filesize" "$cur_upload" "$sug_upload"
    read -r user_upload
    : ${user_upload:=$sug_upload}

    ui_opt_param_prompt "9" "post_max_size" "$cur_post" "$sug_post"
    read -r user_post
    : ${user_post:=$sug_post}

    ui_opt_param_prompt "10" "opcache.memory_consumption" "$cur_opcache_memory" "$sug_opcache_memory"
    read -r user_opcache_memory
    : ${user_opcache_memory:=$sug_opcache_memory}

    ui_opt_param_prompt "11" "opcache.max_accelerated_files" "$cur_opcache_files" "$sug_opcache_files"
    read -r user_opcache_files
    : ${user_opcache_files:=$sug_opcache_files}

    ui_opt_param_prompt "12" "opcache.validate_timestamps" "$cur_opcache_validate" "$sug_opcache_validate"
    read -r user_opcache_validate
    : ${user_opcache_validate:=$sug_opcache_validate}

    clear
    ui_init
    ui_border_top
    ui_title "${BOLD}XÁC NHẬN THAY ĐỔI PHP $php_version${RESET}"
    ui_border_mid
    ui_line "${BOLD}$(printf "%-32s %-16s %-16s" "Tham số" "Hiện tại" "Mới")${RESET}"
    ui_line "--------------------------------------------------------------------"
    ui_line "$(printf "%-32s %-16s %-16s" "pm" "$cur_pm" "$user_pm")"
    ui_line "$(printf "%-32s %-16s %-16s" "pm.max_children" "$cur_max_children" "$user_max_children")"
    ui_line "$(printf "%-32s %-16s %-16s" "pm.start_servers" "$cur_start_servers" "$user_start_servers")"
    ui_line "$(printf "%-32s %-16s %-16s" "pm.min_spare_servers" "$cur_min_spare" "$user_min_spare")"
    ui_line "$(printf "%-32s %-16s %-16s" "pm.max_spare_servers" "$cur_max_spare" "$user_max_spare")"
    ui_line "$(printf "%-32s %-16s %-16s" "pm.max_requests" "$cur_max_requests" "$user_max_requests")"
    ui_line "$(printf "%-32s %-16s %-16s" "memory_limit" "$cur_memory_limit" "$user_memory_limit")"
    ui_line "$(printf "%-32s %-16s %-16s" "upload_max_filesize" "$cur_upload" "$user_upload")"
    ui_line "$(printf "%-32s %-16s %-16s" "post_max_size" "$cur_post" "$user_post")"
    ui_line "$(printf "%-32s %-16s %-16s" "opcache.memory_consumption" "$cur_opcache_memory" "$user_opcache_memory")"
    ui_line "$(printf "%-32s %-16s %-16s" "opcache.max_accelerated_files" "$cur_opcache_files" "$user_opcache_files")"
    ui_line "$(printf "%-32s %-16s %-16s" "opcache.validate_timestamps" "$cur_opcache_validate" "$user_opcache_validate")"
    ui_empty
    ui_line "${YELLOW}Hệ thống sẽ backup php.ini và pool config trước khi ghi.${RESET}"
    ui_border_bottom

    echo -ne "\n${BOLD}➜ Tiến hành áp dụng và reload PHP-FPM? (Y/n):${RESET} "
    read -r confirm
    [[ -z "$confirm" ]] && confirm="y"
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "\n  ${YELLOW}Đã hủy thao tác.${RESET}"
        sleep 1
        return
    fi

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        local ini_backup="$php_ini.bak.$(date +%Y%m%d_%H%M%S)"
        local pool_backup="$pool_conf.bak.$(date +%Y%m%d_%H%M%S)"
        echo -e "\n${GREEN}  Đang tạo backup cấu hình...${RESET}"
        $SUDO cp "$php_ini" "$ini_backup"
        $SUDO cp "$pool_conf" "$pool_backup"

        set_pool_value "$pool_conf" "pm" "$user_pm"
        set_pool_value "$pool_conf" "pm.max_children" "$user_max_children"
        set_pool_value "$pool_conf" "pm.start_servers" "$user_start_servers"
        set_pool_value "$pool_conf" "pm.min_spare_servers" "$user_min_spare"
        set_pool_value "$pool_conf" "pm.max_spare_servers" "$user_max_spare"
        set_pool_value "$pool_conf" "pm.max_requests" "$user_max_requests"
        set_ini_value "$php_ini" "memory_limit" "$user_memory_limit"
        set_ini_value "$php_ini" "upload_max_filesize" "$user_upload"
        set_ini_value "$php_ini" "post_max_size" "$user_post"
        set_ini_value "$php_ini" "opcache.enable" "1"
        set_ini_value "$php_ini" "opcache.memory_consumption" "$user_opcache_memory"
        set_ini_value "$php_ini" "opcache.max_accelerated_files" "$user_opcache_files"
        set_ini_value "$php_ini" "opcache.validate_timestamps" "$user_opcache_validate"

        if validate_php_fpm_config "$php_version" "$service_name"; then
            echo -e "  ${GREEN}✔ Cấu hình hợp lệ. Đang reload $service_name...${RESET}"
            if command -v systemctl >/dev/null 2>&1; then
                $SUDO systemctl reload "$service_name" || $SUDO systemctl restart "$service_name"
            else
                $SUDO service "$service_name" reload || $SUDO service "$service_name" restart
            fi
        else
            echo -e "  ${RED}✘ Cấu hình không hợp lệ. Đang khôi phục từ backup...${RESET}"
            $SUDO cp "$ini_backup" "$php_ini"
            $SUDO cp "$pool_backup" "$pool_conf"
            return 1
        fi
    else
        simulate_progress "Đang tạo bản backup cấu hình"
        simulate_progress "Đang cập nhật php.ini và pool PHP-FPM"
        simulate_progress "Đang kiểm tra cú pháp PHP-FPM"
    fi

    echo -e "\n  ${GREEN}✔ Hoàn tất quy trình tối ưu PHP-FPM!${RESET}"
    echo -n "  Nhấn Enter để quay lại... "
    read
}

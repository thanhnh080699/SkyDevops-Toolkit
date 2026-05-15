#!/bin/bash

# ==============================
# MARIADB OPTIMIZATION PLUGIN
# ==============================

. core/ui.sh
. core/os.sh
. core/utils.sh

detect_mariadb_service() {
    if command -v systemctl >/dev/null 2>&1; then
        if systemctl list-unit-files mariadb.service >/dev/null 2>&1; then
            echo "mariadb"
            return
        fi
        if systemctl list-unit-files mysql.service >/dev/null 2>&1; then
            echo "mysql"
            return
        fi
    fi
    echo "mariadb"
}

get_mariadb_optimize_file() {
    if [ -d /etc/mysql/mariadb.conf.d ]; then
        echo "/etc/mysql/mariadb.conf.d/99-optimize_mariadb.cnf"
    elif [ -d /etc/my.cnf.d ]; then
        echo "/etc/my.cnf.d/99-optimize_mariadb.cnf"
    else
        echo "/etc/mysql/mariadb.conf.d/99-optimize_mariadb.cnf"
    fi
}

get_mariadb_current() {
    local key=$1
    local value=""
    local files=(
        "/etc/mysql/mariadb.conf.d/99-optimize_mariadb.cnf"
        "/etc/mysql/mariadb.conf.d/50-server.cnf"
        "/etc/mysql/my.cnf"
        "/etc/my.cnf.d/99-optimize_mariadb.cnf"
        "/etc/my.cnf.d/server.cnf"
        "/etc/my.cnf"
    )

    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            value=$(grep -E "^[[:space:]]*${key}[[:space:]]*=" "$file" 2>/dev/null | tail -1 | cut -d= -f2- | xargs)
            [ -n "$value" ] && break
        fi
    done

    [ -n "$value" ] && echo "$value" || echo "N/A"
}

pause_before_menu() {
    echo -n "  Bấm phím bất kỳ để quay lại menu chính... "
    read -n 1 -s -r
    echo
}

optimize_mariadb() {
    clear
    ui_init
    ui_border_top
    ui_title "${BOLD}TỐI ƯU HÓA CẤU HÌNH MARIADB${RESET}"
    ui_border_mid

    if ! command -v mariadb >/dev/null 2>&1 && ! command -v mysql >/dev/null 2>&1; then
        ui_line "${RED}✘ Lỗi: MariaDB chưa được cài đặt trên hệ thống.${RESET}"
        ui_line "Vui lòng cài đặt MariaDB trước khi thực hiện tối ưu."
        ui_border_bottom
        echo -n "  Nhấn Enter để quay lại... "
        read
        return 1
    fi

    local vcpu=1
    local ram_mb=1024
    local disk_type="unknown"

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        vcpu=$(nproc 2>/dev/null || echo 1)
        local ram_kb
        ram_kb=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}' || echo 1048576)
        ram_mb=$((ram_kb / 1024))
        local root_disk
        root_disk=$(lsblk -ndo PKNAME "$(findmnt -n -o SOURCE / 2>/dev/null)" 2>/dev/null | head -1)
        [ -z "$root_disk" ] && root_disk=$(lsblk -ndo NAME,TYPE 2>/dev/null | awk '$2=="disk"{print $1; exit}')
        local rotational
        rotational=$(cat "/sys/block/$root_disk/queue/rotational" 2>/dev/null)
        [ "$rotational" = "0" ] && disk_type="SSD"
        [ "$rotational" = "1" ] && disk_type="HDD"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        vcpu=$(sysctl -n hw.ncpu 2>/dev/null || echo 1)
        local ram_bytes
        ram_bytes=$(sysctl -n hw.memsize 2>/dev/null || echo 1073741824)
        ram_mb=$((ram_bytes / 1024 / 1024))
    fi

    local cur_buffer_pool=$(get_mariadb_current "innodb_buffer_pool_size")
    local cur_log_file=$(get_mariadb_current "innodb_log_file_size")
    local cur_flush=$(get_mariadb_current "innodb_flush_log_at_trx_commit")
    local cur_max_conn=$(get_mariadb_current "max_connections")
    local cur_tmp=$(get_mariadb_current "tmp_table_size")
    local cur_heap=$(get_mariadb_current "max_heap_table_size")
    local cur_thread_cache=$(get_mariadb_current "thread_cache_size")
    local cur_key_buffer=$(get_mariadb_current "key_buffer_size")
    local cur_buffer_instances=$(get_mariadb_current "innodb_buffer_pool_instances")
    local cur_flush_method=$(get_mariadb_current "innodb_flush_method")
    local cur_io_capacity=$(get_mariadb_current "innodb_io_capacity")
    local cur_io_capacity_max=$(get_mariadb_current "innodb_io_capacity_max")
    local cur_read_io_threads=$(get_mariadb_current "innodb_read_io_threads")
    local cur_write_io_threads=$(get_mariadb_current "innodb_write_io_threads")
    local cur_log_buffer=$(get_mariadb_current "innodb_log_buffer_size")
    local cur_table_open_cache=$(get_mariadb_current "table_open_cache")
    local cur_table_def_cache=$(get_mariadb_current "table_definition_cache")
    local cur_open_files=$(get_mariadb_current "open_files_limit")
    local cur_query_cache_type=$(get_mariadb_current "query_cache_type")
    local cur_query_cache_size=$(get_mariadb_current "query_cache_size")
    local cur_wait_timeout=$(get_mariadb_current "wait_timeout")
    local cur_interactive_timeout=$(get_mariadb_current "interactive_timeout")
    local cur_connect_timeout=$(get_mariadb_current "connect_timeout")
    local cur_slow_log=$(get_mariadb_current "slow_query_log")
    local cur_long_query_time=$(get_mariadb_current "long_query_time")
    local cur_slow_verbosity=$(get_mariadb_current "log_slow_verbosity")

    local sug_buffer_pool=$((ram_mb * 70 / 100))
    [ "$sug_buffer_pool" -lt 128 ] && sug_buffer_pool=128
    local sug_buffer_pool_size="${sug_buffer_pool}M"

    local sug_log_file_size="256M"
    [ "$ram_mb" -ge 4096 ] && sug_log_file_size="512M"
    [ "$ram_mb" -ge 16384 ] && sug_log_file_size="1G"

    local sug_flush=2
    local sug_max_connections=$((ram_mb / 10))
    [ "$sug_max_connections" -lt 50 ] && sug_max_connections=50
    [ "$sug_max_connections" -gt 1000 ] && sug_max_connections=1000

    local sug_tmp_table_size="64M"
    [ "$ram_mb" -ge 4096 ] && sug_tmp_table_size="128M"
    [ "$ram_mb" -ge 16384 ] && sug_tmp_table_size="256M"
    local sug_thread_cache=$((vcpu * 8))
    [ "$sug_thread_cache" -lt 8 ] && sug_thread_cache=8
    [ "$sug_thread_cache" -gt 64 ] && sug_thread_cache=64
    local sug_key_buffer_size="32M"
    local sug_buffer_instances=1
    if [ "$sug_buffer_pool" -ge 1024 ]; then
        sug_buffer_instances=$vcpu
        [ "$sug_buffer_instances" -lt 1 ] && sug_buffer_instances=1
        [ "$sug_buffer_instances" -gt 8 ] && sug_buffer_instances=8
    fi

    local sug_flush_method="O_DIRECT"
    local sug_io_capacity=200
    local sug_io_capacity_max=400
    if [ "$disk_type" = "SSD" ]; then
        sug_io_capacity=1000
        sug_io_capacity_max=2000
    fi

    local sug_io_threads=$((vcpu / 2))
    [ "$sug_io_threads" -lt 4 ] && sug_io_threads=4
    [ "$sug_io_threads" -gt 16 ] && sug_io_threads=16
    local sug_log_buffer_size="64M"
    [ "$ram_mb" -ge 16384 ] && sug_log_buffer_size="128M"
    local sug_table_open_cache=$((sug_max_connections * 4))
    [ "$sug_table_open_cache" -lt 400 ] && sug_table_open_cache=400
    [ "$sug_table_open_cache" -gt 4000 ] && sug_table_open_cache=4000
    local sug_table_def_cache=2000
    [ "$ram_mb" -lt 2048 ] && sug_table_def_cache=800
    local sug_open_files_limit=65535
    local sug_query_cache_type=0
    local sug_query_cache_size=0
    local sug_wait_timeout=60
    local sug_interactive_timeout=60
    local sug_connect_timeout=10
    local sug_slow_log=1
    local sug_long_query_time=2
    local sug_slow_verbosity="query_plan"

    clear
    ui_init
    ui_border_top
    ui_title "${BOLD}CẤU HÌNH MARIADB ĐỀ XUẤT${RESET}"
    ui_border_mid
    ui_line "Hệ thống phát hiện: ${YELLOW}$vcpu vCPU${RESET} | ${YELLOW}${ram_mb}MB RAM${RESET} | Disk: ${YELLOW}$disk_type${RESET}"
    ui_empty
    ui_line "Nhấn Enter để dùng giá trị gợi ý hoặc nhập giá trị khác."
    ui_border_bottom

    ui_opt_param_prompt "1" "innodb_buffer_pool_size" "$cur_buffer_pool" "$sug_buffer_pool_size"
    read -r user_buffer_pool_size
    : ${user_buffer_pool_size:=$sug_buffer_pool_size}

    ui_opt_param_prompt "2" "innodb_log_file_size" "$cur_log_file" "$sug_log_file_size"
    read -r user_log_file_size
    : ${user_log_file_size:=$sug_log_file_size}

    ui_opt_param_prompt "3" "innodb_flush_log_at_trx_commit" "$cur_flush" "$sug_flush"
    read -r user_flush
    : ${user_flush:=$sug_flush}

    ui_opt_param_prompt "4" "max_connections" "$cur_max_conn" "$sug_max_connections"
    read -r user_max_connections
    : ${user_max_connections:=$sug_max_connections}

    ui_opt_param_prompt "5" "tmp_table_size" "$cur_tmp" "$sug_tmp_table_size"
    read -r user_tmp_table_size
    : ${user_tmp_table_size:=$sug_tmp_table_size}

    ui_opt_param_prompt "6" "max_heap_table_size" "$cur_heap" "$user_tmp_table_size"
    read -r user_heap_table_size
    : ${user_heap_table_size:=$user_tmp_table_size}

    ui_opt_param_prompt "7" "thread_cache_size" "$cur_thread_cache" "$sug_thread_cache"
    read -r user_thread_cache
    : ${user_thread_cache:=$sug_thread_cache}

    ui_opt_param_prompt "8" "key_buffer_size" "$cur_key_buffer" "$sug_key_buffer_size"
    read -r user_key_buffer_size
    : ${user_key_buffer_size:=$sug_key_buffer_size}

    ui_opt_param_prompt "9" "innodb_buffer_pool_instances" "$cur_buffer_instances" "$sug_buffer_instances"
    read -r user_buffer_instances
    : ${user_buffer_instances:=$sug_buffer_instances}

    ui_opt_param_prompt "10" "innodb_flush_method" "$cur_flush_method" "$sug_flush_method"
    read -r user_flush_method
    : ${user_flush_method:=$sug_flush_method}

    ui_opt_param_prompt "11" "innodb_io_capacity" "$cur_io_capacity" "$sug_io_capacity"
    read -r user_io_capacity
    : ${user_io_capacity:=$sug_io_capacity}

    ui_opt_param_prompt "12" "innodb_io_capacity_max" "$cur_io_capacity_max" "$sug_io_capacity_max"
    read -r user_io_capacity_max
    : ${user_io_capacity_max:=$sug_io_capacity_max}

    ui_opt_param_prompt "13" "innodb_read_io_threads" "$cur_read_io_threads" "$sug_io_threads"
    read -r user_read_io_threads
    : ${user_read_io_threads:=$sug_io_threads}

    ui_opt_param_prompt "14" "innodb_write_io_threads" "$cur_write_io_threads" "$sug_io_threads"
    read -r user_write_io_threads
    : ${user_write_io_threads:=$sug_io_threads}

    ui_opt_param_prompt "15" "innodb_log_buffer_size" "$cur_log_buffer" "$sug_log_buffer_size"
    read -r user_log_buffer_size
    : ${user_log_buffer_size:=$sug_log_buffer_size}

    ui_opt_param_prompt "16" "table_open_cache" "$cur_table_open_cache" "$sug_table_open_cache"
    read -r user_table_open_cache
    : ${user_table_open_cache:=$sug_table_open_cache}

    ui_opt_param_prompt "17" "table_definition_cache" "$cur_table_def_cache" "$sug_table_def_cache"
    read -r user_table_def_cache
    : ${user_table_def_cache:=$sug_table_def_cache}

    ui_opt_param_prompt "18" "open_files_limit" "$cur_open_files" "$sug_open_files_limit"
    read -r user_open_files_limit
    : ${user_open_files_limit:=$sug_open_files_limit}

    ui_opt_param_prompt "19" "query_cache_type" "$cur_query_cache_type" "$sug_query_cache_type"
    read -r user_query_cache_type
    : ${user_query_cache_type:=$sug_query_cache_type}

    ui_opt_param_prompt "20" "query_cache_size" "$cur_query_cache_size" "$sug_query_cache_size"
    read -r user_query_cache_size
    : ${user_query_cache_size:=$sug_query_cache_size}

    ui_opt_param_prompt "21" "wait_timeout" "$cur_wait_timeout" "$sug_wait_timeout"
    read -r user_wait_timeout
    : ${user_wait_timeout:=$sug_wait_timeout}

    ui_opt_param_prompt "22" "interactive_timeout" "$cur_interactive_timeout" "$sug_interactive_timeout"
    read -r user_interactive_timeout
    : ${user_interactive_timeout:=$sug_interactive_timeout}

    ui_opt_param_prompt "23" "connect_timeout" "$cur_connect_timeout" "$sug_connect_timeout"
    read -r user_connect_timeout
    : ${user_connect_timeout:=$sug_connect_timeout}

    ui_opt_param_prompt "24" "slow_query_log" "$cur_slow_log" "$sug_slow_log"
    read -r user_slow_log
    : ${user_slow_log:=$sug_slow_log}

    ui_opt_param_prompt "25" "long_query_time" "$cur_long_query_time" "$sug_long_query_time"
    read -r user_long_query_time
    : ${user_long_query_time:=$sug_long_query_time}

    ui_opt_param_prompt "26" "log_slow_verbosity" "$cur_slow_verbosity" "$sug_slow_verbosity"
    read -r user_slow_verbosity
    : ${user_slow_verbosity:=$sug_slow_verbosity}

    clear
    ui_init
    ui_border_top
    ui_title "${BOLD}XÁC NHẬN THAY ĐỔI MARIADB${RESET}"
    ui_border_mid
    ui_line "${BOLD}$(printf "%-35s %-18s %-18s" "Tham số" "Hiện tại" "Mới")${RESET}"
    ui_line "------------------------------------------------------------------------"
    ui_line "$(printf "%-35s %-18s %-18s" "innodb_buffer_pool_size" "$cur_buffer_pool" "$user_buffer_pool_size")"
    ui_line "$(printf "%-35s %-18s %-18s" "innodb_log_file_size" "$cur_log_file" "$user_log_file_size")"
    ui_line "$(printf "%-35s %-18s %-18s" "innodb_flush_log_at_trx_commit" "$cur_flush" "$user_flush")"
    ui_line "$(printf "%-35s %-18s %-18s" "max_connections" "$cur_max_conn" "$user_max_connections")"
    ui_line "$(printf "%-35s %-18s %-18s" "tmp_table_size" "$cur_tmp" "$user_tmp_table_size")"
    ui_line "$(printf "%-35s %-18s %-18s" "max_heap_table_size" "$cur_heap" "$user_heap_table_size")"
    ui_line "$(printf "%-35s %-18s %-18s" "thread_cache_size" "$cur_thread_cache" "$user_thread_cache")"
    ui_line "$(printf "%-35s %-18s %-18s" "key_buffer_size" "$cur_key_buffer" "$user_key_buffer_size")"
    ui_line "$(printf "%-35s %-18s %-18s" "innodb_buffer_pool_instances" "$cur_buffer_instances" "$user_buffer_instances")"
    ui_line "$(printf "%-35s %-18s %-18s" "innodb_flush_method" "$cur_flush_method" "$user_flush_method")"
    ui_line "$(printf "%-35s %-18s %-18s" "innodb_io_capacity" "$cur_io_capacity" "$user_io_capacity")"
    ui_line "$(printf "%-35s %-18s %-18s" "innodb_io_capacity_max" "$cur_io_capacity_max" "$user_io_capacity_max")"
    ui_line "$(printf "%-35s %-18s %-18s" "innodb_read_io_threads" "$cur_read_io_threads" "$user_read_io_threads")"
    ui_line "$(printf "%-35s %-18s %-18s" "innodb_write_io_threads" "$cur_write_io_threads" "$user_write_io_threads")"
    ui_line "$(printf "%-35s %-18s %-18s" "innodb_log_buffer_size" "$cur_log_buffer" "$user_log_buffer_size")"
    ui_line "$(printf "%-35s %-18s %-18s" "table_open_cache" "$cur_table_open_cache" "$user_table_open_cache")"
    ui_line "$(printf "%-35s %-18s %-18s" "table_definition_cache" "$cur_table_def_cache" "$user_table_def_cache")"
    ui_line "$(printf "%-35s %-18s %-18s" "open_files_limit" "$cur_open_files" "$user_open_files_limit")"
    ui_line "$(printf "%-35s %-18s %-18s" "query_cache_type" "$cur_query_cache_type" "$user_query_cache_type")"
    ui_line "$(printf "%-35s %-18s %-18s" "query_cache_size" "$cur_query_cache_size" "$user_query_cache_size")"
    ui_line "$(printf "%-35s %-18s %-18s" "wait_timeout" "$cur_wait_timeout" "$user_wait_timeout")"
    ui_line "$(printf "%-35s %-18s %-18s" "interactive_timeout" "$cur_interactive_timeout" "$user_interactive_timeout")"
    ui_line "$(printf "%-35s %-18s %-18s" "connect_timeout" "$cur_connect_timeout" "$user_connect_timeout")"
    ui_line "$(printf "%-35s %-18s %-18s" "slow_query_log" "$cur_slow_log" "$user_slow_log")"
    ui_line "$(printf "%-35s %-18s %-18s" "long_query_time" "$cur_long_query_time" "$user_long_query_time")"
    ui_line "$(printf "%-35s %-18s %-18s" "log_slow_verbosity" "$cur_slow_verbosity" "$user_slow_verbosity")"
    ui_empty
    ui_line "${YELLOW}Cấu hình sẽ được ghi vào include 99-optimize_mariadb.cnf và backup nếu file đã tồn tại.${RESET}"
    ui_line "${YELLOW}MariaDB cần restart để nhận các tham số InnoDB này.${RESET}"
    ui_border_bottom

    echo -ne "\n${BOLD}➜ Tiến hành áp dụng và restart MariaDB? (Y/n):${RESET} "
    read -r confirm
    [[ -z "$confirm" ]] && confirm="y"
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "\n  ${YELLOW}Đã hủy thao tác.${RESET}"
        sleep 1
        return
    fi

    local optimize_file
    optimize_file=$(get_mariadb_optimize_file)
    local optimize_dir
    optimize_dir=$(dirname "$optimize_file")
    local backup_file=""

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo -e "\n${CYAN}==> Chuẩn bị thư mục cấu hình: $optimize_dir${RESET}"
        if ! $SUDO mkdir -p "$optimize_dir"; then
            echo -e "  ${RED}✘ Không thể tạo thư mục cấu hình.${RESET}"
            pause_before_menu
            return 1
        fi

        if [ -f "$optimize_file" ]; then
            backup_file="$optimize_file.bak.$(date +%Y%m%d_%H%M%S)"
            echo -e "\n${CYAN}==> Tạo bản backup tại $backup_file${RESET}"
            if ! $SUDO cp "$optimize_file" "$backup_file"; then
                echo -e "  ${RED}✘ Không thể tạo backup cấu hình.${RESET}"
                pause_before_menu
                return 1
            fi
        fi

        local tmp_file
        tmp_file=$(mktemp)
        echo -e "\n${CYAN}==> Ghi file cấu hình tối ưu: $optimize_file${RESET}"
        cat > "$tmp_file" <<EOF
[mysqld]
# Managed by SkyDevOps Toolkit
innodb_buffer_pool_size = $user_buffer_pool_size
innodb_log_file_size = $user_log_file_size
innodb_log_buffer_size = $user_log_buffer_size
innodb_flush_log_at_trx_commit = $user_flush
innodb_buffer_pool_instances = $user_buffer_instances
innodb_flush_method = $user_flush_method
innodb_io_capacity = $user_io_capacity
innodb_io_capacity_max = $user_io_capacity_max
innodb_read_io_threads = $user_read_io_threads
innodb_write_io_threads = $user_write_io_threads
max_connections = $user_max_connections
tmp_table_size = $user_tmp_table_size
max_heap_table_size = $user_heap_table_size
thread_cache_size = $user_thread_cache
key_buffer_size = $user_key_buffer_size
table_open_cache = $user_table_open_cache
table_definition_cache = $user_table_def_cache
open_files_limit = $user_open_files_limit
query_cache_type = $user_query_cache_type
query_cache_size = $user_query_cache_size
wait_timeout = $user_wait_timeout
interactive_timeout = $user_interactive_timeout
connect_timeout = $user_connect_timeout
slow_query_log = $user_slow_log
long_query_time = $user_long_query_time
log_slow_verbosity = $user_slow_verbosity
EOF
        if ! $SUDO cp "$tmp_file" "$optimize_file"; then
            rm -f "$tmp_file"
            echo -e "  ${RED}✘ Không thể ghi file cấu hình tối ưu.${RESET}"
            pause_before_menu
            return 1
        fi
        rm -f "$tmp_file"

        local service_name
        service_name=$(detect_mariadb_service)
        echo -e "\n${CYAN}==> Bỏ qua validate daemon, restart service để kiểm tra cấu hình: $service_name${RESET}"
        if command -v systemctl >/dev/null 2>&1; then
            if ! $SUDO systemctl restart "$service_name"; then
                echo -e "  ${RED}✘ Restart $service_name thất bại. Đang hiển thị trạng thái service...${RESET}"
                $SUDO systemctl status "$service_name" --no-pager -l || true
                echo -e "\n  ${YELLOW}Đang khôi phục cấu hình trước đó...${RESET}"
                if [ -n "$backup_file" ]; then
                    $SUDO cp "$backup_file" "$optimize_file"
                else
                    $SUDO rm -f "$optimize_file"
                fi
                $SUDO systemctl restart "$service_name" || true
                pause_before_menu
                return 1
            fi
        else
            if ! $SUDO service "$service_name" restart; then
                echo -e "  ${RED}✘ Restart $service_name thất bại.${RESET}"
                if [ -n "$backup_file" ]; then
                    $SUDO cp "$backup_file" "$optimize_file"
                else
                    $SUDO rm -f "$optimize_file"
                fi
                $SUDO service "$service_name" restart || true
                pause_before_menu
                return 1
            fi
        fi
    else
        simulate_progress "Đang tạo bản backup cấu hình"
        simulate_progress "Đang ghi include MariaDB 99-optimize_mariadb.cnf"
        simulate_progress "Đang restart MariaDB để áp dụng cấu hình"
    fi

    echo -e "\n  ${GREEN}✔ Hoàn tất quy trình tối ưu MariaDB!${RESET}"
    pause_before_menu
}

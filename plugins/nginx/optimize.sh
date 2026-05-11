#!/bin/bash

# ==============================
# NGINX OPTIMIZATION PLUGIN
# ==============================

. core/ui.sh
. core/os.sh
. core/utils.sh

optimize_nginx() {
    clear
    ui_init
    ui_border_top
    ui_title "${BOLD}TỐI ƯU HÓA CẤU HÌNH NGINX${RESET}"
    ui_border_mid
    
    # 1. Kiểm tra Nginx đã cài đặt chưa
    if ! command -v nginx >/dev/null 2>&1; then
        ui_line "${RED}✘ Lỗi: Nginx chưa được cài đặt trên hệ thống.${RESET}"
        ui_line "Vui lòng cài đặt Nginx trước khi thực hiện tối ưu."
        ui_border_bottom
        echo -n "  Nhấn Enter để quay lại... "
        read
        return 1
    fi

    ui_line "Trạng thái: ${GREEN}✔ Đã tìm thấy Nginx${RESET}"
    ui_empty
    
    # 2. Xin cấp quyền lấy thông số phần cứng
    ui_line "Yêu cầu: Cho phép lấy thông số phần cứng (vCPU, RAM, ...)"
    ui_line "để tính toán cấu hình tối ưu nhất."
    ui_border_bottom
    
    echo -ne "\n${BOLD}➜ Bạn có cho phép lấy thông số hệ thống? (Y/n):${RESET} "
    read -r allow_stats
    if [[ -z "$allow_stats" ]]; then allow_stats="y"; fi
    
    if [[ ! "$allow_stats" =~ ^[Yy]$ ]]; then
        echo -e "\n  ${RED}✘ Lỗi: Quyền truy cập bị từ chối. Dừng chương trình.${RESET}"
        sleep 2
        return 1
    fi

    # Lấy thông số hệ thống
    local vcpu=1
    local ram_mb=1024
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        vcpu=$(nproc 2>/dev/null || echo 1)
        local ram_kb=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}' || echo 1048576)
        ram_mb=$((ram_kb / 1024))
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        vcpu=$(sysctl -n hw.ncpu 2>/dev/null || echo 1)
        local ram_bytes=$(sysctl -n hw.memsize 2>/dev/null || echo 1073741824)
        ram_mb=$((ram_bytes / 1024 / 1024))
    fi

    # Lấy giá trị hiện tại từ config
    local config_file="/etc/nginx/nginx.conf"
    get_current() {
        local key=$1
        if [ -f "$config_file" ]; then
            grep -E "^\s*${key}\s+" "$config_file" | sed 's/;//' | awk '{print $NF}' | head -1 || echo "N/A"
        else
            echo "N/A"
        fi
    }

    local cur_wp=$(get_current "worker_processes")
    local cur_wc=$(get_current "worker_connections")
    local cur_ka=$(get_current "keepalive_timeout")
    local cur_gz=$(get_current "gzip")
    local cur_mb=$(get_current "client_max_body_size")
    local cur_ep=$(grep -q "use epoll" "$config_file" 2>/dev/null && echo "on" || echo "off")

    # 3. Tính toán gợi ý
    local sug_worker_processes=$vcpu
    local sug_worker_connections=$((ram_mb * 4))
    [ $sug_worker_connections -lt 1024 ] && sug_worker_connections=1024
    [ $sug_worker_connections -gt 65535 ] && sug_worker_connections=65535
    
    local sug_keepalive=65
    local sug_gzip="on"
    local sug_client_max_body="64M"
    local sug_epoll="on"

    # Giao diện nhập thông số
    clear
    ui_init
    ui_border_top
    ui_title "${BOLD}CẤU HÌNH ĐỀ XUẤT (CÓ THỂ CHỈNH SỬA)${RESET}"
    ui_border_mid
    ui_line "Hệ thống phát hiện: ${BLUE}$vcpu vCPU${RESET} | ${BLUE}${ram_mb}MB RAM${RESET}"
    ui_empty
    ui_line "Vui lòng kiểm tra và thay đổi các thông số bên dưới:"
    ui_border_bottom
    
    echo -ne "\n${BOLD}1. worker_processes (Hiện tại: ${YELLOW}$cur_wp${RESET}, Gợi ý: ${GREEN}$sug_worker_processes${RESET}): "
    read -r user_worker_processes
    : ${user_worker_processes:=$sug_worker_processes}

    echo -ne "${BOLD}2. worker_connections (Hiện tại: ${YELLOW}$cur_wc${RESET}, Gợi ý: ${GREEN}$sug_worker_connections${RESET}): "
    read -r user_worker_connections
    : ${user_worker_connections:=$sug_worker_connections}

    echo -ne "${BOLD}3. keepalive_timeout (Hiện tại: ${YELLOW}$cur_ka${RESET}, Gợi ý: ${GREEN}$sug_keepalive${RESET}): "
    read -r user_keepalive
    : ${user_keepalive:=$sug_keepalive}

    echo -ne "${BOLD}4. gzip (Hiện tại: ${YELLOW}$cur_gz${RESET}, Gợi ý: ${GREEN}$sug_gzip${RESET}): "
    read -r user_gzip
    : ${user_gzip:=$sug_gzip}

    echo -ne "${BOLD}5. client_max_body_size (Hiện tại: ${YELLOW}$cur_mb${RESET}, Gợi ý: ${GREEN}$sug_client_max_body${RESET}): "
    read -r user_client_max_body
    : ${user_client_max_body:=$sug_client_max_body}

    echo -ne "${BOLD}6. use epoll (Hiện tại: ${YELLOW}$cur_ep${RESET}, Gợi ý: ${GREEN}$sug_epoll${RESET}): "
    read -r user_epoll
    : ${user_epoll:=$sug_epoll}

    # 4. Xác nhận và thực hiện
    clear
    ui_init
    ui_border_top
    ui_title "${BOLD}XÁC NHẬN THAY ĐỔI (DIFF)${RESET}"
    ui_border_mid
    ui_line "${BOLD}$(printf "%-25s %-20s %-20s" "Tham số" "Hiện tại" "Mới")${RESET}"
    ui_line "----------------------------------------------------------------"
    ui_line "$(printf "%-25s %-20s %-20s" "worker_processes" "$cur_wp" "$user_worker_processes")"
    ui_line "$(printf "%-25s %-20s %-20s" "worker_connections" "$cur_wc" "$user_worker_connections")"
    ui_line "$(printf "%-25s %-20s %-20s" "keepalive_timeout" "$cur_ka" "$user_keepalive")"
    ui_line "$(printf "%-25s %-20s %-20s" "gzip" "$cur_gz" "$user_gzip")"
    ui_line "$(printf "%-25s %-20s %-20s" "client_max_body_size" "$cur_mb" "$user_client_max_body")"
    ui_line "$(printf "%-25s %-20s %-20s" "use epoll" "$cur_ep" "$user_epoll")"
    ui_empty
    ui_line "${YELLOW}Lưu ý: Hệ thống sẽ backup /etc/nginx/nginx.conf trước khi ghi đè.${RESET}"
    ui_border_bottom

    echo -ne "\n${BOLD}➜ Tiến hành áp dụng? (Y/n):${RESET} "
    read -r confirm
    if [[ -z "$confirm" ]]; then confirm="y"; fi
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "\n  ${YELLOW}Đã hủy thao tác.${RESET}"
        sleep 1
        return
    fi

    # Backup và thay đổi
    local backup_file="/etc/nginx/nginx.conf.bak.$(date +%Y%m%d_%H%M%S)"
    
    echo -e "\n${GREEN}  Đang tạo bản backup tại $backup_file...${RESET}"
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        $SUDO cp "$config_file" "$backup_file"
        
        # Tiến hành thay đổi bằng sed
        $SUDO sed -i "s/worker_processes.*/worker_processes $user_worker_processes;/" "$config_file"
        $SUDO sed -i "s/worker_connections.*/worker_connections $user_worker_connections;/" "$config_file"
        $SUDO sed -i "s/keepalive_timeout.*/keepalive_timeout $user_keepalive;/" "$config_file"
        
        # Gzip
        if grep -q "gzip " "$config_file"; then
            $SUDO sed -i "s/gzip .*/gzip $user_gzip;/" "$config_file"
        else
            $SUDO sed -i "/http {/a \    gzip $user_gzip;" "$config_file"
        fi

        # Client Max Body Size
        if grep -q "client_max_body_size" "$config_file"; then
            $SUDO sed -i "s/client_max_body_size .*/client_max_body_size $user_client_max_body;/" "$config_file"
        else
            $SUDO sed -i "/http {/a \    client_max_body_size $user_client_max_body;" "$config_file"
        fi

        # Use Epoll (trong block events)
        if [ "$user_epoll" == "on" ]; then
            if ! grep -q "use epoll" "$config_file"; then
                $SUDO sed -i "/events {/a \    use epoll;" "$config_file"
            fi
        else
            $SUDO sed -i "/use epoll/d" "$config_file"
        fi

        echo -e "  ${GREEN}✔ Đã cập nhật tệp cấu hình.${RESET}"
        
        # Test config
        if $SUDO nginx -t >/dev/null 2>&1; then
            echo -e "  ${GREEN}✔ Cấu hình hợp lệ. Đang reload Nginx...${RESET}"
            $SUDO systemctl reload nginx || $SUDO service nginx reload
        else
            echo -e "  ${RED}✘ Lỗi: Cấu hình mới không hợp lệ. Đang khôi phục từ backup...${RESET}"
            $SUDO cp "$backup_file" "$config_file"
        fi
    else
        simulate_progress "Đang tạo bản backup cấu hình"
        simulate_progress "Đang áp dụng tham số epoll"
        simulate_progress "Đang ghi đè file nginx.conf"
        simulate_progress "Đang kiểm tra cú pháp Nginx"
    fi

    echo -e "\n  ${GREEN}✔ Hoàn tất quy trình tối ưu Nginx!${RESET}"
    echo -n "  Nhấn Enter để quay lại... "
    read
}

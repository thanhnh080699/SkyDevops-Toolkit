#!/bin/bash

# ==============================
# RESPONSIVE UI FRAMEWORK
# ==============================

ESC=$(printf '\033')
RESET="${ESC}[0m"
BOLD="${ESC}[1m"
CYAN="${ESC}[0;36m"
GREEN="${ESC}[0;32m"
YELLOW="${ESC}[1;33m"
RED="${ESC}[0;31m"

MIN_WIDTH=80

# Initialize UI dimensions
ui_init() {
    local term_w=$(tput cols 2>/dev/null)
    [ -z "$term_w" ] && term_w=$MIN_WIDTH
    
    IS_TOO_SMALL=0
    if [ "$term_w" -lt "$MIN_WIDTH" ]; then
        IS_TOO_SMALL=1
        WIDTH=$term_w
        INNER_WIDTH=$(( WIDTH - 2 ))
        return
    fi

    WIDTH=$term_w
    
    INNER_WIDTH=$(( WIDTH - 2 ))
    
    local available=$(( INNER_WIDTH - 8 ))
    COL1_WIDTH=$(( (available * 42) / 100 ))
    COL2_WIDTH=$(( (available * 29) / 100 ))
    COL3_WIDTH=$(( available - COL1_WIDTH - COL2_WIDTH ))

    # Minimums keep installed-version markers readable on 80-column terminals.
    [ "$COL1_WIDTH" -lt 30 ] && COL1_WIDTH=30
    [ "$COL2_WIDTH" -lt 20 ] && COL2_WIDTH=20
    COL3_WIDTH=$(( available - COL1_WIDTH - COL2_WIDTH ))
}

ui_too_small() {
    clear
    local term_w=$(tput cols 2>/dev/null || echo 80)
    echo -e "${RED}${BOLD}"
    echo "  TERMINAL TOO SMALL ($term_w < $MIN_WIDTH)"
    echo "  Please resize your terminal window to at least ${MIN_WIDTH} columns."
    echo -e "${RESET}"
}

strip_ansi() {
    echo -n "$1" | sed "s/${ESC}\[[0-9;]*[mK]//g"
}

truncate_text() {
    local text="$1"
    local max_w="$2"
    local visible=$(strip_ansi "$text")
    if [ ${#visible} -gt $max_w ]; then
        # If string contains ANSI or multi-byte, avoid byte-based truncation
        # which can corrupt the character or sequence. 
        # For our toolkit, we prioritize showing the full status.
        if [[ "$text" == *"$ESC"* || "$text" =~ [^[:ascii:]] ]]; then
            echo -n "$text"
        else
            echo -n "${text:0:$((max_w-3))}..."
        fi
    else
        echo -n "$text"
    fi
}

center_text() {
    local text="$1"
    local visible=$(strip_ansi "$text")
    local len=${#visible}
    local pad=$(( (INNER_WIDTH - len) / 2 ))
    local rpad=$(( INNER_WIDTH - len - pad ))

    [ $pad -lt 0 ] && pad=0
    [ $rpad -lt 0 ] && rpad=0

    printf "%${pad}s" ""
    echo -ne "$text"
    printf "%${rpad}s" ""
}

ui_title() {
    [ "$IS_TOO_SMALL" -eq 1 ] && return
    printf "${CYAN}║${RESET}"
    center_text "$1"
    printf "${CYAN}║${RESET}\n"
}

ui_border_top() {
    [ "$IS_TOO_SMALL" -eq 1 ] && return
    printf "${CYAN}╔"
    printf '═%.0s' $(seq 1 $INNER_WIDTH)
    printf "╗${RESET}\n"
}

ui_border_mid() {
    [ "$IS_TOO_SMALL" -eq 1 ] && return
    printf "${CYAN}╠"
    printf '═%.0s' $(seq 1 $INNER_WIDTH)
    printf "╣${RESET}\n"
}

ui_border_bottom() {
    [ "$IS_TOO_SMALL" -eq 1 ] && return
    printf "${CYAN}╚"
    printf '═%.0s' $(seq 1 $INNER_WIDTH)
    printf "╝${RESET}\n"
}

ui_line() {
    [ "$IS_TOO_SMALL" -eq 1 ] && return
    local text="$1"
    local visible=$(strip_ansi "$text")
    local len=${#visible}
    local pad=$((INNER_WIDTH - len - 2))
    [ $pad -lt 0 ] && pad=0

    echo -ne "${CYAN}║${RESET} "
    echo -ne "$text"
    printf "%${pad}s" ""
    echo -e " ${CYAN}║${RESET}"
}

ui_empty() {
    [ "$IS_TOO_SMALL" -eq 1 ] && return
    echo -ne "${CYAN}║${RESET}"
    printf "%${INNER_WIDTH}s" ""
    echo -e "${CYAN}║${RESET}"
}

ui_row_3col() {
    [ "$IS_TOO_SMALL" -eq 1 ] && return
    
    local c1=$(truncate_text "$1" $COL1_WIDTH)
    local c2=$(truncate_text "$2" $COL2_WIDTH)
    local c3=$(truncate_text "$3" $COL3_WIDTH)

    local v1=$(strip_ansi "$c1")
    local v2=$(strip_ansi "$c2")
    local v3=$(strip_ansi "$c3")

    printf "${CYAN}║${RESET} "
    printf "%s" "$c1"; printf "%$((COL1_WIDTH - ${#v1}))s" ""
    printf " ${CYAN}│${RESET} "
    printf "%s" "$c2"; printf "%$((COL2_WIDTH - ${#v2}))s" ""
    printf " ${CYAN}│${RESET} "
    printf "%s" "$c3"; printf "%$((COL3_WIDTH - ${#v3}))s" ""
    printf " ${CYAN}║${RESET}\n"
}

ui_input() {
    echo -ne "\n${BOLD}➜ Nhập lựa chọn:${RESET} "
}

ui_opt_param_description() {
    case "$1" in
        worker_processes) echo "Số process Nginx xử lý request. Thường đặt bằng số vCPU để tận dụng CPU." ;;
        worker_connections) echo "Số kết nối tối đa mỗi worker. Giá trị cao giúp chịu tải đồng thời tốt hơn." ;;
        keepalive_timeout) echo "Thời gian giữ kết nối HTTP. Cao quá giữ tài nguyên lâu, thấp quá tăng handshake." ;;
        gzip) echo "Bật nén nội dung text trước khi gửi client. Giảm bandwidth, dùng thêm một ít CPU." ;;
        client_max_body_size) echo "Giới hạn dung lượng upload/request body. Cần đủ lớn cho ứng dụng upload file." ;;
        "use epoll") echo "Dùng event engine epoll của Linux. Phù hợp server tải cao trên Linux." ;;
        innodb_buffer_pool_size) echo "RAM dành cho cache dữ liệu/index InnoDB. Đây là tham số quan trọng nhất của DB." ;;
        innodb_log_file_size) echo "Kích thước redo log cũ. Lớn hơn giúp ghi tốt hơn nhưng recovery có thể lâu hơn." ;;
        innodb_redo_log_capacity) echo "Dung lượng redo log trên MySQL mới. Lớn hơn hỗ trợ workload ghi nhiều ổn định hơn." ;;
        innodb_log_buffer_size) echo "Bộ đệm redo log trong RAM. Hữu ích khi transaction ghi lớn hoặc nhiều." ;;
        innodb_flush_log_at_trx_commit) echo "Mức ghi log xuống disk khi commit. 1 an toàn nhất, 2 cân bằng hiệu năng." ;;
        innodb_buffer_pool_instances) echo "Chia buffer pool thành nhiều vùng để giảm tranh chấp lock trên server RAM lớn." ;;
        innodb_flush_method) echo "Cách InnoDB ghi dữ liệu xuống disk. O_DIRECT thường giảm double caching với Linux." ;;
        innodb_io_capacity) echo "Mức IOPS nền InnoDB giả định. SSD nên cao hơn HDD để flush/merge kịp tải." ;;
        innodb_io_capacity_max) echo "Mức IOPS tối đa khi InnoDB cần đẩy mạnh flush dữ liệu." ;;
        innodb_read_io_threads) echo "Số thread đọc I/O của InnoDB. Tăng vừa phải theo vCPU và loại disk." ;;
        innodb_write_io_threads) echo "Số thread ghi I/O của InnoDB. Hữu ích với workload ghi nhiều." ;;
        max_connections) echo "Số kết nối DB đồng thời tối đa. Cao quá có thể gây hết RAM." ;;
        tmp_table_size) echo "Dung lượng tối đa cho bảng tạm trong RAM trước khi đẩy xuống disk." ;;
        max_heap_table_size) echo "Giới hạn bảng MEMORY. Nên đồng bộ với tmp_table_size." ;;
        thread_cache_size) echo "Cache thread kết nối DB để giảm chi phí tạo thread mới." ;;
        key_buffer_size) echo "Bộ đệm MyISAM index. Giữ thấp nếu ứng dụng chủ yếu dùng InnoDB." ;;
        table_open_cache) echo "Số table handle được cache. Tăng giúp giảm chi phí mở bảng lặp lại." ;;
        table_definition_cache) echo "Cache metadata định nghĩa bảng. Hữu ích khi có nhiều database/table." ;;
        open_files_limit) echo "Giới hạn file descriptor cho DB process. Cần đủ lớn với nhiều table/kết nối." ;;
        query_cache_type) echo "Bật/tắt query cache MariaDB. Thường tắt để tránh tranh chấp trên workload ghi." ;;
        query_cache_size) echo "Dung lượng query cache. MySQL 8 không còn hỗ trợ nên sẽ bỏ qua khi cần." ;;
        wait_timeout) echo "Thời gian giữ kết nối idle thường. Giảm giúp dọn kết nối treo nhanh hơn." ;;
        interactive_timeout) echo "Thời gian giữ kết nối idle kiểu interactive. Thường đặt gần wait_timeout." ;;
        connect_timeout) echo "Thời gian chờ hoàn tất kết nối DB. Quá cao làm giữ tài nguyên lâu khi lỗi mạng." ;;
        slow_query_log) echo "Bật log truy vấn chậm để hỗ trợ điều tra hiệu năng." ;;
        long_query_time) echo "Ngưỡng thời gian để ghi slow query. Thấp hơn ghi nhiều log hơn." ;;
        log_slow_verbosity) echo "Mức chi tiết slow log của MariaDB, giúp thấy thêm query plan." ;;
        log_queries_not_using_indexes) echo "Ghi log query không dùng index. Hữu ích khi debug, có thể nhiều log trên production." ;;
        pm) echo "Chế độ quản lý PHP-FPM process. dynamic cân bằng giữa hiệu năng và RAM." ;;
        pm.max_children) echo "Số PHP worker tối đa. Đây là giới hạn tải chính, cần tính theo RAM." ;;
        pm.start_servers) echo "Số worker khởi tạo sẵn khi PHP-FPM start." ;;
        pm.min_spare_servers) echo "Số worker idle tối thiểu để nhận request nhanh." ;;
        pm.max_spare_servers) echo "Số worker idle tối đa trước khi PHP-FPM thu hồi bớt." ;;
        pm.max_requests) echo "Số request mỗi worker xử lý trước khi tái tạo, giúp giảm rò rỉ RAM." ;;
        memory_limit) echo "RAM tối đa cho mỗi PHP request. Cao quá dễ làm hết RAM khi nhiều request." ;;
        upload_max_filesize) echo "Dung lượng file upload tối đa PHP cho phép." ;;
        post_max_size) echo "Dung lượng POST body tối đa. Nên không nhỏ hơn upload_max_filesize." ;;
        opcache.memory_consumption) echo "RAM dành cho OPcache lưu bytecode PHP, giúp giảm thời gian parse code." ;;
        opcache.max_accelerated_files) echo "Số file PHP OPcache có thể cache. Cần đủ lớn cho CMS/framework nhiều file." ;;
        opcache.validate_timestamps) echo "Kiểm tra thay đổi file PHP. 1 tiện khi deploy thường xuyên, 0 nhanh hơn cho production." ;;
        *) echo "Tham số tối ưu hiệu năng. Hãy giữ gợi ý nếu bạn chưa có yêu cầu riêng." ;;
    esac
}

ui_opt_param_prompt() {
    local idx="$1"
    local key="$2"
    local current="$3"
    local suggested="$4"

    echo
    echo -e "${CYAN}┌─ ${BOLD}${idx}. ${key}${RESET}"
    echo -e "${CYAN}│${RESET} $(ui_opt_param_description "$key")"
    echo -e "${CYAN}│${RESET} Hiện tại: ${YELLOW}${current}${RESET} | Gợi ý: ${GREEN}${suggested}${RESET}"
    echo -ne "${CYAN}└─${RESET} ${BOLD}Nhập giá trị mới (Enter dùng gợi ý):${RESET} "
}

get_status() {
    local app=$1
    if command -v "$app" >/dev/null 2>&1; then
        local ver=""
        case $app in
            nginx) ver=$(nginx -v 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+') ;;
            php) ver=$(php -v 2>&1 | head -n 1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+') ;;
            node) ver=$(node -v 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+') ;;
            npm) ver=$(npm -v 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+') ;;
            pm2) ver=$(pm2 -v 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+') ;;
            yarn) ver=$(yarn -v 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+') ;;
            pnpm) ver=$(pnpm -v 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+') ;;
            docker) ver=$(docker -v | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1) ;;
            mariadb) ver=$(mariadb -V 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+') ;;
            mysql) ver=$(mysql -V 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+') ;;
            apache2) 
                if command -v apache2 >/dev/null 2>&1; then
                    ver=$(apache2 -v 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+') 
                elif command -v httpd >/dev/null 2>&1; then
                    ver=$(httpd -v 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
                fi
                ;;
        esac
        [ -n "$ver" ] && echo -e "${GREEN}✔ v$ver${RESET}" || echo -e "${GREEN}✔${RESET}"
    else
        echo " "
    fi
}

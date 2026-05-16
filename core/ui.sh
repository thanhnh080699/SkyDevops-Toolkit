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
BLUE="${ESC}[0;34m"

MIN_WIDTH=80
SKYDEVOPS_LANG="${SKYDEVOPS_LANG:-vi}"

i18n_set_language() {
    case "$1" in
        en|EN|english|English) SKYDEVOPS_LANG="en" ;;
        *) SKYDEVOPS_LANG="vi" ;;
    esac
    export SKYDEVOPS_LANG
}

i18n_prompt_language() {
    local choice
    while true; do
        clear
        echo -e "${CYAN}${BOLD}SkyDevOps Toolkit${RESET}"
        echo
        echo "1. English"
        echo "2. Tiếng Việt"
        echo
        echo -ne "${BOLD}Select language / Chọn ngôn ngữ [1-2]: ${RESET}"
        read -r choice
        case "$choice" in
            1|en|EN) i18n_set_language en; return ;;
            2|vi|VI|"") i18n_set_language vi; return ;;
            *) echo -e "${RED}Invalid choice / Lựa chọn không hợp lệ.${RESET}"; sleep 1 ;;
        esac
    done
}

tr_ui() {
    local text="$*"
    [ "$SKYDEVOPS_LANG" != "en" ] && { printf "%s" "$text"; return; }

    text="${text//Giới thiệu:/Introduction:}"
    text="${text//Công cụ cài đặt & quản trị/Installation and administration toolkit}"
    text="${text//Hệ quản trị DevOps & SysAdmin chuyên nghiệp/Professional DevOps and SysAdmin management}"
    text="${text//CÀI ĐẶT/INSTALL}"
    text="${text//TỐI ƯU/OPTIMIZE}"
    text="${text//KIỂM TRA/CHECK}"
    text="${text//XÁC NHẬN/CONFIRM}"
    text="${text//THAY ĐỔI/CHANGES}"
    text="${text//HÓA/}"
    text="${text//CẤU HÌNH/CONFIGURATION}"
    text="${text//TÀI NGUYÊN/RESOURCES}"
    text="${text//Ổ ĐĨA/DISK}"
    text="${text//BẢO MẬT/SECURITY}"
    text="${text//CẬP NHẬT/UPDATES}"
    text="${text//TỔNG QUAN HỆ THỐNG/SYSTEM OVERVIEW}"
    text="${text//SERVICES QUAN TRỌNG/IMPORTANT SERVICES}"
    text="${text//Tối ưu/Optimize}"
    text="${text//Tổng quan/System overview}"
    text="${text//Thoát/Exit}"
    text="${text//Quay lại menu chính/Back to main menu}"
    text="${text//Quay lại/Back}"
    text="${text//Lựa chọn không hợp lệ/Invalid choice}"
    text="${text//Sai lựa chọn/Invalid choice}"
    text="${text//Nhập lựa chọn/Enter choice}"
    text="${text//Nhập giá trị mới (Enter dùng gợi ý)/Enter new value (Enter uses suggestion)}"
    text="${text//Xác nhận cài đặt/Confirm installation}"
    text="${text//Xác nhận/Confirm}"
    text="${text//Tổng quan thông tin/Information summary}"
    text="${text//Thông tin hệ thống/System information}"
    text="${text//Hệ điều hành/Operating system}"
    text="${text//Phiên bản/Version}"
    text="${text//Ứng dụng/Application}"
    text="${text//Hành động/Action}"
    text="${text//Trạng thái/Status}"
    text="${text//Đã cài đặt/Installed}"
    text="${text//Chưa cài đặt/Not installed}"
    text="${text//Đang dùng/In use}"
    text="${text//Cài đặt mới (Chưa cài đặt)/Fresh install (not installed)}"
    text="${text//Cài đặt mới/Fresh install}"
    text="${text//Cài thêm bản/Install additional version}"
    text="${text//Cập nhật lên bản mới nhất/Update to latest version}"
    text="${text//Gỡ bản cũ/Remove old version}"
    text="${text//Đang chạy/Running}"
    text="${text//Hiện tại/Current}"
    text="${text//Mới/New}"
    text="${text//Gợi ý/Suggested}"
    text="${text//Tham số/Parameter}"
    text="${text//Bạn có muốn tiếp tục chạy tiến trình cài đặt?/Do you want to continue the installation process?}"
    text="${text//Đã hủy thao tác cài đặt./Installation canceled.}"
    text="${text//Đã hủy thao tác./Action canceled.}"
    text="${text//Nhấn Enter để quay lại/Press Enter to go back}"
    text="${text//Bấm phím bất kỳ để quay lại menu chính/Press any key to return to the main menu}"
    text="${text//Hoàn tất/Done}"
    text="${text//Đang tải/Loading}"
    text="${text//Đang cấu hình/Configuring}"
    text="${text//Đang tải xuống/Downloading}"
    text="${text//Đang thiết lập/Setting up}"
    text="${text//Đang gỡ bỏ/Removing}"
    text="${text//Đang tạo bản backup/Creating backup}"
    text="${text//Đang áp dụng/Applying}"
    text="${text//Đang kiểm tra/Checking}"
    text="${text//Không thể/Unable to}"
    text="${text//lấy thông tin/get information}"
    text="${text//Lỗi/Error}"
    text="${text//Cấu hình/Configuration}"
    text="${text//ĐỀ XUẤT/RECOMMENDED}"
    text="${text//CÓ THỂ CHỈNH SỬA/EDITABLE}"
    text="${text//Hệ thống phát hiện/System detected}"
    text="${text//Nhấn Enter để dùng giá trị gợi ý hoặc nhập giá trị khác./Press Enter to use the suggested value, or type another value.}"
    text="${text//Vui lòng kiểm tra và thay đổi các thông số bên dưới:/Review and adjust the parameters below:}"
    text="${text//Tiến hành áp dụng và restart/Apply and restart}"
    text="${text//Tiến hành áp dụng và reload/Apply and reload}"
    text="${text//Tiến hành áp dụng?/Apply changes?}"
    text="${text//Lưu ý/Note}"
    text="${text//Khuyên dùng/Recommended}"
    text="${text//Mới nhất/Latest}"
    text="${text//Bản mới nhất/Latest version}"
    text="${text//Bản ổn định phổ biến/Popular stable version}"
    text="${text//Bản LTS mới nhất/Latest LTS version}"
    text="${text//Các phiên bản khác/Other versions}"
    text="${text//Lựa chọn phiên bản/Select version}"
    text="${text//Select version PHP để cài đặt/Select PHP version to install}"
    text="${text//Select version hệ thống/Select system version}"
    text="${text//để cài đặt/to install}"
    text="${text//Tự động kéo từ/Auto-fetched from}"
    text="${text//hệ thống/system}"
    text="${text//New nhất/Latest}"
    text="${text//Công cụ quản lý & Package Manager/Management tools and package managers}"
    text="${text//Các ứng dụng phổ biến/Popular utilities}"
    text="${text//Cài đặt nền tảng/Platform installation}"
    text="${text//Quản lý cài đặt & Cập nhật/Install and update management}"
    text="${text//Port đang listen/Listening ports}"
    text="${text//Trạng thái service/Service status}"
    text="${text//Service đang failed/Failed services}"
    text="${text//Không tìm thấy/Not found}"
    text="${text//chưa cài đặt/not installed}"
    text="${text//Không phát hiện/No}"
    text="${text//OS chưa hỗ trợ kiểm tra update tự động./This OS is not supported for automatic update checks.}"

    printf "%s" "$text"
}

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
    echo "  $(tr_ui "TERMINAL TOO SMALL") ($term_w < $MIN_WIDTH)"
    echo "  $(tr_ui "Please resize your terminal window to at least ${MIN_WIDTH} columns.")"
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
    local text
    text=$(tr_ui "$1")
    printf "${CYAN}║${RESET}"
    center_text "$text"
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
    local text
    text=$(tr_ui "$1")
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
    
    local t1 t2 t3
    t1=$(tr_ui "$1")
    t2=$(tr_ui "$2")
    t3=$(tr_ui "$3")
    local c1=$(truncate_text "$t1" $COL1_WIDTH)
    local c2=$(truncate_text "$t2" $COL2_WIDTH)
    local c3=$(truncate_text "$t3" $COL3_WIDTH)

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
    echo -ne "\n${BOLD}➜ $(tr_ui "Nhập lựa chọn"):${RESET} "
}

ui_opt_param_description() {
    if [ "$SKYDEVOPS_LANG" = "en" ]; then
        case "$1" in
            worker_processes) echo "Number of Nginx worker processes. Usually set to the vCPU count." ;;
            worker_connections) echo "Maximum connections per worker. Higher values help with concurrent load." ;;
            keepalive_timeout) echo "How long HTTP connections stay open. Too high keeps resources busy; too low adds handshakes." ;;
            gzip) echo "Compress text responses before sending them. Saves bandwidth with a small CPU cost." ;;
            client_max_body_size) echo "Maximum upload/request body size. Set high enough for file uploads." ;;
            "use epoll") echo "Use Linux epoll event engine. Suitable for high-load Linux servers." ;;
            innodb_buffer_pool_size) echo "RAM used to cache InnoDB data and indexes. This is the most important DB parameter." ;;
            innodb_log_file_size) echo "Legacy redo log size. Larger logs improve writes but may increase recovery time." ;;
            innodb_redo_log_capacity) echo "Redo log capacity for newer MySQL versions. Helps write-heavy workloads stay stable." ;;
            innodb_log_buffer_size) echo "Redo log buffer in RAM. Useful for large or frequent write transactions." ;;
            innodb_flush_log_at_trx_commit) echo "How commit logs are flushed to disk. 1 is safest; 2 balances performance." ;;
            innodb_buffer_pool_instances) echo "Splits the buffer pool to reduce lock contention on larger servers." ;;
            innodb_flush_method) echo "How InnoDB writes data to disk. O_DIRECT often reduces double caching on Linux." ;;
            innodb_io_capacity) echo "Expected background IOPS for InnoDB. SSD values should be higher than HDD." ;;
            innodb_io_capacity_max) echo "Maximum IOPS InnoDB can use during burst flushing." ;;
            innodb_read_io_threads) echo "InnoDB read I/O thread count. Increase moderately by vCPU and disk type." ;;
            innodb_write_io_threads) echo "InnoDB write I/O thread count. Useful for write-heavy workloads." ;;
            max_connections) echo "Maximum concurrent DB connections. Too high can exhaust RAM." ;;
            tmp_table_size) echo "Maximum in-memory temporary table size before spilling to disk." ;;
            max_heap_table_size) echo "MEMORY table limit. Keep it aligned with tmp_table_size." ;;
            thread_cache_size) echo "Caches DB connection threads to reduce thread creation cost." ;;
            key_buffer_size) echo "MyISAM index buffer. Keep low when the application mainly uses InnoDB." ;;
            table_open_cache) echo "Number of table handles to cache. Reduces repeated table open cost." ;;
            table_definition_cache) echo "Caches table metadata. Useful with many databases or tables." ;;
            open_files_limit) echo "File descriptor limit for the DB process. Needs to cover tables and connections." ;;
            query_cache_type) echo "Enables or disables MariaDB query cache. Usually off to avoid contention." ;;
            query_cache_size) echo "Query cache size. MySQL 8 no longer supports it, so it is skipped when needed." ;;
            wait_timeout) echo "Idle timeout for normal connections. Lower values clear stale connections faster." ;;
            interactive_timeout) echo "Idle timeout for interactive connections. Usually close to wait_timeout." ;;
            connect_timeout) echo "Timeout for completing DB connections. Too high holds resources during network issues." ;;
            slow_query_log) echo "Enables slow query logging for performance investigation." ;;
            long_query_time) echo "Slow query threshold. Lower values produce more log entries." ;;
            log_slow_verbosity) echo "MariaDB slow log detail level, useful for query plans." ;;
            log_queries_not_using_indexes) echo "Logs queries without indexes. Useful for debugging, but can be noisy in production." ;;
            pm) echo "PHP-FPM process manager mode. dynamic balances performance and RAM." ;;
            pm.max_children) echo "Maximum PHP worker count. This is the main load limit and should be sized by RAM." ;;
            pm.start_servers) echo "Number of PHP workers started when PHP-FPM starts." ;;
            pm.min_spare_servers) echo "Minimum idle workers kept ready for requests." ;;
            pm.max_spare_servers) echo "Maximum idle workers before PHP-FPM trims them." ;;
            pm.max_requests) echo "Requests handled by each worker before recycling, helping reduce memory leaks." ;;
            memory_limit) echo "Maximum RAM for each PHP request. Too high can exhaust memory under concurrency." ;;
            upload_max_filesize) echo "Maximum PHP file upload size." ;;
            post_max_size) echo "Maximum POST body size. Should not be lower than upload_max_filesize." ;;
            opcache.memory_consumption) echo "RAM used by OPcache to store PHP bytecode and reduce parse time." ;;
            opcache.max_accelerated_files) echo "Number of PHP files OPcache can cache. Needs to fit CMS/framework file counts." ;;
            opcache.validate_timestamps) echo "Checks PHP file changes. 1 helps frequent deploys; 0 is faster for production." ;;
            *) echo "Performance tuning parameter. Keep the suggestion if you do not have a specific requirement." ;;
        esac
        return
    fi

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
    echo -e "${CYAN}│${RESET} $(tr_ui "Hiện tại"): ${YELLOW}${current}${RESET} | $(tr_ui "Gợi ý"): ${GREEN}${suggested}${RESET}"
    echo -ne "${CYAN}└─${RESET} ${BOLD}$(tr_ui "Nhập giá trị mới (Enter dùng gợi ý)"):${RESET} "
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

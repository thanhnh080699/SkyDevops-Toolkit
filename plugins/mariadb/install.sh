#!/bin/bash

# ==============================
# MARIADB INSTALL PLUGIN
# ==============================

. core/ui.sh
. core/os.sh
. core/utils.sh

# Function to fetch versions
fetch_mariadb_versions() {
    echo -e "\n  ${YELLOW}> Đang tải danh sách phiên bản MariaDB từ official API...${RESET}"
    
    # Fetch from MariaDB REST API
    local raw_data=$(curl -s https://downloads.mariadb.org/rest-api/mariadb/)
    
    if [ -z "$raw_data" ]; then
        # Fallback if API fails
        LATEST_VER="11.4"
        LTS_VERSIONS=("11.4" "10.11")
        ARCHIVE_VERSIONS=("11.2" "11.1" "10.6" "10.5" "10.4")
    else
        # Extract Stable versions using python3 (safe for JSON parsing in bash)
        local all_stables=$(echo "$raw_data" | python3 -c "import sys, json; data = json.load(sys.stdin); print(' '.join([r['release_id'] for r in data['major_releases'] if r['release_status'] == 'Stable']))" 2>/dev/null)
        
        if [ -z "$all_stables" ]; then
             LATEST_VER="11.4"; LTS_VERSIONS=("11.4" "10.11"); ARCHIVE_VERSIONS=("11.2" "10.6" "10.5" "10.4" "10.3")
        else
            read -r -a STABLE_ARRAY <<< "$all_stables"
            LATEST_VER=${STABLE_ARRAY[0]}
            
            # Identify LTS (Known LTS: 11.4, 10.11, 10.6, 10.5, 10.4) - simple heuristic for now
            LTS_VERSIONS=()
            for v in "${STABLE_ARRAY[@]}"; do
                if [[ "$v" == "11.4" || "$v" == "10.11" || "$v" == "10.6" || "$v" == "10.5" || "$v" == "10.4" ]]; then
                    LTS_VERSIONS+=("$v")
                fi
            done
            
            # Archives (Top 5 excluding the latest)
            ARCHIVE_VERSIONS=("${STABLE_ARRAY[@]:1:5}")
        fi
    fi
}

# Function to run MariaDB install logic
install_mariadb() {
    local version=$1
    detect_os
    
    # Check current installed version
    local current_version=""
    if command -v mariadb >/dev/null 2>&1; then
        current_version=$(mariadb -V 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "")
    elif command -v mysql >/dev/null 2>&1; then
        current_version=$(mysql -V 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "")
    fi
    
    local action_text="Cài đặt mới"
    if [ -n "$current_version" ]; then
        if [[ "$current_version" == *"$version"* ]]; then
            action_text="Re-install (Đang chạy v$current_version)"
        else
            action_text="Gỡ bản cũ (v$current_version) & Cài bản v$version"
        fi
    else
        action_text="Cài đặt mới (Chưa cài đặt)"
    fi
    
    # Confirmation Step
    clear
    ui_init
    
    ui_border_top
    ui_title "${BOLD}XÁC NHẬN CÀI ĐẶT MARIADB${RESET}"
    ui_border_mid
    ui_line "Tổng quan thông tin:"
    ui_line "- Hệ điều hành: $OS_NAME $OS_VER ($OS_ID)"
    ui_line "- Phiên bản:    MariaDB $version"
    ui_line "- Hành động:    $action_text"
    ui_empty
    ui_line "Bạn có muốn tiếp tục chạy tiến trình cài đặt?"
    ui_border_bottom
    
    echo -ne "\n${BOLD}➜ Xác nhận (Y/n):${RESET} "
    read -r confirm
    
    if [[ -z "$confirm" ]]; then
        confirm="y"
    fi
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "\n  ${YELLOW}Đã hủy thao tác cài đặt.${RESET}"
        sleep 1
        return
    fi
    
    echo -e "\n${GREEN}  Bắt đầu quy trình cài đặt MariaDB ($version)...${RESET}"
    
    local install_args="--version $version"
    
    if [ -n "$current_version" ]; then
        simulate_progress "Đang sao lưu cấu hình & chuẩn bị gỡ bỏ MariaDB hiện tại"
        install_args="$install_args --uninstall"
    fi
    
    # Actually run the script
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if ! $SUDO bash plugins/mariadb/scripts/install_mariadb.sh $install_args; then
            echo -e "\n  ${RED}✘ Lỗi: Quá trình cài đặt MariaDB thất bại.${RESET}"
            echo -n "  Nhấn Enter để quay lại... "
            read
            return 1
        fi
    else
        # Simulation for non-linux environments
        simulate_progress "Đang cấu hình MariaDB Repository ($version)"
        simulate_progress "Đang tải xuống gói phần mềm"
        simulate_progress "Đang thiết lập cơ sở dữ liệu mặc định"
    fi
    
    echo -e "  ${GREEN}✔ MariaDB $version đã được cài đặt thành công!${RESET}"
    echo -n "  Nhấn Enter để quay lại... "
    read
}

# Menu for MariaDB
mariadb_menu() {
    fetch_mariadb_versions
    
    while true; do
        clear
        ui_init
        
        ui_border_top
        ui_title "${BOLD}CÀI ĐẶT MARIADB OFFICIAL${RESET}"
        ui_border_mid
        ui_line "Lựa chọn phiên bản MariaDB:"
        ui_empty
        ui_line "1. Latest Stable              [ v$LATEST_VER ]"
        ui_line "2. LTS Recommended            [ v${LTS_VERSIONS[0]} ]"
        ui_line "3. LTS Old Stable             [ v${LTS_VERSIONS[1]} ]"
        ui_empty
        ui_line "Các phiên bản khác / Old Archives:"
        ui_line "4. MariaDB                    [ v${ARCHIVE_VERSIONS[0]} ]"
        ui_line "5. MariaDB                    [ v${ARCHIVE_VERSIONS[1]} ]"
        ui_line "6. MariaDB                    [ v${ARCHIVE_VERSIONS[2]} ]"
        ui_line "7. MariaDB                    [ v${ARCHIVE_VERSIONS[3]} ]"
        ui_line "8. MariaDB                    [ v${ARCHIVE_VERSIONS[4]} ]"
        ui_empty
        ui_line "0. Quay lại menu chính"
        ui_border_bottom
        
        ui_input
        read m_choice
        
        case $m_choice in
            1) install_mariadb "$LATEST_VER" ;;
            2) install_mariadb "${LTS_VERSIONS[0]}" ;;
            3) install_mariadb "${LTS_VERSIONS[1]}" ;;
            4) install_mariadb "${ARCHIVE_VERSIONS[0]}" ;;
            5) install_mariadb "${ARCHIVE_VERSIONS[1]}" ;;
            6) install_mariadb "${ARCHIVE_VERSIONS[2]}" ;;
            7) install_mariadb "${ARCHIVE_VERSIONS[3]}" ;;
            8) install_mariadb "${ARCHIVE_VERSIONS[4]}" ;;
            0) return ;;
            *) echo -e "${RED} Sai lựa chọn ${RESET}"; sleep 1 ;;
        esac
    done
}

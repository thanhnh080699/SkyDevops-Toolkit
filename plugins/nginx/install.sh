#!/bin/bash

# ==============================
# NGINX INSTALL PLUGIN
# ==============================

. core/ui.sh
. core/os.sh
. core/utils.sh

# Function to fetch versions
fetch_nginx_versions() {
    echo -e "\n  ${YELLOW}> Đang tải danh sách phiên bản Nginx mới nhất...${RESET}"
    
    # Get versions and filter unique ones up to 7, ignoring potential timeouts silently
    local raw_versions=$(curl -s https://nginx.org/en/download.html | grep -oE 'nginx-[0-9]+\.[0-9]+\.[0-9]+' | sed 's/nginx-//' | sort -rV | awk '!seen[$0]++' | head -n 7)
    
    if [ -z "$raw_versions" ]; then
        # Fallback versions if offline (Latest stable and mainline as of March 2026)
        raw_versions="1.29.7 1.28.3 1.26.3 1.25.4 1.24.0 1.22.1 1.20.2"
    fi

    # Read the text into variables
    local c=0
    OTHER_VERSIONS=()
    for v in $raw_versions; do
        if [ $c -eq 0 ]; then
            MAINLINE_VER=$v
        elif [ $c -eq 1 ]; then
            STABLE_VER=$v
        else
            OTHER_VERSIONS+=("$v")
        fi
        c=$((c + 1))
    done
}

# Function to run Nginx install logic
install_nginx() {
    local version=$1
    local v_name=$2
    detect_os
    
    # Check current installed version
    local current_version=""
    if command -v nginx >/dev/null 2>&1; then
        current_version=$(nginx -v 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "")
    fi
    
    local action_text="Cài đặt mới"
    if [ -n "$current_version" ]; then
        if [ "$current_version" == "$version" ]; then
            action_text="Re-install (Đang chạy v$current_version)"
        else
            action_text="Gỡ bản cũ (v$current_version) & Cài bản v$version"
        fi
    else
        action_text="Cài đặt mới (Chưa cài đặt)"
    fi
    
    # Confirmation Step
    clear
    ui_init  # re-init UI dynamically in case terminal was resized
    
    ui_border_top
    ui_title "${BOLD}XÁC NHẬN CÀI ĐẶT NGINX${RESET}"
    ui_border_mid
    ui_line "Tổng quan thông tin:"
    ui_line "- Hệ điều hành: $OS_NAME $OS_VER ($OS_ID)"
    ui_line "- Phiên bản:    Nginx $version ($v_name)"
    ui_line "- Hành động:    $action_text"
    ui_empty
    ui_line "Bạn có muốn tiếp tục chạy tiến trình cài đặt?"
    ui_border_bottom
    
    echo -ne "\n${BOLD}➜ $(tr_ui "Xác nhận") (Y/n):${RESET} "
    read -r confirm
    
    # Default to 'y' if user just presses Enter
    if [[ -z "$confirm" ]]; then
        confirm="y"
    fi
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "\n  ${YELLOW}$(tr_ui "Đã hủy thao tác cài đặt.")${RESET}"
        sleep 1
        return
    fi
    
    echo -e "\n${GREEN}  Bắt đầu quy trình cài đặt Nginx ($version)...${RESET}"
    
    local install_args="--version $version"
    
    if [ -n "$current_version" ] && [ "$current_version" != "$version" ]; then
        simulate_progress "Đang gỡ bỏ phiên bản Nginx v$current_version hiện tại"
        install_args="$install_args --uninstall"
    fi
    
    # Actually run the script
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if ! $SUDO bash plugins/nginx/scripts/install_nginx.sh $install_args; then
            echo -e "\n  ${RED}✘ Lỗi: Quá trình cài đặt Nginx thất bại.${RESET}"
            echo -n "  $(tr_ui "Nhấn Enter để quay lại")... "
            read
            return 1
        fi
    else
        # Simulation for non-linux environments (like Mac dev)
        simulate_progress "Đang cấu hình Repository ($OS_ID)"
        simulate_progress "Đang tải xuống gói cài đặt"
        simulate_progress "Đang thiết lập Systemd Service"
    fi
    
    echo -e "  ${GREEN}✔ Nginx $version đã được khởi tạo & cài đặt thành công!${RESET}"
    echo -n "  $(tr_ui "Nhấn Enter để quay lại")... "
    read
}

# Nested Menu for Nginx
nginx_menu() {
    fetch_nginx_versions
    
    while true; do
        clear
        ui_init # Responsive layout
        
        ui_border_top
        ui_title "${BOLD}CÀI ĐẶT NGINX OFFICIAL${RESET}"
        ui_border_mid
        ui_line "Lựa chọn phiên bản hệ thống (Tự động kéo từ nginx.org):"
        ui_empty
        ui_line "1. Stable (Khuyên dùng)       [ v$STABLE_VER ]"
        ui_line "2. Mainline (Bản mới nhất)    [ v$MAINLINE_VER ]"
        ui_empty
        ui_line "Các phiên bản khác / Old Archives:"
        ui_line "3. Nginx                      [ v${OTHER_VERSIONS[0]} ]"
        ui_line "4. Nginx                      [ v${OTHER_VERSIONS[1]} ]"
        ui_line "5. Nginx                      [ v${OTHER_VERSIONS[2]} ]"
        ui_line "6. Nginx                      [ v${OTHER_VERSIONS[3]} ]"
        ui_line "7. Nginx                      [ v${OTHER_VERSIONS[4]} ]"
        ui_empty
        ui_line "0. Quay lại menu chính"
        ui_border_bottom
        
        ui_input
        read n_choice
        
        case $n_choice in
            1) install_nginx "$STABLE_VER" "Stable" ;;
            2) install_nginx "$MAINLINE_VER" "Mainline" ;;
            3) install_nginx "${OTHER_VERSIONS[0]}" "Archive" ;;
            4) install_nginx "${OTHER_VERSIONS[1]}" "Archive" ;;
            5) install_nginx "${OTHER_VERSIONS[2]}" "Archive" ;;
            6) install_nginx "${OTHER_VERSIONS[3]}" "Archive" ;;
            7) install_nginx "${OTHER_VERSIONS[4]}" "Archive" ;;
            0) return ;;
            *) echo -e "${RED} $(tr_ui "Sai lựa chọn") ${RESET}"; sleep 1 ;;
        esac
    done
}

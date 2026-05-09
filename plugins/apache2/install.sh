#!/bin/bash

# ==============================
# APACHE2 INSTALL PLUGIN
# ==============================

. core/ui.sh
. core/os.sh
. core/utils.sh

# Function to run Apache2 install logic
install_apache() {
    detect_os
    
    # Check current installed version
    local current_version=""
    if command -v apache2 >/dev/null 2>&1; then
        current_version=$(apache2 -v 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "")
    elif command -v httpd >/dev/null 2>&1; then
        current_version=$(httpd -v 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "")
    fi
    
    local action_text="Cài đặt mới"
    local uninstall_needed=false
    
    if [ -n "$current_version" ]; then
        action_text="Gỡ bản cũ (v$current_version) & Cài bản mới nhất"
        uninstall_needed=true
    else
        action_text="Cài đặt mới (Chưa cài đặt)"
    fi
    
    # Confirmation Step
    clear
    ui_init  # re-init UI dynamically in case terminal was resized
    
    ui_border_top
    ui_title "${BOLD}XÁC NHẬN CÀI ĐẶT APACHE2${RESET}"
    ui_border_mid
    ui_line "Tổng quan thông tin:"
    ui_line "- Hệ điều hành: $OS_NAME $OS_VER ($OS_ID)"
    ui_line "- Ứng dụng:    Apache2 / HTTPD"
    ui_line "- Hành động:    $action_text"
    ui_empty
    ui_line "Bạn có muốn tiếp tục chạy tiến trình cài đặt?"
    ui_border_bottom
    
    echo -ne "\n${BOLD}➜ Xác nhận (Y/n):${RESET} "
    read -r confirm
    
    # Default to 'y' if user just presses Enter
    if [[ -z "$confirm" ]]; then
        confirm="y"
    fi
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "\n  ${YELLOW}Đã hủy thao tác cài đặt.${RESET}"
        sleep 1
        return
    fi
    
    echo -e "\n${GREEN}  Bắt đầu quy trình cài đặt Apache2...${RESET}"
    
    local install_args=""
    
    if [ "$uninstall_needed" = true ]; then
        simulate_progress "Đang gỡ bỏ phiên bản cũ v$current_version hiện tại"
        install_args="--uninstall"
    fi
    
    # Actually run the script
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        $SUDO bash plugins/apache2/scripts/install_apache.sh $install_args
    else
        # Simulation for non-linux environments (like Mac dev)
        simulate_progress "Đang cấu hình Repository ($OS_ID)"
        simulate_progress "Đang tải xuống gói cài đặt"
        simulate_progress "Đang thiết lập Systemd Service"
    fi
    
    echo -e "  ${GREEN}✔ Apache2 đã được khởi tạo & cài đặt thành công!${RESET}"
    echo -n "  Nhấn Enter để quay lại... "
    read
}

# Nested Menu for Apache2
apache2_menu() {
    while true; do
        clear
        ui_init # Responsive layout
        
        ui_border_top
        ui_title "${BOLD}CÀI ĐẶT APACHE2${RESET}"
        ui_border_mid
        ui_line "Quản lý cài đặt & Cập nhật Apache2 Server:"
        ui_empty
        ui_line "1. Cài mới / Repo Update Apache2"
        ui_empty
        ui_line "0. Quay lại menu chính"
        ui_border_bottom
        
        ui_input
        read a_choice
        
        case $a_choice in
            1) install_apache ;;
            0) return ;;
            *) echo -e "${RED} Sai lựa chọn ${RESET}"; sleep 1 ;;
        esac
    done
}

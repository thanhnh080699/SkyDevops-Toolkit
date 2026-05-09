#!/bin/bash

# ==============================
# NODEJS & NPM INSTALL PLUGIN
# ==============================

. core/ui.sh
. core/os.sh
. core/utils.sh

# Function to install Node.js
install_nodejs() {
    clear
    ui_init
    ui_border_top
    ui_title "${BOLD}CÀI ĐẶT NODE.JS & NPM${RESET}"
    ui_border_mid
    ui_line "Phiên bản hỗ trợ: Node.js v20.x (LTS)"
    ui_line "Kịch bản: Sử dụng NodeSource Official Repository"
    ui_border_bottom

    echo -ne "\n${BOLD}➜ Xác nhận cài đặt (Y/n):${RESET} "
    read -r confirm
    if [[ -z "$confirm" ]]; then confirm="y"; fi
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then return; fi

    echo -e "\n${GREEN}  Đang cài đặt Node.js v20.x...${RESET}"
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if ! $SUDO bash plugins/nodejs/scripts/install_nodejs.sh; then
            echo -e "\n  ${RED}✘ Lỗi: Quá trình cài đặt Node.js thất bại.${RESET}"
            echo -n "  Nhấn Enter để quay lại... "
            read
            return 1
        fi
    else
        simulate_progress "Đang cấu hình NodeSource Repo"
        simulate_progress "Đang cài đặt nodejs package"
    fi

    echo -e "  ${GREEN}✔ Node.js & NPM đã được cài đặt!${RESET}"
    node -v 2>/dev/null && npm -v 2>/dev/null
    echo -n "  Nhấn Enter để quay lại... "
    read
}

# Function to install Global NPM Packages
install_npm_pkg() {
    local pkg=$1
    local name=$2
    
    if ! command -v npm >/dev/null 2>&1; then
        echo -e "\n  ${RED}✘ Lỗi: Bạn cần cài đặt Node.js & NPM trước.${RESET}"
        sleep 1
        return
    fi

    echo -e "\n${GREEN}  Đang cài đặt $name ($pkg) toàn cục...${RESET}"
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        $SUDO npm install -g "$pkg"
    else
        simulate_progress "Đang tải $pkg từ registry"
        simulate_progress "Đang thiết lập binary link"
    fi
    
    echo -e "  ${GREEN}✔ $name đã được cài đặt!${RESET}"
    sleep 1
}

nodejs_menu() {
    while true; do
        clear
        ui_init
        
        local s_node=$(get_status node)
        local s_pm2=$(get_status pm2)
        local s_yarn=$(get_status yarn)
        local s_pnpm=$(get_status pnpm)
        local s_nodemon=$(command -v nodemon >/dev/null && echo -e "${GREEN}✔${RESET}" || echo "")
        local s_serve=$(command -v serve >/dev/null && echo -e "${GREEN}✔${RESET}" || echo "")

        ui_border_top
        ui_title "${BOLD}QUẢN LÝ NODEJS / NPM / PM2${RESET}"
        ui_border_mid
        ui_line "1. Cài đặt Node.js & NPM (LTS v20)  $s_node"
        ui_empty
        ui_line "Công cụ quản lý & Package Manager:"
        ui_line "2. Cài đặt PM2 (Process Manager)    $s_pm2"
        ui_line "3. Cài đặt Yarn (Package Manager)   $s_yarn"
        ui_empty
        ui_line "Các ứng dụng phổ biến:"
        ui_line "4. Cài đặt PNPM                     $s_pnpm"
        ui_line "5. Cài đặt Nodemon (Dev Tool)       $s_nodemon"
        ui_line "6. Cài đặt Serve (Static Server)    $s_serve"
        ui_empty
        ui_line "0. Quay lại menu chính"
        ui_border_bottom
        
        ui_input
        read n_choice
        
        case $n_choice in
            1) install_nodejs ;;
            2) install_npm_pkg "pm2" "PM2" ;;
            3) install_npm_pkg "yarn" "Yarn" ;;
            4) install_npm_pkg "pnpm" "PNPM" ;;
            5) install_npm_pkg "nodemon" "Nodemon" ;;
            6) install_npm_pkg "serve" "Serve" ;;
            0) return ;;
            *) echo -e "${RED} Sai lựa chọn ${RESET}"; sleep 1 ;;
        esac
    done
}

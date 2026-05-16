#!/bin/bash

# ==============================
# NODEJS & NPM INSTALL PLUGIN (NVM SUPPORT)
# ==============================

. core/ui.sh
. core/os.sh
. core/utils.sh

# Function to load NVM into current session
load_nvm() {
    if [ -d "$HOME/.nvm" ]; then
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    elif [ -d "/root/.nvm" ]; then
        export NVM_DIR="/root/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    fi
}

# Check if NVM is installed
get_nvm_status() {
    load_nvm
    if command -v nvm >/dev/null 2>&1; then
        local v=$(nvm --version)
        echo -e "${GREEN}✔ v$v${RESET}"
    else
        echo ""
    fi
}

# Function to install NVM
install_nvm() {
    clear
    ui_init
    ui_border_top
    ui_title "${BOLD}CÀI ĐẶT NVM (NODE VERSION MANAGER)${RESET}"
    ui_border_mid
    ui_line "NVM cho phép cài đặt và quản lý nhiều phiên bản Node.js"
    ui_line "Kịch bản: Tải và chạy script cài đặt từ GitHub chính thức"
    ui_border_bottom

    echo -ne "\n${BOLD}➜ $(tr_ui "Xác nhận cài đặt") (Y/n):${RESET} "
    read -r confirm
    if [[ -z "$confirm" ]]; then confirm="y"; fi
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then return; fi

    echo -e "\n${GREEN}  Đang cài đặt NVM...${RESET}"
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
        
        # Sourcing for immediate use in current script
        load_nvm
        
        # Add to profile if not exists (usually handled by nvm installer, but we ensure it)
        local profile_file=""
        if [ -f "$HOME/.bashrc" ]; then profile_file="$HOME/.bashrc";
        elif [ -f "$HOME/.bash_profile" ]; then profile_file="$HOME/.bash_profile";
        elif [ -f "$HOME/.zshrc" ]; then profile_file="$HOME/.zshrc"; fi
        
        if [ -n "$profile_file" ] && ! grep -q "NVM_DIR" "$profile_file"; then
            echo -e "\n${YELLOW}  Lưu ý: Bạn có thể cần 'source $profile_file' sau khi thoát toolkit.${RESET}"
        fi
    else
        simulate_progress "Đang tải NVM installer"
        simulate_progress "Đang thiết lập môi trường NVM"
    fi

    echo -e "  ${GREEN}✔ NVM đã được cài đặt!${RESET}"
    echo -n "  $(tr_ui "Nhấn Enter để quay lại")... "
    read
}

# Function to install a specific Node.js version via NVM
install_nodejs_nvm() {
    local version=$1
    load_nvm
    
    if ! command -v nvm >/dev/null 2>&1; then
        echo -e "\n  ${RED}✘ Lỗi: NVM chưa được cài đặt. Vui lòng cài NVM trước.${RESET}"
        sleep 2
        return
    fi

    clear
    ui_init
    ui_border_top
    ui_title "${BOLD}CÀI ĐẶT NODE.JS $version${RESET}"
    ui_border_mid
    ui_line "Hệ thống sẽ sử dụng NVM để cài đặt Node.js $version"
    ui_border_bottom

    echo -ne "\n${BOLD}➜ $(tr_ui "Xác nhận cài đặt") (Y/n):${RESET} "
    read -r confirm
    if [[ -z "$confirm" ]]; then confirm="y"; fi
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then return; fi

    echo -e "\n${GREEN}  Đang cài đặt Node.js $version qua NVM...${RESET}"
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        nvm install "$version"
        nvm use "$version"
        nvm alias default "$version"
    else
        simulate_progress "Đang tải Node.js $version"
        simulate_progress "Đang thiết lập binary link"
    fi

    echo -e "  ${GREEN}✔ Node.js $version đã được cài đặt và đặt làm mặc định!${RESET}"
    node -v 2>/dev/null && npm -v 2>/dev/null
    echo -n "  $(tr_ui "Nhấn Enter để quay lại")... "
    read
}

# Sub-menu for choosing Node.js versions
nodejs_version_menu() {
    load_nvm
    if ! command -v nvm >/dev/null 2>&1; then
        echo -e "\n  ${RED}✘ Lỗi: NVM chưa được cài đặt.${RESET}"
        sleep 2
        return
    fi

    echo -e "\n  ${CYAN}Đang tải danh sách phiên bản từ NVM...${RESET}"
    # Fetch LTS versions, clean up ANSI codes, filter for LTS, get latest 10
    local raw_data=$(nvm list-remote --lts | grep "LTS" | tail -n 10)
    local versions=($(echo "$raw_data" | awk '{print $1}'))
    local aliases=($(echo "$raw_data" | awk -F'[(]' '{print $2}' | awk -F'[)]' '{print $1}'))
    
    if [ ${#versions[@]} -eq 0 ]; then
        echo -e "\n  ${RED}✘ Lỗi: Không thể kết nối với NVM registry.${RESET}"
        sleep 2
        return
    fi

    while true; do
        clear
        ui_init
        
        ui_border_top
        ui_title "${BOLD}CHỌN PHIÊN BẢN NODE.JS (LTS)${RESET}"
        ui_border_mid
        
        local current_node=$(node -v 2>/dev/null || echo "")
        
        for i in "${!versions[@]}"; do
            local v="${versions[$i]}"
            local a="${aliases[$i]}"
            local status=""
            if [[ "$current_node" == "$v"* ]]; then
                status="${GREEN}✔ Đang dùng${RESET}"
            fi
            ui_line "$((i+1)). Node.js $v ($a) $status"
        done
        
        ui_empty
        ui_line "0. Quay lại"
        ui_border_bottom
        
        ui_input
        read v_choice
        
        if [[ "$v_choice" == "0" ]]; then return; fi
        
        if [[ "$v_choice" =~ ^[0-9]+$ ]] && [ "$v_choice" -le "${#versions[@]}" ]; then
            local selected_ver="${versions[$((v_choice-1))]}"
            install_nodejs_nvm "$selected_ver"
        else
            echo -e "${RED} $(tr_ui "Sai lựa chọn") ${RESET}"; sleep 1
        fi
    done
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
        # When using NVM, we don't usually need sudo for global packages if installed in user space
        # But we use the $SUDO variable as per toolkit standards if needed.
        # However, NVM global packages are usually in ~/.nvm/versions/node/vX/lib/node_modules
        # So we try without sudo first, or let the user decide.
        npm install -g "$pkg" || $SUDO npm install -g "$pkg"
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
        
        load_nvm
        local s_nvm=$(get_nvm_status)
        local s_node=$(get_status node)
        local s_pm2=$(get_status pm2)
        local s_yarn=$(get_status yarn)
        local s_pnpm=$(get_status pnpm)
        local s_nodemon=$(command -v nodemon >/dev/null && echo -e "${GREEN}✔${RESET}" || echo "")
        local s_serve=$(command -v serve >/dev/null && echo -e "${GREEN}✔${RESET}" || echo "")

        ui_border_top
        ui_title "${BOLD}QUẢN LÝ NODEJS / NPM / PM2${RESET}"
        ui_border_mid
        ui_line "Cài đặt nền tảng:"
        ui_line "1. Cài đặt NVM (Quản lý phiên bản)  $s_nvm"
        ui_line "2. Cài đặt Node.js & NPM (Multi)     $s_node"
        ui_empty
        ui_line "Công cụ quản lý & Package Manager:"
        ui_line "3. Cài đặt PM2 (Process Manager)    $s_pm2"
        ui_line "4. Cài đặt Yarn (Package Manager)   $s_yarn"
        ui_line "5. Cài đặt PNPM                     $s_pnpm"
        ui_empty
        ui_line "Các ứng dụng phổ biến:"
        ui_line "6. Cài đặt Nodemon (Dev Tool)       $s_nodemon"
        ui_line "7. Cài đặt Serve (Static Server)    $s_serve"
        ui_empty
        ui_line "0. Quay lại menu chính"
        ui_border_bottom
        
        ui_input
        read n_choice
        
        case $n_choice in
            1) install_nvm ;;
            2) nodejs_version_menu ;;
            3) install_npm_pkg "pm2" "PM2" ;;
            4) install_npm_pkg "yarn" "Yarn" ;;
            5) install_npm_pkg "pnpm" "PNPM" ;;
            6) install_npm_pkg "nodemon" "Nodemon" ;;
            7) install_npm_pkg "serve" "Serve" ;;
            0) return ;;
            *) echo -e "${RED} $(tr_ui "Sai lựa chọn") ${RESET}"; sleep 1 ;;
        esac
    done
}

# Auto-load NVM on source
load_nvm

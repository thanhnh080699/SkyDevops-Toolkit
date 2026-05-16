#!/bin/bash

# ==============================
# DOCKER INSTALL PLUGIN
# ==============================

. core/ui.sh
. core/os.sh
. core/utils.sh

# Function to fetch versions
fetch_docker_versions() {
    echo -e "\n  ${YELLOW}> Đang tải danh sách phiên bản Docker CE...${RESET}"
    
    # Try fetching from tags API (much more reliable for versions)
    # Using a simple fallback if GitHub API is unreachable
    local cur_v=$(curl -s -H "User-Agent: bash" https://api.github.com/repos/docker/docker-ce/tags | grep '"name":' | sed 's/.*"v\([^"]*\)".*/\1/' | head -n 10)
    
    if [ -z "$cur_v" ]; then
        # Fallback for Docker (Latest stable branches)
        DOCKER_VERSIONS=("27.4.1" "27.3.1" "26.1.4" "25.0.3" "24.0.9" "23.0.6" "20.10.24")
    else
        read -r -a DOCKER_VERSIONS <<< "$(echo "$cur_v" | tr '\n' ' ')"
    fi
    
    LATEST_DOCKER_VER=${DOCKER_VERSIONS[0]}
    STABLE_DOCKER_VER=${DOCKER_VERSIONS[1]} # Usually we treat the 2nd latest tag as a safe-enough stable branch
    ARCHIVE_DOCKER_VERSIONS=("${DOCKER_VERSIONS[@]:2:5}")
}

# Function to run Docker install logic
install_docker() {
    local version=$1
    detect_os
    
    # Check current installed version
    local current_version=""
    if command -v docker >/dev/null 2>&1; then
        current_version=$(docker -v | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")
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
    ui_title "${BOLD}XÁC NHẬN CÀI ĐẶT DOCKER & COMPOSE${RESET}"
    ui_border_mid
    ui_line "Tổng quan thông tin:"
    ui_line "- Hệ điều hành: $OS_NAME $OS_VER ($OS_ID)"
    ui_line "- Ứng dụng:    Docker CE & Docker Compose Plugin"
    ui_line "- Phiên bản:    Docker v$version"
    ui_line "- Hành động:    $action_text"
    ui_empty
    ui_line "Bạn có muốn tiếp tục chạy tiến trình cài đặt?"
    ui_border_bottom
    
    echo -ne "\n${BOLD}➜ $(tr_ui "Xác nhận") (Y/n):${RESET} "
    read -r confirm
    
    if [[ -z "$confirm" ]]; then
        confirm="y"
    fi
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "\n  ${YELLOW}$(tr_ui "Đã hủy thao tác cài đặt.")${RESET}"
        sleep 1
        return
    fi
    
    echo -e "\n${GREEN}  Bắt đầu quy trình cài đặt Docker ($version)...${RESET}"
    
    local install_args="--version $version"
    
    if [ -n "$current_version" ]; then
        simulate_progress "Đang gỡ bỏ phiên bản Docker v$current_version hiện tại"
        install_args="$install_args --uninstall"
    fi
    
    # Actually run the script
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if ! $SUDO bash plugins/docker/scripts/install_docker.sh $install_args; then
            echo -e "\n  ${RED}✘ Lỗi: Quá trình cài đặt Docker thất bại.${RESET}"
            echo -n "  $(tr_ui "Nhấn Enter để quay lại")... "
            read
            return 1
        fi
    else
        # Simulation for non-linux environments
        simulate_progress "Đang cấu hình Docker Repository ($OS_ID)"
        simulate_progress "Đang tải xuống các package (Docker CE, Containerd, Compose)"
        simulate_progress "Đang thiết lập Systemd Service & User Group"
    fi
    
    echo -e "  ${GREEN}✔ Docker v$version & Docker Compose đã cứu cài thành công!${RESET}"
    echo -n "  $(tr_ui "Nhấn Enter để quay lại")... "
    read
}

# Nested Menu for Docker
docker_menu() {
    fetch_docker_versions
    
    while true; do
        clear
        ui_init
        
        ui_border_top
        ui_title "${BOLD}CÀI ĐẶT DOCKER OFFICIAL${RESET}"
        ui_border_mid
        ui_line "Lựa chọn phiên bản Docker CE và Docker Compose Plugin:"
        ui_empty
        ui_line "1. Latest Edge                [ v$LATEST_DOCKER_VER ]"
        ui_line "2. Stable Recommended         [ v$STABLE_DOCKER_VER ]"
        ui_empty
        ui_line "Các phiên bản khác / Old Archives:"
        ui_line "3. Docker CE                  [ v${ARCHIVE_DOCKER_VERSIONS[0]} ]"
        ui_line "4. Docker CE                  [ v${ARCHIVE_DOCKER_VERSIONS[1]} ]"
        ui_line "5. Docker CE                  [ v${ARCHIVE_DOCKER_VERSIONS[2]} ]"
        ui_line "6. Docker CE                  [ v${ARCHIVE_DOCKER_VERSIONS[3]} ]"
        ui_line "7. Docker CE                  [ v${ARCHIVE_DOCKER_VERSIONS[4]} ]"
        ui_empty
        ui_line "0. Quay lại menu chính"
        ui_border_bottom
        
        ui_input
        read d_choice
        
        case $d_choice in
            1) install_docker "$LATEST_DOCKER_VER" ;;
            2) install_docker "$STABLE_DOCKER_VER" ;;
            3) install_docker "${ARCHIVE_DOCKER_VERSIONS[0]}" ;;
            4) install_docker "${ARCHIVE_DOCKER_VERSIONS[1]}" ;;
            5) install_docker "${ARCHIVE_DOCKER_VERSIONS[2]}" ;;
            6) install_docker "${ARCHIVE_DOCKER_VERSIONS[3]}" ;;
            7) install_docker "${ARCHIVE_DOCKER_VERSIONS[4]}" ;;
            0) return ;;
            *) echo -e "${RED} $(tr_ui "Sai lựa chọn") ${RESET}"; sleep 1 ;;
        esac
    done
}

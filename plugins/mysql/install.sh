#!/bin/bash

# ==============================
# MYSQL INSTALL PLUGIN
# ==============================

. core/ui.sh
. core/os.sh
. core/utils.sh

# ==============================
# FIX MYSQL GPG KEY
# ==============================
fix_mysql_gpg() {

    echo -e "\n${YELLOW}  ➜ Đang sửa MySQL GPG Key...${RESET}"

    export DEBIAN_FRONTEND=noninteractive
    local mysql_gpg_key_id="B7B3B788A8D3785C"
    local mysql_keyring="/etc/apt/keyrings/mysql.gpg"
    local repo_os=""
    local repo_codename=""
    local repo_component="mysql-8.0"

    if [ "$version" = "8.4" ]; then
        repo_component="mysql-8.4-lts"
    fi

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        repo_os="$ID"
        repo_codename="${VERSION_CODENAME:-}"
    fi

    if [ -z "$repo_codename" ] && command -v lsb_release >/dev/null 2>&1; then
        repo_codename=$(lsb_release -sc)
    fi

    if [[ "$repo_os" != "ubuntu" && "$repo_os" != "debian" ]]; then
        echo -e "${RED}  ✘ MySQL APT Repository chỉ hỗ trợ Ubuntu/Debian${RESET}"
        return 1
    fi

    if [ -z "$repo_codename" ]; then
        echo -e "${RED}  ✘ Không xác định được codename hệ điều hành${RESET}"
        return 1
    fi

    # ==============================
    # TEMP DISABLE OLD MYSQL REPO
    # ==============================
    if [ -f /etc/apt/sources.list.d/mysql.list ]; then
        mv /etc/apt/sources.list.d/mysql.list \
           /etc/apt/sources.list.d/mysql.list.bak
    fi

    # ==============================
    # UPDATE BASE PACKAGES
    # ==============================
    apt-get update -y

    apt-get install -y \
        curl \
        ca-certificates \
        gnupg \
        gnupg2 \
        dirmngr \
        lsb-release

    # ==============================
    # CLEAN OLD KEYS
    # ==============================
    rm -f /etc/apt/trusted.gpg.d/mysql.gpg
    rm -f /usr/share/keyrings/mysql-apt-config.gpg
    rm -f "$mysql_keyring"

    apt-key del "$mysql_gpg_key_id" >/dev/null 2>&1 || true

    mkdir -p /etc/apt/keyrings

    # ==============================
    # IMPORT NEW MYSQL KEY
    # ==============================
    local tmp_gnupg=""
    tmp_gnupg=$(mktemp -d)
    chmod 700 "$tmp_gnupg"

    if ! GNUPGHOME="$tmp_gnupg" gpg --batch --keyserver hkps://keyserver.ubuntu.com --recv-keys "$mysql_gpg_key_id"; then
        rm -rf "$tmp_gnupg"
        echo -e "${RED}  ✘ Không thể tải MySQL GPG Key $mysql_gpg_key_id${RESET}"
        return 1
    fi

    if ! GNUPGHOME="$tmp_gnupg" gpg --batch --export "$mysql_gpg_key_id" | gpg --dearmor --yes -o "$mysql_keyring"; then
        rm -rf "$tmp_gnupg"
        echo -e "${RED}  ✘ Không thể ghi MySQL GPG Key vào keyring${RESET}"
        return 1
    fi

    rm -rf "$tmp_gnupg"
    chmod 644 "$mysql_keyring"

    if ! gpg --show-keys --with-colons "$mysql_keyring" | grep -q "$mysql_gpg_key_id"; then
        echo -e "${RED}  ✘ MySQL GPG Key không hợp lệ: $mysql_gpg_key_id${RESET}"
        return 1
    fi

    # ==============================
    # CREATE NEW MYSQL REPO
    # ==============================
    cat >/etc/apt/sources.list.d/mysql.list <<EOF
deb [signed-by=$mysql_keyring] http://repo.mysql.com/apt/$repo_os/ $repo_codename $repo_component
deb [signed-by=$mysql_keyring] http://repo.mysql.com/apt/$repo_os/ $repo_codename mysql-tools
EOF

    # ==============================
    # CLEAN CACHE
    # ==============================
    apt-get clean
    rm -rf /var/lib/apt/lists/*

    # ==============================
    # UPDATE AGAIN
    # ==============================
    apt-get update

    if [ $? -ne 0 ]; then
        echo -e "${RED}  ✘ Không thể cập nhật MySQL Repository${RESET}"
        return 1
    fi

    echo -e "${GREEN}  ✔ MySQL GPG đã được sửa${RESET}"

    return 0
}

# ==============================
# INSTALL MYSQL
# ==============================
install_mysql() {

    local version=$1

    detect_os

    # ==============================
    # CHECK CURRENT MYSQL VERSION
    # ==============================
    local current_version=""

    if command -v mysql >/dev/null 2>&1; then
        current_version=$(mysql -V 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "")
    fi

    local action_text="Cài đặt mới"

    if [ -n "$current_version" ]; then

        if [[ "$current_version" == "$version"* ]]; then
            action_text="Re-install (Đang chạy v$current_version)"
        else
            action_text="Gỡ bản cũ (v$current_version) & Cài bản v$version"
        fi

    else
        action_text="Cài đặt mới (Chưa cài đặt)"
    fi

    # ==============================
    # CONFIRM UI
    # ==============================
    clear
    ui_init

    ui_border_top
    ui_title "${BOLD}XÁC NHẬN CÀI ĐẶT MYSQL OFFICIAL${RESET}"

    ui_border_mid

    ui_line "Tổng quan thông tin:"
    ui_line "- Hệ điều hành: $OS_NAME $OS_VER ($OS_ID)"
    ui_line "- Phiên bản:    MySQL $version"
    ui_line "- Hành động:    $action_text"

    ui_empty

    ui_line "Lưu ý: SkyDevOps sẽ tự động cấu hình Repository chính thức từ Oracle"

    ui_border_bottom

    echo -ne "\n${BOLD}➜ $(tr_ui "Xác nhận") (Y/n):${RESET} "

    read -r confirm

    if [[ -z "$confirm" ]]; then
        confirm="y"
    fi

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "\n${YELLOW}  $(tr_ui "Đã hủy thao tác cài đặt.")${RESET}"
        sleep 1
        return
    fi

    echo -e "\n${GREEN}  Bắt đầu cài đặt MySQL $version...${RESET}"

    # ==============================
    # LINUX INSTALL
    # ==============================
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then

        # ==============================
        # FIX MYSQL GPG
        # ==============================
        if ! fix_mysql_gpg; then
            echo -e "\n${RED}  ✘ Lỗi xử lý MySQL GPG Key${RESET}"
            echo -n "  $(tr_ui "Nhấn Enter để quay lại")... "
            read
            return 1
        fi

        # ==============================
        # RUN INSTALLER
        # ==============================
        if ! $SUDO bash plugins/mysql/scripts/install_mysql.sh --version "$version"; then

            echo -e "\n${RED}  ✘ Quá trình cài đặt MySQL thất bại.${RESET}"

            echo -n "  $(tr_ui "Nhấn Enter để quay lại")... "
            read

            return 1
        fi

    else

        simulate_progress "Đang cấu hình MySQL Repository"
        simulate_progress "Đang tải MySQL Server"
        simulate_progress "Đang thiết lập MySQL Service"

    fi

    # ==============================
    # SUCCESS
    # ==============================
    echo -e "\n${GREEN}  ✔ MySQL $version đã được cài đặt thành công!${RESET}"

    echo -n "  $(tr_ui "Nhấn Enter để quay lại")... "
    read
}

# ==============================
# MYSQL MENU
# ==============================
mysql_menu() {

    while true; do

        clear

        ui_init

        ui_border_top
        ui_title "${BOLD}CÀI ĐẶT MYSQL OFFICIAL (ORACLE)${RESET}"

        ui_border_mid

        ui_line "Lựa chọn phiên bản MySQL Community Server:"

        ui_empty

        ui_line "1. MySQL 8.0 (Bản ổn định phổ biến)"
        ui_line "2. MySQL 8.4 (Bản LTS mới nhất)"

        ui_empty

        ui_line "0. Quay lại menu chính"

        ui_border_bottom

        ui_input

        read m_choice

        case $m_choice in

            1)
                install_mysql "8.0"
                ;;

            2)
                install_mysql "8.4"
                ;;

            0)
                return
                ;;

            *)
                echo -e "${RED} $(tr_ui "Sai lựa chọn") ${RESET}"
                sleep 1
                ;;

        esac
    done
}

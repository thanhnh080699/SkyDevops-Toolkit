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

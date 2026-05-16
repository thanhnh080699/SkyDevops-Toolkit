#!/bin/bash

# ==============================
# UI EFFECTS & UTILS
# ==============================

# Progress Bar
# Arguments: percentage (0-100), width
# Use: show_progress 50 20
show_progress() {
    local percent=$1
    local width=${2:-30}
    local filled=$(( percent * width / 100 ))
    local empty=$(( width - filled ))
    
    printf "\r${BOLD}  $(tr_ui "Progress"): [${GREEN}"
    printf '█%.0s' $(seq 1 $filled 2>/dev/null)
    [ $filled -eq 0 ] && printf ""
    printf "${RESET}"
    printf '░%.0s' $(seq 1 $empty 2>/dev/null)
    [ $empty -eq 0 ] && printf ""
    printf "] $percent%%${RESET}"
}

# Spinner / Loading Animation
# Use: run_with_spinner "Task name" "command to run"
run_with_spinner() {
    local msg="$1"
    local pid
    local delay=0.1
    local spinstr='|/-\'
    
    # Run the command in background
    eval "$2" > /dev/null 2>&1 &
    pid=$!
    
    echo -ne "  ${msg}  "
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf " [OK]  \n"
    wait "$pid"
}

# Simulate progress for demo/install
simulate_progress() {
    local msg="$1"
    msg=$(tr_ui "$msg")
    echo -e "  ${msg}..."
    for i in {0..100..5}; do
        show_progress $i 40
        sleep 0.05
    done
    echo -e "\n  ${GREEN}✔ $(tr_ui "Hoàn tất")!${RESET}\n"
}

---
name: skydevops-toolkit
description: "Master skill for the SkyDevOps Toolkit project — a Bash-based automation platform for installing, configuring, and optimizing server software (Nginx, PHP, MySQL, MariaDB, Docker, Apache2, Node.js) on Ubuntu and CentOS/RHEL. Use this skill whenever the user wants to add a new plugin, optimize existing configurations, write installation scripts, fix repository/GPG issues, improve the CLI UI, manage multi-OS compatibility, tune server performance (sysctl, limits, kernel), or follow project conventions. This skill should trigger for any DevOps automation task, Linux server management, software installation scripting, performance tuning, or bash toolkit development within this project."
---

# SkyDevOps Toolkit — Master Project Skill

This skill defines the conventions, architecture, coding standards, and optimization rules for the **SkyDevOps Toolkit** — a modular Bash automation platform for Linux server management.

## Project Overview

SkyDevOps Toolkit is a CLI-based DevOps automation tool that provides:
- **Automated installation** of server software from official repositories
- **Performance optimization** with hardware-aware configurations
- **System check tools** for common operational diagnostics
- **Multi-OS support** for Ubuntu/Debian and CentOS/RHEL/Rocky/AlmaLinux
- **Responsive CLI UI** with progress bars, spinners, and Unicode box-drawing

### Supported Software Stack
| Software | Plugin Path | Features |
|----------|-------------|----------|
| Nginx | `plugins/nginx/` | Install (Stable/Mainline), Optimize |
| PHP | `plugins/php/` | Multi-version (7.2–8.3), Composer, Optimize |
| MySQL | `plugins/mysql/` | 8.0, 8.4 LTS with GPG auto-fix, Optimize |
| MariaDB | `plugins/mariadb/` | Dynamic API-fetched versions, Optimize |
| Docker | `plugins/docker/` | CE + Compose + Buildx |
| Apache2 | `plugins/apache2/` | Install/Update |
| Node.js | `plugins/nodejs/` | NVM-based, PM2, Yarn, PNPM |

---

## Architecture

```
.
├── main.sh                 # Entry point: sources core + plugins, main menu loop
├── core/
│   ├── ui.sh               # Responsive UI framework (box-drawing, 3-column layout)
│   ├── os.sh               # OS detection (detect_os, is_ubuntu, is_centos)
│   └── utils.sh            # Progress bar, spinner, simulate_progress
├── plugins/
│   └── <software>/
│       ├── install.sh       # Menu + confirmation UI (sourced by main.sh)
│       ├── optimize.sh      # Performance tuning UI (optional)
│       └── scripts/
│           └── install_<sw>.sh  # Actual installer (run via $SUDO bash)
└── .agent/skills/           # Agent skills directory
```

### Key Design Decisions
- **`install.sh`** files in plugin roots are **sourced** by `main.sh` — they define menu functions and UI flows
- **`scripts/*.sh`** files are **executed** as subprocesses via `$SUDO bash` — they perform the actual system modifications
- This separation means `install.sh` has access to all UI functions (`ui_border_top`, `ui_line`, etc.) while `scripts/*.sh` are standalone and portable

---

## Coding Conventions (Mandatory)

### 1. Global SUDO Pattern
Never hardcode `sudo`. The global `$SUDO` variable is set in `main.sh` and detects root vs. non-root users:

```bash
# In scripts/*.sh — use direct commands (they're already called with $SUDO bash)
apt-get install -y nginx

# In install.sh — use the global variable
$SUDO bash plugins/nginx/scripts/install_nginx.sh $install_args
```

### 2. OS Detection Pattern
Always use the `detect_os` function from `core/os.sh` and branch with `is_ubuntu` / `is_centos`:

```bash
detect_os

if is_ubuntu; then
    # Ubuntu/Debian path
elif is_centos; then
    # CentOS/RHEL/Rocky/AlmaLinux path
fi
```

The `is_centos()` function covers: `centos`, `rhel`, `rocky`, `almalinux`.

### 3. Plugin File Structure

Every new plugin MUST follow this structure:

```
plugins/<software>/
├── install.sh           # Required: Menu + confirmation + delegation
├── optimize.sh          # Optional: Performance tuning
└── scripts/
    └── install_<sw>.sh  # Required: Actual installation logic
```

### 4. Plugin install.sh Template

```bash
#!/bin/bash

. core/ui.sh
. core/os.sh
. core/utils.sh

install_<software>() {
    local version=$1
    detect_os

    # 1. Detect current version
    local current_version=""
    if command -v <software> >/dev/null 2>&1; then
        current_version=$(<software> --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    fi

    # 2. Smart action text
    local action_text="Cài đặt mới (Chưa cài đặt)"
    if [ -n "$current_version" ]; then
        if [[ "$current_version" == "$version"* ]]; then
            action_text="Re-install (Đang chạy v$current_version)"
        else
            action_text="Gỡ bản cũ (v$current_version) & Cài bản v$version"
        fi
    fi

    # 3. Confirmation UI
    clear
    ui_init
    ui_border_top
    ui_title "${BOLD}XÁC NHẬN CÀI ĐẶT <SOFTWARE>${RESET}"
    ui_border_mid
    ui_line "- Hệ điều hành: $OS_NAME $OS_VER ($OS_ID)"
    ui_line "- Phiên bản:    <Software> $version"
    ui_line "- Hành động:    $action_text"
    ui_border_bottom

    echo -ne "\n${BOLD}➜ Xác nhận (Y/n):${RESET} "
    read -r confirm
    [[ -z "$confirm" ]] && confirm="y"
    [[ ! "$confirm" =~ ^[Yy]$ ]] && return

    # 4. Execute
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if ! $SUDO bash plugins/<software>/scripts/install_<sw>.sh --version "$version"; then
            echo -e "\n  ${RED}✘ Lỗi: Quá trình cài đặt thất bại.${RESET}"
            echo -n "  Nhấn Enter để quay lại... "; read
            return 1
        fi
    else
        simulate_progress "Đang cấu hình Repository"
        simulate_progress "Đang tải xuống gói cài đặt"
        simulate_progress "Đang thiết lập Service"
    fi

    echo -e "  ${GREEN}✔ <Software> $version đã cài đặt thành công!${RESET}"
    echo -n "  Nhấn Enter để quay lại... "; read
}

<software>_menu() {
    while true; do
        clear; ui_init
        ui_border_top
        ui_title "${BOLD}CÀI ĐẶT <SOFTWARE>${RESET}"
        ui_border_mid
        ui_line "1. Version X"
        ui_line "0. Quay lại menu chính"
        ui_border_bottom
        ui_input; read choice
        case $choice in
            1) install_<software> "X.Y" ;;
            0) return ;;
            *) echo -e "${RED} Sai lựa chọn ${RESET}"; sleep 1 ;;
        esac
    done
}
```

### 5. Plugin scripts/*.sh Template

```bash
#!/bin/bash
set -e

TARGET_VERSION=""
UNINSTALL=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --version) TARGET_VERSION="$2"; shift ;;
        --uninstall) UNINSTALL=true ;;
        --help) echo "Usage: $0 [--version VER] [--uninstall]"; exit 0 ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# OS Detection (standalone, no sourcing core/)
if [ -f /etc/os-release ]; then
    OS_ID=$(grep -E '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
    CODENAME=$(grep -E '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
elif [ -f /etc/redhat-release ]; then
    OS_ID="centos"
fi

pre_install_checks() {
    echo "Checking and installing basic dependencies..."
    case $OS_ID in
        ubuntu|debian)
            apt-get update -y
            apt-get install -y curl gnupg2 ca-certificates lsb-release
            ;;
        centos|rhel|fedora|almalinux|rocky)
            yum install -y curl yum-utils
            ;;
    esac
}

perform_uninstall() {
    # OS-specific removal
}

install_ubuntu() {
    # GPG key + Repository + apt install
}

install_centos() {
    # yum repo + yum install
}

# Execution
pre_install_checks
[ "$UNINSTALL" = true ] && perform_uninstall

case $OS_ID in
    ubuntu|debian) install_ubuntu ;;
    *) install_centos ;;
esac

# Service verification
if command -v systemctl >/dev/null 2>&1; then
    systemctl enable <service> || true
    systemctl start <service> || true
    if systemctl is-active --quiet <service>; then
        echo "✔ <Service> is active and running."
    else
        echo "✘ ERROR: <Service> failed to start."
        exit 1
    fi
fi
```

### 6. Registering a New Plugin

After creating the plugin files, update `main.sh`:

```bash
# 1. Source it (near the top, with other plugin sources)
. plugins/<software>/install.sh

# 2. Add status detection in show_main_menu
M8=$(get_status <software>)

# 3. Add menu row
ui_row_3col "8. <SOFTWARE>     [$M8]" "" ""

# 4. Add case handler in handle_choice
8) <software>_menu ;;
```

---

## Installation Optimization Rules

These rules govern how every installation script should be written to ensure reliability, security, and performance across Ubuntu and CentOS.

### Rule 1: Always Use Official Repositories
- Never install from third-party PPAs or untrusted sources
- Use the software vendor's official GPG keys and repository URLs
- Pin repository priority where needed (e.g., `Pin-Priority: 900` for Nginx)

**Ubuntu pattern:**
```bash
# Import GPG key
curl -fsSL <KEY_URL> | gpg --dearmor -o /etc/apt/keyrings/<software>.gpg
chmod a+r /etc/apt/keyrings/<software>.gpg

# Add repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/<software>.gpg] <REPO_URL> $(lsb_release -cs) stable" \
    | tee /etc/apt/sources.list.d/<software>.list

# Update and install
apt-get update -y
apt-get install -y <package>
```

**CentOS pattern:**
```bash
# Add repository
yum-config-manager --add-repo <REPO_URL>
# OR create /etc/yum.repos.d/<software>.repo manually

# Import GPG key
rpm --import <GPG_KEY_URL>

# Install
yum install -y <package>
```

### Rule 2: Robust Dependency Pre-checks
Every script must have a `pre_install_checks()` function that installs essential tools before using them. This is critical for fresh servers and Docker containers.

**Minimum dependencies per OS:**

| Ubuntu/Debian | CentOS/RHEL |
|---------------|-------------|
| `curl` | `curl` |
| `gnupg2` | `yum-utils` |
| `ca-certificates` | `epel-release` (when needed) |
| `lsb-release` | |
| `software-properties-common` (for PPAs) | |

### Rule 3: GPG Key Management
- Use modern keyring path: `/etc/apt/keyrings/` (not deprecated `apt-key`)
- Always use `signed-by=` in source list entries
- Clean old keys before importing new ones to avoid conflicts
- Verify key fingerprint after import when critical (e.g., MySQL)

### Rule 4: Architecture Awareness
- Check CPU architecture before adding repositories (`dpkg --print-architecture` or `uname -m`)
- Provide automatic fallback for unsupported architectures (e.g., ARM → default OS packages)
- Log a clear warning when falling back

### Rule 5: Service Lifecycle Management
After installation, always:
1. `systemctl enable <service>` — Ensure auto-start on boot
2. `systemctl start <service>` — Start immediately
3. **Verify** with `systemctl is-active --quiet <service>` — Exit with error if failed
4. Handle environments without `systemctl` (Docker/LXC containers)

### Rule 6: Idempotent Installations
- Check if already installed before proceeding
- Compare current version vs. target version
- Support clean uninstall before reinstall (`perform_uninstall()`)
- Clean up old repository files before adding new ones

### Rule 7: Non-Interactive Mode
- Set `DEBIAN_FRONTEND=noninteractive` for apt operations
- Use `--assumeyes` / `-y` flags everywhere
- Never prompt during the actual installation script (prompting happens in the UI layer)

---

## Software Optimization Rules

These rules define how to build optimization features (like the Nginx optimizer in `plugins/nginx/optimize.sh`).

### Rule 1: Hardware-Aware Configuration
Always detect system specs before suggesting configuration values:

```bash
# CPU cores
vcpu=$(nproc 2>/dev/null || echo 1)

# RAM in MB
ram_kb=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}')
ram_mb=$((ram_kb / 1024))

# Disk type (SSD vs HDD)
disk_type=$(cat /sys/block/sda/queue/rotational 2>/dev/null)
# 0 = SSD, 1 = HDD
```

### Rule 2: Optimization Parameter Guidelines

#### Nginx Optimization
| Parameter | Formula / Guideline | Range |
|-----------|-------------------|-------|
| `worker_processes` | = vCPU count | 1–auto |
| `worker_connections` | RAM_MB × 4 | 1024–65535 |
| `keepalive_timeout` | 65s (balanced) | 30–120 |
| `gzip` | Always `on` | on/off |
| `gzip_comp_level` | 4–6 (balanced CPU/size) | 1–9 |
| `client_max_body_size` | 64M (web apps) | 1M–512M |
| `use epoll` | Always for Linux | on/off |
| `multi_accept` | `on` | on/off |
| `sendfile` | `on` | on/off |
| `tcp_nopush` | `on` | on/off |
| `tcp_nodelay` | `on` | on/off |

#### MySQL / MariaDB Optimization
| Parameter | Formula / Guideline | Notes |
|-----------|-------------------|-------|
| `innodb_buffer_pool_size` | ~70% of RAM | Most critical parameter |
| `innodb_log_file_size` | 256M–1G | Larger = better write perf |
| `innodb_flush_log_at_trx_commit` | 2 (perf) or 1 (safety) | Trade durability for speed |
| `max_connections` | RAM_MB / 10 | Prevent OOM |
| `query_cache_size` | 0 (MySQL 8+) or 64M | Deprecated in MySQL 8 |
| `tmp_table_size` | 64M–256M | For complex queries |
| `max_heap_table_size` | Same as tmp_table_size | Must match |
| `thread_cache_size` | 8–64 | Reduce thread creation |
| `key_buffer_size` | 32M (MyISAM) | Low if InnoDB only |

#### PHP-FPM Optimization
| Parameter | Formula / Guideline | Notes |
|-----------|-------------------|-------|
| `pm` | `dynamic` | Balanced mode |
| `pm.max_children` | RAM_MB / 40 | ~40MB per child |
| `pm.start_servers` | vCPU × 2 | Initial workers |
| `pm.min_spare_servers` | vCPU | Minimum idle |
| `pm.max_spare_servers` | vCPU × 4 | Maximum idle |
| `pm.max_requests` | 500–1000 | Prevent memory leaks |
| `memory_limit` | 128M–256M | Per-process |
| `upload_max_filesize` | Match nginx `client_max_body_size` | Sync values |
| `opcache.memory_consumption` | 128–256 | In MB |
| `opcache.max_accelerated_files` | 10000–20000 | Script count |
| `opcache.validate_timestamps` | 0 (prod) / 1 (dev) | |

#### System Kernel Optimization (sysctl)
| Parameter | Value | Purpose |
|-----------|-------|---------|
| `net.core.somaxconn` | 65535 | Max listen backlog |
| `net.core.netdev_max_backlog` | 65535 | Network queue |
| `net.ipv4.tcp_max_syn_backlog` | 65535 | SYN queue |
| `net.ipv4.tcp_fin_timeout` | 15 | Faster socket reuse |
| `net.ipv4.tcp_tw_reuse` | 1 | TIME_WAIT reuse |
| `net.ipv4.ip_local_port_range` | "1024 65535" | More ephemeral ports |
| `vm.swappiness` | 10 | Prefer RAM over swap |
| `vm.overcommit_memory` | 1 | For Redis/similar |
| `fs.file-max` | 2097152 | Max open files |

#### Security Limits (/etc/security/limits.conf)
```
* soft nofile 65535
* hard nofile 65535
* soft nproc  65535
* hard nproc  65535
```

### Rule 3: Always Backup Before Modifying
```bash
local backup_file="/etc/<software>/<config>.bak.$(date +%Y%m%d_%H%M%S)"
$SUDO cp "$config_file" "$backup_file"
```

### Rule 4: Config Validation Before Reload
- Always test config syntax after modification when the software provides a reliable validation command: `nginx -t`, `apachectl configtest`
- Do not use `mariadbd --validate-config` or `mysqld --validate-config` in DB optimizers because support differs by version/distribution; apply config by restarting the service, show service logs on failure, then rollback
- Auto-rollback from backup if validation fails
- Only reload (not restart) after config changes: `systemctl reload <service>`

### Rule 5: Diff-Based Confirmation
Before applying changes, show a comparison table:
```
| Parameter       | Current  | New      |
|-----------------|----------|----------|
| worker_processes| 1        | 4        |
| worker_conns    | 768      | 8192     |
```
This empowers the user to review and customize before committing.

### Rule 6: Interactive with Smart Defaults
- Present hardware-calculated suggestions as defaults
- Allow the user to override each parameter
- Use the Bash default-value pattern: `: ${var:=$default}`

### Rule 7: Keep Execution Logs Visible
After the user confirms an optimization or system-changing action:
- Do not call `clear` until the action fully finishes and the user has acknowledged the result
- Print each execution phase and command result so errors are visible: backup, write config, validate, reload/restart
- Do not suppress validation output unless it is duplicated elsewhere; users must see why validation failed
- On failure, print a clear red error, show relevant service/config logs when available, rollback if possible, then wait for a keypress before returning to the main menu
- On success, print a clear green success message and wait for a keypress before returning to the main menu

---

## UI Standards

### ANSI Color Palette
```bash
ESC=$(printf '\033')
RESET="${ESC}[0m"
BOLD="${ESC}[1m"
CYAN="${ESC}[0;36m"      # Borders, structural elements
GREEN="${ESC}[0;32m"      # Success indicators
YELLOW="${ESC}[1;33m"     # Warnings, labels
RED="${ESC}[0;31m"        # Errors
```

### Menu Construction Rules
1. Always call `ui_init` at the start of every menu redraw
2. Use `ui_border_top` / `ui_border_mid` / `ui_border_bottom` for framing
3. Use `ui_title` for centered headers
4. Use `ui_line` for content rows
5. Use `ui_row_3col` only in the main menu's 3-column layout
6. Use `ui_empty` for vertical spacing
7. End every menu with `ui_input` to show the prompt
8. Service names in main menu: **UPPERCASE** (e.g., NGINX, DOCKER)
9. Status format: `[${GREEN}✔ vX.Y.Z${RESET}]` or `[ ]` if not installed
10. All bracketed statuses `[...]` must be vertically aligned

### Responsive Design
- Read terminal width from `tput cols` — never hardcode
- Minimum width guard: 80 columns
- Column widths in 3-column layout are calculated as percentages of available space
- Text truncation handles ANSI sequences gracefully

---

## Common Pitfalls & Fixes

### GPG Key Issues (Ubuntu)
```bash
# Modern approach — use /etc/apt/keyrings/
mkdir -p /etc/apt/keyrings
curl -fsSL <KEY_URL> | gpg --dearmor -o /etc/apt/keyrings/<software>.gpg

# NEVER use apt-key (deprecated since Ubuntu 22.04)
```

### Repository Conflicts
```bash
# Always clean before adding
rm -f /etc/apt/sources.list.d/<software>.list
# Then write the new source
```

### Docker/Container Environments
```bash
# systemctl may not exist
if command -v systemctl >/dev/null 2>&1; then
    systemctl enable <service>
else
    echo "WARNING: systemctl not found. Start manually."
fi
```

### ARM Architecture Fallbacks
```bash
local arch=$(dpkg --print-architecture)
if [[ "$arch" != "amd64" && "$arch" != "i386" ]]; then
    echo "WARNING: Falling back to OS default packages"
    apt-get install -y <package>
    return
fi
```

---

## Checklist for New Plugins

- [ ] Created `plugins/<sw>/install.sh` with menu + confirmation
- [ ] Created `plugins/<sw>/scripts/install_<sw>.sh` with actual logic
- [ ] `scripts/*.sh` includes `set -e` and `pre_install_checks()`
- [ ] Both Ubuntu and CentOS paths implemented
- [ ] Service verification after installation
- [ ] Simulation mode for non-Linux environments
- [ ] Plugin sourced in `main.sh`
- [ ] Menu entry added to `show_main_menu` (3-column layout)
- [ ] Case handler added to `handle_choice`
- [ ] `get_status` function covers the new software
- [ ] Status brackets vertically aligned in main menu
- [ ] Tested at 80-column and 120-column terminal widths

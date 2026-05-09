---
name: nginx-install
description: Automate the installation of Nginx, PHP (v7.2 - v8.3), and Node.js/NPM (v20 LTS) on Ubuntu and CentOS using official repositories. Supports selecting between Stable (LTS) and Mainline (Latest) versions for Nginx. Use this skill when the user wants to install Nginx, PHP, Node.js, upgrade services, or manage Linux server software.
---

# Nginx Install Skill (Modular Plugin)

This skill automates the installation of Nginx using a modular plugin system that supports multi-level menus, OS detection, and progress animations.

## Architecture
The project is organized into a core framework and a plugin system:
- **`core/`**: Contains the UI framework, OS detection, and utility functions (progress bars, spinners).
- **`plugins/`**: Contains the logic for each service (e.g., `plugins/nginx/install.sh`).
- **`main.sh`**: The main entry point that sources the core components and routes the user's choices to the appropriate plugins.

## Features
- **Nested Menus**: Supports multiple levels of navigation (e.g., Service -> Action -> Version).
- **Auto OS Detect**: Automatically detects if the system is Ubuntu/Debian or CentOS/RHEL/Rockylinux.
- **PHP Multi-Version**: Supports installing PHP 7.2, 7.4, 8.0, 8.1, 8.2, 8.3 with common extensions.
- **Node.js/NPM**: Automated setup of Node.js v20 (LTS) with PM2, Yarn, PNPM and other ecosystem tools.
- **Progressive UI**: Uses progress bars and spinners for a modern CLI experience.
- **Plugin System**: Easily add new software by creating a new folder in `plugins/` and sourcing it in `main.sh`.

## Adding a Plugin
To add a new software plugin:
1. Create a folder in `plugins/your-software/`.
2. Create `install.sh`, `optimize.sh`, etc.
3. Put installation heavy-lifting scripts in `plugins/your-software/scripts/`.
4. Source the plugin in `main.sh`.
5. Add the menu entry in `show_main_menu` and the case in `handle_choice`.

## Advanced Features
- **Dynamic Sudo/Root Detection**: `main.sh` automatically detects if the user is root or has sudo access, setting a global `$SUDO` variable.
- **Auto-Dependency Installation**: Installation scripts automatically install `curl`, `gnupg2`, `lsb-release`, etc., before the main software installation.
- **Container Compatibility**: Explicitly checks for `systemctl` existence to avoid errors in Docker/LXC environments.

## Requirements
The core toolkit requires:
- `bash`, `sed`, `grep`, `tput`.
- Root or `sudo` access (automatically detected).
- **Auto-installed by scripts**: `curl`, `gnupg2`, `lsb-release`, `ca-certificates`.

## Standard Plugin Structure (Best Practices)
When creating installation plugins for any new software, strictly adhere to the following workflow:
1. **Fetch Dynamic Versions**: Always fetch the latest versions dynamically from official sources instead of hardcoding whenever possible.
2. **Current Version Detection**: Identify if the software is already installed on the system and parse its exact version (e.g., `nginx -v`, `mysql -V`, `docker -v`).
3. **Smart Action Definition**: Based on the current version compared to the requested target version, dynamically define the installation action text:
   - *Cài đặt mới (Chưa cài đặt)*: If not installed.
   - *Re-install (Đang chạy vX)*: If target version equals current version.
   - *Gỡ bản cũ (vX) & Cài bản mới (vY)*: If target version differs from current version (Upgrade/Downgrade).
4. **User Confirmation**: Always display an overview UI box detailing the OS, Target Version, and Smart Action text. Explicit confirmation (`Y/n`) is required before proceeding.
5. **Real/Simulated Progress**: If an upgrade/downgrade is detected, explicitly simulate or run the uninstallation step before configuring the new repository and installing the new version.
6. **Robust Dependency Check**: Every installation script must include a `pre_install_checks` function to install required tools like `curl` before using them.
7. **Execution logic**: Always use the global `$SUDO` variable (defined in `main.sh`) instead of hardcoding `sudo`.

## UI Review & Alignment Workflow (Mandatory)
After adding any new software or modifying menu entries in `main.sh`:
1. **Responsive Width First**: Do not hardcode the UI to 100 columns. `core/ui.sh` must read the current terminal width with `tput cols`, use it as `WIDTH`, and derive `INNER_WIDTH` and column widths dynamically. Keep only a minimum supported width guard.
2. **Dynamic Column Allocation**: The main menu should use `ui_row_3col` with calculated `COL1_WIDTH`, `COL2_WIDTH`, and `COL3_WIDTH`. The first column must receive enough space for service labels plus installed-version markers; wider terminals should expand all columns naturally.
3. **Vertical Alignment**: All status brackets `[...]` must be perfectly aligned vertically. Use manual space padding for labels to ensure consistency (e.g., padding "PHP" with spaces to match "NODEJS/NPM").
4. **Case Consistency**: Service names in the main menu should be in `UPPERCASE` (e.g., NGINX, DOCKER, NODEJS/NPM).
5. **Status Indicators**: Use `${GREEN}✔ vX.Y.Z${RESET}` for installed software and keep the brackets `[ ]` consistent across all rows.
6. **Responsive Integrity**: Ensure no line exceeds the current `INNER_WIDTH`. Use `ui_line`, `ui_title`, and `ui_row_3col` instead of manual `center_text` or raw border printing.
7. **Visual Balance**: Maintain a balanced distribution of items across the 3-column layout in the main menu at narrow, standard, and wide terminal widths.

# Ubuntu Server Optimization Reference

## Table of Contents
1. [System Update & Package Management](#1-system-update--package-management)
2. [Kernel Tuning (sysctl)](#2-kernel-tuning-sysctl)
3. [Security Limits](#3-security-limits)
4. [Swap Configuration](#4-swap-configuration)
5. [Firewall (UFW)](#5-firewall-ufw)
6. [SSH Hardening](#6-ssh-hardening)
7. [Systemd Service Optimization](#7-systemd-service-optimization)
8. [Disk I/O Optimization](#8-disk-io-optimization)
9. [Network Optimization](#9-network-optimization)
10. [Log Management](#10-log-management)

---

## 1. System Update & Package Management

### Best Practices
```bash
# Always update before installing
apt-get update -y && apt-get upgrade -y

# Use DEBIAN_FRONTEND=noninteractive for scripts
export DEBIAN_FRONTEND=noninteractive

# Enable unattended security updates
apt-get install -y unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades

# Clean up unused packages
apt-get autoremove -y && apt-get autoclean -y
```

### Repository Management
```bash
# Modern GPG keyring location (Ubuntu 22.04+)
mkdir -p /etc/apt/keyrings

# Add repository with signed-by
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/<sw>.gpg] <URL> $(lsb_release -cs) stable" \
    | tee /etc/apt/sources.list.d/<sw>.list

# Pin priority to prefer official repos
cat > /etc/apt/preferences.d/99<sw> <<EOF
Package: *
Pin: origin <domain>
Pin-Priority: 900
EOF
```

---

## 2. Kernel Tuning (sysctl)

### Production Server Profile
```bash
# /etc/sysctl.d/99-skydevops.conf

# --- Network Performance ---
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 262144
net.core.wmem_default = 262144

# --- TCP Optimization ---
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_max_tw_buckets = 1440000
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_mtu_probing = 1

# --- Memory ---
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.overcommit_memory = 1
vm.max_map_count = 262144

# --- File System ---
fs.file-max = 2097152
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512
```

Apply: `sysctl -p /etc/sysctl.d/99-skydevops.conf`

---

## 3. Security Limits

```bash
# /etc/security/limits.d/99-skydevops.conf
*         soft    nofile      65535
*         hard    nofile      65535
*         soft    nproc       65535
*         hard    nproc       65535
root      soft    nofile      65535
root      hard    nofile      65535
www-data  soft    nofile      65535
www-data  hard    nofile      65535
mysql     soft    nofile      65535
mysql     hard    nofile      65535
```

Also update systemd service limits:
```bash
# /etc/systemd/system/<service>.service.d/limits.conf
[Service]
LimitNOFILE=65535
LimitNPROC=65535
```

---

## 4. Swap Configuration

### Recommendations by RAM
| RAM | Swap Size | swappiness |
|-----|-----------|------------|
| ≤ 2 GB | 2× RAM | 60 |
| 2–8 GB | = RAM | 30 |
| 8–32 GB | ½ RAM | 10 |
| > 32 GB | 4–8 GB fixed | 5 |

```bash
# Create swap file
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# Persist
echo '/swapfile none swap sw 0 0' >> /etc/fstab
echo 'vm.swappiness=10' >> /etc/sysctl.d/99-skydevops.conf
sysctl -p
```

---

## 5. Firewall (UFW)

```bash
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
# MySQL (only from specific IPs)
ufw allow from 10.0.0.0/8 to any port 3306
ufw --force enable
```

---

## 6. SSH Hardening

```bash
# /etc/ssh/sshd_config.d/99-skydevops.conf
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
X11Forwarding no
AllowAgentForwarding no
```

---

## 7. Systemd Service Optimization

### Nginx Service Hardening
```ini
# /etc/systemd/system/nginx.service.d/override.conf
[Service]
LimitNOFILE=65535
Restart=on-failure
RestartSec=5s
```

### MySQL Service Hardening
```ini
# /etc/systemd/system/mysql.service.d/override.conf
[Service]
LimitNOFILE=65535
LimitMEMLOCK=infinity
TimeoutStartSec=300
Restart=on-failure
RestartSec=10s
OOMScoreAdjust=-500
```

---

## 8. Disk I/O Optimization

### Scheduler for SSD
```bash
# Check current scheduler
cat /sys/block/sda/queue/scheduler

# Set to 'none' or 'mq-deadline' for SSD
echo 'none' > /sys/block/sda/queue/scheduler

# Persist via udev rule
cat > /etc/udev/rules.d/60-skydevops-iosched.rules <<EOF
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="mq-deadline"
EOF
```

### Mount Options for ext4
```
# /etc/fstab
UUID=... /  ext4  defaults,noatime,nodiratime  0  1
```

---

## 9. Network Optimization

### TCP BBR Congestion Control
```bash
modprobe tcp_bbr
echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
echo "net.core.default_qdisc=fq" >> /etc/sysctl.d/99-skydevops.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.d/99-skydevops.conf
sysctl -p
```

---

## 10. Log Management

### Journald Configuration
```bash
# /etc/systemd/journald.conf
[Journal]
SystemMaxUse=500M
SystemMaxFileSize=50M
MaxRetentionSec=30day
Compress=yes
```

### Logrotate for Nginx
```bash
# /etc/logrotate.d/nginx
/var/log/nginx/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data adm
    sharedscripts
    postrotate
        [ -f /var/run/nginx.pid ] && kill -USR1 `cat /var/run/nginx.pid`
    endscript
}
```

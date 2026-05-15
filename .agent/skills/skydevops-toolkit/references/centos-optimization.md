# CentOS / RHEL Server Optimization Reference

## Table of Contents
1. [System Update & Package Management](#1-system-update--package-management)
2. [Kernel Tuning (sysctl)](#2-kernel-tuning-sysctl)
3. [Security Limits](#3-security-limits)
4. [SELinux Configuration](#4-selinux-configuration)
5. [Firewall (firewalld)](#5-firewall-firewalld)
6. [SSH Hardening](#6-ssh-hardening)
7. [YUM/DNF Repository Management](#7-yumdnf-repository-management)
8. [Disk I/O & LVM Optimization](#8-disk-io--lvm-optimization)
9. [Network & TCP Tuning](#9-network--tcp-tuning)
10. [Service Management](#10-service-management)

---

## 1. System Update & Package Management

### Best Practices
```bash
# CentOS 7
yum update -y
yum install -y epel-release

# CentOS 8 / Stream / Rocky / AlmaLinux
dnf update -y
dnf install -y epel-release

# Essential tools
yum install -y curl wget yum-utils net-tools bind-utils \
    vim htop iotop sysstat lsof strace perf

# Auto-update for security
yum install -y yum-cron
# or dnf-automatic for CentOS 8+
systemctl enable --now yum-cron
```

### Version-Specific Package Managers
| CentOS Version | Package Manager | Notes |
|----------------|-----------------|-------|
| CentOS 7 | `yum` | EOL June 2024, use as-is |
| CentOS 8 Stream | `dnf` | `yum` is symlink to `dnf` |
| Rocky Linux 8/9 | `dnf` | RHEL-compatible drop-in |
| AlmaLinux 8/9 | `dnf` | RHEL-compatible drop-in |

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

# --- TCP Optimization ---
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# --- BBR (CentOS 8+ / Kernel 4.9+) ---
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# --- Memory ---
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.overcommit_memory = 1
vm.max_map_count = 262144

# --- File System ---
fs.file-max = 2097152
fs.inotify.max_user_watches = 524288
```

Apply: `sysctl --system`

> **CentOS 7 Note:** BBR requires kernel 4.9+. Install ELRepo and upgrade kernel first:
> ```bash
> yum install -y https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm
> yum --enablerepo=elrepo-kernel install -y kernel-ml
> grub2-set-default 0 && reboot
> ```

---

## 3. Security Limits

```bash
# /etc/security/limits.d/99-skydevops.conf
*         soft    nofile      65535
*         hard    nofile      65535
*         soft    nproc       65535
*         hard    nproc       65535

# CentOS 7 also needs:
# /etc/security/limits.d/20-nproc.conf
# Override the default 4096 limit:
*         soft    nproc       65535
```

### Systemd Service Override
```bash
mkdir -p /etc/systemd/system/nginx.service.d/
cat > /etc/systemd/system/nginx.service.d/limits.conf <<EOF
[Service]
LimitNOFILE=65535
LimitNPROC=65535
EOF
systemctl daemon-reload
```

---

## 4. SELinux Configuration

SELinux is enabled by default on CentOS. Work with it rather than disabling it.

### Check Status
```bash
getenforce
sestatus
```

### Common Permissions for Web Servers
```bash
# Allow Nginx to connect to upstream (PHP-FPM, proxy)
setsebool -P httpd_can_network_connect 1

# Allow Nginx to serve from non-standard directories
semanage fcontext -a -t httpd_sys_content_t "/var/www/mysite(/.*)?"
restorecon -Rv /var/www/mysite

# Allow Nginx to write to upload directory
semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/mysite/storage(/.*)?"
restorecon -Rv /var/www/mysite/storage

# Allow MySQL to use non-standard port
semanage port -a -t mysqld_port_t -p tcp 3307
```

### Troubleshooting
```bash
# Install troubleshooting tools
yum install -y setroubleshoot-server setools-console

# Check audit log for denials
ausearch -m avc -ts recent
sealert -a /var/log/audit/audit.log
```

> **Important:** Only set SELinux to `permissive` for debugging, never in production. If you must temporarily disable:
> ```bash
> setenforce 0  # Temporary (reverts on reboot)
> # NEVER use: sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
> ```

---

## 5. Firewall (firewalld)

```bash
# Enable firewalld
systemctl enable --now firewalld

# Allow common services
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-service=ssh

# Allow MySQL from specific subnet
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="10.0.0.0/8" port port="3306" protocol="tcp" accept'

# Reload
firewall-cmd --reload

# Verify
firewall-cmd --list-all
```

### Zone-Based Configuration
```bash
# Create a custom zone for database servers
firewall-cmd --permanent --new-zone=database
firewall-cmd --permanent --zone=database --add-source=10.0.0.0/8
firewall-cmd --permanent --zone=database --add-port=3306/tcp
firewall-cmd --permanent --zone=database --add-port=6379/tcp
firewall-cmd --reload
```

---

## 6. SSH Hardening

```bash
# /etc/ssh/sshd_config.d/99-skydevops.conf (CentOS 8+)
# For CentOS 7, edit /etc/ssh/sshd_config directly

PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
X11Forwarding no
AllowAgentForwarding no
UseDNS no
```

---

## 7. YUM/DNF Repository Management

### Adding Official Repos Safely
```bash
# Method 1: RPM package
yum install -y https://dev.mysql.com/get/mysql80-community-release-el$(rpm -E %rhel)-1.noarch.rpm

# Method 2: Manual repo file
cat > /etc/yum.repos.d/nginx.repo <<EOF
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
EOF

# Import GPG key
rpm --import https://nginx.org/keys/nginx_signing.key

# Verify
yum repolist
```

### Module Management (CentOS 8+)
```bash
# Disable default module to use 3rd-party repo
dnf module disable php -y
dnf module disable nginx -y
dnf module disable mysql -y

# Then install from custom repo
dnf install -y php
```

---

## 8. Disk I/O & LVM Optimization

### I/O Scheduler
```bash
# For SSD
echo 'none' > /sys/block/sda/queue/scheduler

# For HDD
echo 'mq-deadline' > /sys/block/sda/queue/scheduler

# Persistent via tuned
yum install -y tuned
tuned-adm profile throughput-performance  # For DB servers
tuned-adm profile latency-performance     # For web servers
```

### XFS (default on CentOS) Optimization
```
# /etc/fstab mount options
UUID=... / xfs defaults,noatime,nodiratime 0 0
```

---

## 9. Network & TCP Tuning

### Network Interface Tuning
```bash
# Increase ring buffer size
ethtool -G eth0 rx 4096 tx 4096

# Enable offloading
ethtool -K eth0 gso on gro on tso on

# Persistent via NetworkManager
nmcli connection modify eth0 ethtool.feature-gro on
nmcli connection modify eth0 ethtool.feature-tso on
```

### TCP BBR (CentOS 8+)
```bash
modprobe tcp_bbr
echo "tcp_bbr" >> /etc/modules-load.d/bbr.conf
# sysctl values already in section 2
```

---

## 10. Service Management

### Disable Unnecessary Services
```bash
systemctl disable --now postfix
systemctl disable --now avahi-daemon
systemctl disable --now cups
systemctl disable --now bluetooth
```

### Service Priority Tuning
```bash
# Nginx — high priority
cat > /etc/systemd/system/nginx.service.d/priority.conf <<EOF
[Service]
Nice=-10
CPUSchedulingPolicy=other
IOSchedulingClass=realtime
EOF

# MySQL — prevent OOM killing
cat > /etc/systemd/system/mysqld.service.d/oom.conf <<EOF
[Service]
OOMScoreAdjust=-500
EOF

systemctl daemon-reload
```

### Health Check Script Pattern
```bash
#!/bin/bash
# /opt/skydevops/healthcheck.sh

check_service() {
    local svc=$1
    if systemctl is-active --quiet "$svc"; then
        echo "✔ $svc: running"
    else
        echo "✘ $svc: DOWN"
        systemctl restart "$svc" || echo "  Failed to restart $svc"
    fi
}

check_service nginx
check_service mysqld
check_service php-fpm
check_service docker
```

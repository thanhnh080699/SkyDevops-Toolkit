# SkyDevOps Toolkit

**SkyDevOps Toolkit** là bộ công cụ CLI viết bằng Bash giúp SysAdmin, DevOps Engineer và đội vận hành cài đặt, tối ưu và kiểm tra nhanh các thành phần phổ biến trên máy chủ Linux.

Công cụ tập trung vào 3 nhóm việc chính:

- **Cài đặt phần mềm máy chủ** từ repository chính thức.
- **Tối ưu cấu hình theo phần cứng thực tế** như vCPU, RAM, disk SSD/HDD.
- **Kiểm tra tình trạng hệ thống** bằng các công cụ chẩn đoán thường dùng.

---

## Tính Năng Chính

### Cài Đặt Tự Động

SkyDevOps Toolkit hỗ trợ cài đặt các thành phần phổ biến:

| Nhóm | Hỗ trợ |
|---|---|
| Nginx | Stable / Mainline |
| Apache2 | Install / Update |
| MariaDB | Lấy phiên bản động từ official API |
| MySQL | 8.0 / 8.4 LTS |
| Docker | Docker CE, Compose, Buildx |
| PHP | Multi-version 7.2 đến 8.3, PHP-FPM, extension phổ biến |
| Node.js | NVM, PM2, Yarn, PNPM |

Các installer được thiết kế theo hướng:

- Tự nhận diện Ubuntu/Debian hoặc CentOS/RHEL/Rocky/AlmaLinux.
- Dùng repository chính thức khi có thể.
- Có cơ chế xử lý GPG/repository phổ biến.
- Không hardcode `sudo`; toolkit tự xử lý quyền qua biến `$SUDO`.

---

## Tối Ưu Hiệu Năng

Các mục tối ưu hiện có trong menu:

| Menu | Chức năng |
|---|---|
| `8. Tối ưu Nginx` | Tối ưu worker, connection, gzip, upload limit, epoll |
| `9. Tối ưu MariaDB` | Tối ưu InnoDB, IO, cache, timeout, slow query |
| `10. Tối ưu PHP` | Scan PHP-FPM đã cài và tối ưu version được chọn |
| `11. Tối ưu MySQL` | Tối ưu InnoDB, redo log, IO, cache, timeout, slow query |

### Cách Tối Ưu Hoạt Động

Trước khi áp dụng thay đổi, toolkit sẽ:

1. Kiểm tra phần mềm đã được cài đặt hay chưa.
2. Lấy thông số phần cứng như vCPU, RAM và loại disk khi có thể.
3. Tính toán giá trị đề xuất.
4. Hiển thị từng tham số với:
   - Ý nghĩa dễ hiểu cho client.
   - Giá trị hiện tại.
   - Giá trị đề xuất.
   - Cho phép nhập giá trị tùy chỉnh.
5. Hiển thị bảng diff trước khi áp dụng.
6. Backup cấu hình trước khi ghi.
7. Áp dụng cấu hình, restart/reload service phù hợp.
8. Nếu lỗi, hiển thị log, rollback cấu hình và chờ người dùng xác nhận.

### File Cấu Hình Tối Ưu DB

MariaDB và MySQL dùng file include riêng để dễ quản lý:

| Dịch vụ | File |
|---|---|
| MariaDB Ubuntu/Debian | `/etc/mysql/mariadb.conf.d/99-optimize_mariadb.cnf` |
| MariaDB RHEL/CentOS | `/etc/my.cnf.d/99-optimize_mariadb.cnf` |
| MySQL Ubuntu/Debian | `/etc/mysql/mysql.conf.d/99-optimize_mysql.cnf` hoặc `/etc/mysql/conf.d/99-optimize_mysql.cnf` |
| MySQL RHEL/CentOS | `/etc/my.cnf.d/99-optimize_mysql.cnf` |

---

## Công Cụ Kiểm Tra Hệ Thống

Cột **KIỂM TRA** cung cấp tối đa 8 công cụ chẩn đoán thường dùng:

| Menu | Công cụ | Nội dung |
|---|---|---|
| `12` | Tổng quan | OS, kernel, hostname, uptime, CPU/RAM |
| `13` | CPU/RAM/Process | Memory/swap và top process theo CPU/RAM |
| `14` | Disk & Inode | Dung lượng filesystem, inode, block devices, thư mục lớn |
| `15` | Network & Ports | IP, route, DNS, port đang listen |
| `16` | Services | Trạng thái service quan trọng và failed units |
| `17` | Firewall | UFW, firewalld, iptables |
| `18` | Updates/Sec | Gói có thể cập nhật và security updates |
| `19` | Runtime Stack | Version Web/DB/PHP/Node/Docker và container đang chạy |

Các công cụ kiểm tra là read-only, không tự cài đặt hay thay đổi hệ thống.

---

## Giao Diện CLI

Toolkit sử dụng UI dạng bảng 3 cột:

- **CÀI ĐẶT**: cài mới hoặc cài lại phần mềm.
- **TỐI ƯU**: tinh chỉnh cấu hình theo phần cứng.
- **KIỂM TRA**: xem nhanh tình trạng hệ thống.

Đặc điểm UI:

- Tự căn chỉnh theo chiều rộng terminal.
- Hiển thị trạng thái phần mềm đã cài.
- Có màu sắc phân biệt success/warning/error.
- Các bước thực thi quan trọng luôn hiển thị log và chờ người dùng đọc kết quả.

---

## Cấu Trúc Dự Án

```text
.
├── main.sh
├── core/
│   ├── ui.sh
│   ├── os.sh
│   └── utils.sh
├── plugins/
│   ├── apache2/
│   ├── docker/
│   ├── mariadb/
│   ├── mysql/
│   ├── nginx/
│   ├── nodejs/
│   ├── php/
│   └── system/
│       └── check.sh
├── .agent/
│   └── skills/
└── LICENSE
```

Mỗi plugin thường có:

```text
plugins/<software>/
├── install.sh
├── optimize.sh
└── scripts/
    └── install_<software>.sh
```

---

## Yêu Cầu Hệ Thống

Khuyến nghị:

- Ubuntu/Debian hoặc CentOS/RHEL/Rocky/AlmaLinux.
- Bash shell.
- Quyền root hoặc user có `sudo`.
- Kết nối internet khi cài đặt phần mềm từ repository.

Một số lệnh kiểm tra có fallback nhẹ cho môi trường local/dev, nhưng mục tiêu chính vẫn là Linux server.

---

## Cách Chạy

```bash
chmod +x main.sh
./main.sh
```

Nếu chạy bằng user thường, toolkit sẽ dùng `sudo` khi cần. Nếu chạy bằng root, toolkit thực thi trực tiếp.

---

## Nguyên Tắc An Toàn

- Luôn backup cấu hình trước khi ghi.
- Không ẩn log lỗi quan trọng khi áp dụng cấu hình.
- Nếu restart service thất bại, hiển thị trạng thái service và rollback khi có thể.
- Không dùng `mariadbd --validate-config` hoặc `mysqld --validate-config` vì tùy phiên bản/distro có thể không hỗ trợ.
- Không tự động cài update trong mục kiểm tra hệ thống.

---

## Tác Giả

Dự án được phát triển bởi **thanhnh**.

Website: [https://thanhnh.id.vn](https://thanhnh.id.vn)


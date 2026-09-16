\# Hướng dẫn SQL - E-commerce OLTP



\## 1. Giới thiệu



Thư mục này chứa các SQL script dùng để tạo và kiểm tra cơ sở dữ liệu

OLTP cho hệ thống thương mại điện tử.



File SQL chính:



`sql/student/01\_create\_oltp.sql`





\## 2. Yêu cầu trước khi chạy



Cần chuẩn bị:



\- Docker đã được cài đặt và đang chạy.

\- PostgreSQL 16 được khởi động bằng Docker Compose.

\- DBeaver được cài đặt để kết nối và thực thi SQL.



\## 3. Khởi động PostgreSQL



Từ thư mục gốc của project, chạy:



```bash

docker compose up -d postgres


docker compose ps ## để kiểm tra trạng thái




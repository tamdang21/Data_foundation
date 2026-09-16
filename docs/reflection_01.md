1.Trong quá trình thực hiện bài tập, khó khăn lớn nhất của em là kết nối PostgreSQL từ Docker với DBeaver. Ban đầu DBeaver báo lỗi xác thực mật khẩu và sau đó gặp lỗi TimeZone. Em đã kiểm tra container, tài khoản PostgreSQL và thay đổi port kết nối để xác định nguyên nhân, cuối cùng kết nối thành công.



2.Với data type, em chọn NUMERIC cho tiền tệ vì cần lưu giá trị chính xác, tránh sai số khi tính toán. Ví dụ unit\_price NUMERIC(14,2) có thể lưu giá sản phẩm với hai chữ số thập phân. Thời gian sử dụng TIMESTAMPTZ để lưu ngày giờ kèm múi giờ. ID sử dụng VARCHAR vì các mã như customer\_id, product\_id có thể chứa cả chữ và số.



3\.Quan hệ 1:N giữa customers và orders nghĩa là một khách hàng có thể có nhiều đơn hàng, nhưng mỗi đơn hàng thuộc về một khách hàng. Ví dụ customer C001 có các order O001, O002 và O003.



4.Nếu schema cần thay đổi, em sẽ ưu tiên dùng ALTER TABLE cho các thay đổi nhỏ như thêm cột hoặc thêm constraint. Khi thay đổi lớn ảnh hưởng nhiều đến cấu trúc và dữ liệu, em sẽ cân nhắc tạo lại hoặc migration có kiểm soát để tránh mất dữ liệu.


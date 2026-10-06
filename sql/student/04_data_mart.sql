-- GRAIN: theo Order_item một dòng là một sản phẩm trong 1 đơn hàng  (Vì sau này có thể dễ ràng tính doanh thu theo sản phẩm/ doanh thu theo category/ theo đơn hàng/ theo số lượng/ theo ngày bán ra,...)
CREATE table IF NOT EXISTS dim_date (
    date_key INT PRIMARY KEY,
    full_date DATE NOT NULL,
    day INT NOT NULL,
    month INT NOT NULL,
    quarter INT NOT NULL,
    year INT NOT NULL
);
-- BUSINESS LOGIC:
-- Grain: 1 dòng đại diện cho 1 ngày.
-- Dùng để phân tích doanh thu và số lượng bán theo ngày, tháng, quý và năm.
--
-- TRANSFORMATION:
-- full_date được tạo từ khoảng thời gian phân tích của Data Mart.
-- date_key được tạo theo định dạng YYYYMMDD từ full_date.
-- day, month, quarter và year được suy ra từ full_date.

CREATE table IF NOT EXISTS dim_customer (
    customer_key SERIAL PRIMARY KEY,
    customer_id varchar(12) not null unique,
    full_name varchar(150) not null,
    email varchar(200) not null,
    phone varchar(30),
    city varchar(100) , 
    customer_segment varchar(30) not null,
    status varchar(50) not null,
    dm_create_time timestamptz DEFAULT CURRENT_TIMESTAMP ,
    dm_update_time timestamptz DEFAULT CURRENT_TIMESTAMP
    
);
-- BUSINESS LOGIC:
-- Grain: 1 dòng đại diện cho 1 khách hàng.
-- Lưu các thuộc tính mô tả khách hàng để phân tích doanh thu và hành vi mua hàng
-- theo khách hàng, thành phố, phân khúc và trạng thái.
--
-- TRANSFORMATION:
-- customer_id, full_name, email, phone, city, customer_segment và status
-- được lấy từ bảng customers và map tương ứng sang dimension.
-- customer_key là surrogate key do Data Mart tự sinh.

CREATE TABLE  IF NOT exists dim_product (
    product_key SERIAL PRIMARY key,
    product_id varchar(12) not null  unique,
    category_id VARCHAR(10) NOT NULL,
    category_name VARCHAR(150),
    product_name varchar(200) not null,
    unit_price numeric(12,2) not null,
    cost_price numeric(12,2) not null,
    status varchar(20) not null,
    dm_create_time timestamptz default current_timestamp ,
    dm_update_time timestamptz default current_timestamp 
);
-- BUSINESS LOGIC:
-- Grain: 1 dòng đại diện cho 1 sản phẩm.
-- Lưu thông tin sản phẩm và danh mục để phân tích doanh thu, số lượng
-- theo sản phẩm và category.
--
-- TRANSFORMATION:
-- product_id, category_id, product_name, unit_price, cost_price và status
-- được lấy từ bảng products.
-- category_name được lấy từ bảng categories thông qua category_id.
-- category information được denormalize vào dim_product vì Data Mart
-- chỉ sử dụng 5 dimensions theo yêu cầu của bài.
-- product_key là surrogate key do Data Mart tự sinh.

CREATE TABLE IF NOT EXISTS dim_payment_method (
    payment_key SERIAL PRIMARY KEY,
    payment_method VARCHAR(30) NOT NULL,
    payment_status VARCHAR(20),

    dm_create_time TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    dm_update_time TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
-- BUSINESS LOGIC:
-- Grain: 1 dòng đại diện cho 1 phương thức thanh toán.
-- Dùng để phân tích doanh thu và số lượng giao dịch theo phương thức thanh toán.
--
-- TRANSFORMATION:
-- payment_method được lấy từ payments.payment_method.
-- Các trường mang tính giao dịch như payment_id, order_id, payment_date
-- và amount không đưa vào dimension vì chúng thuộc mức transaction.
-- payment_key là surrogate key do Data Mart tự sinh.
CREATE TABLE IF NOT exists dim_order_status (
    order_status_key SERIAL PRIMARY KEY,
    status VARCHAR(20) NOT NULL UNIQUE,

    dm_create_time TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    dm_update_time TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
-- BUSINESS LOGIC:
-- Grain: 1 dòng đại diện cho 1 trạng thái đơn hàng.
-- Dùng để phân tích doanh thu, số lượng đơn hàng theo trạng thái.
--
-- TRANSFORMATION:
-- status được lấy từ orders.status.
-- Chỉ giữ các giá trị trạng thái duy nhất để tạo dimension.
-- order_status_key là surrogate key do Data Mart tự sinh.
CREATE TABLE IF NOT exists fact_sales (
   date_key int not null,
   customer_key INT NOT NULL,
   product_key INT NOT NULL,
   payment_key INT NOT NULL,
   order_status_key INT NOT NULL,
   order_id varchar(12) not null,
   quantity int not null,
   unit_price NUMERIC(12,2) NOT NULL,
   revenue NUMERIC(12,2) NOT NULL,
   discount NUMERIC(12,2) NOT NULL,
   shipping_city VARCHAR(100),
   channel VARCHAR(20),
   foreign key (date_key) references dim_date(date_key),
   FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key),
   FOREIGN KEY (product_key)
       REFERENCES dim_product(product_key),
   FOREIGN KEY (payment_key)
       REFERENCES dim_payment_method(payment_key),
   FOREIGN KEY (order_status_key)
      REFERENCES dim_order_status(order_status_key)
);
-- BUSINESS LOGIC:
-- Grain: 1 dòng trong fact_sales đại diện cho 1 sản phẩm trong 1 đơn hàng (order_item).
-- Fact lưu các measures phục vụ phân tích doanh thu, số lượng và giảm giá.
-- order_id được giữ trực tiếp trong Fact như một degenerate dimension.
--
-- TRANSFORMATION:
-- quantity, unit_price và discount được lấy từ order_items.
-- revenue được tính ở mức order_item theo công thức:
-- quantity * unit_price - discount_amount.
--
-- date_key được mapping từ orders.order_date sang dim_date.
-- customer_key được mapping từ orders.customer_id sang dim_customer.
-- product_key được mapping từ order_items.product_id sang dim_product.
-- payment_key được mapping từ payment_method sang dim_payment_method.
-- order_status_key được mapping từ orders.status sang dim_order_status.
--
-- shipping_city và channel được lấy từ orders và giữ ở Fact
-- để phục vụ phân tích theo thành phố giao hàng và kênh bán hàng.







--1.3 Data Loading - Load từ OLTP + verify row counts
-- dim_date
INSERT INTO dm_sales.dim_date (
    date_key,
    full_date,
    day,
    month,
    quarter,
    year
)
SELECT
    TO_CHAR(gs.full_date, 'YYYYMMDD')::INT AS date_key,
    gs.full_date,
    EXTRACT(DAY FROM gs.full_date)::INT AS day,
    EXTRACT(MONTH FROM gs.full_date)::INT AS month,
    EXTRACT(QUARTER FROM gs.full_date)::INT AS quarter,
    EXTRACT(YEAR FROM gs.full_date)::INT AS year
FROM generate_series(
    (SELECT MIN(order_date::DATE) FROM core.orders),
    (SELECT MAX(order_date::DATE) FROM core.orders),
    INTERVAL '1 day'
) AS gs(full_date);
insert into dim_customer (
    customer_id ,
    full_name ,
    email,
    phone ,
    city, 
    customer_segment,
    status 
) select  customer_id,c.full_name ,c.email ,c.phone ,c.city ,c.customer_segment ,c.status  
from core.customers c ;
INSERT INTO dm_sales.dim_product (
    product_id,
    category_id,
    category_name,
    product_name,
    unit_price,
    cost_price,
    status
)
SELECT
    p.product_id,
    p.category_id,
    c.category_name,
    p.product_name,
    p.unit_price,
    p.cost_price,
    p.status
FROM core.products p
LEFT JOIN core.categories c
    ON p.category_id = c.category_id;
INSERT INTO dm_sales.dim_payment_method (
    payment_method
)
SELECT DISTINCT
    payment_method
FROM core.payments
WHERE payment_method IS NOT NULL;
INSERT INTO dm_sales.dim_order_status (
    status
)
SELECT DISTINCT
    status
FROM core.orders
WHERE status IS NOT NULL;INSERT INTO dm_sales.fact_sales (
    date_key,
    customer_key,
    product_key,
    payment_key,
    order_status_key,
    order_id,
    quantity,
    unit_price,
    revenue,
    discount,
    shipping_city,
    channel
)
SELECT
    d.date_key,
    dc.customer_key,
    dp.product_key,
    dpm.payment_key,
    dos.order_status_key,

    o.order_id,

    oi.quantity,
    oi.unit_price,
    oi.quantity * oi.unit_price - oi.discount_amount AS revenue,
    oi.discount_amount AS discount,

    o.shipping_city,
    o.channel

FROM core.order_items oi

JOIN core.orders o
    ON oi.order_id = o.order_id

JOIN core.products p
    ON oi.product_id = p.product_id

JOIN core.payments pay
    ON o.order_id = pay.order_id

JOIN dm_sales.dim_date d
    ON d.full_date = o.order_date::DATE

JOIN dm_sales.dim_customer dc
    ON dc.customer_id = o.customer_id

JOIN dm_sales.dim_product dp
    ON dp.product_id = oi.product_id

JOIN dm_sales.dim_payment_method dpm
    ON dpm.payment_method = pay.payment_method

JOIN dm_sales.dim_order_status dos
    ON dos.status = o.status;
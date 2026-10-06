--thêm 2 trường 
ALTER TABLE dm_sales.dim_product
ADD COLUMN valid_from DATE,
ADD COLUMN valid_to DATE,
ADD COLUMN is_current BOOLEAN;
--gán trạng thái cho dữ liệu hiện tại
UPDATE dm_sales.dim_product
SET
    valid_from = DATE '2026-01-01',
    valid_to = NULL,
    is_current = TRUE;
-- bỏ unique
ALTER TABLE dm_sales.dim_product
DROP CONSTRAINT dim_product_product_id_key;
-- giả lập đổi giá
UPDATE dm_sales.dim_product
SET
    valid_to = DATE '2026-10-05',
    is_current = FALSE
WHERE product_id = 'PRD000118'
  AND is_current = TRUE;

--kiểm tra
SELECT
    product_id,
    product_name,
    unit_price,
    valid_from,
    valid_to,
    is_current
FROM dm_sales.dim_product
WHERE product_id = 'PRD000118';

INSERT INTO dm_sales.dim_product (
    product_id,
    category_id,
    category_name,
    product_name,
    unit_price,
    cost_price,
    status,
    valid_from,
    valid_to,
    is_current
)
SELECT
    product_id,
    category_id,
    category_name,
    product_name,
    12000000,
    cost_price,
    status,
    DATE '2026-10-06',
    NULL,
    TRUE
FROM dm_sales.dim_product
WHERE product_id = 'PRD000118'
  AND is_current = FALSE
  AND valid_to = DATE '2026-10-05';

SELECT
    product_key,
    product_id,
    product_name,
    unit_price,
    valid_from,
    valid_to,
    is_current
FROM dm_sales.dim_product
WHERE product_id = 'PRD000118'
ORDER BY valid_from;
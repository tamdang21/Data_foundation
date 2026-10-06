--1. Total revenue by month (dim_date.month).
select dd.month , Sum(t.revenue) 
from dm_sales.fact_sales t join dm_sales.dim_date dd on t.date_key =dd.date_key 
group by dd.month ;
--2. Revenue by category (qua dim_product.category).
select dp.category_name , sum (t.revenue ) 
from dm_sales.fact_sales t join dm_sales.dim_product dp on t.product_key =dp.product_key 
group by dp.category_name ;
--3. Top 10 products theo revenue.
select dp.product_name  , sum (t.revenue ) 
from dm_sales.fact_sales t join dm_sales.dim_product dp on t.product_key =dp.product_key 
group by dp.product_name 
limit 10;
--4. AOV (SUM(revenue)/COUNT(DISTINCT order_id)).
SELECT
    SUM(revenue) / COUNT(DISTINCT order_id) AS aov
FROM dm_sales.fact_sales;
--5. Customer count by segment/region (nếu không có region: count by dim_order_status + ghi chú).
select dc.customer_segment ,dc.city , count(distinct dc.customer_id )
from dm_sales.dim_customer dc 
group by dc.customer_segment ,dc.city;
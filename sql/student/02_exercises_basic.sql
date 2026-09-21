-- Q1: tất cả orders có total_amount > 100
select * from core.orders o 
where o.order_total > 100

-- Q2: customers chưa có order nào
select * 
from core.customers c left join core.orders o  on c.customer_id = o.customer_id 
where o.order_id  is null

-- Q3:  top 10 customers theo tổng chi tiêu 
select *
from core.customers c  join core.orders o  on c.customer_id =o.customer_id 
order by o.order_total desc
limit 10;

--Q4:  đếm số customers khác nhau có đơn hàng 
select Count(distinct (c.customer_id ))
from customers c left join orders o  on c.customer_id =o.customer_id
where o.order_id  is not null;

-- Q5: 5 orders mới nhất theo order_date
select *
from orders o 
order by o.order_date desc
limit 5;

--Q6: tổng doanh thu theo từng tháng
select Sum(o.order_total ) as Total_revenue, extract(month from o.order_date) as Month
from orders o 
group by extract(month from o.order_date)
order by Month desc ;
--Q7 : Trung bình giá trị đơn hàng theo từng customer
select c.customer_id ,c.full_name ,avg(o.order_total) as  avg_order
from customers c join orders o on c.customer_id =o.customer_id 
group by c.customer_id ;
-- Q8: Số lượng đơn hàng theo từng order_status.
select o.status ,count(*)
from orders o 
group by o.status ;
--Q9: Tổng doanh thu theo category 
select p.category_id , sum(o.order_total ) as Total_revenue
from products p join order_items oi on p.product_id =oi.product_id 
join orders o on o.order_id =oi.order_id 
group by p.category_id 
order by Total_revenue desc; 
--Q10: HAVING: categories có tổng doanh thu > 1000
select p.category_id , sum(o.order_total ) as Total_revenue
from products p join order_items oi on p.product_id =oi.product_id 
join orders o on o.order_id =oi.order_id 
group by p.category_id 
having sum(o.order_total ) >1000
order by Total_revenue desc;

--Q11: Liệt kê orders kèm customer_name, customer_email (orders JOIN customers).
select o.* ,c.full_name ,c.email 
from orders o join customers c on o.customer_id =c.customer_id ;
--Q12: Chi tiết từng order_item kèm product_name, price (order_items JOIN products).
select oi.*,p.product_name ,p.unit_price 
from order_items oi join products p on oi.product_id =p.product_id ;
--Q13: Orders có payments nhưng chưa có order_items (hoặc ngược lại) - dùng LEFT JOIN + IS NULL 1 phía.
SELECT 
    p.order_id
FROM payments p
LEFT JOIN order_items oi
    ON p.order_id = oi.order_id
WHERE oi.order_item_id IS NULL;
--Q14Products chưa từng được bán (products LEFT JOIN order_items ... WHERE order_items.id IS NULL).
select p.*,oi.order_item_id 
from products p left join order_items oi on oi.product_id =p.product_id 
where oi.order_item_id  IS null;
--Q15Đối soát: total order value = SUM(order_items quantity*price) theo từng order (GROUP BY order_id), so với orders.total_amount.
select oi.order_id ,SUM(oi.quantity*(oi.unit_price -oi.discount_amount )) as total_order_value
from order_items oi 
group by oi.order_id 
order by oi.order_id asc;
select o.order_id ,sum(o.order_total ) as total_revenue
from orders o 
group by o.order_id 
order by o.order_id asc;



--1 Total revenue tháng 7/2026 là bao nhiêu?

select extract(month from o.order_date ) as month, Sum(o.order_total) as Total_revenue
from orders o
where extract(month from o.order_date ) = 7 
group by month ;
-- Tháng 7 chưa có dữ liệu do đó doanh thu tháng 7 bằng 0
--2 Customer nào có tổng chi tiêu cao nhất (id + tên + số tiền)?
select c.customer_id ,c.full_name ,o.order_total 
from core.customers c  join core.orders o  on c.customer_id =o.customer_id 
order by o.order_total desc
limit 1;
-- Khánh hàng có customer_id = CUS000569 với tên là Michelle Patel với tổng chi tiêu là 51170000
--3 Category nào có số lượng orders cao nhất?
select p.category_id,c.category_name  , Count(*) as Total_order
from products p join order_items oi on p.product_id =oi.product_id 
join categories c on c.category_id =p.category_id 
group by p.category_id , c.category_name
order by Total_order desc; 
--Category có id = CAT012 có số lượt mua cao nahast là 1144 đơn
--4 Average order value (AOV) là bao nhiêu?
SELECT 
    AVG(o.order_total) AS AOV
FROM orders o;
-- Giá trị trung bình đơn hàng là 12341286.4
--5 Có bao nhiêu customers có hơn 3 orders?
SELECT 
    COUNT(*) AS number_of_customers
FROM (
    SELECT 
        o.customer_id
    FROM orders o
    GROUP BY o.customer_id
    HAVING COUNT(o.order_id) > 3
) AS customer_orders;
-- có 719 khách hàng mua trên 3 đơn
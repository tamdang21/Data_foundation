\--Query 1 — OLTP

EXPLAIN ANALYZE

SELECT

&#x20;   EXTRACT(YEAR FROM o.order\_date) AS year,

&#x20;   EXTRACT(MONTH FROM o.order\_date) AS month,

&#x20;   SUM(oi.quantity \* oi.unit\_price - oi.discount\_amount) AS revenue

FROM core.orders o

JOIN core.order\_items oi

&#x20;   ON o.order\_id = oi.order\_id

JOIN core.products p

&#x20;   ON oi.product\_id = p.product\_id

JOIN core.payments pay

&#x20;   ON o.order\_id = pay.order\_id

GROUP BY

&#x20;   EXTRACT(YEAR FROM o.order\_date),

&#x20;   EXTRACT(MONTH FROM o.order\_date)

ORDER BY

&#x20;   year,

&#x20;   month;

\--kết quả



Sort  (cost=1495.57..1507.86 rows=4915 width=96) (actual time=27.123..27.135 rows=6 loops=1)

&#x20; Sort Key: (EXTRACT(year FROM o.order\_date)), (EXTRACT(month FROM o.order\_date))

&#x20; Sort Method: quicksort  Memory: 25kB

&#x20; ->  HashAggregate  (cost=1108.19..1194.21 rows=4915 width=96) (actual time=27.062..27.107 rows=6 loops=1)

&#x20;       Group Key: EXTRACT(year FROM o.order\_date), EXTRACT(month FROM o.order\_date)

&#x20;       Batches: 1  Memory Usage: 217kB

&#x20;       ->  Hash Join  (cost=388.25..935.86 rows=11489 width=78) (actual time=5.147..19.657 rows=11472 loops=1)

&#x20;             Hash Cond: ((oi.product\_id)::text = (p.product\_id)::text)

&#x20;             ->  Hash Join  (cost=369.00..828.75 rows=11489 width=32) (actual time=4.886..11.737 rows=11472 loops=1)

&#x20;                   Hash Cond: ((oi.order\_id)::text = (o.order\_id)::text)

&#x20;                   ->  Seq Scan on order\_items oi  (cost=0.00..297.17 rows=12717 width=34) (actual time=0.004..1.483 rows=12717 loops=1)

&#x20;                   ->  Hash  (cost=312.54..312.54 rows=4517 width=28) (actual time=4.854..4.860 rows=4517 loops=1)

&#x20;                         Buckets: 8192  Batches: 1  Memory Usage: 329kB

&#x20;                         ->  Hash Join  (cost=190.50..312.54 rows=4517 width=28) (actual time=1.759..3.548 rows=4517 loops=1)

&#x20;                               Hash Cond: ((pay.order\_id)::text = (o.order\_id)::text)

&#x20;                               ->  Seq Scan on payments pay  (cost=0.00..110.17 rows=4517 width=10) (actual time=0.004..0.519 rows=4517 loops=1)

&#x20;                               ->  Hash  (cost=128.00..128.00 rows=5000 width=18) (actual time=1.724..1.726 rows=5000 loops=1)

&#x20;                                     Buckets: 8192  Batches: 1  Memory Usage: 309kB

&#x20;                                     ->  Seq Scan on orders o  (cost=0.00..128.00 rows=5000 width=18) (actual time=0.009..0.752 rows=5000 loops=1)

&#x20;             ->  Hash  (cost=13.00..13.00 rows=500 width=10) (actual time=0.223..0.224 rows=500 loops=1)

&#x20;                   Buckets: 1024  Batches: 1  Memory Usage: 29kB

&#x20;                   ->  Seq Scan on products p  (cost=0.00..13.00 rows=500 width=10) (actual time=0.012..0.088 rows=500 loops=1)

Planning Time: 1.308 ms

Execution Time: 27.321 ms

\--Query 2 — Data Mart

EXPLAIN ANALYZE

SELECT

&#x20;   d.year,

&#x20;   d.month,

&#x20;   SUM(f.revenue) AS revenue

FROM dm\_sales.fact\_sales f

JOIN dm\_sales.dim\_date d

&#x20;   ON f.date\_key = d.date\_key

GROUP BY

&#x20;   d.year,

&#x20;   d.month

ORDER BY

&#x20;   d.year,

&#x20;   d.month;

\--kết quả:

Sort  (cost=379.79..379.80 rows=6 width=40) (actual time=6.961..6.965 rows=6 loops=1)

&#x20; Sort Key: d.year, d.month

&#x20; Sort Method: quicksort  Memory: 25kB

&#x20; ->  HashAggregate  (cost=379.64..379.71 rows=6 width=40) (actual time=6.930..6.935 rows=6 loops=1)

&#x20;       Group Key: d.year, d.month

&#x20;       Batches: 1  Memory Usage: 24kB

&#x20;       ->  Hash Join  (cost=6.05..293.60 rows=11472 width=14) (actual time=0.135..4.144 rows=11472 loops=1)

&#x20;             Hash Cond: (f.date\_key = d.date\_key)

&#x20;             ->  Seq Scan on fact\_sales f  (cost=0.00..256.72 rows=11472 width=10) (actual time=0.016..1.183 rows=11472 loops=1)

&#x20;             ->  Hash  (cost=3.80..3.80 rows=180 width=12) (actual time=0.064..0.065 rows=180 loops=1)

&#x20;                   Buckets: 1024  Batches: 1  Memory Usage: 16kB

&#x20;                   ->  Seq Scan on dim\_date d  (cost=0.00..3.80 rows=180 width=12) (actual time=0.008..0.033 rows=180 loops=1)

Planning Time: 0.542 ms

Execution Time: 7.032 ms



### Nhận xét

Query trên Data Mart có Execution Time thấp hơn OLTP. Nguyên nhân là dữ liệu đã được tổ chức theo mô hình Star Schema và các phép tính doanh thu đã được chuẩn hóa ở Fact, giúp giảm số lượng JOIN và chi phí xử lý.


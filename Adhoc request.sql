-- Request 1
SELECT customer, market, region 
FROM dim_customer
WHERE customer like "Atliq Exclusive"
AND region like "APAC"
GROUP BY market;

-- Request 2
WITH cte1 AS
(SELECT count(DISTINCT product_code) as unique_product_2020
FROM fact_sales_monthly
WHERE fiscal_year=2020),
cte2 AS(SELECT count(DISTINCT product_code) as unique_product_2021
FROM fact_sales_monthly
WHERE fiscal_year=2021)
SELECT 
unique_product_2020,
unique_product_2021,
round((unique_product_2021-unique_product_2020)/unique_product_2020*100,2) as percentage_chg
from cte1, cte2;

-- Request 3
SELECT segment,
COUNT(DISTINCT product_code) as product_count
FROM dim_product
group by segment
ORDER BY product_count DESC;

-- Request 4
WITH cte1 AS
(SELECT p.segment,
count(DISTINCT s.product_code) as product_count_2020
FROM fact_sales_monthly s
join dim_product p
on s.product_code=p.product_code
WHERE fiscal_year=2020
group by segment),
cte2 AS(SELECT p.segment,
count(DISTINCT s.product_code) as product_count_2021
FROM fact_sales_monthly s
join dim_product p
on s.product_code=p.product_code
WHERE fiscal_year=2021
group by segment)
SELECT 
2020_c.segment,
product_count_2020,
product_count_2021,
product_count_2021-product_count_2020 as difference
from cte1 2020_c
join cte2 2020_d
on 2020_c.segment=2020_d.segment
ORDER BY difference DESC
;
-- Request 5
SELECT m.product_code,
p.product, round(m.manufacturing_cost,2) as manufacturing_cost
FROM fact_manufacturing_cost m
join dim_product p
on p.product_code=m.product_code
where manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost)
OR manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)
order by manufacturing_cost desc;

-- Request 6
SELECT d.customer_code, c.customer,
ROUND(AVG(pre_invoice_discount_pct)*100,2) as average_discount_percentage
FROM gdb023.fact_pre_invoice_deductions d
JOIN dim_customer c 
ON d.customer_code=c.customer_code
where c.market= "india" AND d.fiscal_year= 2021
GROUP BY c.customer, d.customer_code
ORDER BY average_discount_percentage DESC
LIMIT 5;

-- Request 7
SELECT monthname(s.date) as month, year(s.date) as year,
ROUND(SUM(gross_price*sold_quantity)/1000000,2) as gross_sales_amount_inmillion 
FROM fact_sales_monthly s
JOIN fact_gross_price p
on p.product_code=s.product_code and
 p.fiscal_year=s.fiscal_year
 JOIN dim_customer c
on c.customer_code=s.customer_code
 WHERE c.customer= 'Atliq Exclusive' 
 GROUP BY monthname(s.date), year(s.date)
 order by year, field(month, 'January', 'February', 'March', 'April', 'May',
 'June', 'July', 'August','September', 'October','November', 'December');
 
 -- Request 8
  SELECT CASE 
        WHEN MONTH(date) in (9,10,11) then "Q1"
        WHEN MONTH(date) in (12,1,2) then "Q2"
        WHEN MONTH(date) in (3,4,5) then "Q3"
        else "Q4"
        END AS quarter, 
	sum(sold_quantity) as total_sold_quantity
    from fact_sales_monthly 
    WHERE fiscal_year= 2020
    GROUP BY quarter
    ORDER BY quarter;
    
-- Request 9
WITH cte1 AS (SELECT c.channel,
ROUND(SUM(gross_price*sold_quantity)/1000000,2) as gross_sales_million 
FROM gdb0041.fact_sales_monthly s
JOIN dim_customer c
on c.customer_code=s.customer_code
JOIN fact_gross_price p
on p.product_code=s.product_code and
 p.fiscal_year=s.fiscal_year
 WHERE s.fiscal_year=2021
 GROUP BY c.channel
 ORDER BY gross_sales_million desc),
 cte2 AS (select sum(gross_sales_million) as total_gross_sales_million from cte1)
 select cte1.*, round((gross_sales_million*100/total_gross_sales_million),2) as percentage_share
 from cte1 join cte2;
 
 -- Request 10
 with cte1 as (SELECT
p.division,
s.product_code,
p.product, 
sum(s.sold_quantity) as total_sold_quantity
FROM fact_sales_monthly s
join dim_product p 
on p.product_code=s.product_code
where s.fiscal_year= 2021
group by p.division,s.product_code, p.product),
cte2 as (SELECT *, dense_rank() over 
(partition by division order by total_sold_quantity desc) as rank_order
from cte1)
select * from cte2 where rank_order in (1,2,3);
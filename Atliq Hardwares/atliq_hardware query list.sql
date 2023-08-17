-- 1 Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

select distinct market from dim_customer where customer='Atliq Exclusive' and region ='APAC'

-- 2. What is the percentage of unique product increase in 2021 vs. 2020?
with cte_pr as (
select fiscal_year,count(distinct product_code) as unique_count from fact_sales_monthly group by fiscal_year)
select fiscal_year,unique_count,
(unique_count-lag(unique_count) over (order by fiscal_year asc))/lag(unique_count) 
over (order by fiscal_year asc)*100 as percentage_change from cte_pr

-- 3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
select * from dim_product limit 5
select segment,count(distinct product_code)as count from dim_product group by segment order by count desc

# Follow-up: Which segment had the most increase in unique products in 2021 vs 2020?

WITH cte_ch AS (
    SELECT
        dp.segment,
        COUNT(DISTINCT CASE WHEN sp.fiscal_year = '2020' THEN dp.product_code END) AS unique_product_count_2020,
        COUNT(DISTINCT CASE WHEN sp.fiscal_year = '2021' THEN dp.product_code END) AS unique_product_count_2021
    FROM dim_product dp
    JOIN fact_sales_monthly sp ON dp.product_code = sp.product_code
    GROUP BY dp.segment
)

SELECT
    segment,
    unique_product_count_2020,
    unique_product_count_2021,
    unique_product_count_2021 - unique_product_count_2020 AS difference,
    (unique_product_count_2021 - unique_product_count_2020)/unique_product_count_2020*100 AS percentage_change
FROM cte_ch order by percentage_change desc

# 5. Get the products that have the highest and lowest manufacturing costs.
# A
select a.product_code,a.product,b.manufacturing_cost from dim_product as a join fact_manufacturing_cost as b
on a.product_code =b.product_code
group by a.product_code,a.product,b.manufacturing_cost order by b.manufacturing_cost desc

# B 
select a.product_code,a.product,b.manufacturing_cost from dim_product as a join fact_manufacturing_cost as b
on a.product_code =b.product_code
group by a.product_code,a.product,b.manufacturing_cost order by b.manufacturing_cost ASC

# Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.

select a.customer_code,b.customer,avg(pre_invoice_discount_pct) as avg_discount 
from fact_pre_invoice_deductions as a
join dim_customer as b on a.customer_code = b.customer_code
Where market ='india' and  fiscal_year = '2021'
group by customer_code,customer
order by avg_discount desc limit 5 

# 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and high-performing months and take strategic decisions.
WITH cte_ss AS(
SELECT (fgp.gross_price*fsm.sold_quantity) AS gross_sales,dc.customer,monthname(fsm.date) AS months,fsm.fiscal_year
FROM dim_product AS dp
JOIN fact_sales_monthly AS fsm ON dp.product_code = fsm.product_code
JOIN fact_pre_invoice_deductions AS fpi ON fpi.customer_code = fsm.customer_code
JOIN fact_manufacturing_cost AS mc ON mc.product_code = dp.product_code
JOIN fact_gross_price AS fgp ON fgp.product_code = dp.product_code
JOIN dim_customer AS dc ON dc.customer_code = fsm.customer_code
WHERE fsm.fiscal_year = fgp.fiscal_year
AND fsm.fiscal_year = fpi.fiscal_year
AND fsm.fiscal_year = mc.cost_year
GROUP BY dc.customer,months,fsm.fiscal_year,gross_sales)
SELECT * FROM cte_ss WHERE customer = 'Atliq Exclusive'

# In which quarter of 2020, got the maximum total_sold_quantity?
select quarter(a.date) as quarters,sum(a.sold_quantity) as sold_quanty from fact_sales_monthly as a where a.fiscal_year = '2020' and a.date = 2020-01-01 <=2021-01-01
group by quarters order by quarters

# . Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 

WITH cte_ss1 AS(
SELECT (fgp.gross_price*fsm.sold_quantity) AS gross_sales,dc.customer_code,
fsm.fiscal_year,dp.product,dp.product_code,dc.channel,fgp.gross_price,mc.manufacturing_cost,
fpi.pre_invoice_discount_pct,fsm.sold_quantity
FROM dim_product AS dp
JOIN fact_sales_monthly AS fsm ON dp.product_code = fsm.product_code
JOIN fact_pre_invoice_deductions AS fpi ON fpi.customer_code = fsm.customer_code
JOIN fact_manufacturing_cost AS mc ON mc.product_code = dp.product_code
JOIN fact_gross_price AS fgp ON fgp.product_code = dp.product_code
JOIN dim_customer AS dc ON dc.customer_code = fsm.customer_code
WHERE fsm.fiscal_year = fgp.fiscal_year
AND fsm.fiscal_year = fpi.fiscal_year
AND fsm.fiscal_year = mc.cost_year)
SELECT channel,sum(gross_sales), sum(gross_sales)/(select sum(gross_sales) FROM cte_ss1 where fiscal_year = 2021)*100 as percentage_contribution from cte_ss1 where fiscal_year =2021
group by channel

# 0. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
 
SELECT *
FROM (
    SELECT
        division,
        SUM(sold_quantity),
        sg.product_code,
        dp.product,
        DENSE_RANK() OVER (PARTITION BY division ORDER BY SUM(sold_quantity) DESC) AS rnk
    FROM fact_sales_monthly AS sg
    JOIN dim_product AS dp ON sg.product_code = dp.product_code
    WHERE fiscal_year = 2021
    GROUP BY division, sg.product_code, dp.product
) x
WHERE x.rnk < 4

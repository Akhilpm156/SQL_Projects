SELECT * FROM wk.fact_order_lines limit 5;

-- Finding Total order Counts;

SELECT * FROM wk.fact_order_lines limit 5;
SELECT count(distinct order_id) as Total_order_Lines FROM wk.fact_order_lines;

-- Finding LIFR % Line Fill Rate (Number of order lines shipped In Full Quantity / Total Order Lines)
select c1.customer_name,count(case when `In Full`=1 then delivery_qty else 0 end) as ol,
count(delivery_qty) as olq,round((count(case when `In Full`=1 then delivery_qty else 0 end)/count(delivery_qty))*100,2) as `LIFR %` 
from fact_order_lines as sc1 
inner join dim_customers as c1 on sc1.customer_id = c1.customer_id 
group by c1.customer_name;

SELECT * FROM wk.fact_order_lines limit 5;

with consol as (
select c1.customer_name,sum(sc1.order_qty) as total_qty,
sum(case when `In Full`=1 then sc1.order_qty else 0 end) as In_full_delvery,
sum(case when `On Time`=1 then sc1.order_qty else 0 end) as on_time_delvery,
sum(case when `On Time In Full`=1 then sc1.order_qty else 0 end) as on_time_full_delvery
from dim_customers as c1
inner join fact_order_lines as sc1 on sc1.customer_id = c1.customer_id
inner join fact_orders_aggregate as sa1 on sa1.ï»¿order_id = sc1.order_id
group by c1.customer_name)

select customer_name,
total_qty,
In_full_delvery,
on_time_delvery,
on_time_full_delvery,
round(In_full_delvery/total_qty*100,2) as 'In_full %',
round(on_time_delvery/total_qty*100,2) as 'on_time %',
round(on_time_full_delvery/total_qty*100,2) as 'on_time_full %'
from consol;

-- Volum fill rate VOFR % (Total Quantity shipped / Total Quantity Ordered)
select c1.customer_name,sum(case when `In Full`=1 then delivery_qty else 0 end) as ol,
sum(order_qty) as olq,round((sum(case when `In Full`=1 then delivery_qty else 0 end)/sum(order_qty))*100,2) as `VOFR %` 
from fact_order_lines as sc1 
inner join dim_customers as c1 on sc1.customer_id = c1.customer_id 
group by c1.customer_name;


select * from fact_order_lines limit 5;

select c1.customer_name,sc1.order_qty,sc1.delivery_qty,round(sc1.delivery_qty/sc1.order_qty*100,2) as 'VOFR %' from fact_order_lines as sc1 
inner join dim_customers as c1 on sc1.customer_id = c1.customer_id 
group by c1.customer_name,sc1.order_qty,sc1.delivery_qty;

/* OT % = Number of orders delivered On Time / Total Number of Orders
IF % = Number of orders delivered in Full quantity / Total Number of Orders
OTIF % = Number of orders delivered both IN Full & On Time / Total Number of Orders
*/
select * from fact_orders_aggregate limit 5;
ALTER TABLE fact_orders_aggregate
rename column `ï»¿order_id` to order_id;

select c1.customer_name,count(distinct(order_id)) as Total_Numbers_of_orders,
round(sum(case when on_time = 1 then 1 else 0 end)/count(distinct order_id)*100,2) as ot_per,
round(sum(case when in_full= 1 then 1 else 0 end)/count(distinct order_id)*100,2) as In_Full_DV,
round(sum(case when otif = 1 then 1 else 0 end)/count(distinct order_id)*100,2) as on_time_In_Full_DV
from dim_customers as c1 inner join fact_orders_aggregate as sc1 on c1.customer_id=sc1.customer_id 
group by c1.customer_name;

-- Average of On-Time Target,In-Full Target,OTIF Target
 
select * from dim_targets_orders limit 5;
select avg(`ontime_target%`),avg(`infull_target%`),avg(`otif_target%`) from dim_targets_orders;

-- Diff in target and actual
select * from dim_targets_orders limit 5;
select * from fact_orders_aggregate limit 5;
with Realf as (
select dc.city,
round(sum(on_time)/count(on_time)*100,2) as actual_OT,
round(sum(in_full)/count(on_time)*100,2) as actual_IF,
round(sum(otif)/count(on_time)*100,2) as actual_OTIF
from fact_orders_aggregate as atu inner join
dim_customers as dc on atu.customer_id=dc.customer_id
group by dc.city
),SECOND_1 as(
select dc01.city,
round(sum(`ontime_target%`)/count(dim_targets_orders.customer_id),2) as tar_OT,
round(sum(`infull_target%`)/count(dim_targets_orders.customer_id),2) as tar_IF,
round(sum(`otif_target%`)/count(dim_targets_orders.customer_id),2) as tar_OTIF
from dim_targets_orders
inner join dim_customers as dc01 on dc01.customer_id=dim_targets_orders.customer_id
group by dc01.city)
select Realf.city,
round((Realf.actual_OT-SECOND_1.tar_OT)/SECOND_1.tar_OT*100,2) as target_Variance_OT,
round((Realf.actual_IF-SECOND_1.tar_IF)/SECOND_1.tar_IF*100,2) as target_Variance_IF,
round((Realf.actual_OTIF-SECOND_1.tar_OTIF)/SECOND_1.tar_OTIF*100,2) as target_Variance_OTIF
from Realf inner join SECOND_1 on Realf.city = SECOND_1.city;

-- find most order received product
select * from fact_order_lines limit 5;
select * from dim_products; 

select product_name,sum(order_qty) as Total_order_qty,sum(delivery_qty) as delvered_qty from dim_products as dp
inner join fact_order_lines as fol on dp.product_id=fol.product_id
group by product_name order by Total_order_qty desc limit 5;

-- based on category

select category,sum(order_qty) as Total_order_qty,sum(delivery_qty) as delvered_qty from dim_products as dp
inner join fact_order_lines as fol on dp.product_id=fol.product_id
group by category order by Total_order_qty desc;

-- based on city (customer)

select city,sum(order_qty) as Total_order_qty,sum(delivery_qty) as delvered_qty from dim_customers as dm
inner join fact_order_lines as fol on dm.customer_id=fol.customer_id
group by city order by Total_order_qty desc;

-- customer place lowest orders
select customer_name,sum(order_qty) as Total_order_qty,sum(delivery_qty) as delvered_qty from dim_customers as dm
inner join fact_order_lines as fol on dm.customer_id=fol.customer_id
group by customer_name order by Total_order_qty limit 5;

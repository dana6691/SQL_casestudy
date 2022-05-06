----------------------------------------------------
------ Pizza Metrics
----------------------------------------------------
-- 1. How many pizzas were ordered?
select count(*) from customer_orders

-- 2. How many unique customer orders were made?
select count(distinct order_id) from customer_orders

-- 3. How many successful orders were delivered by each runner?
select runner_id, count(duration) as YesDelivered from runner_orders 
WHERE duration != 'null'
group by runner_id

-- 4. How many of each type of pizza was delivered?
select CAST(pizza_name AS NVARCHAR(100)), count(*) as cnt
from customer_orders c
right join runner_orders r on c.order_id = r.order_id
left join pizza_names p on p.pizza_id=c.pizza_id
WHERE duration != 'null'
group by CAST(pizza_name AS NVARCHAR(100))

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
select  CAST(c.customer_id AS NVARCHAR(100)) customer_id, CAST(pizza_name AS NVARCHAR(100)) pizza_name, count(*) as cnt
from customer_orders c
join pizza_names p on p.pizza_id = c.pizza_id
group by CAST(customer_id AS NVARCHAR(100)), CAST(pizza_name AS NVARCHAR(100)) 

select c.customer_id,
	SUM(CASE WHEN  CAST(pizza_name AS NVARCHAR(100)) = 'Vegetarian' THEN 1 ELSE 0 END) AS vegetarian,
	SUM(CASE WHEN  CAST(pizza_name AS NVARCHAR(100)) = 'Meatlovers' THEN 1 ELSE 0 END) AS meatlovers
from customer_orders AS c
INNER JOIN pizza_names AS p ON c.pizza_id = p.pizza_id
group by c.customer_id

-- 6. What was the maximum number of pizzas delivered in a single order?
with countmax AS (select order_id, count(order_id) as cnt
from customer_orders
group by order_id
)
select * from countmax
where cnt = (select max(cnt) from countmax)

SUM(CASE WHEN toppaddremove = 'yes' then 1 ELSE 0 END) as atleast_1_change,

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
select customer_id,
 SUM(CASE when (exclusions ='null' OR exclusions ='') AND ( extras ='null' OR extras='' OR extras IS NULL) THEN 1 ELSE 0 END) as atleast_1_change,
 SUM(CASE when (exclusions ='null' OR exclusions ='') AND ( extras ='null' OR extras='' OR extras IS NULL) THEN 0 ELSE 1 END) as no_change
from customer_orders
group by customer_id

-- 8. How many pizzas were delivered that had both exclusions and extras?
With topping AS (
SELECT exclusions, extras,
		CASE when exclusions ='null' OR exclusions='' then 'no'
			 when extras ='null' OR extras='' then 'no'
		ELSE 'yes' END AS toppaddremove
from customer_orders )
select count(*)
from topping
where toppaddremove = 'yes'

SELECT SUM(CASE when exclusions ='null' OR exclusions='' OR extras ='null' OR extras='' then 0 ELSE 1 END) AS exclusion
from customer_orders

-- 9. What was the total volume of pizzas ordered for each hour of the day?
select DATEPART(hh, order_time) as hour, count(*) as cnt
from customer_orders
group by DATEPART(hh, order_time)

-- 10. What was the volume of orders for each day of the week?
select DATENAME(dw, order_time) as day, count(*) as cnt
from customer_orders
group by DATENAME(dw, order_time)
----------------------------------------------------
------ Runner and Customer Experience
----------------------------------------------------
-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
select datediff(day,'2021-01-01',registration_date)/7+1 as weekno, count(*) as cnt
from runners
group by datediff(day,'2021-01-01',registration_date)/7+1

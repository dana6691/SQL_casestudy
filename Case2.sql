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

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
with pick AS (select order_id, runner_id, pickup_time, case when pickup_time = 'null' then NULL
		else pickup_time END as pickuptime
		from runner_orders)
select runner_id, AVG(CAST(DATEDIFF(minute, order_time,convert(datetime, pickuptime)) AS float)) as AvgMinute
from pick r
inner join customer_orders  c on r.order_id = c.order_id
GROUP BY runner_id	

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
with pick AS (select order_id, runner_id, pickup_time, case when pickup_time = 'null' then NULL
		else pickup_time END as pickuptime
		from runner_orders)
select c.order_id, count(*) as nopizza, AVG(DATEDIFF(minute, order_time,convert(datetime, pickuptime))) as AvgMinute
from pick r
join customer_orders  c on r.order_id = c.order_id
where pickuptime IS NOT NULL
group by c.order_id

-- 4. What was the average distance travelled for each customer?
WITH avgdistance AS (
	select r.order_id, c.customer_id,
	CASE WHEN distance LIKE '%km' then TRIM('km' from distance)
	WHEN distance ='null' then NULL
	ELSE distance END AS distance2
	from runner_orders r
	LEFT JOIN customer_orders c on r.order_id = c.order_id)
SELECT customer_id, AVG(CAST(distance2 AS FLOAT)) as avgdistance
from avgdistance
group by customer_id

-- 5. What was the difference between the longest and shortest delivery times for all orders?
With taketime AS (
	select *,
	CASE WHEN duration LIKE '%mins' then TRIM('mins' from duration)
	WHEN duration LIKE '%minutes' then TRIM('minutes' from duration)
	WHEN duration LIKE '%minute' then TRIM('minute' from duration)
	WHEN duration ='null' then NULL
	ELSE duration END AS duration2
	from runner_orders)
SELECT CAST(MAX(duration2) AS INT)-CAST(MIN(duration2) AS INT) as Timediff
from taketime

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
With taketime AS (
	select *,
	CASE WHEN distance LIKE '%km' then TRIM('km' from distance)
	WHEN distance ='null' then NULL
	ELSE distance END AS distance2,
	CASE WHEN duration LIKE '%mins' then TRIM('mins' from duration)
	WHEN duration LIKE '%minutes' then TRIM('minutes' from duration)
	WHEN duration LIKE '%minute' then TRIM('minute' from duration)
	WHEN duration ='null' OR duration ='' then NULL
	ELSE duration END AS duration2
	from runner_orders)
SELECT runner_id, order_id, AVG(CAST(distance2 AS float)/ (CAST(duration2 AS float)/60)) as avg_speed
from taketime
group by runner_id, order_id
having AVG(CAST(distance2 AS float)/ (CAST(duration2 AS float)/60)) is not null
order by runner_id, order_id

-- 7. What is the successful delivery percentage for each runner?
select runner_id, COUNT(*) as all_delivery, 
	COUNT(CASE WHEN duration = 'null' then NULL
		  ELSE duration END) as success_delivery,
	CAST(COUNT(CASE WHEN duration = 'null' then NULL ELSE duration END) AS float)/CAST(COUNT(*) AS float)*100 as percentage
from runner_orders
group by runner_id
----------------------------------------------------
------ Ingredient Optimization
-- STRING_SPLIT: splits a string into rows of substrings
-- CONCAT
-- 
----------------------------------------------------
-- 1. What are the standard ingredients for each pizza?
select * from pizza_toppings

With recipe AS (
	SELECT pizza_id, value  
	FROM pizza_recipes CROSS APPLY STRING_SPLIT(CAST(toppings AS VARCHAR(50)), ','))
SELECT pizza_id, topping_name
from recipe r
join pizza_toppings p on p.topping_id = r.value

-- 2. What was the most commonly added extra?
With ex AS (select TOP 1 value as extra,count(value) as cnt
			from customer_orders c  CROSS APPLY STRING_SPLIT(extras,',') 
			where extras !='null' AND extras !=''
			group by value
			order by cnt desc)
select topping_name
from ex c
join pizza_toppings p on c.extra = p.topping_id

-- 3. What was the most common exclusion?
With ex AS (select TOP 1 value as exclude,count(value) as cnt
			from customer_orders c  CROSS APPLY STRING_SPLIT(exclusions,',') 
			where exclusions !='null' AND exclusions !=''
			group by value
			order by cnt desc)
select topping_name
from ex c
join pizza_toppings p on c.exclude = p.topping_id
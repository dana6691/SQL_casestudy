----------------------------------------------------
------ Customer Journey
----------------------------------------------------
-- 1. Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
select customer_id, 
	MAX(case when plan_id = 0 then start_date end) AS trial,
	MAX(case when plan_id = 1 then start_date end) AS basic_monthly,
	MAX(case when plan_id = 2 then start_date end) AS pro_monthyl,
	MAX(case when plan_id = 3 then start_date end) AS pro_yearly,
	MAX(case when plan_id = 4 then start_date end) AS churn
from subscriptions
group by customer_id
----------------------------------------------------
------ Data Analysis Questions
----------------------------------------------------
-- 1. How many customers has Foodie-Fi ever had?
select count(distinct customer_id) as CustomerNo from subscriptions
where plan_id !=0

-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
select DATEPART(month, start_date) as startmonth, DATENAME(month, start_date) as startmonth2, count(*) as cnt from subscriptions
where plan_id = 0
group by DATEPART(month, start_date),DATENAME(month, start_date)
order by DATEPART(month, start_date) asc

-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT plan_name, count(*) as cnt
FROM subscriptions s
JOIN plans p ON s.plan_id = p.plan_id 
WHERE start_date > '2019-12-31'
GROUP BY plan_name

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT COUNT(*) AS churn_count,
	   CAST(100*CAST(count(*) AS DECIMAL (4,1)) / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions) AS DECIMAL (4,1)) AS churn_percentage 
FROM subscriptions
WHERE plan_id = 4

-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
With a AS (
select *, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY plan_id) as rank
from subscriptions)
SELECT  count(*) AS churn_cnt, 
		ROUND(100*count(*)/(SELECT COUNT(DISTINCT customer_id) FROM subscriptions),0) as straightchurn_percent 
FROM a
where rank=2 AND plan_id = 4

-- 6. What is the number and percentage of customer plans after their initial free trial?
With a AS (
select customer_id, plan_id, start_date, RANK() OVER(PARTITION BY customer_id ORDER BY start_date) as rank
from subscriptions)
select plan_id, count(*) as cnt, CAST(100*CAST(count(*) AS DECIMAL (4,1))/(SELECT COUNT(DISTINCT customer_id) FROM subscriptions) AS DECIMAL (4,1)) as afterinitial_percent 
from a
where rank = 2
group by plan_id
order by plan_id asc

With a AS (
select customer_id, plan_id, start_date, LEAD(plan_id, 1) OVER(PARTITION BY customer_id ORDER BY start_date) as rank
from subscriptions)
select rank, count(*)  as cnt, CAST(100*CAST(count(*) AS DECIMAL (4,1))/(SELECT COUNT(DISTINCT customer_id) FROM subscriptions) AS DECIMAL (4,1)) as afterinitial_percent 
from a
where plan_id = 0
group by rank

-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
With cte AS (
select customer_id, max(start_date) as date
from subscriptions
where start_date <= '2020-12-31'
group by customer_id)
select p.plan_id, count(*) as cnt, CAST(100*CAST(count(*) AS DECIMAL (4,1))/(SELECT COUNT(DISTINCT customer_id) FROM subscriptions) AS DECIMAL (4,1)) as afterinitial_percent 
from cte a
join subscriptions p ON a.customer_id = p.customer_id AND a.date = p.start_date  
group by plan_id
order by plan_id asc

WITH next_plan AS(
SELECT 
  customer_id, 
  plan_id, 
  start_date,
  LEAD(start_date, 1) OVER(PARTITION BY customer_id ORDER BY start_date) as next_date
FROM subscriptions
WHERE start_date <= '2020-12-31'
)
select plan_id, count(*) as cnt, CAST(100*CAST(count(*) AS DECIMAL (4,1))/(SELECT COUNT(DISTINCT customer_id) FROM subscriptions) AS DECIMAL (4,1)) as afterinitial_percent 
from next_plan 
where next_date IS NULL
group by plan_id
order by plan_id asc

-- 8. How many customers have upgraded to an annual plan in 2020?
SELECT COUNT(DISTINCT customer_id) AS cnt
FROM subscriptions
WHERE plan_id = 3 AND start_date <= '2020-12-31';

-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
With cte_avg AS 
(select 	customer_id, 
	MAX(case when plan_id = 0 then start_date end) AS trial,
	MAX(case when plan_id = 3 then start_date end) AS pro_yearly
from subscriptions
group by customer_id)
select AVG(DATEDIFF(DAY, trial,pro_yearly)) as avg_date
from cte_avg
where pro_yearly IS NOT NULL

-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
With cte_avg AS 
(select 	customer_id, 
	MAX(case when plan_id = 0 then start_date end) AS trial,
	MAX(case when plan_id = 3 then start_date end) AS pro_yearly
from subscriptions
group by customer_id)
select category, count(*) from (
select Customer_id, DATEDIFF(DAY, trial,pro_yearly) as avg_date, 
	(case when DATEDIFF(DAY, trial,pro_yearly) < 30 then '0-30 days'
	     when DATEDIFF(DAY, trial,pro_yearly) < 60 then '31-60 days'
		 when DATEDIFF(DAY, trial,pro_yearly) < 90 then '61-90 days'
		 when DATEDIFF(DAY, trial,pro_yearly) < 120 then '91-120 days'
		 when DATEDIFF(DAY, trial,pro_yearly) < 150 then '121-150 days'
		 when DATEDIFF(DAY, trial,pro_yearly) < 180 then '151-180 days'
		 ELSE '> 181 days' END) AS category
from cte_avg
where pro_yearly IS NOT NULL) q 
group by category

With cte_avg AS 
    (select 	customer_id, 
        MAX(case when plan_id = 0 then start_date end) AS trial,
        MAX(case when plan_id = 3 then start_date end) AS pro_yearly
    from subscriptions
    group by customer_id),
avgdate AS 
    (select Customer_id, DATEDIFF(DAY, trial,pro_yearly) as avg_date, DATEDIFF(DAY, trial,pro_yearly)/30 as d
    from cte_avg
    ),
daycat AS 
    (select Customer_id, avg_date, (CAST(d*30 AS varchar) + ' - '  + CAST((d+1)*30 as VARCHAR) + ' days') as date_category 
    from avgdate)
SELECT date_category, count(*)
FROM daycat
WHERE date_category IS NOT NULL
GROUP BY date_category

-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
WITH next_plan AS(
SELECT 
  customer_id, 
  plan_id, 
  start_date,
  LEAD(plan_id, 1) OVER(PARTITION BY customer_id ORDER BY start_date) as next_date
FROM subscriptions
WHERE start_date <= '2020-12-31'
)
select count(*) as cnt
from next_plan
where plan_id = 2 AND next_date =1;
--------------------------------------
CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


 -- 1. What is the total amount each customer spent at the restaurant?
 select  s.customer_id,  sum(m.price) as Amt
 from sales s
 left join menu m
 on s.product_id = m.product_id
 group by customer_id

-- 2. How many days has each customer visited the restaurant?
select DISTINCT  customer_id, count(order_date) as VisitTimes
from sales
group by customer_id

-- 3. What was the first item from the menu purchased by each customer?
-- (solution 1)
select a.customer_id, m.product_name  from (
select customer_id, order_date, product_id, ROW_NUMBER() over (partition by customer_id ORDER BY customer_id, order_date) as no
from sales
) a
left join menu m
on a.product_id = m.product_id
where a.no = 1
-- (solution 2) using window function
select DISTINCT customer_id, first_value(m.product_name) over(partition by customer_id order by customer_id) as first
from sales a
left join menu m
on a.product_id = m.product_id

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select m.product_name, count(s.product_id) as timesales
from sales s
left join menu m
on s.product_id = m.product_id
group by m.product_name
order by count(s.product_id) desc

--5. Which item was the most popular for each customer?
-- (solution 1)
select customer_id, m.product_name, salesTimes from (
select customer_id, product_id, count(product_id) as salesTimes, rank() over(partition by customer_id order by count(product_id) desc) as rank
from sales
group by customer_id, product_id
) a
left join menu m
on a.product_id = m.product_id
where rank = 1
-- (solution 2)
with ranked as (
select customer_id,product_id, count(product_id) as cnt, DENSE_RANK() over (partition by customer_id order by count(product_id) desc) as rank
from sales
group by customer_id,product_id
)
select customer_id, m.product_name, a.cnt
from ranked  a
left join menu m
on a.product_id = m.product_id
where rank = 1

-- 6. Which item was purchased first by the customer after they became a member?
with ranked as (
select  s.customer_id, mm.product_name, DENSE_RANK() over (partition by s.customer_id order by order_date asc) as rank
from sales s
join members m on s.customer_id = m.customer_id
join menu mm on s.product_id = mm.product_id
where s.order_date > m.join_date
)
select customer_id, product_name
from ranked 
where rank = 1

-- 7. Which item was purchased just before the customer became a member?
with ranked as (
select s.customer_id, mm.product_name, DENSE_RANK() over (partition by s.customer_id order by order_date desc) as rank
from sales s
join members m on s.customer_id = m.customer_id
join menu mm on s.product_id = mm.product_id
where s.order_date < m.join_date
)
select customer_id, product_name
from ranked 
where rank = 1

-- 8. What is the total items and amount spent for each member before they became a member?
select s.customer_id, count(s.product_id) as Totalitems, sum(mm.price) as AmtSpent
from sales s
join members m on s.customer_id = m.customer_id
join menu mm on s.product_id = mm.product_id
where s.order_date < m.join_date
group by s.customer_id

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with withpoint AS (
Select *, Case When product_id = 1 THEN price*20
          Else price*10
	      End as Points
From Menu
)
select customer_id, sum(Points) as points
from sales s
Join withpoint p on p.product_id = s.product_id
group by customer_id

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
with newtable AS (
select *, DATEADD(day, 6, m.join_date) as  lastd
from members m
)
select s.customer_id,
	SUM(
		Case when order_date between join_date and lastd then mm.price*20 
			 when s.product_id = 1 then mm.price*20
		Else mm.price*10
		End
	)  as Points
from sales s
join newtable n on n.customer_id = s.customer_id
join menu mm on s.product_id = mm.product_id
where order_date < '2021-02-01'
group by s.customer_id


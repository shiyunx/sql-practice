--1. What is the total amount each customer spent at the restaurant?

SELECT sales.customer_id, 
SUM(menu.price) AS total_spent
FROM dannys_diner.sales
JOIN dannys_diner.menu
ON sales.product_id = menu.product_id
GROUP BY customer_id
ORDER BY customer_id;

--2. How many days has each customer visited the restaurant?

SELECT customer_id,
COUNT(DISTINCT order_date) AS visit_days
FROM dannys_diner.sales
GROUP BY customer_id
ORDER BY customer_id;

--3. What was the first item from the menu purchased by each customer?

SELECT sales.customer_id, menu.product_name
FROM dannys_diner.sales
JOIN dannys_diner.menu
ON sales.product_id = menu.product_id
WHERE (sales.customer_id, sales.order_date) IN (
SELECT customer_id, MIN(order_date)
FROM sales
GROUP BY customer_id
)
ORDER BY sales.customer_id;

--4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT sales.product_id, menu.product_name,
COUNT(*) AS total_qty
FROM dannys_diner.sales
JOIN dannys_diner.menu
ON sales.product_id = menu.product_id
GROUP BY sales.product_id, menu.product_name;

--5. Which item was the most popular for each customer?

SELECT customer_id, product_name, total_orders
FROM (
SELECT s.customer_id, m.product_name,
COUNT(*) AS total_orders,
RANK() OVER (
PARTITION BY s.customer_id
ORDER BY COUNT(*) DESC
) AS rnk
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id, m.product_name
) t
WHERE rnk = 1;

--6. Which item was purchased first by the customer after they became a member?

SELECT customer_id, product_name, order_date
FROM (
SELECT s.customer_id, me.product_name, s.order_date,
ROW_NUMBER() OVER (
PARTITION BY s.customer_id
ORDER BY s.order_date
) AS rn
FROM sales s
JOIN members m
ON s.customer_id = m.customer_id
JOIN menu me
ON s.product_id = me.product_id
WHERE s.order_date > m.join_date
) t
WHERE rn = 1;

--7. Which item was purchased just before the customer became a member?

SELECT customer_id, product_name, order_date
FROM (
SELECT s.customer_id, me.product_name, s.order_date,
ROW_NUMBER() OVER (
PARTITION BY s.customer_id
ORDER BY s.order_date DESC
) AS rn
FROM sales s
JOIN members m
ON s.customer_id = m.customer_id
JOIN menu me
ON s.product_id = me.product_id
WHERE s.order_date < m.join_date
) t
WHERE rn = 1;

--8. What is the total items and amount spent for each member before they became a member?

SELECT 
s.customer_id,
COUNT(*) AS total_items,
SUM(me.price) AS total_amount
FROM sales s
JOIN members m
ON s.customer_id = m.customer_id
JOIN menu me
ON s.product_id = me.product_id
WHERE s.order_date < m.join_date
GROUP BY s.customer_id;

--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT s.customer_id,
SUM(
CASE 
WHEN m.product_name = 'sushi' 
THEN m.price * 10 * 2
ELSE m.price * 10
END
) AS total_points
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;

--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH base AS (
SELECT s.customer_id, s.order_date, m.join_date, me.product_name, me.price,
CASE 
WHEN s.order_date BETWEEN m.join_date AND (m.join_date + 6)
THEN 2
WHEN me.product_name = 'sushi'
THEN 2
ELSE 1
END AS multiplier
FROM sales s
JOIN menu me ON s.product_id = me.product_id
JOIN members m ON s.customer_id = m.customer_id
WHERE s.order_date <= '2021-01-31'
)
SELECT 
customer_id,
SUM(price * 10 * multiplier) AS total_points
FROM base
GROUP BY customer_id
ORDER BY customer_id;
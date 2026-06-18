--1. What is the total amount each customer spent at the restaurant?

SELECT
    sales.customer_id,
    SUM(menu.price) AS total_amount_spent
FROM dannys_diner.sales sales
JOIN dannys_diner.menu menu
    ON sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY sales.customer_id;

--2. How many days has each customer visited the restaurant?

SELECT 
    customer_id,
    COUNT(DISTINCT order_date) AS visit_days
FROM dannys_diner.sales
GROUP BY customer_id
ORDER BY customer_id;

--3. What was the first item from the menu purchased by each customer?

WITH first_order_date AS (
    SELECT
        customer_id,
        MIN(order_date) AS first_order_date
    FROM dannys_diner.sales
    GROUP BY customer_id
)

SELECT
    sales.customer_id,
    menu.product_name
FROM dannys_diner.sales AS sales
JOIN first_order_date
    ON sales.customer_id = first_order_date.customer_id
   AND sales.order_date = first_order_date.first_order_date
JOIN dannys_diner.menu AS menu
    ON sales.product_id = menu.product_id
ORDER BY
    sales.customer_id,
    menu.product_name;

--4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT
    menu.product_name,
    COUNT(*) AS purchase_count
FROM dannys_diner.sales sales
JOIN dannys_diner.menu menu
    ON sales.product_id = menu.product_id
GROUP BY menu.product_name
ORDER BY purchase_count DESC
LIMIT 1;

--5. Which item was the most popular for each customer?

SELECT customer_id, product_name, total_orders
FROM (
    SELECT 
        s.customer_id,
        m.product_name,
        COUNT(*) AS total_orders,
        RANK() OVER (
            PARTITION BY s.customer_id
            ORDER BY COUNT(*) DESC
        ) AS rnk
    FROM dannys_diner.sales s
    JOIN dannys_diner.menu m
        ON s.product_id = m.product_id
    GROUP BY 
        s.customer_id,
        m.product_name
) t
WHERE rnk = 1;

--6. Which item was purchased first by the customer after they became a member?

SELECT customer_id, product_name
FROM (
    SELECT
        s.customer_id,
        m.product_name,
        s.order_date,
        ROW_NUMBER() OVER (
            PARTITION BY s.customer_id
            ORDER BY s.order_date
        ) AS rn
    FROM dannys_diner.sales s
    JOIN dannys_diner.menu m
        ON s.product_id = m.product_id
    JOIN dannys_diner.members mem
        ON s.customer_id = mem.customer_id
    WHERE s.order_date > mem.join_date
) t
WHERE rn = 1
ORDER BY customer_id;

--7. Which item was purchased just before the customer became a member?

SELECT customer_id, product_name
FROM (
    SELECT
        s.customer_id,
        m.product_name,
        s.order_date,
        ROW_NUMBER() OVER (
            PARTITION BY s.customer_id
            ORDER BY s.order_date DESC
        ) AS rn
    FROM dannys_diner.sales s
    JOIN dannys_diner.menu m
        ON s.product_id = m.product_id
    JOIN dannys_diner.members mem
        ON s.customer_id = mem.customer_id
    WHERE s.order_date < mem.join_date
) t
WHERE rn = 1
ORDER BY customer_id;

--8. What is the total items and amount spent for each member before they became a member?

SELECT
    s.customer_id,
    COUNT(*) AS total_items,
    SUM(m.price) AS total_amount
FROM dannys_diner.sales s
JOIN dannys_diner.menu m
    ON s.product_id = m.product_id
JOIN dannys_diner.members mem
    ON s.customer_id = mem.customer_id
WHERE s.order_date < mem.join_date
GROUP BY s.customer_id
ORDER BY s.customer_id;

--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT
    s.customer_id,
    SUM(
        CASE 
            WHEN m.product_name = 'sushi' THEN m.price * 2 * 10
            ELSE m.price * 10
        END
    ) AS total_points
FROM dannys_diner.sales s
JOIN dannys_diner.menu m
    ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;

--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT
    s.customer_id,
    SUM(
        CASE 
            WHEN s.order_date BETWEEN mem.join_date 
                                 AND mem.join_date + INTERVAL '6 day'
                THEN m.price * 10 * 2

            WHEN m.product_name = 'sushi'
                THEN m.price * 10 * 2

            ELSE m.price * 10
        END
    ) AS total_points
FROM dannys_diner.sales s
JOIN dannys_diner.menu m
    ON s.product_id = m.product_id
JOIN dannys_diner.members mem
    ON s.customer_id = mem.customer_id
WHERE s.order_date <= '2021-01-31'
GROUP BY s.customer_id
ORDER BY s.customer_id;
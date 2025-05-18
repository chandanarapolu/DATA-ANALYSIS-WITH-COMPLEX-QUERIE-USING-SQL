--Create dummy 'sales' table
CREATE TABLE sales (
    order_id INT,
    customer_id INT,
    product_id INT,
    order_date DATE,
    quantity INT,
    price DECIMAL(10, 2)
);

-- Step 2: Insert dummy data
INSERT INTO sales (order_id, customer_id, product_id, order_date, quantity, price)
VALUES 
(1, 101, 201, '2025-01-10', 2, 100.00),
(2, 102, 202, '2025-01-15', 1, 150.00),
(3, 101, 203, '2025-02-05', 3, 50.00),
(4, 103, 201, '2025-02-20', 5, 80.00),
(5, 104, 202, '2025-03-10', 2, 200.00),
(6, 102, 201, '2025-03-25', 4, 100.00);

-- Step 3: CTEs for revenue analysis
WITH order_revenue AS (
    SELECT 
        order_id,
        customer_id,
        product_id,
        order_date,
        quantity,
        price,
        quantity * price AS revenue
    FROM sales
),
monthly_revenue AS (
    SELECT 
        FORMAT(order_date, 'yyyy-MM') AS month,
        SUM(revenue) AS total_monthly_revenue
    FROM order_revenue
    GROUP BY FORMAT(order_date, 'yyyy-MM')
),
customer_monthly_revenue AS (
    SELECT 
        FORMAT(order_date, 'yyyy-MM') AS month,
        customer_id,
        SUM(revenue) AS customer_monthly_revenue
    FROM order_revenue
    GROUP BY FORMAT(order_date, 'yyyy-MM'), customer_id
),
customer_monthly_rank AS (
    SELECT *,
        RANK() OVER (PARTITION BY month ORDER BY customer_monthly_revenue DESC) AS revenue_rank
    FROM customer_monthly_revenue
),
product_performance AS (
    SELECT 
        FORMAT(order_date, 'yyyy-MM') AS month,
        product_id,
        SUM(revenue) AS product_revenue,
        RANK() OVER (PARTITION BY FORMAT(order_date, 'yyyy-MM') ORDER BY SUM(revenue) DESC) AS revenue_rank
    FROM order_revenue
    GROUP BY FORMAT(order_date, 'yyyy-MM'), product_id
)

-- Final report
SELECT 
    m.month,
    m.total_monthly_revenue,
    cmr.customer_id,
    cmr.customer_monthly_revenue,
    pp.product_id AS top_product,
    pp.product_revenue AS top_product_revenue
FROM monthly_revenue m
LEFT JOIN customer_monthly_rank cmr ON m.month = cmr.month AND cmr.revenue_rank = 1
LEFT JOIN product_performance pp ON m.month = pp.month AND pp.revenue_rank = 1
ORDER BY m.month;


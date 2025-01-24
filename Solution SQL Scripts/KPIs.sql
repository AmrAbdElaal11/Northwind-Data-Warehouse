
-- Sales KPIs
-- Total Revenues Per product

SELECT 
    p.product_name, 
    SUM(f.unitprice * f.quantity * (1 - f.discount)) AS total_revenue
FROM 
    fct_orders f
JOIN 
    dim_products p ON f.product_fk = p.product_sk
GROUP BY 
    p.product_name
ORDER BY 
    total_revenue DESC;


-- Total Revenues per Region
SELECT 
    c.region, 
    SUM(f.unitprice * f.quantity * (1 - f.discount)) AS total_revenue
FROM 
    fct_orders f
JOIN 
    dim_customers c ON f.customer_fk = c.customer_sk
GROUP BY 
    c.region
ORDER BY 
    total_revenue DESC;

-- Month Over Month Revenue
   
   WITH monthly_revenue AS (
    SELECT 
        TO_CHAR(d.date, 'YYYY-MM') AS year_month, 
        SUM(f.unitprice * f.quantity * (1 - f.discount)) AS total_revenue
    FROM 
        fct_orders f
    JOIN 
        dim_date d ON f.order_date_fk = d.date_sk
    GROUP BY 
        TO_CHAR(d.date, 'YYYY-MM') 
)
SELECT 
    year_month,
    total_revenue,
    LAG(total_revenue) OVER (ORDER BY year_month) AS previous_month_revenue,
    total_revenue - LAG(total_revenue) OVER (ORDER BY year_month) AS mom_revenue_growth,
    ROUND(
        cast((((total_revenue - LAG(total_revenue) OVER (ORDER BY year_month)) / LAG(total_revenue) OVER (ORDER BY year_month)) * 100) as numeric), 
        2 ) AS mom_revenue_growth_percentage
FROM 
    monthly_revenue
ORDER BY 
    year_month;
   
-- Year over Year for specific month 
   WITH revenue AS (
    SELECT 
        EXTRACT(YEAR FROM dd.date) AS year,
        SUM(fo.unitprice * fo.quantity * (1 - fo.discount)) AS revenue
    FROM 
        fct_orders fo
    JOIN 
        dim_date dd ON fo.order_date_fk = dd.date_sk
    WHERE 
        EXTRACT(MONTH FROM dd.date) = 7  
    GROUP BY 
        EXTRACT(YEAR FROM dd.date)
)
    SELECT
        year,
        revenue,
        LAG(revenue) OVER (ORDER BY year) AS previous_year_revenue,
        ROUND(
        (((revenue -  LAG(revenue) OVER (ORDER BY year)) /  LAG(revenue) OVER (ORDER BY year)) * 100)::numeric, 2
    ) AS yoy_growth_percentage
    FROM
        revenue;

-- Average Order Value
SELECT 
   round(SUM(f.unitprice * f.quantity * (1 - f.discount)) / COUNT(DISTINCT f.order_id))  AS average_order_value
FROM 
    fct_orders f;
------------------------------------------------------------------------------------------------------------------------

-- Customers KPIs
-- Customer Lifetime Value
SELECT 
    c.customer_id,
    c.company_name,
    MIN(d.date) AS first_order_date,
    MAX(d.date) AS last_order_date,
    MAX(d.date) - MIN(d.date) AS customer_lifetime,
    COUNT(DISTINCT f.order_id) AS total_orders,
    SUM(f.unitprice * f.quantity * (1 - f.discount)) AS total_revenue
FROM 
    fct_orders f
JOIN 
    dim_customers c ON f.customer_fk = c.customer_sk
JOIN 
    dim_date d ON f.order_date_fk = d.date_sk
GROUP BY 
    c.customer_id, c.company_name
ORDER BY 
    customer_lifetime DESC;

   
  -- Churn Rate
   WITH latest_order_dates AS (
    SELECT 
        c.customer_id,
        MAX(d.date) AS last_order_date
    FROM 
        fct_orders f
    JOIN 
        dim_customers c ON f.customer_fk = c.customer_sk
    JOIN 
        dim_date d ON f.order_date_fk = d.date_sk
    GROUP BY 
        c.customer_id
),
churned_customers AS (
    SELECT 
        customer_id
    FROM 
        latest_order_dates
    WHERE 
        last_order_date < date('1998-09-08') - INTERVAL '12 months' 
),
total_customers AS (
    SELECT 
        COUNT(DISTINCT customer_id) AS total_customers
    FROM 
        dim_customers
)
SELECT 
    COUNT(DISTINCT cc.customer_id) AS churned_customers,
    tc.total_customers,
    ROUND(
        (COUNT(DISTINCT cc.customer_id) * 100.0 / tc.total_customers), 
        2
    ) AS churn_rate
FROM 
    churned_customers cc
natural JOIN 
    total_customers tc
GROUP BY 
    tc.total_customers;
------------------------------------------------------------------------------------------------------------------------
-- Operational KPIs
-- On-time Delivery rate
WITH order_delivery AS (
    SELECT 
        order_id,
        MAX(d1.date) AS required_date, 
        MAX(d2.date) AS shipped_date   
    FROM 
        fct_orders f
    JOIN 
        dim_date d1 ON f.required_date_fk = d1.date_sk 
    JOIN 
        dim_date d2 ON f.shipped_date_fk = d2.date_sk  
    GROUP BY 
        order_id
),
on_time_orders AS (
    SELECT 
        order_id,
        CASE 
            WHEN shipped_date <= required_date THEN TRUE 
            ELSE FALSE 
        END AS is_on_time
    FROM 
        order_delivery
)
SELECT 
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE is_on_time = TRUE) AS on_time_orders,
    ROUND(
        (COUNT(*) FILTER (WHERE is_on_time = TRUE) * 100.0 / COUNT(*)), 
        2
    ) AS on_time_delivery_rate
FROM 
    on_time_orders;
   
-- Average Deivery Delay
   WITH order_delivery AS (
    SELECT 
        order_id,
        MAX(d1.date) AS required_date,
        MAX(d2.date) AS shipped_date
    FROM 
        fct_orders f
    JOIN 
        dim_date d1 ON f.required_date_fk = d1.date_sk
    JOIN 
        dim_date d2 ON f.shipped_date_fk = d2.date_sk
    GROUP BY 
        order_id
),
delayed_orders AS (
    SELECT 
        order_id,
        (shipped_date - required_date) AS delivery_delay
    FROM 
        order_delivery
    WHERE 
        shipped_date > required_date -- Filter for delayed orders
)
SELECT 
    COUNT(*) AS total_delayed_orders,
    AVG(delivery_delay) AS average_delivery_delay
FROM 
    delayed_orders;
   
------------------------------------------------------------------------------------------------------------------------
-- Financial KPIs
 -- Net Profit
   WITH order_revenue AS (
    SELECT 
        order_id,
        SUM(unitprice * quantity * (1 - discount)) AS total_revenue,
        MAX(freight) AS freight -- Freight is assumed to be the same for all lines of the same order
    FROM 
        fct_orders
    GROUP BY 
        order_id
)
SELECT 
    order_id,
    total_revenue,
    freight,
    (total_revenue - freight) AS net_profit
FROM 
    order_revenue;
------------------------------------------------------------------------------------------------------------------------



USE SUPPLY_CHAIN;

---1 City wise number of customers and orders placed.
CREATE VIEW cityWise_NOofCustomer_andOrders_placed AS
	 SELECT 
        city,
        COUNT(DISTINCT dim_customers.customer_id) AS customers,
        COUNT(DISTINCT fact_order_lines.order_id) AS orders_count
    FROM dim_customers
    LEFT JOIN fact_order_lines
        ON dim_customers.customer_id = fact_order_lines.customer_id
    GROUP BY city;

SELECT * FROM cityWise_NOofCustomer_andOrders_placed;

---Insights : AS per the answer Ahmedabad and Vadodara has highest number of customer and orders as compared to Surat.


--- 2. Customer wise Total Orders
CREATE VIEW CustomerWiseTotalOrder AS
    SELECT 
        customer_name,
        COUNT(DISTINCT fact_order_lines.order_id) AS orders
    FROM dim_customers
    LEFT JOIN fact_order_lines
        ON dim_customers.customer_id = fact_order_lines.customer_id
    GROUP BY customer_name;

SELECT * FROM CustomerWiseTotalOrder;

--- Insights : Customers like Lotus Mart, Acclaimed Stores, Vijay stores, Rel Fresh, Coolblue, People Mart orders most. 
--             These 6 customers orders more than 50% of total orders. So we should give higher preference to these customers. 
--             For these customers we should have less deviation of OT,IF,OTIF from their target value.


--- 3. Average Lead Time for each city
CREATE VIEW  AVG_Lead_Time_for_each_city AS 
SELECT 
    city,
    ROUND(AVG(DATEDIFF(day, order_placement_date, actual_delivery_date)), 2) AS avg_lead_time
FROM dim_customers
LEFT JOIN fact_order_lines
    ON dim_customers.customer_id = fact_order_lines.customer_id
GROUP BY city;

SELECT * FROM AVG_Lead_Time_for_each_city;

---Insight: Average Lead time for Ahmedabad, Vodadara and Surat is approximately same. 
---         AtliQ Mart should try to reduce lead time of Ahmedabad and Vadodara as there are more number of orders and customers 
--          as compared to Surat.

--- 4. Citywise OT%,IF%,OTIF%
CREATE VIEW Citywise_OT_IF_OTIF_pct AS

SELECT 
    city,
    COUNT(*) AS total_orders,
    COUNT(DISTINCT CASE WHEN on_time = 1 THEN order_id END) AS on_time_orders,
    ROUND(
        COUNT(DISTINCT CASE WHEN on_time = 1 THEN order_id END) * 100.0 / COUNT(*), 
        2
    ) AS pct_On_time,

    COUNT(DISTINCT CASE WHEN in_full = 1 THEN order_id END) AS in_full_orders,
    ROUND(
        COUNT(DISTINCT CASE WHEN in_full = 1 THEN order_id END) * 100.0 / COUNT(*), 
        2
    ) AS pct_In_full,

    COUNT(DISTINCT CASE WHEN otif = 1 THEN order_id END) AS on_time_in_full_orders,
    ROUND(
        COUNT(DISTINCT CASE WHEN otif = 1 THEN order_id END) * 100.0 / COUNT(*), 
        2
    ) AS pct_OTIF

FROM dim_customers
LEFT JOIN fact_orders_aggregate
    ON dim_customers.customer_id = fact_orders_aggregate.customer_id
GROUP BY city;

SELECT * FROM Citywise_OT_IF_OTIF_pct; 


--- Insight : From the above image we can see On Time In Full(OTIF) very less approximately 20%. 
--            So Atliq Mart should try to improve this matric. It will help to expand their market.

--- 5. Customer Wise LIFR,VOFR %
CREATE VIEW CustomerWiseLIFR_VOFR   AS
SELECT
    dc.customer_id,
    dc.customer_name,
    
    -- Line Fill Rate %
    ROUND(
        SUM(CASE WHEN fol.order_qty = fol.delivery_qty THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2
    ) AS line_fill_rate_percent,
    
    -- Volume Fill Rate %
    ROUND(
        SUM(fol.delivery_qty) * 100.0
        / NULLIF(SUM(fol.order_qty), 0), 2
    ) AS volume_fill_rate_percent

FROM fact_order_lines fol
JOIN dim_customers dc ON fol.customer_id = dc.customer_id

GROUP BY dc.customer_id, dc.customer_name;

SELECT * FROM CustomerWiseLIFR_VOFR ;

---6. Product Wise LIFR % and LIFR by month VOFR% and VOFR by month
CREATE VIEW ProductWiseLIFR_VOFR_percent  AS
SELECT
    dp.product_id,
    dp.product_name,
    
    -- Line Fill Rate %
    ROUND(
        SUM(CASE WHEN fol.order_qty = fol.delivery_qty THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2
    ) AS line_fill_rate_percent,
    
    -- Volume Fill Rate %
    ROUND(
        SUM(fol.delivery_qty) * 100.0
        / NULLIF(SUM(fol.order_qty), 0), 2
    ) AS volume_fill_rate_percent

FROM fact_order_lines fol
JOIN dim_products dp ON fol.product_id = dp.product_id

GROUP BY dp.product_id, dp.product_name;

SELECT * FROM ProductWiseLIFR_VOFR_percent;

---7. Days delayed 
CREATE VIEW DAYS_DELAYED AS 
SELECT 
    order_id,
    DATEDIFF(DAY, agreed_delivery_date, actual_delivery_date) AS Days_Delayed
FROM 
    fact_order_lines
WHERE 
    DATEDIFF(DAY, agreed_delivery_date, actual_delivery_date) > 0;

SELECT * FROM DAYS_DELAYED;

---Insights: On an average, Orders getting delayed by 1.69 days to be
--           delivered from the agreed delivery date.     

---8. Customerwise total orders, IF%, OT%, OTIF%
CREATE VIEW Customerwise_OT_IF_OTIF_Percentage AS
WITH x AS (
    SELECT 
        customer_name,
        COUNT(*) AS total_orders,
        SUM(CASE WHEN on_time = 1 THEN 1 ELSE 0 END) AS on_time_orders,
        SUM(CASE WHEN in_full = 1 THEN 1 ELSE 0 END) AS in_full_orders,
        SUM(CASE WHEN otif = 1 THEN 1 ELSE 0 END) AS on_time_in_full_orders
    FROM dim_customers
    LEFT JOIN fact_orders_aggregate
        ON dim_customers.customer_id = fact_orders_aggregate.customer_id
    GROUP BY customer_name
)
SELECT 
    customer_name,
    total_orders,
    on_time_orders,
    in_full_orders,
    on_time_in_full_orders,
    CONCAT(ROUND((on_time_orders * 100.0 / total_orders), 2), '%') AS "OT%",
    CONCAT(ROUND((in_full_orders * 100.0 / total_orders), 2), '%') AS "IF%",
    CONCAT(ROUND((on_time_in_full_orders * 100.0 / total_orders), 2), '%') AS "OTIF%"
FROM x;

SELECT * FROM Customerwise_OT_IF_OTIF_Percentage;

Insights : As Lotus Mart, Acclaimed Mart, Vijay Stores, Coolblue are the top customers of AtliQ Mart but for these customers OT%,IF% and OTIF% is very less as compared to other customers. So we need to improve these numbers to prevent customer churn.

---9. Customerwise Deviation of OT%,IF%,OTIF% from target.
CREATE VIEW Customerwise_Deviation_of_OT_IF_OTIF AS
WITH deviation AS (
    SELECT 
        dc.customer_name,
        ROUND(AVG(dt.column2), 2) AS Target_OT,
        ROUND(AVG(dt.column3), 2) AS Target_IF,
        ROUND(AVG(dt.column4), 2) AS Target_OTIF,
        ROUND(SUM(CASE WHEN fa.on_time = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Actual_OT,
        ROUND(SUM(CASE WHEN fa.in_full = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Actual_IF,
        ROUND(SUM(CASE WHEN fa.otif = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Actual_OTIF
    FROM dim_customers dc
    JOIN dim_targets_orders dt
        ON dc.customer_id = dt.column1
    LEFT JOIN fact_orders_aggregate fa
        ON dc.customer_id = fa.customer_id
    GROUP BY dc.customer_name
)
SELECT 
    customer_name,
    Target_OT - Actual_OT AS OT_deviation,
    Target_IF - Actual_IF AS IF_deviation,
    Target_OTIF - Actual_OTIF AS OTIF_deviation
FROM deviation;

SELECT * FROM Customerwise_Deviation_of_OT_IF_OTIF;


---10. City wise deviation between actual and target OT%,IF%,OTIF%
CREATE VIEW Citywise_deviation_between_actual_target_OT_IF_OTIF_PERCENTAGE AS
WITH target AS (
    SELECT 
        dc.city,
        AVG(dt.column2) AS target_OT,
        AVG(dt.column3) AS target_IF,
        AVG(dt.column4) AS target_OTIF
    FROM dim_targets_orders dt
    JOIN dim_customers dc ON dc.customer_id = dt.column1
    GROUP BY dc.city
),
actual AS (
    SELECT 
        dc.city,
        SUM(CASE WHEN fa.on_time = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS actual_OT,
        SUM(CASE WHEN fa.in_full = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS actual_IF,
        SUM(CASE WHEN fa.otif = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS actual_OTIF
    FROM dim_customers dc
    LEFT JOIN fact_orders_aggregate fa ON dc.customer_id = fa.customer_id
    GROUP BY dc.city
)
SELECT 
    t.city,
    ROUND(t.target_OT - a.actual_OT, 2) AS OT_deviation,
    ROUND(t.target_IF - a.actual_IF, 2) AS IF_deviation,
    ROUND(t.target_OTIF - a.actual_OTIF, 2) AS OTIF_deviation
FROM target t
JOIN actual a ON t.city = a.city;

SELECT * FROM Citywise_deviation_between_actual_target_OT_IF_OTIF_PERCENTAGE;

---Insights : From the above chart you can see major problem AtliQ is facing is that the difference between target OTIF% and actual OTIF% is very high for every city.

---11. Average delivery time for Each customer
CREATE VIEW AVGdeliveryTimeForEachCustomer AS
    SELECT 
        customer_name,
        ROUND(AVG(DATEDIFF(DAY, order_placement_date, actual_delivery_date)), 2) AS avg_delivery_days
    FROM 
        dim_customers
    LEFT JOIN 
        fact_order_lines ON dim_customers.customer_id = fact_order_lines.customer_id
    GROUP BY 
        customer_name;

SELECT * FROM AVGdeliveryTimeForEachCustomer;

---Insights : Lotus Mart, Coolblue, Acclaimed Stores are the top customers of AtliQ Mart but the delivery time for these customers is approximately 1 day more 
--             as compared to other customers. This could led to customer churn.

---12. Weekly trend of IF%, OT% & OTIF%
CREATE VIEW WeeklyTrendOfIF_OT_OTIFpercentage AS
    SELECT  
        d.week_no,
        SUM(CASE WHEN f.on_time = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS OT_percentage,
        SUM(CASE WHEN f.in_full = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS IF_percentage,
        SUM(CASE WHEN f.otif = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS OTIF_percentage
    FROM 
        dim_date d
    LEFT JOIN 
        fact_orders_aggregate f ON f.order_placement_date = d.date
    GROUP BY 
        d.week_no;

SELECT * FROM WeeklyTrendOfIF_OT_OTIFpercentage;

---Insights : OTIF% is very less all over the weeks. This could be one of the main reasons that why AtliQ is facing difficulty to expand it’s business.
--            By forecasting demand accurately, supply chain managers can ensure that they have the right inventory levels, allowing them to meet customer 
--            demand without the risk of stockouts or overstocking.


---13. Customer wise Delivered quantity
CREATE VIEW CustomerWiseDeliveredQuantity AS
    SELECT 
        customer_name,
        SUM(order_qty) AS order_qty
    FROM 
        dim_customers
    LEFT JOIN 
        fact_order_lines ON dim_customers.customer_id = fact_order_lines.customer_id
    GROUP BY 
        customer_name;

SELECT * FROM CustomerWiseDeliveredQuantity;


---14. Customer wise and category wise order quantity
CREATE VIEW CustomerWiseCategoryWiseOrderQuantity AS
    WITH category_totals AS (
        SELECT 
            dc.customer_name,
            SUM(CASE WHEN dp.category = 'Dairy' THEN fol.order_qty ELSE 0 END) AS dairy_qty,
            SUM(CASE WHEN dp.category = 'Food' THEN fol.order_qty ELSE 0 END) AS food_qty,
            SUM(CASE WHEN dp.category = 'Beverages' THEN fol.order_qty ELSE 0 END) AS beverages_qty,
            SUM(fol.order_qty) AS total_qty
        FROM 
            dim_customers dc
        JOIN 
            fact_order_lines fol ON dc.customer_id = fol.customer_id
        JOIN 
            dim_products dp ON fol.product_id = dp.product_id
        GROUP BY 
            dc.customer_name
    )
    SELECT 
        customer_name,
        ROUND((dairy_qty * 100.0 / NULLIF(total_qty, 0)), 2) AS dairy_pct,
        ROUND((food_qty * 100.0 / NULLIF(total_qty, 0)), 2) AS food_pct,
        ROUND((beverages_qty * 100.0 / NULLIF(total_qty, 0)), 2) AS beverages_pct
    FROM 
        category_totals;

SELECT * FROM CustomerWiseCategoryWiseOrderQuantity;


--- Insights : For each customer more than 75% ordered products are dairy products followed by food products and beverages.

--- 15. Top 3 product in each category by delivered quantity
CREATE VIEW Top3ProductInEachCategorybyDeliveredQuantity AS
    WITH ProductOrderQuantities AS (
        SELECT 
            dp.category,
            dp.product_name,
            COALESCE(SUM(fol.order_qty), 0) AS order_qty
        FROM 
            dim_products dp
        LEFT JOIN 
            fact_order_lines fol ON dp.product_id = fol.product_id
        GROUP BY 
            dp.category,
            dp.product_name
    ),
    RankedProducts AS (
        SELECT 
            category,
            product_name,
            order_qty,
            RANK() OVER (PARTITION BY category ORDER BY order_qty DESC) AS rnk
        FROM 
            ProductOrderQuantities
    )
    SELECT 
        category,
        product_name,
        order_qty,
        rnk
    FROM 
        RankedProducts
    WHERE 
        rnk <= 3;

SELECT * FROM Top3ProductInEachCategorybyDeliveredQuantity;

--- These are the top 3 most ordered products from each category.

--- 16. Citywise and categorywsie orders
CREATE VIEW Citywise_categorywise_orders AS
SELECT 
    dc.city,
    COUNT(DISTINCT CASE WHEN dp.category = 'Dairy' THEN fo.order_id END) * 100.0 / COUNT(DISTINCT fo.order_id) AS Dairy,
    COUNT(DISTINCT CASE WHEN dp.category = 'Food' THEN fo.order_id END) * 100.0 / COUNT(DISTINCT fo.order_id) AS Food,
    COUNT(DISTINCT CASE WHEN dp.category = 'Beverages' THEN fo.order_id END) * 100.0 / COUNT(DISTINCT fo.order_id) AS Beverages
FROM 
    dim_customers dc
LEFT JOIN 
    fact_order_lines fo ON dc.customer_id = fo.customer_id
LEFT JOIN 
    dim_products dp ON fo.product_id = dp.product_id
GROUP BY 
    dc.city;

SELECT * FROM Citywise_categorywise_orders;

--- 17. Customer wise most and least ordered products
CREATE VIEW Customer_wise_most_and_least_ordered_products AS
WITH most_orders AS (
    SELECT 
        c.customer_name,
        p.product_name,
        COUNT(f.product_id) AS product_count
    FROM 
        dim_customers c
    JOIN 
        fact_order_lines f ON c.customer_id = f.customer_id
    JOIN 
        dim_products p ON p.product_id = f.product_id
    GROUP BY 
        c.customer_name, p.product_name
),
x AS (
    SELECT 
        customer_name,
        product_name,
        RANK() OVER(PARTITION BY customer_name ORDER BY product_count DESC) AS rnk_max,
        RANK() OVER(PARTITION BY customer_name ORDER BY product_count ASC) AS rnk_min
    FROM 
        most_orders
)
SELECT 
    customer_name,
    MAX(CASE WHEN rnk_max = 1 THEN product_name END) AS most_ordered_product,
    MAX(CASE WHEN rnk_min = 1 THEN product_name END) AS least_ordered_product
FROM 
    x
GROUP BY 
    customer_name;

SELECT * FROM Customer_wise_most_and_least_ordered_products;

--- 18. Week over week change of orders
CREATE VIEW WeekOverWeekChangeOfOrders AS
    WITH x AS (
        SELECT 
            d.week_no,
            COUNT(DISTINCT f.order_id) AS orders
        FROM 
            dim_date d
        LEFT JOIN 
            fact_order_lines f ON d.date = f.order_placement_date
        GROUP BY 
            d.week_no
    ),
    y AS (
        SELECT 
            x.week_no,
            x.orders,
            LAG(x.orders) OVER (ORDER BY x.week_no ASC) AS previous_week_orders
        FROM 
            x
    )
    SELECT 
        y.week_no,
        y.orders,
        y.previous_week_orders,
        CASE 
            WHEN y.previous_week_orders = 0 OR y.previous_week_orders IS NULL THEN 0
            ELSE ROUND(((y.orders - y.previous_week_orders) * 100.0) / y.previous_week_orders, 2)
        END AS percentage_change
    FROM 
        y;

SELECT * FROM WeekOverWeekChangeOfOrders;

--- Total Order lines
CREATE VIEW Total_order_line AS
SELECT COUNT(*) AS TotalOrderLines 
FROM fact_order_lines;

SELECT * FROM Total_order_line;

--- Total order
CREATE VIEW Total_order AS
SELECT COUNT(DISTINCT order_id) AS TotalOrders 
FROM fact_orders_aggregate;

SELECT * FROM Total_order;

---On Time Target
CREATE VIEW AVG_OnTime AS
SELECT AVG(column2) AS AvgOnTimeTarget 
FROM dim_targets_orders;

SELECT * FROM AVG_OnTime;

--- In Full Target
CREATE VIEW AVG_InFull AS
SELECT AVG(column3) AS AvgInFullTarget 
FROM dim_targets_orders;

SELECT * FROM AVG_InFull;

---On-Time-In-Full Target
CREATE VIEW AVG_OTIF_Target AS
SELECT AVG(column4) AS AvgOTIFTarget 
FROM dim_targets_orders;

SELECT * FROM AVG_OTIF_Target;

--- Line fill rate
CREATE VIEW Line_Fill_Rate AS
SELECT 
    FORMAT(
        CAST(SUM(CASE WHEN In_Full = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*),
        'P2'
    ) AS Line_Fill_Rate
FROM fact_order_lines;

SELECT * FROM Line_Fill_Rate;

--- Volume Fill Rate
CREATE VIEW Volume_Fill_Rate AS
SELECT 
    FORMAT(
        CAST(SUM(delivery_qty) AS FLOAT) / SUM(order_qty),
        'P2'
    ) AS Volume_Fill_Rate
FROM fact_order_lines;

SELECT * FROM Volume_Fill_Rate;

--- On Time Delivery %
CREATE VIEW OnTime_Delivery AS
SELECT 
    FORMAT(CAST(SUM(CASE WHEN on_time = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*), 'P2') AS On_Time_Delivery
FROM fact_orders_aggregate;

SELECT * FROM OnTime_Delivery;

--- In Full Delivery %
CREATE VIEW InFull_Delivery AS
SELECT 
    FORMAT(CAST(SUM(CASE WHEN in_full = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*), 'P2') AS In_Full_Delivery
FROM fact_orders_aggregate;

SELECT * FROM InFull_Delivery;

--- On Time In Full
CREATE VIEW OnTime_InFull_Delivery AS
SELECT 
    FORMAT(
        CAST(SUM(CASE WHEN on_time = 1 AND in_full = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*),
        'P2'
    ) AS On_Time_In_Full_Percentage
FROM fact_orders_aggregate;

SELECT * FROM OnTime_InFull_Delivery;


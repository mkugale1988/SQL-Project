SELECT DISTINCT market
FROM dim_customer
WHERE customer = 'Atliq Exclusive' AND region = 'APAC';


SELECT
    COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END) AS unique_products_2020,
    COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN product_code END) AS unique_products_2021,
    ROUND(((COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN product_code END) - 
             COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END)) /
             COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END)) * 100, 2) AS percentage_chg
FROM fact_sales_monthly
WHERE fiscal_year IN (2020, 2021);


SELECT
    segment,
    COUNT(DISTINCT product_code) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;


SELECT
    segment,
    COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END) AS product_count_2020,
    COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN product_code END) AS product_count_2021,
    COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN product_code END) -
    COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END) AS difference
FROM fact_sales_monthly
JOIN dim_product ON fact_sales_monthly.product_code = dim_product.product_code
WHERE fiscal_year IN (2020, 2021)
GROUP BY segment
ORDER BY difference DESC
LIMIT 1;



SELECT
    d.segment,
    COUNT(DISTINCT CASE WHEN f.fiscal_year = 2020 THEN p.product_code END) AS product_count_2020,
    COUNT(DISTINCT CASE WHEN f.fiscal_year = 2021 THEN p.product_code END) AS product_count_2021,
    COUNT(DISTINCT CASE WHEN f.fiscal_year = 2021 THEN p.product_code END) -
    COUNT(DISTINCT CASE WHEN f.fiscal_year = 2020 THEN p.product_code END) AS difference
FROM fact_sales_monthly f
JOIN dim_product p ON f.product_code = p.product_code
JOIN dim_product d ON f.product_code = d.product_code
WHERE f.fiscal_year IN (2020, 2021)
GROUP BY d.segment
ORDER BY difference DESC
;


-- Product with the highest manufacturing cost
SELECT
    dp.product_code,
    dp.product,
    fmc.manufacturing_cost
FROM dim_product dp
JOIN fact_manufacturing_cost fmc ON dp.product_code = fmc.product_code
ORDER BY fmc.manufacturing_cost DESC
LIMIT 1;

-- Product with the lowest manufacturing cost
SELECT
    dp.product_code,
    dp.product,
    fmc.manufacturing_cost
FROM dim_product dp
JOIN fact_manufacturing_cost fmc ON dp.product_code = fmc.product_code
ORDER BY fmc.manufacturing_cost ASC
LIMIT 1;


SELECT
    fs.customer_code,
    dc.customer,
    AVG(fs.pre_invoice_discount_pct) AS average_discount_percentage
FROM fact_pre_invoice_deductions fs
JOIN dim_customer dc ON fs.customer_code = dc.customer_code
WHERE fs.fiscal_year = 2021 AND dc.market = 'India'
GROUP BY fs.customer_code, dc.customer
ORDER BY average_discount_percentage DESC
LIMIT 5;


SELECT
    MONTH(fsm.date) AS Month,
    YEAR(fsm.date) AS Year,
    SUM(fsm.sold_quantity * fgp.gross_price) AS Gross_sales_Amount
FROM fact_sales_monthly fsm
JOIN dim_customer dc ON fsm.customer_code = dc.customer_code
JOIN fact_gross_price fgp ON fsm.product_code = fgp.product_code
WHERE dc.customer = 'Atliq Exclusive'
GROUP BY Month, Year
ORDER BY Year, Month;


SELECT
    CONCAT('Q', QUARTER(date)) AS Quarter,
    SUM(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly
WHERE YEAR(date) = 2020
GROUP BY Quarter
ORDER BY total_sold_quantity DESC
LIMIT 1;



SELECT
    dc.channel,
    SUM(fsm.sold_quantity * fgp.gross_price) / 1000000 AS gross_sales_mln,
    (SUM(fsm.sold_quantity * fgp.gross_price) / (SELECT SUM(sold_quantity * gross_price) FROM fact_sales_monthly WHERE fiscal_year = 2021)) * 100 AS percentage
FROM fact_sales_monthly fsm
JOIN dim_customer dc ON fsm.customer_code = dc.customer_code
JOIN dim_product dp ON fsm.product_code = dp.product_code
JOIN fact_gross_price fgp ON fsm.product_code = fgp.product_code
WHERE fsm.fiscal_year = 2021
GROUP BY dc.channel
ORDER BY gross_sales_mln DESC;


SELECT *
FROM (
    SELECT
        division,
        product_code,
        product,
        total_sold_quantity,
        ROW_NUMBER() OVER(PARTITION BY division ORDER BY total_sold_quantity DESC) AS rank_order
    FROM (
        SELECT
            dp.division,
            fsm.product_code,
            dp.product,
            SUM(fsm.sold_quantity) AS total_sold_quantity
        FROM fact_sales_monthly fsm
        JOIN dim_product dp ON fsm.product_code = dp.product_code
        WHERE fsm.fiscal_year = 2021
        GROUP BY dp.division, fsm.product_code, dp.product
    ) AS product_sales
) AS ranked_products
WHERE rank_order <= 3
ORDER BY division, rank_order;






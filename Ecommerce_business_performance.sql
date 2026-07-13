---Creating a database---

CREATE DATABASE Ecommerce_db
-- checking for no duplicates--

SELECT COUNT (*) FROM customers 
SELECT COUNT (*) FROM orders
SELECT COUNT (*) FROM order_items
SELECT COUNT (*) FROM order_payments
SELECT COUNT (*) FROM order_reviews
SELECT COUNT (*) FROM products
SELECT COUNT (*) FROM sellers

SELECT customer_id , count(*) 
from customers
group by customer_id
having  count(*)>1

SELECT order_id , count(*) 
from orders
group by order_id
having  count(*)>1

SELECT product_id , count(*) 
from products
group by product_id
having  count(*)>1

SELECT seller_id , count(*) 
from sellers
group by seller_id
having  count(*)>1

--- primary key--

Alter table customers
Add constraint pk_customers
primary key (customer_id)

Alter table orders
Add constraint pk_orders
primary key (order_id)

Alter table products
Add constraint pk_products
primary key (product_id)

Alter table sellers
Add constraint pk_sellers
primary key (seller_id)


--- foreign key--
 -- orders to customers--

 alter table orders
 add constraint fk_orders_customers
 foreign key (customer_id)
 references customers (customer_id)
  -- order items to orders--

  alter table orders
 add constraint fk_order_items_orders
 foreign key (order_id)
 references orders (order_id)

 -- order items to products--

  alter table order_items
 add constraint fk_orderitems_products
 foreign key (product_id)
 references products (product_id)

 -- order items to sellers
  alter table order_items
 add constraint fk_orderitems_sellers
 foreign key (seller_id)
 references sellers (seller_id)

 -- order payments to orders
 alter table order_payments
 add constraint fk_orderpayments_orders
 foreign key (orders)
 references orders (order_id)

 -- order review to order 
 alter table order_reviews
 add constraint fk_orderreviews_orders
 foreign key (order_id)
 references orders (order_id)

-- business questions 
 -- revenue anlysis--
 --Total revenue ---

SELECT SUM(payment_value) AS total_revenue FROM order_payments

-- Revenue over time--

SELECT YEAR (o.order_purchase_timestamp) as order_year ,
MONTH (o.order_purchase_timestamp) as order_month,
ROUND(SUM(op.payment_value),2) as revenue
FROM orders o
JOIN order_payments op ON O.order_id = op.order_id
GROUP BY YEAR (o.order_purchase_timestamp) ,MONTH (o.order_purchase_timestamp)
ORDER BY order_year, order_month

-- Top 5 product with highest revenue--

SELECT TOP 5 p.product_category_name,
ROUND(SUM(OI.price),2) as product_revenue
FROM order_items oi 
JOIN products p ON oi.product_id = p.product_id 
GROUP BY p.product_category_name

-- Ranking products based on revenue--

SELECT p.product_category_name,
ROUND(SUM(OI.price),2) as product_revenue,
DENSE_RANK() OVER(order by sum(oi.price) DESC) as revenue_rank
FROM order_items oi 
JOIN products p ON oi.product_id = p.product_id 
GROUP BY p.product_category_name
ORDER BY revenue_rank

--- customer analysis--
 -- Count total unique customers--

 SELECT COUNT(distinct customer_unique_id)
 as total_unique_customers FROM customers


 -- top 10 customers by revenue

 SELECT TOP 10 c.customer_unique_id,
 SUM(op.payment_value) as revenue,
 DENSE_RANK () OVER (order by SUM(op.payment_value) DESC) as customer_rank
 FROM customers c
 JOIN orders O ON c.customer_id = o.customer_id
 JOIN order_payments op ON O.order_id = OP.order_id
 GROUP BY c.customer_unique_id
 ORDER BY revenue DESC
   
   -- Number of Repeat customers--

   WITH customers_orders AS (
   SELECT c.customer_unique_id, COUNT(O.order_id) AS total_orders 
   FROM customers c
   JOIN orders o ON c.customer_id = o.customer_id
   GROUP BY c.customer_unique_id
  )
SELECT COUNT(*) as repeat_customers
FROM customers_orders 
WHERE total_orders > 1

---- product analysis--
-- Products with highest sale volume--

SELECT product_category_name ,COUNT (*) AS units_sold
FROM products P
JOIN  order_items oi ON p.product_id = oi.product_id 
GROUP BY P.product_category_name
ORDER BY units_sold DESC

-- Products generating above average revenue--
WITH category_revenue AS (
SELECT p.product_category_name, SUM (oi.price) as revenue
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_category_name)
   
SELECT * FROM category_revenue 
WHERE revenue > (SELECT AVG(revenue) FROM category_revenue)
ORDER BY revenue DESC

--- Average review score--

SELECT p.product_category_name,
ROUND(AVG(CAST (r.review_score AS FLOAT )),2) AS avg_rating,
COUNT(r.review_id) AS total_review
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN order_reviews r ON oi.order_id = r.order_id
GROUP BY p.product_category_name
HAVING COUNT(r.review_id) >=100
ORDER BY avg_rating DESC


-- Late delivery percentage---

SELECT 
ROUND(
  100 * SUM(
  CASE 
  WHEN
  order_delivered_customer_date > order_estimated_delivery_date
  THEN 1
  ELSE 0
  END) / COUNT(*),2 
 ) AS late_delivery_percentage
  FROM orders
  WHERE order_delivered_customer_date is NOT NULL

  --Sellers with highest revenue--

SELECT s.seller_id,
SUM (oi.price) as revenue,
DENSE_RANK() OVER(order by SUM (oi.price )DESC) as ranking
FROM sellers s
JOIN order_items oi ON s.seller_id = oi.seller_id
JOIN order_payments op ON oi.order_id = op.order_id
GROUP BY s.seller_id
ORDER BY revenue DESC

--Impact of late delivery on product ratings--

SELECT
CASE
WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
 THEN 'Late Delivery'
 ELSE 'On Time'
 END AS Delivery_Status,

    ROUND(AVG(CAST(r.review_score AS FLOAT)),2) AS Average_Review_Score,

    COUNT(*) AS Total_Orders

FROM orders o
JOIN order_reviews r
    ON o.order_id = r.order_id

WHERE o.order_delivered_customer_date IS NOT NULL

GROUP BY
CASE
    WHEN o.order_delivered_customer_date >
         o.order_estimated_delivery_date
    THEN 'Late Delivery'
    ELSE 'On Time'
END;







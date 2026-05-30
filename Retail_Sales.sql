CREATE DATABASE retail_db;
USE retail_db;

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_status INT,
    order_date DATE,
    required_date DATE,
    shipped_date DATE,
    store_id INT,
    staff_id INT,
    order_status_label VARCHAR(50)
);

CREATE TABLE order_items (
    order_id INT,
    item_id INT,
    product_id INT,
    quantity INT,
    list_price DECIMAL(10,2),
    discount DECIMAL(5,2),
    net_revenue DECIMAL(12,2),

    PRIMARY KEY (order_id, item_id)
);

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(30),
    email VARCHAR(150),
    street VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    zip_code VARCHAR(20)
);

CREATE TABLE brands (
    brand_id INT PRIMARY KEY,
    brand_name VARCHAR(100)
);

CREATE TABLE product (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(255),
    brand_id INT,
    category_id INT,
    model_year INT,
    list_price DECIMAL(10,2)
);

CREATE TABLE staff (
    staff_id INT PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(150),
    phone VARCHAR(30),
    Active TINYINT,
    store_id INT,
    manager_id INT
);

CREATE TABLE stores (
    store_id INT PRIMARY KEY,
    store_name VARCHAR(150),
    phone VARCHAR(30),
    email VARCHAR(150),
    street VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    zip_code VARCHAR(20)
);

CREATE TABLE stock (
    store_id INT,
    product_id INT,
    quantity INT,

    PRIMARY KEY (store_id, product_id)
);

CREATE TABLE categories (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(100)
);

# Products-Brands #
ALTER TABLE product
ADD CONSTRAINT fk_product_brands
FOREIGN KEY (brand_id)
REFERENCES brands(brand_id);

# Products- Categories #
ALTER TABLE product
ADD CONSTRAINT fk_product_categories
FOREIGN KEY (category_id)
REFERENCES categories(category_id);

# Staffs - Stores #
ALTER TABLE staff
ADD CONSTRAINT fk_staff_stores
FOREIGN KEY (store_id)
REFERENCES stores(store_id);

# Staffs - Manager #
ALTER TABLE staff
ADD CONSTRAINT fk_staff_manager
FOREIGN KEY (manager_id)
REFERENCES staff(staff_id);

# Stocks - Stores #
ALTER TABLE stock
ADD CONSTRAINT fk_stock_stores
FOREIGN KEY (store_id)
REFERENCES stores(store_id);

# Stocks-Products #
ALTER TABLE stock
ADD CONSTRAINT fk_stock_product
FOREIGN KEY (Product_id)
REFERENCES product(Product_id);

# Orders - Customers #
ALTER TABLE orders
ADD CONSTRAINT fk_orders_customers
FOREIGN KEY (customer_id)
REFERENCES customers(customer_id);

# Orders - Stores #
ALTER TABLE orders
ADD CONSTRAINT fk_orders_stores
FOREIGN KEY (store_id)
REFERENCES stores(store_id);

# Order - Staff #
ALTER TABLE orders
ADD CONSTRAINT fk_orders_staff
FOREIGN KEY (staff_id)
REFERENCES staff(staff_id);

# Order_items - Orders #
ALTER TABLE order_items
ADD CONSTRAINT fk_orderitems_orders
FOREIGN KEY (order_id)
REFERENCES orders(order_id);

# Order_items - Products #
ALTER TABLE order_items
ADD CONSTRAINT fk_orderitems_product
FOREIGN KEY (product_id)
REFERENCES product(product_id);


SELECT 
    TABLE_NAME,
    CONSTRAINT_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE REFERENCED_TABLE_NAME IS NOT NULL
AND TABLE_SCHEMA = 'retail_db';

select  * from brands;
select  * from categories;
select  * from customers;
select  * from order_items;
select  * from product;
select  * from staff;
select  * from orders;
select  * from stock;
select  * from stores;

SHOW KEYS FROM product WHERE Key_name = 'PRIMARY';
SHOW KEYS FROM orders WHERE Key_name = 'PRIMARY';
SHOW KEYS FROM customers WHERE Key_name = 'PRIMARY';
SHOW KEYS FROM stock WHERE Key_name = 'PRIMARY';

SELECT 
    o.order_id,
    c.first_name,
    p.product_name,
    oi.quantity,
    oi.net_revenue
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN product p
    ON oi.product_id = p.product_id
LIMIT 10;

# Q1 — Revenue by Store

SELECT 
    s.store_name,
    ROUND(SUM(oi.net_revenue),2) AS total_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN stores s
    ON o.store_id = s.store_id
GROUP BY s.store_name
ORDER BY total_revenue DESC;

# Q2 — Revenue by Brand

SELECT 
    b.brand_name,
    ROUND(SUM(oi.net_revenue),2) AS total_revenue
FROM order_items oi
JOIN product p
    ON oi.product_id = p.product_id
JOIN brands b
    ON p.brand_id = b.brand_id
GROUP BY b.brand_name
ORDER BY total_revenue DESC;

# Q3 — Revenue by Category

SELECT 
    c.category_name,
    ROUND(SUM(oi.net_revenue),2) AS total_revenue
FROM order_items oi
JOIN product p
    ON oi.product_id = p.product_id
JOIN categories c
    ON p.category_id = c.category_id
GROUP BY c.category_name
ORDER BY total_revenue DESC;

# Q4 — Top 10 Best-Selling Products

SELECT 
    p.product_name,
    SUM(oi.quantity) AS total_quantity_sold,
    ROUND(SUM(oi.net_revenue),2) AS total_revenue
FROM order_items oi
JOIN product p
    ON oi.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_quantity_sold DESC
LIMIT 10;

# Q5 — Staff Performance

SELECT 
    CONCAT(s.first_name,' ',s.last_name) AS staff_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.net_revenue),2) AS total_revenue
FROM staff s
JOIN orders o
    ON s.staff_id = o.staff_id
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY staff_name
ORDER BY total_revenue DESC;

# Q6 — Monthly Sales Trend (2016–2018)

SELECT 
    YEAR(o.order_date) AS order_year,
    MONTH(o.order_date) AS order_month,
    ROUND(SUM(oi.net_revenue),2) AS monthly_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY order_year, order_month
ORDER BY order_year, order_month;

# Q7 — Delayed Shipment Analysis by Store

SELECT 
    s.store_name,
    COUNT(o.order_id) AS total_orders,
    
    SUM(
        CASE
            WHEN o.shipped_date > o.required_date
            THEN 1
            ELSE 0
        END
    ) AS delayed_orders,

    ROUND(
        SUM(
            CASE
                WHEN o.shipped_date > o.required_date
                THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(o.order_id),
        2
    ) AS delay_rate_percent

FROM orders o
JOIN stores s
    ON o.store_id = s.store_id

GROUP BY s.store_name
ORDER BY delay_rate_percent DESC;

# Q8 — Top 15 Customers by Order Frequency + Lifetime Value

SELECT 
    c.customer_id,
    CONCAT(c.first_name,' ',c.last_name) AS customer_name,

    COUNT(DISTINCT o.order_id) AS total_orders,

    ROUND(SUM(oi.net_revenue),2) AS lifetime_value

FROM customers c

JOIN orders o
    ON c.customer_id = o.customer_id

JOIN order_items oi
    ON o.order_id = oi.order_id

GROUP BY c.customer_id, customer_name

ORDER BY lifetime_value DESC
LIMIT 15;

# Q9 — Customer Distribution by State

SELECT 
    state,
    COUNT(customer_id) AS total_customers
FROM customers
GROUP BY state
ORDER BY total_customers DESC;

# Q10 — Inventory Low Stock Alert

SELECT 
    s.store_name,
    p.product_name,
    st.quantity,

    CASE
        WHEN st.quantity = 0 THEN 'Out of Stock'
        WHEN st.quantity <= 10 THEN 'Low Stock'
        ELSE 'Adequate'
    END AS stock_status

FROM stock st

JOIN stores s
    ON st.store_id = s.store_id

JOIN product p
    ON st.product_id = p.product_id

ORDER BY st.quantity ASC;

# Q11 — Year-over-Year Revenue by Store

SELECT 
    s.store_name,

    YEAR(o.order_date) AS order_year,

    ROUND(SUM(oi.net_revenue),2) AS total_revenue

FROM orders o

JOIN order_items oi
    ON o.order_id = oi.order_id

JOIN stores s
    ON o.store_id = s.store_id

GROUP BY s.store_name, order_year

ORDER BY s.store_name, order_year;

# Q12 — Discount Tier Impact on Revenue

SELECT 

    CASE
        WHEN discount <= 0.05 THEN '0-5%'
        WHEN discount <= 0.10 THEN '6-10%'
        WHEN discount <= 0.15 THEN '11-15%'
        ELSE '16-20%'
    END AS discount_tier,

    COUNT(*) AS total_orders,

    ROUND(SUM(net_revenue),2) AS total_revenue,

    ROUND(AVG(net_revenue),2) AS avg_revenue

FROM order_items

GROUP BY discount_tier

ORDER BY total_revenue DESC;


-- Adding New Update

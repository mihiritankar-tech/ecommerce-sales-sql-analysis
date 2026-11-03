-- =====================================================================
-- E-Commerce Sales Analysis | Database Schema
-- Compatible with SQLite, PostgreSQL and MySQL (standard SQL types)
-- =====================================================================

DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id    INTEGER PRIMARY KEY,
    customer_name  VARCHAR(100) NOT NULL,
    segment        VARCHAR(30)  NOT NULL,   -- Consumer | Small Business | Corporate
    city           VARCHAR(50)  NOT NULL,
    region         VARCHAR(30)  NOT NULL,
    signup_date    DATE         NOT NULL
);

CREATE TABLE products (
    product_id     INTEGER PRIMARY KEY,
    product_name   VARCHAR(100)  NOT NULL,
    category       VARCHAR(50)   NOT NULL,
    unit_price     DECIMAL(10,2) NOT NULL,
    unit_cost      DECIMAL(10,2) NOT NULL
);

CREATE TABLE orders (
    order_id       INTEGER PRIMARY KEY,
    customer_id    INTEGER     NOT NULL REFERENCES customers(customer_id),
    order_date     DATE        NOT NULL,
    channel        VARCHAR(30) NOT NULL,    -- Website | Mobile App | Marketplace
    status         VARCHAR(20) NOT NULL     -- Delivered | Returned | Cancelled
);

CREATE TABLE order_items (
    order_item_id  INTEGER PRIMARY KEY,
    order_id       INTEGER       NOT NULL REFERENCES orders(order_id),
    product_id     INTEGER       NOT NULL REFERENCES products(product_id),
    quantity       INTEGER       NOT NULL,
    unit_price     DECIMAL(10,2) NOT NULL,
    discount       DECIMAL(4,2)  NOT NULL DEFAULT 0   -- e.g. 0.10 = 10% off
);

CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_date     ON orders(order_date);
CREATE INDEX idx_items_order     ON order_items(order_id);
CREATE INDEX idx_items_product   ON order_items(product_id);

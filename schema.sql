DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS delivery_log CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS cart_items CASCADE;
DROP TABLE IF EXISTS product_images CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS subcategories CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS pickup_point_schedule CASCADE;
DROP TABLE IF EXISTS pickup_points CASCADE;
DROP TABLE IF EXISTS couriers CASCADE;
DROP TABLE IF EXISTS warehouses CASCADE;
DROP TABLE IF EXISTS sellers CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS cities CASCADE;
DROP TABLE IF EXISTS promo_codes CASCADE;

-- 1. Города
CREATE TABLE cities (
    city_id SERIAL PRIMARY KEY,
    name    VARCHAR(100) NOT NULL UNIQUE,
    region  VARCHAR(100) NOT NULL
);

-- 2. Покупатели
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    email       VARCHAR(100) NOT NULL UNIQUE,
    city_id     INT REFERENCES cities(city_id)
);

-- 3. Продавцы
CREATE TABLE sellers (
    seller_id    SERIAL PRIMARY KEY,
    company_name VARCHAR(100) NOT NULL,
    city_id      INT REFERENCES cities(city_id),
    rating       NUMERIC(3,2) NOT NULL DEFAULT 0.00
);

-- 4. Склады
CREATE TABLE warehouses (
    warehouse_id SERIAL PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    city_id      INT NOT NULL REFERENCES cities(city_id)
);

-- 5. Курьеры
CREATE TABLE couriers (
    courier_id SERIAL PRIMARY KEY,
    name       VARCHAR(100) NOT NULL,
    city_id    INT NOT NULL REFERENCES cities(city_id),
    rating     NUMERIC(3,2) NOT NULL DEFAULT 5.00
);

-- 6. Пункты выдачи (ПВЗ)
CREATE TABLE pickup_points (
    point_id SERIAL PRIMARY KEY,
    name     VARCHAR(100) NOT NULL,
    city_id  INT NOT NULL REFERENCES cities(city_id),
    address  TEXT NOT NULL
);

-- 7. Расписание ПВЗ
CREATE TABLE pickup_point_schedule (
    schedule_id SERIAL PRIMARY KEY,
    point_id    INT  NOT NULL REFERENCES pickup_points(point_id) ON DELETE CASCADE,
    day_of_week INT  NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
    open_time   TIME NOT NULL
);

-- 8. Категории
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE
);

-- 9. Подкатегории
CREATE TABLE subcategories (
    subcategory_id SERIAL PRIMARY KEY,
    category_id    INT NOT NULL REFERENCES categories(category_id) ON DELETE CASCADE,
    name           VARCHAR(100) NOT NULL
);

-- 10. Товары (цена и остаток хранятся здесь)
CREATE TABLE products (
    product_id     SERIAL PRIMARY KEY,
    name           VARCHAR(200) NOT NULL,
    seller_id      INT NOT NULL REFERENCES sellers(seller_id),
    subcategory_id INT NOT NULL REFERENCES subcategories(subcategory_id),
    price          NUMERIC(10,2) NOT NULL CHECK (price > 0),
    stock_qty      INT NOT NULL DEFAULT 0
);

-- 11. Изображения товаров
CREATE TABLE product_images (
    image_id   SERIAL PRIMARY KEY,
    product_id INT  NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    url        TEXT NOT NULL
);

-- 12. Промокоды
CREATE TABLE promo_codes (
    promo_id     SERIAL PRIMARY KEY,
    code         VARCHAR(30) NOT NULL UNIQUE,
    discount_pct INT NOT NULL CHECK (discount_pct BETWEEN 1 AND 100),
    valid_to     DATE NOT NULL
);

-- 13. Корзина
CREATE TABLE cart_items (
    cart_item_id SERIAL PRIMARY KEY,
    customer_id  INT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    product_id   INT NOT NULL REFERENCES products(product_id),
    quantity     INT NOT NULL DEFAULT 1 CHECK (quantity > 0)
);

-- 14. Заказы
CREATE TABLE orders (
    order_id    SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(customer_id),
    order_date  TIMESTAMP NOT NULL DEFAULT NOW(),
    status      VARCHAR(20) NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending','confirmed','assembling',
                                  'shipped','in_transit','at_pickup',
                                  'delivered','cancelled','returned'))
);

-- 15. Детали доставки заказа
CREATE TABLE order_delivery (
    delivery_id     SERIAL PRIMARY KEY,
    order_id        INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    delivery_type   VARCHAR(10) NOT NULL CHECK (delivery_type IN ('pickup','courier')),
    pickup_point_id INT REFERENCES pickup_points(point_id),
    courier_id      INT REFERENCES couriers(courier_id)
);

-- 16. Позиции заказа
CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id      INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id    INT NOT NULL REFERENCES products(product_id),
    quantity      INT NOT NULL CHECK (quantity > 0)
);

-- 17. Лог доставки
CREATE TABLE delivery_log (
    log_id     SERIAL PRIMARY KEY,
    order_id   INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    status     VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 18. Отзывы
CREATE TABLE reviews (
    review_id   SERIAL PRIMARY KEY,
    product_id  INT NOT NULL REFERENCES products(product_id),
    customer_id INT NOT NULL REFERENCES customers(customer_id),
    rating      INT NOT NULL CHECK (rating BETWEEN 1 AND 5)
);


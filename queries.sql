-- ============================================================
-- 50 SQL-запросов для Online Marketplace Database
-- ============================================================

-- ============================================================
-- РАЗДЕЛ 1: Базовые SELECT запросы (1-5)
-- ============================================================

-- 1. Все товары с ценой и остатком
SELECT p.product_id, p.name, s.company_name AS seller, p.price, p.stock_qty
FROM products p
JOIN sellers s ON p.seller_id = s.seller_id
ORDER BY p.price DESC;

-- 2. Покупатели из Москвы
SELECT c.name, c.email
FROM customers c
JOIN cities ci ON c.city_id = ci.city_id
WHERE ci.name = 'Москва';

-- 3. Товары дешевле 5000 рублей
SELECT p.name, p.price
FROM products p
WHERE p.price < 5000
ORDER BY p.price;

-- 4. Заказы со статусом 'delivered'
SELECT order_id, customer_id, order_date, status
FROM orders
WHERE status = 'delivered'
ORDER BY order_date DESC;

-- 5. Курьеры с рейтингом выше 4.5
SELECT name, rating
FROM couriers
WHERE rating > 4.5
ORDER BY rating DESC;

-- ============================================================
-- РАЗДЕЛ 2: JOIN запросы (6-12)
-- ============================================================

-- 6. Товары с категорией и подкатегорией
SELECT p.name, cat.name AS category, sub.name AS subcategory
FROM products p
JOIN subcategories sub ON p.subcategory_id = sub.subcategory_id
JOIN categories cat ON sub.category_id = cat.category_id
ORDER BY cat.name, sub.name;

-- 7. Заказы с именем покупателя и городом
SELECT o.order_id, c.name AS customer, ci.name AS city, o.status
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN cities ci ON c.city_id = ci.city_id
ORDER BY o.order_date DESC;

-- 8. Позиции заказа с названием товара и ценой
SELECT oi.order_id, p.name AS product, oi.quantity,
       p.price, oi.quantity * p.price AS subtotal
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id;

-- 9. Заказы с деталями доставки (ПВЗ или курьер)
SELECT o.order_id, c.name AS customer, od.delivery_type,
       pp.name AS pickup_point, co.name AS courier
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_delivery od ON o.order_id = od.order_id
LEFT JOIN pickup_points pp ON od.pickup_point_id = pp.point_id
LEFT JOIN couriers co ON od.courier_id = co.courier_id;

-- 10. Товары продавца с ценой и остатком
SELECT p.name, s.company_name, p.price, p.stock_qty
FROM products p
JOIN sellers s ON p.seller_id = s.seller_id
ORDER BY s.company_name, p.name;

-- 11. Отзывы с именем покупателя и товара
SELECT r.rating, c.name AS customer, p.name AS product
FROM reviews r
JOIN customers c ON r.customer_id = c.customer_id
JOIN products p ON r.product_id = p.product_id
ORDER BY r.rating DESC;

-- 12. Полная информация о заказе (6 таблиц)
SELECT o.order_id, cu.name AS customer, ci.name AS city,
       p.name AS product, oi.quantity, p.price,
       od.delivery_type, co.name AS courier, pp.name AS pickup_point
FROM orders o
JOIN customers cu ON o.customer_id = cu.customer_id
JOIN cities ci ON cu.city_id = ci.city_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN order_delivery od ON o.order_id = od.order_id
LEFT JOIN couriers co ON od.courier_id = co.courier_id
LEFT JOIN pickup_points pp ON od.pickup_point_id = pp.point_id
WHERE o.status = 'delivered';

-- ============================================================
-- РАЗДЕЛ 3: Агрегация (13-19)
-- ============================================================

-- 13. Количество заказов по статусам
SELECT status, COUNT(*) AS order_count
FROM orders
GROUP BY status
ORDER BY order_count DESC;

-- 14. Средний рейтинг по продавцам
SELECT s.company_name, ROUND(AVG(r.rating), 2) AS avg_rating, COUNT(r.review_id) AS reviews
FROM sellers s
JOIN products p ON s.seller_id = p.seller_id
JOIN reviews r ON p.product_id = r.product_id
GROUP BY s.company_name
ORDER BY avg_rating DESC;

-- 15. Сумма продаж по категориям
SELECT cat.name AS category, SUM(oi.quantity * p.price) AS total_sales
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN subcategories sub ON p.subcategory_id = sub.subcategory_id
JOIN categories cat ON sub.category_id = cat.category_id
GROUP BY cat.name
ORDER BY total_sales DESC;

-- 16. Покупатели с количеством заказов (только > 1)
SELECT c.name, COUNT(o.order_id) AS order_count
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.name
HAVING COUNT(o.order_id) > 1
ORDER BY order_count DESC;

-- 17. Топ-5 самых продаваемых товаров
SELECT p.name, SUM(oi.quantity) AS total_sold
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.name
ORDER BY total_sold DESC
LIMIT 5;

-- 18. Количество товаров по категориям
SELECT cat.name AS category, COUNT(p.product_id) AS product_count
FROM categories cat
JOIN subcategories sub ON cat.category_id = sub.category_id
JOIN products p ON sub.subcategory_id = p.subcategory_id
GROUP BY cat.name
ORDER BY product_count DESC;

-- 19. Средняя цена товаров по категориям
SELECT cat.name AS category, ROUND(AVG(p.price), 2) AS avg_price
FROM categories cat
JOIN subcategories sub ON cat.category_id = sub.category_id
JOIN products p ON sub.subcategory_id = p.subcategory_id
GROUP BY cat.name
ORDER BY avg_price DESC;

-- ============================================================
-- РАЗДЕЛ 4: Подзапросы (20-27)
-- ============================================================

-- 20. Товары, которые есть в заказах (IN)
SELECT name FROM products
WHERE product_id IN (SELECT DISTINCT product_id FROM order_items);

-- 21. Товары, которых нет ни в одном заказе (NOT IN)
SELECT name FROM products
WHERE product_id NOT IN (SELECT DISTINCT product_id FROM order_items);

-- 22. Покупатели, у которых есть хотя бы один заказ (EXISTS)
SELECT name FROM customers c
WHERE EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id
);

-- 23. Покупатели без ни одного заказа (NOT EXISTS)
SELECT name FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id
);

-- 24. Товары дороже средней цены (коррелированный подзапрос)
SELECT name, price
FROM products
WHERE price > (SELECT AVG(price) FROM products)
ORDER BY price DESC;

-- 25. Покупатели с количеством заказов выше среднего
SELECT c.name, COUNT(o.order_id) AS order_count
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.name
HAVING COUNT(o.order_id) > (SELECT AVG(cnt) FROM (
    SELECT COUNT(*) AS cnt FROM orders GROUP BY customer_id
) sub);

-- 26. Продавцы с товарами в категории 'Электроника'
SELECT DISTINCT s.company_name
FROM sellers s
WHERE s.seller_id IN (
    SELECT p.seller_id FROM products p
    JOIN subcategories sub ON p.subcategory_id = sub.subcategory_id
    JOIN categories cat ON sub.category_id = cat.category_id
    WHERE cat.name = 'Электроника'
);

-- 27. Города, в которых есть и покупатели, и ПВЗ
SELECT ci.name FROM cities ci
WHERE ci.city_id IN (SELECT city_id FROM customers)
  AND ci.city_id IN (SELECT city_id FROM pickup_points);

-- ============================================================
-- РАЗДЕЛ 5: CTE (28-31)
-- ============================================================

-- 28. CTE: топ покупатели по количеству заказов
WITH customer_orders AS (
    SELECT c.name, COUNT(o.order_id) AS order_count
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status = 'delivered'
    GROUP BY c.name
)
SELECT name, order_count
FROM customer_orders
ORDER BY order_count DESC
LIMIT 5;

-- 29. CTE: продажи по месяцам (количество заказов)
WITH monthly_orders AS (
    SELECT DATE_TRUNC('month', order_date) AS month, COUNT(*) AS order_count
    FROM orders
    WHERE status = 'delivered'
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT TO_CHAR(month, 'YYYY-MM') AS month, order_count
FROM monthly_orders
ORDER BY month;

-- 30. CTE: рейтинг товаров с количеством отзывов
WITH product_ratings AS (
    SELECT p.name, ROUND(AVG(r.rating), 2) AS avg_rating, COUNT(*) AS review_count
    FROM products p
    JOIN reviews r ON p.product_id = r.product_id
    GROUP BY p.name
)
SELECT * FROM product_ratings
WHERE review_count >= 2
ORDER BY avg_rating DESC;

-- 31. CTE с FILTER: статистика заказов по статусам
WITH order_stats AS (
    SELECT
        COUNT(*) AS total_orders,
        COUNT(*) FILTER (WHERE status = 'delivered')  AS delivered,
        COUNT(*) FILTER (WHERE status = 'cancelled')  AS cancelled,
        COUNT(*) FILTER (WHERE status = 'returned')   AS returned,
        COUNT(*) FILTER (WHERE status = 'pending')    AS pending
    FROM orders
)
SELECT * FROM order_stats;

-- ============================================================
-- РАЗДЕЛ 6: Оконные функции (32-36)
-- ============================================================

-- 32. Ранг товаров по цене внутри категории
SELECT cat.name AS category, p.name, p.price,
       RANK() OVER (PARTITION BY cat.name ORDER BY p.price DESC) AS price_rank
FROM products p
JOIN subcategories sub ON p.subcategory_id = sub.subcategory_id
JOIN categories cat ON sub.category_id = cat.category_id;

-- 33. Накопительное количество заказов по дате
SELECT order_date::DATE AS day,
       COUNT(*) AS daily_orders,
       SUM(COUNT(*)) OVER (ORDER BY order_date::DATE) AS running_total
FROM orders
WHERE status = 'delivered'
GROUP BY order_date::DATE
ORDER BY day;

-- 34. Предыдущий и следующий заказ покупателя (LAG/LEAD)
SELECT customer_id, order_date, status,
       LAG(order_date)  OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_order_date,
       LEAD(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS next_order_date
FROM orders
ORDER BY customer_id, order_date;

-- 35. DENSE_RANK продавцов по количеству продаж
SELECT s.company_name, COUNT(oi.order_item_id) AS items_sold,
       DENSE_RANK() OVER (ORDER BY COUNT(oi.order_item_id) DESC) AS sales_rank
FROM sellers s
JOIN products p ON s.seller_id = p.seller_id
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY s.company_name;

-- 36. Доля каждого товара в общих продажах (%)
SELECT p.name,
       SUM(oi.quantity * p.price) AS sales,
       ROUND(100.0 * SUM(oi.quantity * p.price) /
             SUM(SUM(oi.quantity * p.price)) OVER (), 2) AS pct
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.name
ORDER BY sales DESC;

-- ============================================================
-- РАЗДЕЛ 7: Аналитические запросы (37-42)
-- ============================================================

-- 37. Курьеры с количеством доставленных заказов
SELECT co.name, COUNT(od.order_id) AS deliveries, co.rating
FROM couriers co
LEFT JOIN order_delivery od ON co.courier_id = od.courier_id
LEFT JOIN orders o ON od.order_id = o.order_id AND o.status = 'delivered'
GROUP BY co.name, co.rating
ORDER BY deliveries DESC;

-- 38. ПВЗ с количеством заказов
SELECT pp.name, ci.name AS city, COUNT(od.order_id) AS orders_count
FROM pickup_points pp
JOIN cities ci ON pp.city_id = ci.city_id
LEFT JOIN order_delivery od ON pp.point_id = od.pickup_point_id
GROUP BY pp.name, ci.name
ORDER BY orders_count DESC;

-- 39. Анализ корзины: что чаще добавляют, но не покупают
SELECT p.name, COUNT(ci.cart_item_id) AS in_cart,
       COUNT(oi.order_item_id) AS in_orders
FROM products p
LEFT JOIN cart_items ci ON p.product_id = ci.product_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.name
HAVING COUNT(ci.cart_item_id) > 0
ORDER BY in_cart DESC;

-- 40. Товары с низким остатком (< 50 штук)
SELECT p.name, p.stock_qty, p.price
FROM products p
WHERE p.stock_qty < 50
ORDER BY p.stock_qty;

-- 41. Статистика доставки: pickup vs courier
SELECT od.delivery_type,
       COUNT(*) AS total,
       COUNT(*) FILTER (WHERE o.status = 'delivered') AS delivered
FROM order_delivery od
JOIN orders o ON od.order_id = o.order_id
GROUP BY od.delivery_type;

-- 42. Покупатели с отзывами и без
SELECT c.name,
       COUNT(r.review_id) AS reviews_written,
       CASE WHEN COUNT(r.review_id) = 0 THEN 'Нет отзывов' ELSE 'Есть отзывы' END AS status
FROM customers c
LEFT JOIN reviews r ON c.customer_id = r.customer_id
GROUP BY c.name
ORDER BY reviews_written DESC;

-- ============================================================
-- РАЗДЕЛ 8: DML операции (43-45)
-- ============================================================

-- 43. INSERT: добавить новый товар
INSERT INTO products (name, seller_id, subcategory_id, price, stock_qty)
VALUES ('Новый смартфон X', 1, 1, 29990.00, 100);

-- 44. UPDATE: обновить рейтинг продавца на основе отзывов
UPDATE sellers
SET rating = (
    SELECT ROUND(AVG(r.rating), 2)
    FROM reviews r
    JOIN products p ON r.product_id = p.product_id
    WHERE p.seller_id = sellers.seller_id
)
WHERE seller_id IN (SELECT DISTINCT seller_id FROM products);

-- 45. DELETE: удалить товары с нулевым остатком, которых нет в заказах
DELETE FROM products
WHERE stock_qty = 0
  AND product_id NOT IN (SELECT DISTINCT product_id FROM order_items);

-- ============================================================
-- РАЗДЕЛ 9: Представления (46-47)
-- ============================================================

-- 46. VIEW: активные товары с ценой и остатком
CREATE OR REPLACE VIEW v_products AS
SELECT p.product_id, p.name, s.company_name AS seller,
       cat.name AS category, p.price, p.stock_qty
FROM products p
JOIN sellers s ON p.seller_id = s.seller_id
JOIN subcategories sub ON p.subcategory_id = sub.subcategory_id
JOIN categories cat ON sub.category_id = cat.category_id
WHERE p.stock_qty > 0;

SELECT * FROM v_products ORDER BY price DESC LIMIT 10;

-- 47. VIEW: статистика заказов по покупателям
CREATE OR REPLACE VIEW v_customer_stats AS
SELECT c.customer_id, c.name, ci.name AS city,
       COUNT(o.order_id) AS total_orders
FROM customers c
JOIN cities ci ON c.city_id = ci.city_id
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name, ci.name;

SELECT * FROM v_customer_stats ORDER BY total_orders DESC NULLS LAST;

-- ============================================================
-- РАЗДЕЛ 10: Операции над множествами (48-50)
-- ============================================================

-- 48. UNION: города с покупателями или продавцами
SELECT ci.name, 'покупатель' AS type FROM cities ci
WHERE ci.city_id IN (SELECT city_id FROM customers)
UNION
SELECT ci.name, 'продавец' AS type FROM cities ci
WHERE ci.city_id IN (SELECT city_id FROM sellers)
ORDER BY name;

-- 49. INTERSECT: города, где есть и покупатели, и курьеры
SELECT name FROM cities WHERE city_id IN (SELECT city_id FROM customers)
INTERSECT
SELECT name FROM cities WHERE city_id IN (SELECT city_id FROM couriers)
ORDER BY name;

-- 50. EXCEPT: города с покупателями, но без ПВЗ
SELECT ci.name FROM cities ci
WHERE ci.city_id IN (SELECT city_id FROM customers)
EXCEPT
SELECT ci.name FROM cities ci
WHERE ci.city_id IN (SELECT city_id FROM pickup_points)
ORDER BY name;

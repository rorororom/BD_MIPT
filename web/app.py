"""
Online Marketplace Database - Web UI
Flask application for browsing tables and running SQL queries.
"""

import os
import psycopg2
import psycopg2.extras
from flask import Flask, render_template, request

app = Flask(__name__)

DB_CONFIG = {
    'host': os.environ.get('DB_HOST', 'postgres'),
    'port': os.environ.get('DB_PORT', '5432'),
    'dbname': os.environ.get('DB_NAME', 'marketplace'),
    'user': os.environ.get('DB_USER', 'student'),
    'password': os.environ.get('DB_PASS', 'student123'),
}

EXAMPLE_QUERIES = [
    {
        'category': 'Базовые (SELECT, WHERE, ORDER BY)',
        'queries': [
            {
                'name': '1. Все товары с ценой',
                'sql': "SELECT p.name, s.company_name AS seller, p.price, p.stock_qty FROM products p JOIN sellers s ON p.seller_id = s.seller_id ORDER BY p.price DESC;"
            },
            {
                'name': '2. Товары дешевле 5000 руб.',
                'sql': "SELECT name, price FROM products WHERE price < 5000 ORDER BY price;"
            },
            {
                'name': '3. Покупатели из Москвы',
                'sql': "SELECT c.name, c.email FROM customers c JOIN cities ci ON c.city_id = ci.city_id WHERE ci.name = 'Москва';"
            },
            {
                'name': '4. Топ-5 дорогих товаров',
                'sql': "SELECT name, price FROM products ORDER BY price DESC LIMIT 5;"
            },
            {
                'name': '5. Заказы за апрель 2025',
                'sql': "SELECT order_id, customer_id, order_date, status FROM orders WHERE order_date >= '2025-04-01' ORDER BY order_date DESC;"
            },
        ]
    },
    {
        'category': 'JOIN (соединения таблиц)',
        'queries': [
            {
                'name': '6. Товары с категориями и продавцами',
                'sql': """SELECT p.name AS product, cat.name AS category, sub.name AS subcategory, s.company_name AS seller, p.price
FROM products p
JOIN subcategories sub ON p.subcategory_id = sub.subcategory_id
JOIN categories cat ON sub.category_id = cat.category_id
JOIN sellers s ON p.seller_id = s.seller_id
ORDER BY cat.name, p.price DESC;"""
            },
            {
                'name': '7. Заказы с покупателями и доставкой',
                'sql': """SELECT o.order_id, o.order_date, o.status,
    c.name AS customer, od.delivery_type,
    COALESCE(pp.name, co.name) AS delivery_info
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_delivery od ON o.order_id = od.order_id
LEFT JOIN pickup_points pp ON od.pickup_point_id = pp.point_id
LEFT JOIN couriers co ON od.courier_id = co.courier_id
ORDER BY o.order_date DESC;"""
            },
            {
                'name': '8. Позиции заказа №1',
                'sql': """SELECT o.order_id, o.status, p.name AS product, oi.quantity, p.price, s.company_name AS seller
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN sellers s ON p.seller_id = s.seller_id
WHERE o.order_id = 1;"""
            },
            {
                'name': '9. ПВЗ с расписанием',
                'sql': """SELECT pp.name, pp.address, ci.name AS city, pps.day_of_week, pps.open_time
FROM pickup_points pp
JOIN cities ci ON pp.city_id = ci.city_id
LEFT JOIN pickup_point_schedule pps ON pp.point_id = pps.point_id
ORDER BY pp.name, pps.day_of_week;"""
            },
        ]
    },
    {
        'category': 'Агрегация (GROUP BY, HAVING)',
        'queries': [
            {
                'name': '10. Количество товаров по категориям',
                'sql': """SELECT cat.name AS category, COUNT(p.product_id) AS products,
    ROUND(AVG(p.price), 2) AS avg_price
FROM categories cat
JOIN subcategories sub ON cat.category_id = sub.category_id
JOIN products p ON sub.subcategory_id = p.subcategory_id
GROUP BY cat.name ORDER BY products DESC;"""
            },
            {
                'name': '11. Заказы по статусам',
                'sql': "SELECT status, COUNT(*) AS order_count FROM orders GROUP BY status ORDER BY order_count DESC;"
            },
            {
                'name': '12. Топ покупателей по количеству заказов',
                'sql': """SELECT c.name, COUNT(o.order_id) AS orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'delivered'
GROUP BY c.name
ORDER BY orders DESC;"""
            },
            {
                'name': '13. ПВЗ с более чем 1 заказом (HAVING)',
                'sql': """SELECT pp.name, ci.name AS city, COUNT(od.order_id) AS order_count
FROM pickup_points pp
JOIN cities ci ON pp.city_id = ci.city_id
JOIN order_delivery od ON pp.point_id = od.pickup_point_id
GROUP BY pp.name, ci.name
HAVING COUNT(od.order_id) > 1
ORDER BY order_count DESC;"""
            },
        ]
    },
    {
        'category': 'Подзапросы',
        'queries': [
            {
                'name': '14. Покупатели без заказов (NOT EXISTS)',
                'sql': """SELECT name, email FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id);"""
            },
            {
                'name': '15. Товары без заказов (NOT IN)',
                'sql': """SELECT name, price FROM products
WHERE product_id NOT IN (SELECT DISTINCT product_id FROM order_items)
ORDER BY price DESC;"""
            },
            {
                'name': '16. Товары дороже средней цены',
                'sql': """SELECT name, price FROM products
WHERE price > (SELECT AVG(price) FROM products)
ORDER BY price DESC;"""
            },
        ]
    },
]


def get_db_connection():
    return psycopg2.connect(**DB_CONFIG)


def get_tables():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT table_name FROM information_schema.tables
        WHERE table_schema = 'public' AND table_type = 'BASE TABLE' ORDER BY table_name;
    """)
    tables = []
    for (table_name,) in cur.fetchall():
        cur.execute(f'SELECT COUNT(*) FROM "{table_name}"')
        count = cur.fetchone()[0]
        tables.append({'name': table_name, 'count': count})
    cur.close()
    conn.close()
    return tables


@app.route('/')
def index():
    try:
        tables = get_tables()
        return render_template('index.html', tables=tables, example_queries=EXAMPLE_QUERIES)
    except Exception as e:
        return render_template('index.html', tables=[], example_queries=EXAMPLE_QUERIES, error=str(e))


@app.route('/table/<table_name>')
def view_table(table_name):
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute("""
            SELECT column_name, data_type, is_nullable, column_default
            FROM information_schema.columns
            WHERE table_name = %s AND table_schema = 'public' ORDER BY ordinal_position;
        """, (table_name,))
        columns_info = cur.fetchall()
        cur.execute(f'SELECT * FROM "{table_name}" LIMIT 100')
        rows = cur.fetchall()
        columns = [desc[0] for desc in cur.description] if cur.description else []
        cur.close()
        conn.close()
        return render_template('table.html', table_name=table_name, columns=columns,
                               columns_info=columns_info, rows=rows)
    except Exception as e:
        return render_template('table.html', table_name=table_name, columns=[],
                               columns_info=[], rows=[], error=str(e))


@app.route('/query', methods=['GET', 'POST'])
def query_page():
    sql = ''
    results = None
    columns = []
    error = None
    row_count = 0

    if request.method == 'POST':
        sql = request.form.get('sql', '').strip()
        if sql:
            try:
                conn = get_db_connection()
                cur = conn.cursor()
                cur.execute(sql)
                if cur.description:
                    columns = [desc[0] for desc in cur.description]
                    results = cur.fetchall()
                    row_count = len(results)
                else:
                    conn.commit()
                    row_count = cur.rowcount
                    results = []
                cur.close()
                conn.close()
            except Exception as e:
                error = str(e)
                try:
                    conn.close()
                except Exception:
                    pass

    return render_template('query.html', sql=sql, columns=columns, results=results,
                           error=error, row_count=row_count, example_queries=EXAMPLE_QUERIES)


@app.route('/schema')
def schema_page():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            SELECT t.table_name, c.column_name, c.data_type, c.is_nullable, c.column_default,
                   CASE WHEN pk.column_name IS NOT NULL THEN 'PK' ELSE '' END AS is_pk
            FROM information_schema.tables t
            JOIN information_schema.columns c ON t.table_name = c.table_name AND t.table_schema = c.table_schema
            LEFT JOIN (
                SELECT ku.table_name, ku.column_name
                FROM information_schema.table_constraints tc
                JOIN information_schema.key_column_usage ku ON tc.constraint_name = ku.constraint_name
                WHERE tc.constraint_type = 'PRIMARY KEY' AND tc.table_schema = 'public'
            ) pk ON c.table_name = pk.table_name AND c.column_name = pk.column_name
            WHERE t.table_schema = 'public' AND t.table_type = 'BASE TABLE'
            ORDER BY t.table_name, c.ordinal_position;
        """)
        rows = cur.fetchall()
        cur.execute("""
            SELECT tc.table_name, kcu.column_name, ccu.table_name, ccu.column_name
            FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
            JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
            WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_schema = 'public' ORDER BY tc.table_name;
        """)
        fk_rows = cur.fetchall()
        cur.close()
        conn.close()

        tables = {}
        for table_name, col_name, data_type, nullable, default, is_pk in rows:
            if table_name not in tables:
                tables[table_name] = []
            tables[table_name].append({
                'name': col_name, 'type': data_type, 'nullable': nullable,
                'default': default, 'is_pk': is_pk == 'PK'
            })

        foreign_keys = [
            {'from_table': r[0], 'from_column': r[1], 'to_table': r[2], 'to_column': r[3]}
            for r in fk_rows
        ]
        return render_template('schema.html', tables=tables, foreign_keys=foreign_keys)
    except Exception as e:
        return render_template('schema.html', tables={}, foreign_keys=[], error=str(e))


@app.route('/otl10')
def otl10_page():
    return render_template('otl10.html')


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)

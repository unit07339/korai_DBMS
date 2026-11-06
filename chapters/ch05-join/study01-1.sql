use hanip_delivery05;

select
    r.name as restaurant_name,
    m.name as menu_name,
    m.price
from
    menus m
inner join restaurants r on r.restaurant_id = m.restaurant_id
where r.category = '치킨'
order by r.restaurant_id, m.price desc;


select
    r.name as rider_name,
    r.vehicle,
    count(o.delivered_at) as delieveries
from riders r
inner join orders o on o.rider_id = r.rider_id
where o.status = '배달완료'
group by r.name, r.vehicle
order by delieveries desc;


select
    rv.review_id,
    rv.rating,
    r.name as restaurant_name,
    c.name as customer_name,
    rv.content
from
    reviews rv
inner join orders o on o.order_id = rv.order_id
inner join restaurants r on r.restaurant_id = o.restaurant_id
inner join customers c on c.customer_id = o.customer_id
where rating <= 2
order by created_at desc;


select
    o.order_id,
    o.status,
    c.name as customer_name,
    r.name as restaurant_name,
    rd.name as rider_name
from
    orders o
inner join customers c on c.customer_id = o.customer_id
inner join restaurants r on r.restaurant_id = o.restaurant_id
left join riders rd on rd.rider_id = o.rider_id
where o.status in ('접수', '조리중', '배달중');


select
    rs.name as restaurant_name,
    round(avg(rating) ,2) as avg_rating,
    count(*) as review_count
from
    reviews r
inner join orders o on o.order_id = r.order_id
inner join restaurants rs on rs.restaurant_id = o.restaurant_id
group by rs.name
having count(*) >= 10
order by avg_rating desc;

-- 11
select
    m.name as menu_name,
    oi.unit_price,
    m.price as current_price,
    sum(oi.quantity) as sold_quantity -- count 행의 수 sum 행 안에 있는 숫자들의 합
from
    order_items oi
inner join menus m on m.menu_id = oi.menu_id and m.price != oi.unit_price
inner join orders o on o.order_id = oi.order_id and o.status = '배달완료'
group by oi.menu_id, m.name, oi.unit_price, m.price
order by oi.menu_id

-- 13

select
    rt.name as restaurant_name,
    count(od.order_id) as delivered_orders,
    count(rv.review_id) as reviewed,
    round(count(rv.order_id) / count(od.order_id) * 100, 1) as review_rate
from
    restaurants rt
left outer join orders od on od.restaurant_id = rt.restaurant_id and od.status = '배달완료'
left outer join reviews rv on rv.order_id = od.order_id
group by rt.restaurant_id, rt.name
ORDER BY
    review_rate desc;


-- 14

select
    date_format(ordered_at, '%Y-%m') as order_month,
    sum(if(rt.category = '한식', oi.quantity * oi.unit_price, 0)) as korean,
    sum(if(rt.category = '중식', oi.quantity * oi.unit_price, 0)) as chinese,
    sum(if(rt.category = '치킨', oi.quantity * oi.unit_price, 0)) as chicken,
    sum(if(rt.category = '피자', oi.quantity * oi.unit_price, 0)) as pizza,
    sum(oi.quantity * oi.unit_price) as all_categories
from
    orders od
inner join order_items oi on oi.order_id = od.order_id and od.status = '배달완료'
left outer join restaurants rt on rt.restaurant_id = od.restaurant_id
group by
    date_format(ordered_at, '%Y-%m')












-- 0 -------------------------------------------------------------------











-- 1

SELECT restaurant_id, name, price
FROM menus
WHERE price = (SELECT MAX(price) FROM menus);




-- 2

SELECT r.restaurant_id, r.name
FROM restaurants r
WHERE EXISTS (
    SELECT 1
    FROM reviews rv
             JOIN orders o ON rv.order_id = o.order_id
    WHERE o.restaurant_id = r.restaurant_id
)
ORDER BY r.restaurant_id;




-- 3

SELECT o.order_id, o.ordered_at, c.name AS customer_name, o.status
FROM orders o
         JOIN customers c ON o.customer_id = c.customer_id
WHERE o.ordered_at = (SELECT MAX(ordered_at) FROM orders);

-- 4

SELECT COUNT(*) AS review_count,
       (SELECT COUNT(*) FROM orders WHERE status = '배달완료') AS delivered_orders,
       ROUND(COUNT(*) * 100 / (SELECT COUNT(*) FROM orders WHERE status = '배달완료'), 1) AS review_rate
FROM reviews;


-- 5

SELECT c.name, c.joined_at
FROM customers c
WHERE c.joined_at < '2026-06-01'
  AND NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.customer_id
      AND o.ordered_at >= '2026-06-01'
      AND o.ordered_at <  '2026-07-01'
)
ORDER BY c.joined_at;



-- 6

SELECT r.name,
       r.category,
       r.min_order_amount,
       (SELECT ROUND(AVG(r2.min_order_amount)) FROM restaurants r2 WHERE r2.category = r.category) AS category_avg
FROM restaurants r
WHERE r.min_order_amount > (
    SELECT AVG(r2.min_order_amount)
    FROM restaurants r2
    WHERE r2.category = r.category
)
ORDER BY r.category, r.name;


-- 7

WITH order_food AS (
    SELECT order_id, SUM(quantity * unit_price) AS food_amount
    FROM order_items
    GROUP BY order_id
)
SELECT o.order_id,
       f.food_amount,
       o.delivery_fee,
       o.discount_amount,
       f.food_amount + o.delivery_fee - o.discount_amount AS paid_amount
FROM orders o
         JOIN order_food f ON o.order_id = f.order_id
WHERE o.status = '배달완료'
ORDER BY paid_amount DESC, o.order_id
LIMIT 5;



-- 8


WITH last_order AS (
    SELECT customer_id, MAX(ordered_at) AS last_ordered_at
    FROM orders
    GROUP BY customer_id
)
SELECT c.name,
       DATE(lo.last_ordered_at) AS last_order_date,
       DATEDIFF('2026-06-30', lo.last_ordered_at) AS days_since_last
FROM last_order lo
         JOIN customers c ON lo.customer_id = c.customer_id
WHERE DATEDIFF('2026-06-30', lo.last_ordered_at) >= 30
ORDER BY days_since_last DESC;




-- 9

WITH store_sales AS (
    SELECT o.restaurant_id,
           SUM(oi.quantity * oi.unit_price) AS food_sales
    FROM orders o
             JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = '배달완료'
    GROUP BY o.restaurant_id
)
SELECT RANK() OVER (ORDER BY ss.food_sales DESC) AS sales_rank,
       r.name AS restaurant_name,
       ss.food_sales,
       ROUND(ss.food_sales * 100 / SUM(ss.food_sales) OVER (), 1) AS share_pct
FROM store_sales ss
         JOIN restaurants r ON ss.restaurant_id = r.restaurant_id
ORDER BY sales_rank;




 -- 10

WITH numbered AS (
    SELECT o.customer_id,
           o.restaurant_id,
           o.ordered_at,
           ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.ordered_at, o.order_id) AS rn
    FROM orders o
)
SELECT c.name AS customer_name,
       n.ordered_at AS first_ordered_at,
       r.name AS restaurant_name
FROM numbered n
         JOIN customers c   ON n.customer_id   = c.customer_id
         JOIN restaurants r ON n.restaurant_id = r.restaurant_id
WHERE n.rn = 1
ORDER BY c.customer_id;




-- 11

WITH store_sales AS (
    SELECT r.category,
           r.restaurant_id,
           r.name AS restaurant_name,
           SUM(oi.quantity * oi.unit_price) AS food_sales
    FROM orders o
             JOIN order_items oi ON o.order_id      = oi.order_id
             JOIN restaurants r  ON o.restaurant_id = r.restaurant_id
    WHERE o.status = '배달완료'
    GROUP BY r.category, r.restaurant_id, r.name
),
     ranked AS (
         SELECT ss.*,
                ROW_NUMBER() OVER (PARTITION BY category ORDER BY food_sales DESC, restaurant_id) AS category_rank
         FROM store_sales ss
     )
SELECT category, category_rank, restaurant_name, food_sales
FROM ranked
WHERE category_rank <= 2
ORDER BY category, category_rank;




 -- 12

WITH months AS (
    SELECT DISTINCT DATE_FORMAT(ordered_at, '%Y-%m') AS order_month
    FROM orders
),
     stores AS (
         SELECT restaurant_id, name
         FROM restaurants
         WHERE category = '치킨'
     ),
     sales AS (
         SELECT o.restaurant_id,
                DATE_FORMAT(o.ordered_at, '%Y-%m') AS order_month,
                SUM(oi.quantity * oi.unit_price) AS food_sales
         FROM orders o
                  JOIN order_items oi ON o.order_id = oi.order_id
         WHERE o.status = '배달완료'
         GROUP BY o.restaurant_id, order_month
     )
SELECT m.order_month,
       s.name AS restaurant_name,
       IFNULL(sa.food_sales, 0) AS food_sales
FROM months m
         CROSS JOIN stores s
         LEFT JOIN sales sa
                   ON sa.restaurant_id = s.restaurant_id
                       AND sa.order_month = m.order_month
ORDER BY s.restaurant_id, m.order_month;





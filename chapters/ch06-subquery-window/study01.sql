use hanip_delivery06;

-- 표
select
    menu_id,
    name as menu_name
from
    menus;

select
    *
from
    (select menu_id,
            name as menu_name from menus) m # m이 테이블명 , 이름을 꼭 넣어야함. 동일한 테이블명을 사용할 때는 as 사용해서 구분
where
    menu_name like '%국밥';

select
    *
from
    (select
         *
     from
         (select * from menus) m) m2;



# 목록
select
    menu_id
from
    menus;

select
    *
from
    order_items
where
    menu_id in (select menu_id from menus where menus.menu_id mod 2 = 0); # mod 는 나머지 구하는 연산 2를 나누면 0인지

-- 스탈라 쿼리
select
    menu_id,
    name,
    (select name from restaurants where restaurants.restaurant_id = menus.restaurant_id)
from
    menus
where
    restaurant_id = (select restaurant_id from restaurants where name = '장전동든든김밥');


# null이 포함된 목록을 서브쿼리로 사용했을 때
select
    rider_id
from
    orders
where
    ordered_at >= '2026-06-30';

select
    *
from
    riders
where
    rider_id  not in (select # not in 을 쓸 때에는 꼭 null 처리 해야함
                         rider_id
                     from
                         orders
                     where
                         ordered_at >= '2026-06-30'); # (and orders.rider_id is not null);


select rd.name
from riders rd
where not exists (
    select 1
    from orders o
    where o.rider_id = rd.rider_id
    and o.ordered_at >= '2026-06-30');


select name,
       rider_id
from riders
where exists(select 1);
# 행이 있다없다를 따짐, exists 아래의 select 를 했을 때 행이 존재하면 나옴, not 붙이면 존재하지 않는 거




with ap_cte as (
    select
        od.restaurant_id,
        date_format(od.ordered_at, '%Y-%m') as order_month,
        round(avg(quantity * unit_price), 0) as avg_price
    from
        orders od
        left outer join order_items oi on oi.order_id = od.order_id
    group by
        od.restaurant_id,
        date_format(od.ordered_at, '%Y-%m')
    order by
        od.restaurant_id,
        order_month
) # 아래 select를 위한 가상의 table을 만듦. 아래의 select가 간결해짐

select
    *
from
    restaurants rt
    left outer join ap_cte ap on ap.restaurant_id = rt.restaurant_id;


# union은 위아래 컬럼의 수가 동일해야하고 가능한 자료형을 맞춰야함



with day_of_week_kor as (select 1 as day_id, '일' as kor_name
union all
select 2, '월'
union all
select 3, '화'
union all
select 4, '수'
union all
select 5, '목'
union all
select 6, '금'
union all
select 7, '토'
)

select
    od.order_id,
    od.ordered_at,
    dowk.kor_name
from
    orders od
    left outer join day_of_week_kor dowk on dowk.day_id = dayofweek(od.ordered_at);


# 카테고리별로 판매 총 수량 순위
select
    r.category,
    rank() over (partition by r.category order by sum(oi.quantity) desc) as restaurant_rank,
    r.restaurant_id,
    r.name,
    sum(oi.quantity) as total_quantity

from
    orders o
    left outer join order_items oi on oi.order_id = o.order_id
    left outer join restaurants r on r.restaurant_id = o.restaurant_id
group by r.category, r.restaurant_id, r.name;


select
    r.category,
    rank() over (partition by r.category order by sum(ifnull(oi.quantity, 0)) desc) as restaurant_rank,
    r.restaurant_id,
    r.name as restaurant_name,
    sum(ifnull(oi.quantity, 0)) as total_quantity

from
    restaurants r
left outer join orders o on o.restaurant_id = r.restaurant_id
left outer join order_items oi on oi.order_id = o.order_id
group by r.category, r.restaurant_id, r.name;



select
    date_format(ordered_at, '%Y-%m') as order_month,
    sum(ifnull(delivery_fee, 0)) as delivery_fee_sum,
    sum(sum(ifnull(delivery_fee, 0))) over(order by date_format(ordered_at, '%Y-%m')) as cumulative_fee
from
    orders
group by
    date_format(ordered_at, '%Y-%m');


-- 1

select
    restaurant_id,
    name,
    price
from
    menus
where price = (select max(price) from menus);


-- 2

select
    r.restaurant_id,
    r.name
from
    restaurants r
where exists(
    select
        o.restaurant_id
    from
        reviews rv
        inner join orders o on o.order_id = rv.order_id
    where
        o.restaurant_id = r.restaurant_id
);

-- -----

select
    rt.restaurant_id,
    rt.name
from
    restaurants rt
where
    exists(select
               1
           from
               orders od
                   inner join reviews rv on rv.order_id = od.order_id
           where od.restaurant_id = rt.restaurant_id);

-- 3

select
    o.order_id,
    o.ordered_at,
    c.name as customer_name,
    o.status
from
    orders o
    inner join customers c on c.customer_id = o.customer_id
where
    ordered_at = (select max(ordered_at) from orders);

-- ----

select
    od.order_id,
    od.ordered_at,
    (select name from customers ct where ct.customer_id = od.customer_id) as customer_name,
    od.status
from
    orders od
where
    od.ordered_at = (select max(od2.ordered_at) from orders od2);


-- 4

select
    count(*) as review_count,
    (select count(*) from orders where status = '배달완료') as delivered_orders,
    round(count(*) * 100 / (select count(*) from orders where status = '배달완료'), 1) as review_rate
from
    reviews;

-- ----

with delivered_orders_count as (
    select count(*) from orders where status = '배달완료'
)

select
    count(*) as review_count,
    (select * from delivered_orders_count) as delivered_orders,
    round(count(*) / (select * from delivered_orders_count) * 100, 1) as review_rate
from
    reviews;


# select
#     count(order_id) as delivered_orders
# from
#     orders
# where status = '배달완료';


#     SELECT
#       ROUND(AVG(rating), 2) AS avg_rating,
#       COUNT(*) AS review_count,
#       ROUND(COUNT(*) * 100 / 511, 1) AS review_rate
#     FROM reviews;

-- 5

select
    c.name,
    c.joined_at
from
    customers c
where
    joined_at < '2026-06-01'
    and not exists(
        select
            *
        from
            orders o
        where o.customer_id = c.customer_id
        and ordered_at >= '2026-06-01'
        and ordered_at < '2026-07-01'
)
order by joined_at;

-- ----

select
    name,
    joined_at
from customers
where
    date(joined_at) < '2026-06-01'
    and not exists(select
                       1
                   from
                       orders
                   where
                       orders.customer_id = customers.customer_id
                     and date_format(ordered_at, '%Y-%m') = '2026-06')
order by
    joined_at;


# select
#     *
# from
#     orders o
# left outer join customers c on c.customer_id = o.customer_id
# where
#     c.customer_id not in (select





-- 6

select
    r.name,
    r.category,
    r.min_order_amount,
    (select round(avg(r2.min_order_amount))
     from restaurants r2
     where r2.category = r.category) as category_avg
from
    restaurants r
where
    r.min_order_amount >
    (select
         avg(r2.min_order_amount)
     from restaurants r2
     where r2.category = r.category )
order by r.category;


-- ----

select
    rt.name,
    rt.category,
    rt.min_order_amount,
    rt2.category_avg
from
    restaurants rt
    inner join (select
                    category,
                    round(avg(min_order_amount), 0) as category_avg
                from
                    restaurants
                group by
                    category) rt2
        on rt2.category = rt.category
        and rt2.category_avg < rt.min_order_amount
    order by
        rt.category;

-- 7

with order_food as (select
    order_id,
    sum(unit_price * quantity) as food_amount
from
    order_items
group by
    order_id)

select
    o.order_id,
    od.food_amount,
    o.delivery_fee,
    o.discount_amount,
    od.food_amount + o.delivery_fee - o.discount_amount as paid_amount
from
    orders o
inner join order_food od on od.order_id = o.order_id
where
    status = '배달완료'
order by paid_amount desc, order_id
limit 5;

-- --------------------------------------

select
    o.order_id,
    sum(oi.unit_price * oi.quantity) as food_amount,
    o.delivery_fee,
    o.discount_amount,
    sum(oi.unit_price * oi.quantity) + o.delivery_fee - o.discount_amount as paid_amount
from
    order_items oi
    inner join orders o on o.order_id = oi.order_id
where o.status = '배달완료'
group by
    o.order_id
order by paid_amount desc, o.order_id
limit 5;

-- ---- 7


select
    od.order_id,
    (select sum(quantity * unit_price) from order_items oi where oi.order_id = od.order_id) as food_price,
    od.delivery_fee,
    od.discount_amount,
    (select sum(quantity * unit_price) from order_items oi where oi.order_id = od.order_id) + delivery_fee - discount_amount as paid_amount
from
    orders od
where
    status = '배달완료'
order by
    paid_amount desc,
    od.order_id
limit 5;



-- 8

with last_date as (select
    customer_id,
    max(ordered_at) as last_ordered_at
from
    orders
group by
    customer_id)

select
    c.name,
    date(last_ordered_at) as last_order_date,
    datediff('2026-06-30', last_ordered_at) as days_since_last
from
    last_date ld
    inner join customers c on c.customer_id = ld.customer_id
where
    datediff('2026-06-30', last_ordered_at) >= 30
order by
    days_since_last desc;


-- -------------------

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



-- 9

select
    rank() over (order by sum(oi.quantity * oi.unit_price) desc) as sales_rank,
    r.name as restaurant_name,
    sum(oi.quantity * oi.unit_price) as food_sales,
    round(sum(oi.quantity * oi.unit_price) * 100 / sum(sum(oi.quantity * oi.unit_price)) over (), 1) as share_pct

from
    orders o
    inner join order_items oi on oi.order_id = o.order_id
    inner join restaurants r on r.restaurant_id = o.restaurant_id
where
    o.status = '배달완료'
group by
    o.restaurant_id
order by
    sales_rank;


# ROUND(SUM(delivery_fee) * 100 / SUM(SUM(delivery_fee)) OVER (), 1) AS share_pct



-- 12번

with order_month_cte as (
select distinct
    rn.restaurant_id,
    rn.name,
    date_format(ordered_at, '%Y-%m') as order_month
from
    orders od,
    (select restaurant_id, name from restaurants where name in ('대연동크런치치킨', '서면야식치킨') ) rn
order by
    restaurant_id
)

select
    omc.order_month,
    omc.name as restaurant_name,
    ifnull(sum(oi2.food_sales), 0) as food_sales
from
    order_month_cte omc
left outer join (select
                     oi.order_id,
                     od.restaurant_id,
                     date_format(od.ordered_at, '%Y-%m') as order_month,
                         sum(quantity * unit_price) as food_sales
                 from
                     order_items oi
                 inner join orders od on od.order_id = oi.order_id
                 group by order_id,
                          od.restaurant_id,
                          date_format(od.ordered_at, '%Y-%m')) oi2 on oi2.restaurant_id = omc.restaurant_id and oi2.order_month = omc.order_month
group by
    omc.order_month,
    omc.name;



-- ------ 12번 복붙

with order_month_cte as (
    select
    distinct
    rn.restaurant_id,
    rn.name,
    date_format(ordered_at, '%Y-%m') as order_month
    from
    orders od,
    (select restaurant_id, name from restaurants where name in ('대연동크런치치킨', '서면야식치킨')) rn
    order by
    restaurant_id
    )

select
    omc.order_month,
    omc.name as restaurant_name,
    ifnull(sum(oi2.food_sales), 0) as food_sales
from
    order_month_cte omc
        left outer join (select
             oi.order_id,
             od.restaurant_id,
             date_format(od.ordered_at, '%Y-%m') as order_month,
             sum(quantity * unit_price) as food_sales
         from
             order_items oi
                 inner join orders od on od.order_id = oi.order_id
         group by
             order_id,
             od.restaurant_id,
             date_format(od.ordered_at, '%Y-%m')) oi2 on oi2.restaurant_id = omc.restaurant_id and oi2.order_month = omc.order_month
group by
    omc.order_month,
    omc.name;







-- 11
with ranked as (
select
    r.category,
    row_number() over (partition by r.category order by sum(oi.quantity * oi.unit_price) desc) as category_rank,
    r.name as restaurant_name,
    sum(oi.quantity * oi.unit_price) as food_sales
from
    orders o
inner join order_items oi on oi.order_id = o.order_id
inner join restaurants r on r.restaurant_id = o.restaurant_id
where
    o.status = '배달완료'
group by
    r.category, r.name, r.restaurant_id
)

select
    category,
    category_rank,
    restaurant_name,
    food_sales
from ranked
where
    category_rank <= 2
order by
    category, category_rank;



-- 11

select
    category,
    category_rank,
    restaurant_name,
    food_sales
from
    (select
        rt.category,
        row_number() over (partition by category
            order by (select
                   sum(quantity * unit_price)
               from
                   order_items oi
                       inner join orders od on od.order_id = oi.order_id
                       and od.restaurant_id = rt.restaurant_id
                       and od.status = '배달완료') desc) as category_rank,
        rt.name as restaurant_name,

        (select
             sum(quantity * unit_price)
         from
             order_items oi
         inner join orders od on od.order_id = oi.order_id
                                     and od.restaurant_id = rt.restaurant_id
                                     and od.status = '배달완료'

         ) as food_sales
    from
        restaurants rt
    order by
        category) rank_top_2
where
category_rank < 3
and food_sales is not null;


-- 10

with first_order2 as (
    select
    row_number() over (partition by o.customer_id order by ordered_at) as rn,
    o.customer_id,
    o.restaurant_id,
    o.ordered_at
    from
        orders o
)
select
    c.name as customer_name,
    fo.ordered_at as first_ordered_at,
    r.name as restaurant_name
from
    first_order2 fo
inner join customers c on c.customer_id = fo.customer_id
inner join restaurants r on r.restaurant_id = fo.restaurant_id
where fo.rn = 1
order by c.customer_id;



-- 10
with first2 as (
select
    o.customer_id,
    o.restaurant_id,
    o.ordered_at,
    row_number() over (partition by customer_id order by ordered_at) as rn
from
    orders o
)

select
    c.name as customer_name,
    f.ordered_at as fitst_ordered_at,
    r.name as restaurant_name
from
    first2 f
inner join customers c on c.customer_id = f.customer_id
inner join restaurants r on r.restaurant_id = f.restaurant_id
where
    f.rn = 1
order by
    c.customer_id


-- 10

select
    ct.name as customer_name,
    ordered_at as fir_ordered_at,
    rt.name as restaurant_name
from
    (
select
    customer_id,
    row_number() over (partition by customer_id order by ordered_at) as order_num,
    ordered_at,
    restaurant_id
from
    orders) odn
inner join customers ct on ct.customer_id = odn.customer_id
inner join restaurants rt on rt.restaurant_id = odn.restaurant_id
where
    order_num = 1
order by
    odn.customer_id;






-- 1

INSERT INTO menus (restaurant_id, name, price, description, is_signature)
VALUES (9, '치즈 떡볶이', 7500, '모차렐라 듬뿍', TRUE);

SELECT name, price, description, is_signature
FROM menus
WHERE restaurant_id = 9 AND is_signature = TRUE
ORDER BY price;


-- 2

INSERT INTO menus (restaurant_id, name, price) VALUES
                                                   (10, '콜라', 2000),
                                                   (10, '사이다', 2000),
                                                   (10, '아이스티', 2500);

SELECT name, price
FROM menus
WHERE restaurant_id = 10 AND price < 3000
ORDER BY price, name;



-- 3

SELECT name, price FROM menus WHERE restaurant_id = 8 AND price <= 6000;

UPDATE menus
SET price = price + 500
WHERE restaurant_id = 8 AND price <= 6000;

SELECT name, price
FROM menus
WHERE restaurant_id = 8
ORDER BY menu_id;



-- 4

SELECT review_id, content FROM reviews WHERE rating = 1;

DELETE FROM reviews
WHERE review_id IN (SELECT review_id FROM (
                                              SELECT review_id FROM reviews WHERE rating = 1 AND content = '다시는 안 시킬 것 같아요'
                                          ) t);

SELECT COUNT(*) AS one_star_reviews FROM reviews WHERE rating = 1;



-- 5

CREATE TABLE daily_sales (
                             sales_date DATE NOT NULL,
                             orders     INT  NOT NULL,
                             food_sales INT  NOT NULL,
                             CONSTRAINT pk_daily_sales PRIMARY KEY (sales_date)
);

INSERT INTO daily_sales (sales_date, orders, food_sales)
SELECT DATE(o.ordered_at),
       COUNT(DISTINCT o.order_id),
       SUM(oi.quantity * oi.unit_price)
FROM orders o
         JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = '배달완료'
  AND o.ordered_at >= '2026-06-24'
  AND o.ordered_at <  '2026-07-01'
GROUP BY DATE(o.ordered_at);

SELECT sales_date, orders, food_sales
FROM daily_sales
ORDER BY sales_date;


-- 6



SELECT c.customer_id, c.name, c.grade, COUNT(*) AS june_orders
FROM customers c
         JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = '배달완료'
  AND o.ordered_at >= '2026-06-01' AND o.ordered_at < '2026-07-01'
  AND c.grade = '일반'
GROUP BY c.customer_id, c.name, c.grade
HAVING COUNT(*) >= 4;

UPDATE customers c
    JOIN (
        SELECT customer_id
        FROM orders
        WHERE status = '배달완료'
          AND ordered_at >= '2026-06-01' AND ordered_at < '2026-07-01'
        GROUP BY customer_id
        HAVING COUNT(*) >= 4
    ) t ON c.customer_id = t.customer_id
SET c.grade = '실버'
WHERE c.grade = '일반';

SELECT name, grade
FROM customers
WHERE grade = '실버'
ORDER BY customer_id;



-- 7


START TRANSACTION;
UPDATE coupons SET is_active = FALSE WHERE coupon_id > 0;
SELECT COUNT(*) AS active_coupons FROM coupons WHERE is_active = TRUE;
ROLLBACK;

SELECT COUNT(*) AS active_coupons FROM coupons WHERE is_active = TRUE;


-- 8

START TRANSACTION;
UPDATE restaurants SET delivery_fee = 3000 WHERE restaurant_id = 4;
SAVEPOINT fee_done;
UPDATE restaurants SET min_order_amount = 0 WHERE restaurant_id = 4;
ROLLBACK TO SAVEPOINT fee_done;
COMMIT;

SELECT name, delivery_fee, min_order_amount
FROM restaurants
WHERE restaurant_id = 4;



-- 9


START TRANSACTION;

INSERT INTO orders (customer_id, restaurant_id, status, payment_method,
                    delivery_fee, discount_amount, ordered_at)
VALUES (30, 2, '접수', '카드', 3000, 3000, '2026-06-30 19:30:00');
SET @order_id = LAST_INSERT_ID();

INSERT INTO order_items (order_id, menu_id, quantity, unit_price)
SELECT @order_id, menu_id, 1, price
FROM menus
WHERE restaurant_id = 2 AND name IN ('등심카츠', '치즈카츠');

UPDATE customer_coupons
SET used_order_id = @order_id
WHERE customer_id = 30
  AND coupon_id = (SELECT coupon_id FROM coupons WHERE code = 'WELCOME3000')
  AND used_order_id IS NULL;
SELECT ROW_COUNT() AS coupon_rows_updated;

COMMIT;

SELECT c.name AS customer_name,
       m.name AS menu_name,
       oi.quantity,
       oi.unit_price,
       o.discount_amount,
       cp.code AS coupon_code
FROM orders o
         JOIN customers c         ON o.customer_id = c.customer_id
         JOIN order_items oi      ON o.order_id    = oi.order_id
         JOIN menus m             ON oi.menu_id    = m.menu_id
         JOIN customer_coupons cc ON cc.used_order_id = o.order_id
         JOIN coupons cp          ON cc.coupon_id  = cp.coupon_id
WHERE o.order_id = @order_id
ORDER BY m.menu_id;


 -- 10

START TRANSACTION;

UPDATE orders SET status = '취소' WHERE order_id = 563 AND status = '접수';

INSERT INTO customer_coupons (customer_id, coupon_id, issued_at, expires_at)
SELECT o.customer_id,
       cp.coupon_id,
       '2026-06-30 19:40:00',
       DATE_ADD('2026-06-30 19:40:00', INTERVAL cp.valid_days DAY)
FROM orders o
         CROSS JOIN coupons cp
WHERE o.order_id = 563 AND cp.code = 'SORRY2000';

COMMIT;

SELECT o.order_id,
       o.status,
       c.name AS customer_name,
       cp.code AS coupon_code,
       cc.expires_at
FROM orders o
         JOIN customers c         ON o.customer_id  = c.customer_id
         JOIN customer_coupons cc ON cc.customer_id = c.customer_id
         JOIN coupons cp          ON cc.coupon_id   = cp.coupon_id
WHERE o.order_id = 563
ORDER BY cc.customer_coupon_id;



-- 11






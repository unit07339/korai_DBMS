use hanip_delivery04;

select * from customers;

select * from menus;

select
    count(*) as menu_count,
    min(price) as min_price,
    max(price) as max_price,
    sum(price) as total_price,
    avg(price) as avg_price
from
    menus;

select
    count(*) as customers,
    count(email) as with_email,
    count(birth_date) as with_birth,
    count(distinct district) as districts
from
    customers;

select count(*) as orders,
       sum(delivery_fee) as fee_sum,
       ifnull(sum(delivery_fee), 0) as fee_sum_safe
from orders
where restaurant_id = 15;

select distinct -- 단순 중복 제거
    category,
    district
from
    restaurants
order by
    category;

-- 위아래 같은 코드

select
    category,
    district
from
    restaurants
group by -- 중복제거와 집계함수가 같이 쓰일 때 group by
    category,
    district
order by
    category;

select
    category,
    count(*) as restaurant_count,
    max(delivery_fee) as max_delivery_fee
from restaurants
group by
    category
order by restaurant_count desc, category;

select * from orders;

select
    date_format(ordered_at, '%Y-%m') as order_month,
    count(*) as order_count
from
    orders
group by
    date_format(ordered_at, '%Y-%m');
    -- order_month; -- mysql 이라 가능, 정상적인 문법이 아님
    -- 실행 순서가 select가 마지막이라 as 뒤에 있는 걸 쓸 수 없음


        -- 위의 코드를 바꾸자면
# {
#     date_format(ordered_at, '%Y-%m'): 2026-01 3
#         [
#            {order},
#            {order},
#            {order},
#            {order},
#         ],
#     date_format(ordered_at, '%Y-%m'): 2026-02 4
#         [
#            {order},
#            {order},
#            {order},
#            {order},
#         ],
#
# }


select category, count(*) as cnt,
       group_concat(name separator',') as names
from restaurants
group by category
order by names desc, category;


select
    restaurant_id,
    sum(price) as total_price
from menus
group by restaurant_id
having -- group 함수 쓴 결과에 조건 주고 싶을 때
    sum(price) > 50000;
-- group by -> having -> select 라서 as 뒤에 있는 거 쓰면 안됨

select
     order_id,
     count(*) as item_lines,
     sum(quantity) as total_quantity,
     sum(quantity * unit_price) as food_amount
from order_items
group by order_id
order by food_amount desc, order_id;


select ifnull(payment_method, '합계') as payment_method,
       count(*) as delivered_orders,
       sum(delivery_fee) as fee_sum
from orders
where status = '배달완료'
group by payment_method with rollup
-- with rollup 은 맨마지막에 하나의 전체 집계를 해줌
-- group by 하지 않은 count와 sum의 집계함수를 만들어주는 게 with rollup
order by
    fee_sum desc; -- with rollup 과 order by를 같이 쓸 수도 있고 못 쓸 수도 있음(버전에 따라)


select
    *
from
    (select
        payment_method,
        count(*) as delivered_orders,
        sum(delivery_fee) as fee_sum
    from
        orders
    where
        status = '배달완료'
    group by
        payment_method
    order by
        fee_sum desc) as group_orders

union all -- 위의 select결과값 아래의 select 결과값 합쳐줌
-- 서브쿼리
select
    '합계',
    count(*) as delivered_orders,
    sum(delivery_fee) as fee_sum
from
    orders
where
    status = '배달완료';



-- 1번

select
    count(*) as menu_count,
    min(price) as min_price,
    max(price) as max_price,
    round(avg(price)) as avg_price
from
    menus;

-- 2번

select
    category,
    count(*) as restaurant_count
from
    restaurants
where
    is_open = true
group by
    category
order by
    restaurant_count desc, category;


-- 3번

select
    rating,
    count(*) as review_count,
    sum(case when content is null then 1 else 0 end) as rating_only,
    count(case when content is null then 1 end) as rating_only2,
    count(if(content is null, 1, null)) as rating_only3,
    count(*) - count(content) as rating_only4
-- 전부 동일한 결과 나옴
from
    reviews
group by
    rating
order by
    rating desc;


-- 4번

select
    round(avg(rating), 2) as avg_rating,
    count(rating) as review_count,
    round(count(*) * 100 / 511, 1) as review_rate
from
    reviews;


select
    round(avg(rating), 2) as avg_rating,
    count(content) as review_count,
    round(count(*) / 511 * 100, 1) as review_rate
from
    reviews;


select
    round(avg(rating), 2) as avg_rating,
    count(content) as review_count,
    round(count(*) / (select count(*) from orders where status = '배달완료') * 100, 1) as review_rate
from
    reviews;


-- 5번

select
    *
from
    customers;

select
    grade,
    count(*) as members,
    count(if(marketing_agreed = 1, 1, null)) as members,
    count(email) as with_email
from
    customers
group by
    grade
order by
    grade;


-- 6번

select
    *
from
    orders;

select
    payment_method,
    count(*) as delivered_order,
    round(avg(discount_amount)) as avg_discount,
    count(discount_amount) - count(if(discount_amount = 0, 1, null)) as discounted_orders

from
    orders
where
    status = '배달완료'
group by
    payment_method
order by
    count(*) desc;


select
    payment_method,
    count(*) as delivered_orders,
    round(avg(discount_amount), 0) as avg_discount,
    count(if(discount_amount = 0, null, 1)) as discounted_orders
from
    orders
where
    status = '배달완료'
group by
    payment_method
order by
    delivered_orders desc;


-- 7번

select
    hour(ordered_at) as order_hour,
    count(*) as delivered_orders
from
    orders
where
    status = '배달완료'
group by
    order_hour
order by
    delivered_orders desc
limit 5;


-- 8번

select
    *
from
    orders;

select
    customer_id,
    count(*) as order_count,
    date_format(min(ordered_at), '%Y-%m-%d') as first_order,
    date_format(max(ordered_at), '%Y-%m-%d') as last_order
from
    orders
where
    status = '배달완료'
group by
    customer_id
having
    count(*) >= 30
order by
    order_count desc;


-- 9번

select
    order_id,
    count(*) as item_lines,
    sum(quantity * unit_price) as food_amount
from
    order_items
group by order_id
order by
    food_amount desc, order_id
limit 5;


-- 10번

select
    *
from
    order_items;

select
    unit_price,
    sum(quantity) as sold_quantity,
    sum(quantity * unit_price) as sales_amount
from
    order_items
where
    menu_id = 1
group by
    unit_price;

-- 11번

select
    *
from
    orders;

select
    rider_id,
    count(*) as deliveries,
    round(avg(timestampdiff(minute, ordered_at, delivered_at)), 1) as avg_minutesm,
    sum(case when timestampdiff(minute, ordered_at, delivered_at) > 60 then 1 else 0 end) as late_count,
#     sum(if(timestampdiff(minute, ordered_at, delivered_at) > 60, 1, null)) as late_count, -- null 이 그대로 남아있음
#     round(sum(case when timestampdiff(minute, ordered_at, delivered_at) > 60 then 1 else 0 end) * 100 / count(*), 1) as late_rate
    round(count(case when timestampdiff(minute, ordered_at, delivered_at) > 60 then 1 end) / count(*) * 100, 1) as late_rate
from
    orders
where
    status = '배달완료'
group by
    rider_id
order by
    deliveries desc;


-- 12번

select
    *
from
    orders;

select
    date_format(ordered_at, '%Y-%m') as order_month,
    sum(case when payment_method = '카드' then 1 else 0 end) as card,
    sum(case when payment_method = '간편결제' then 1 else 0 end) as easy_pay,
    sum(case when payment_method = '계좌이체' then 1 else 0 end) as transfer,
    sum(case when payment_method = '현장결제' then 1 else 0 end) as on_site,
    count(*) as total
from
    orders
where
    status = '배달완료'
group by
    order_month;


select
    *
from
    orders;

select
    date_format(ordered_at, '%Y-%m') as order_month,
    sum(case when payment_method = '카드' then 1 else 0 end) as card,
    sum(case when payment_method = '간편결제' then 1 else 0 end) as easy_pay,
    sum(case when payment_method = '계좌이체' then 1 else 0 end) as transfer,
    sum(case when payment_method = '현장결제' then 1 else 0 end) as on_sile,
    count(*) as total
from
    orders
where
    status = '배달완료'
group by
    date_format(ordered_at, '%Y-%m')
    -- order_month;


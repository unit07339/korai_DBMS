use hanip_delivery05;

select * from restaurants;
select * from orders;

select
    *
from
    orders, restaurants
where
    orders.restaurant_id = restaurants.restaurant_id
order by
    orders.order_id;


select
    *
from
    orders o inner join restaurants r on r.restaurant_id = o.restaurant_id
order by
    o.order_id;

-- on 바로 뒤에는 on 바로 앞에 있는 테이블 적기!!!!!!!!!!!!!!!!!!!!!!
-- 테이블명 바로 뒤에는 as 안붙임



select
    *
from
    orders o
    left join order_items oi on oi.order_id = o.order_id
    left join menus mn on mn.menu_id = oi.menu_id
    left join reviews rv on rv.order_id = o.order_id
    left join customers ct on ct.customer_id = o.customer_id
    left join restaurants rt on rt.restaurant_id = o.restaurant_id
    left join riders rd on rd.rider_id = o.rider_id
where
    ct.name = '윤지아';


select
    count(*)
from
    orders o
    left outer join reviews rv on rv.order_id = o.order_id -- 리뷰가 달린 오더들을 볼 때는 inner를 씀 <inner는 null 생략
where
    rv.review_id is null; -- 리뷰 안달린 거 카운트


select
    o.order_id, o.status,
    rd.name as rider_name
from
    orders o
left join riders rd on rd.rider_id = o.rider_id
where o.ordered_at >= '2026-06-30'
order by o.order_id;


select
    o.restaurant_id,
    rt.name,
    count(distinct o.order_id), -- 중복 제거
    sum(oi.quantity * oi.unit_price) -- 얼마가 팔렸는지
from
    orders o
    inner join restaurants rt on rt.restaurant_id = o.restaurant_id
    inner join order_items oi on oi.order_id = o.order_id
group by
    o.restaurant_id,
    rt.name; -- restaurant id는 달라도 name이 같을 수 있어서 두 개를 병합해서 그룹의 키값으로...
    -- select 에 name 썼으면 group by 에도 name 써야함


-- 자기 테이블을 자기가 한 번 더 조인 self join


-- 1번

select
    r.name as restaurant_name,
    m.name as menu_name,
    m.price as price
from
    menus m
inner join restaurants r on r.restaurant_id = m.restaurant_id
where r.category = '치킨'
order by
    r.restaurant_id, m.price desc;


-- 2번

select
    rd.name as rider_name,
    rd.vehicle as vehicle,
    count(o.delivered_at) as deliveries
from
    orders o
inner join riders rd on rd.rider_id = o.rider_id
group by rd.vehicle, rd.rider_id, rd.name
order by
    deliveries desc;


-- 3번

select
    review_id,
    rating,
    rt.name as restaurant_name,
    cs.name as customer_name,
    rv.content
from
    reviews rv
left join orders o on o.order_id = rv.order_id
left join restaurants rt on rt.restaurant_id = o.restaurant_id
left join customers cs on cs.customer_id = o.customer_id
where
    rating <= 2
order by created_at desc;



select
    review_id,
    rating,
    rt.name as restaurant_name,
    cs.name as customer_name
from
    reviews rv
inner join orders o on o.order_id = rv.order_id
inner join restaurants rt on rt.restaurant_id = o.restaurant_id
inner join customers cs on cs.customer_id = o.customer_id
where
    rating <= 2
order by created_at desc;


-- 4번

select
    order_id,
    status,
    ct.name as customer_name,
    rt.name as restaurant_name,
    rd.name as rider_name
from
    orders o
left join customers ct on ct.customer_id = o.customer_id
left join restaurants rt on rt.restaurant_id = o.restaurant_id
left join riders rd on rd.rider_id = o.rider_id
where o.status in ('접수', '조리중', '배달중');


-- 5번

select
    rt.name as restaurant_name,
    round(avg(rating), 2) as avg_rating,
    count(*) as review_count
from
    reviews rv
inner join orders o on o.order_id = rv.order_id
inner join restaurants rt on rt.restaurant_id = o.restaurant_id
group by rt.restaurant_id, rt.name
having count(*) >= 10
order by avg_rating desc;



-- 6

select
    rt.name as restaurant_name,
    m.name as menu_name,
    sum(oi.quantity) as sold_quantity
from
    order_items oi
inner join orders o on o.order_id = oi.order_id
inner join menus m on m.menu_id = oi.menu_id
inner join restaurants rt on rt.restaurant_id = m.restaurant_id
where status = '배달완료'
group by rt.name, m.name, m.menu_id
order by sold_quantity desc, m.menu_id
limit 5;


-- 7

select
    r.category,
    count(distinct o.order_id) as delivered_orders,
    sum(oi.quantity * oi.unit_price) as food_sales
from
    orders o
inner join order_items oi on oi.order_id = o.order_id
inner join restaurants r on r.restaurant_id = o.restaurant_id
where status = '배달완료'
group by r.category
order by food_sales desc;


-- 8

select
    m.menu_id,
    m.name as menu_name,
    r.name as restaurant_name
from menus m
inner join restaurants r on r.restaurant_id = m.restaurant_id
left join order_items oi on oi.menu_id = m.menu_id
where oi.order_item_id is null
order by menu_id;


-- 9

select
    c.name as customer_name,
    c.grade as grade,
    count(o.order_id) as delivered_orders
from customers c
left join orders o on o.customer_id = c.customer_id
and o.status = '배달완료'
group by c.customer_id
order by delivered_orders, c.customer_id;



-- 10

select
    r.name as rider_name,
    r.hired_at as hired_at,
    count(o.order_id) as deliveries,
    max(delivered_at) as last_delivered_at
from
    riders r
left join orders o on o.rider_id = r.rider_id
and status = '배달완료'
where r.is_active = 0
group by r.rider_id, r.name, r.hired_at;


-- 11

select
    m.name as menu_name,
    oi.unit_price,
    m.price as current_price,
    sum(oi.quantity) as sold_quantity
from
    order_items oi
inner join orders o on o.order_id = oi.order_id
inner join menus m on m.menu_id = oi.menu_id
where status = '배달완료'
and m.price != oi.unit_price
group by m.name, oi.unit_price, m.price, m.menu_id
order by m.menu_id;


-- 12

select
    count(*) as delivered_orders,
#     sum(case when c.district != r.district then 1 else 0 end) as cross_district,
#     round(sum(case when c.district != r.district then 1 else 0 end) / count(*) * 100, 1) as cross_rate
    sum(if(c.district != r.district, 1, 0)) as cross_district,
    round(sum(if(c.district != r.district,1 ,0)) / count(*) * 100, 1) as cross_rate
from
    orders o
inner join customers c on c.customer_id = o.customer_id
inner join restaurants r on r.restaurant_id = o.restaurant_id
where o.status = '배달완료';



-- 13

select
    r.name as restaurant_name,
    count(*) as delivered_orders,
    count(rv.review_id) as reviewed,
    round(count(rv.review_id) / count(*) * 100 ,1) as review_rate
from
    orders o
inner join restaurants r on r.restaurant_id = o.restaurant_id
left join reviews rv on rv.order_id = o.order_id
where o.status = '배달완료'
group by r.name, r.restaurant_id
order by review_rate desc;


-- 14

select
    date_format(o.ordered_at, '%Y-%m') as order_month,
    sum(if(r.category = '한식', oi.quantity * oi.unit_price, 0)) as korean,
    sum(if(r.category = '중식', oi.quantity * oi.unit_price, 0)) as chinese,
    sum(if(r.category = '치킨', oi.quantity * oi.unit_price, 0)) as chicken,
    sum(if(r.category = '피자', oi.quantity * oi.unit_price, 0)) as pizza,
    sum(oi.quantity * oi.unit_price) as all_categories
from
    orders o
inner join order_items oi on oi.order_id = o.order_id
inner join restaurants r on r.restaurant_id = o.restaurant_id
where o.status = '배달완료'
group by order_month



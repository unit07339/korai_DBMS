show tables;

create view v_names as
select
    od.order_id,
    od.customer_id,
    ct.name as customer_name,
    od.restaurant_id,
    rt.name as restaurant_name,
    od.rider_id,
    rd.name as rider_name
from
    orders od
    left outer join order_items oi on oi.order_id = od.order_id
    left outer join  customers ct on ct.customer_id = od.customer_id
    left outer join restaurants rt on rt.restaurant_id = od.restaurant_id
    left outer join riders rd on rd.rider_id = od.rider_id;

select * from v_names;


create index idx_restaurants_name on restaurants(name);


explain
select
    *
from
    restaurants
where
    name like '%버거%';


-- 중복이 많은 곳은 인덱스 성능 안좋음

explain
select
    *
from
    orders
where
    restaurant_id = 10;

create index idx_ordered_at on orders(ordered_at);

explain
select
    *
from
    orders
where
    ordered_at < '2026-01-04';

-- 문자열'' 안에는 * 안씀
create user 'user1'@'localhost' identified by '1q2w3e4r!';
create user 'user1'@'%' identified by '1q2w3e4r!';

select * from mysql.user;

grant select, insert on `hanip_delivery10`.customers to 'user1'@'%';

select * from orders;
insert into customers
values (null, '김준일', '010-1234-5678', 'test@gmail.com', '1994-09-07','부산진구', '부산광역시 부산진구 동평로', '실버', 1, now());

select * from customers;

show grants for 'user1'@'%';

revoke select on `hanip_delivery10`.* from 'user1'@'%';
revoke insert on `hanip_delivery10`.customers from 'user1'@'%';
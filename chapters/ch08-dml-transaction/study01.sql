use hanip_delivery08;

# 한건만 넣을 때 (단건)
insert into riders(rider_id, name, phone, vehicle, district, hired_at, is_active)
values (default, '김준일', '010-9988-1916', ' 오토바이', '부산진구', curdate(), 1);

insert into riders(phone, vehicle, district, hired_at, is_active, name)
values ('010-9988-1916', ' 오토바이', '부산진구', curdate(), 1, '김준일');

insert into riders
values (default, '김준일', '010-9988-1916', ' 오토바이', '부산진구', curdate(), 1);

# 다건

insert into riders
values
    (default, '김준일', '010-9988-1916', ' 오토바이', '부산진구', curdate(), 1),
    (default, '김준이', '010-9988-1916', ' 오토바이', '부산진구', curdate(), 1),
    (default, '김준삼', '010-9988-1916', ' 오토바이', '부산진구', curdate(), 1),
    (default, '김준사', '010-9988-1916', ' 오토바이', '부산진구', curdate(), 1);




CREATE TABLE rider_settlements (
       settlement_id   INT       NOT NULL AUTO_INCREMENT,
       rider_id        INT       NOT NULL,
       settle_month    CHAR(7)   NOT NULL,
       delivery_count  INT       NOT NULL DEFAULT 0,
       amount          INT       NOT NULL DEFAULT 0,
       is_paid         BOOLEAN   NOT NULL DEFAULT FALSE,
       paid_at         DATETIME      NULL,
       CONSTRAINT pk_rider_settlements PRIMARY KEY (settlement_id),
       CONSTRAINT fk_settlements_rider FOREIGN KEY (rider_id) REFERENCES riders (rider_id),
       CONSTRAINT uq_settlements_month UNIQUE (rider_id, settle_month),
       CONSTRAINT ck_settlements_month CHECK (settle_month REGEXP '^[0-9]{4}-(0[1-9]|1[0-2])$'),
       CONSTRAINT ck_settlements_count CHECK (delivery_count >= 0),
       CONSTRAINT ck_settlements_amount CHECK (amount >= 0),
       CONSTRAINT ck_settlements_paid CHECK (
           (is_paid = TRUE AND paid_at IS NOT NULL)
               OR (is_paid = FALSE AND paid_at IS NULL))
);


select
    rider_id
#     settle_month,
#     delivery_count,
#     amount
from
    orders;


select *
from orders;



insert into rider_settlements(rider_id, settle_month, delivery_count, amount)
select
    rider_id,
    date_format(delivered_at, '%Y-%m') as settle_month,
    count(*) as delivery_count,
    sum(delivery_fee) as amount
from
    orders
where
    delivered_at is not null
group by
    rider_id,
    date_format(delivered_at, '%Y-%m')
order by
    rider_id,
    settle_month;




select
    *
from
    rider_settlements;

update
    rider_settlements
set
    is_paid = true,
    paid_at = '2026-01-10'
where
    settle_month = '2026-01';

update
    riders
set
    is_active = 0
where
    rider_id in (4, 8);

select
    *
from
    riders;

update
    rider_settlements rs
inner join riders r on r.rider_id = rs.rider_id
set
    is_paid = true
where
    r.is_active = 1;

    (select
         is_active
     from riders
     where is_active = 1);
-- in active 가 1 인 애들만 매달 10일에 지급



update
    rider_settlements rs
    left outer join riders r on r.rider_id = rs.rider_id
set
    is_paid = 1,
    paid_at = concat(settle_month, '-10')
where
    r.is_active = 1;

select
    *
from
    rider_settlements;


select @@autocommit; -- 1은 활성화
set @@autocommit = 0; -- 재접속하면 정보 사라짐


start transaction;

insert into riders
values (default, '김준이', '010-1234-5678', '오토바이', '부산진구', curdate(), 1);

select *
from riders;

rollback;

commit; -- 저장



-- 6-1

start transaction;

insert into orders(customer_id, restaurant_id, status, payment_method,
                   delivery_fee, discount_amount, request_note, ordered_at)
values (1, 1, '접수', '간편결제', 2500, 5000, '문 앞에 두고 벨 눌러주세요.', '2026-06-30 19:05:00');

set @order_id = last_insert_id();

insert into order_items(order_id, menu_id, quantity, unit_price)
select @order_id, menu_id, case menu_id when 1 then 2 else 1 end, price
from menus
where menu_id in (1, 4);

update customer_coupons
set used_order_id = @order_id
where customer_id = 1 and coupon_id = 3 and used_order_id is null;

select @order_id as new_order_id, row_count() as coupon_rows_updated;



-- 5

create table daily_sales (
    sales_date date not null primary key,
    orders int not null,
    food_sales int not null
);

# insert into daily_sales (sales_date, orders, food_sales)
select
    date(o.ordered_at) as sales_date,
    count(distinct o.order_id) as orders,
    sum(oi.quantity * oi.unit_price) as food_sales
from
    orders o
    inner join order_items oi on oi.order_id = o.order_id
where
    o.status = '배달완료'
    and o.ordered_at >= '2026-06-24'
    and o.ordered_at < '2026-07-01'
group by date(o.ordered_at);

select
    sales_date, orders, food_sales
from
    daily_sales;


select
    *
from
    daily_sales;


select
    *
from
    orders;


-- -----
# insert into daily_sales (sales_date, orders, food_sales)
select
    date(ordered_at) as sales_date,
    count(distinct o.order_id) as orders,
    sum(oi.quantity * oi.unit_price) as food_sales
from
    orders o
    inner join order_items oi on oi.order_id = o.order_id
where
    date_format(ordered_at, '%Y-%m') = '2026-06'
    and ordered_at >= date_sub(last_day(ordered_at), interval 6 day)
    and date(ordered_at) <= last_day(ordered_at)
    and status = '배달완료'
group by
    date(ordered_at);



-- 6

start transaction;

select
    c.name,
    c.grade
from
    orders o
    join customers c on c.customer_id = o.customer_id
where
    o.status = '배달완료'
    and o.ordered_at >= '2026-06-01'
    and o.ordered_at < '2026-07-01'
    and c.grade = '일반'
group by c.name, c.grade
having count(*) >= 4;



update
    customers
set
    grade = '실버'
where
    grade = '일반'
    and customer_id in (
        select
            o.customer_id
        from
            orders o
        where
            o.status = '배달완료'
          and o.ordered_at >= '2026-06-01'
          and o.ordered_at < '2026-07-01'
        group by o.customer_id
        having count(*) >= 4
    );

select
    name,
    grade
from customers
where
    grade = '실버';


-- ---------------------------

select
    customer_id,
    count(*)
from
    orders
where
    date_format(ordered_at, '%Y-%m') = '2026-06'
group by
    customer_id
having
    count(*) >= 4;



update
    customers c
inner join (select
                customer_id,
                count(*)
            from
                orders
            where
                date_format(ordered_at, '%Y-%m') = '2026-06'
                and status = '배달완료'
            group by
                customer_id
            having
                count(*) >= 4) od on od.customer_id = c.customer_id
set
    c.grade = '실버'
where
    c.grade = '일반';


-- 7 -------

start transaction;


update coupons
set
    is_active = false
where coupon_id > 0;


select
    *
from
    coupons;


rollback;

-- ----------------------
use hanip_market;

-- 1
select
    cg.name,
    count(distinct o.order_id) as orders,
    sum(oi.quantity),
    sum(oi.quantity * oi.unit_price) as sales
from
    orders o
inner join order_items oi on oi.order_id = o.order_id
inner join products p on p.product_id = oi.product_id
inner join categories c on c.category_id = p.category_id
inner join categories cg on cg.category_id = c.parent_id
where
    o.status = '배송완료'
group by cg.name
order by sales desc;

-- ---


select
    c2.name,
    count(distinct o.order_id) as orders,
    sum(oi.quantity) as quantity,
    sum(oi.quantity * oi.unit_price) as sales
from
    orders o
left join order_items oi on oi.order_id = o.order_id
left join products p on p.product_id = oi.product_id
inner join categories c on c.category_id = p.category_id
left join categories c2 on c2.category_id = c.parent_id
where
    o.status = '배송완료'
group by c2.category_id, c2.name
order by sales desc;



-- 2

select
    m.region,
    count(distinct m.member_id) as members,
    count(distinct o.member_id) as buyers,
    round(count(distinct o.member_id) / count(distinct m.member_id) * 100, 1) as conversion_rate
from
    members m
left outer join orders o on o.member_id = m.member_id and o.status = '배송완료'
group by region
order by conversion_rate desc, region;

-- buyers ÷ members × 100


-- 3

select
    p.brand,
    count(*) as reviews,
    round(avg(r.rating), 2) as avg_rating,
    round(sum(if(rating in (1, 2), 1, 0 )) / count(*) * 100, 1) as low_rating_pct
from
    reviews r
inner join products p on p.product_id = r.product_id
group by p.brand
having count(*) >= 10
order by avg_rating, brand;


-- 4

select
    date_format(ordered_at, '%Y-%m') as ym,
    sum(case when payment_method = '카드' then 1 else 0 end) as card,
    sum(case when payment_method = '간편결제' then 1 else 0 end) as easy_pay,
    sum(case when payment_method = '계좌이체' then 1 else 0 end) as bank_transfer,
    count(*) as total
from
    orders
where
    status not in ('취소', '반품')
    and ordered_at >= '2026-01-01'
    and ordered_at < '2027-01-01'
group by
    date_format(ordered_at, '%Y-%m')
order by ym;



-- 5

select
    p.product_id,
    p.name,
    p.is_active,
    p.stock,
    sum(ifnull(oi.quantity, 0)) as ordered_qty,
    sum(if(o.status = '배송완료', oi.quantity, 0)) as sold_qty
from
    products p
left outer join order_items oi on oi.product_id = p.product_id
left outer join orders o on o.order_id = oi.order_id
group by p.product_id, p.name, p.is_active, p.stock
having sold_qty = 0
order by p.product_id;




-- 6

select
    m.name,
    count(*) as orders,
    date(min(t.ordered_at)) as first_order,
    date(max(t.ordered_at)) as last_order,
    round(avg(t.amount)) as avg_amount

from
    (select
         o.order_id,
         o.member_id,
         o.ordered_at,
         sum(oi.quantity * oi.unit_price) + o.shipping_fee - o.coupon_discount as amount
     from
         orders o
     inner join order_items oi on oi.order_id = o.order_id
     where o.status = '배송완료'
     group by o.order_id
     ) t
inner join members m on m.member_id = t.member_id
group by m.member_id
having count(*) >= 10
order by orders desc, avg_amount desc;



-- 7

# (select
#     category_id,
#     round(avg(price)) as category_avg
# from
#     products
# where
#
#     is_active = 1
# group by category_id) t

select
    c.name as category,
    p.name,
    p.price,
    round(t.category_avg) as category_avg
from
    products p
inner join (select
                category_id,
                avg(price) as category_avg
            from
                products
            where

                is_active = 1
            group by category_id) t on t.category_id = p.category_id
inner join categories c on c.category_id = p.category_id
where
    p.price > t.category_avg
    and p.is_active = 1
order by
    c.category_id, price desc;

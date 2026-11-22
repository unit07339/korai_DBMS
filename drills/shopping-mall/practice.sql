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
    date_format(ordered_at, '%Y-%m')       as ym,
#     sum(case when payment_method = '카드' then 1 else 0 end) as card,
#     sum(case when payment_method = '간편결제' then 1 else 0 end) as easy_pay,
#     sum(case when payment_method = '계좌이체' then 1 else 0 end) as bank_transfer,
    sum(IF(payment_method = '카드', 1, 0))   as card,
    sum(IF(payment_method = '간편결제', 1, 0)) as easy_pay,
    sum(IF(payment_method = '계좌이체', 1, 0)) as bank_transfer,
    count(*)                               as total
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


-- ---  10



select
    c.name as category,
    p.name,
    p.brand,
    p.price
from
    products p
inner join (select
        category_id,
        max(price) as max_price
from
    products
group by category_id) p2 on p2.category_id = p.category_id
inner join categories c on c.category_id = p.category_id
where p2.max_price = p.price
order by c.category_id;




-- ------ 10 풀이

select
    category,
    name,
    brand,
    price
from
(select
    rank() over (partition by ct.category_id order by price desc) as rank_num,
    ct.category_id,
    ct.name as category,
    pd.name,
    pd.brand,
    pd.price
from
    categories ct
    left outer join products pd on pd.category_id = ct.category_id
where
    ct.parent_id is not null) as category_rank
where
    rank_num = 1
order by category_id;




-- --- 11


select
    p.name as product_name,
    m.name as member_name,
    m.region,
    count(distinct o.order_id) as times
from
    (select
         oi.product_id,
         sum(oi.quantity) as sold_qty
     from
         orders o
             inner join order_items oi on oi.order_id = o.order_id
     where
         o.status = '배송완료'
     group by oi.product_id
     having sold_qty = (select
                            max(t.sold_qty)
                        from
                            (select
#                                  oi.product_id,
                                 sum(oi.quantity) as sold_qty
                             from
                                 orders o
                                     inner join order_items oi on oi.order_id = o.order_id
                             where
                                 o.status = '배송완료'
                             group by oi.product_id) t)) fn
inner join order_items oi on oi.product_id = fn.product_id
inner join orders o on o.order_id =oi.order_id
inner join members m on m.member_id = o.member_id
inner join products p on p.product_id = fn.product_id
where
    o.status = '배송완료'
group by m.member_id, p.product_id
order by times desc; -- member_name;





select
    oi.product_id,
    sum(oi.quantity) as sold_qty
from
    orders o
        inner join order_items oi on oi.order_id = o.order_id
where
    o.status = '배송완료'
group by oi.product_id
having sold_qty = (select
                       max(t.sold_qty)
                   from
                       (select
#                             oi.product_id,
                            sum(oi.quantity) as sold_qty
                        from
                            orders o
                                inner join order_items oi on oi.order_id = o.order_id
                        where
                            o.status = '배송완료'
                        group by oi.product_id) t);



select
    max(t.sold_qty)
from
    (select
#          oi.product_id,
         sum(oi.quantity) as sold_qty
     from
         orders o
             inner join order_items oi on oi.order_id = o.order_id
     where
         o.status = '배송완료'
     group by oi.product_id) t;







select
    oi.product_id,
    sum(oi.quantity) as sold_qty
from
    orders o
inner join order_items oi on oi.order_id = o.order_id
where
    o.status = '배송완료'
group by oi.product_id
having sold_qty = 31;



select
    *
from
    order_items;


select
    *
from
    orders;

select
    *
from
    members;

select
    *
from
    products;


-- ------- 11번 풀이



select
    product_name,
    mb.name,
    mb.region,
    count(od.order_id) as times
from
    (
    select
        rank() over (order by sum(oi.quantity) desc) as rank_num,
        oi.product_id,
        pd.name as product_name,
        sum(oi.quantity) as total_quantity
    from
        orders od
            inner join order_items oi on oi.order_id = od.order_id and od.status = '배송완료'
            inner join products pd on pd.product_id = oi.product_id
    group by oi.product_id, pd.name
    ) pr
    left outer join order_items oi on oi.product_id = pr.product_id
    inner join orders od on od.order_id = oi.order_id and od.status = '배송완료'
    left outer join members mb on mb.member_id = od.member_id
where rank_num = 1
group by
    product_name,
    mb.member_id,
    mb.name,
    mb.region
order by
    times desc;






-- 공동이 아니라 하나만 뽑을 때는 이렇게 써도 됨
select
    oi.product_id,
    pd.name as product_name,
    sum(oi.quantity) as total_quantity
from
    orders od
inner join order_items oi on oi.order_id = od.order_id and od.status = '배송완료'
inner join products pd on pd.product_id = oi.product_id
group by oi.product_id, pd.name
order by total_quantity desc
limit 1;






-- ----- 14

select
    row_number() over (order by ordered_at, order_id) as order_seq,
    t.order_id,
    t.ordered_at,
    t.amount,
    sum(t.amount) over (order by t.ordered_at, t.order_id) as running_total,
    case when sum(t.amount) over (order by t.ordered_at, t.order_id) >= 500000
                  and sum(t.amount) over (order by t.ordered_at, t.order_id) - t.amount < 500000 then 'VIP 달성' end as vip_reached
from
(select
    o.order_id,
    date(o.ordered_at) as ordered_at,
    sum(oi.quantity * oi.unit_price) + o.shipping_fee - o.coupon_discount as amount
from
    orders o
left outer join order_items oi on oi.order_id = o.order_id
where o.member_id = 1 and o.status = '배송완료'
group by o.order_id, o.ordered_at) as t
order by order_seq;



-- ----- 14번 풀이
select
    order_seq,
    order_id,
    ordered_at,
    amount,
    running_total,
    if(row_number() over (partition by running_total_group order by ordered_at)= 1 and running_total_group = 1, 'VIP 달성', null) as vip_reached
from (select row_number() over (order by date(o.ordered_at)) as order_seq,
             o.order_id,
             date(o.ordered_at) as ordered_at,
             sum(oi.quantity * oi.unit_price) + o.shipping_fee - o.coupon_discount as amount,
             sum(sum(oi.quantity * oi.unit_price) + o.shipping_fee - o.coupon_discount)
                 over (order by o.order_id) as running_total,
             sum(sum(oi.quantity * oi.unit_price) + o.shipping_fee - o.coupon_discount) over (order by o.order_id) >= 500000
                 as running_total_group

      from orders o
               inner join order_items oi
                          on o.order_id = oi.order_id and o.status = '배송완료'
                              and o.member_id = 1
      group by o.order_id,
               date(o.ordered_at)
      ) result;


-- ------ 15
with first_1 as (select
    o.member_id,
    c2.name as main_category,
    row_number() over (partition by o.member_id order by o.ordered_at, o.order_id, oi.order_item_id) as rn
from
    orders o
    inner join order_items oi on oi.order_id = o.order_id
    inner join products p on p.product_id = oi.product_id
    inner join categories c on c.category_id = p.category_id
    inner join categories c2 on c2.category_id = c.parent_id
where
    o.status = '배송완료')

select
    main_category as first_main_category,
    count(main_category) as members
#     round(???, 1)
from
    first_1
where
    rn = 1
group by main_category
order by members desc, first_main_category;



-- round(count(*) / sum(count(*)) over () * 100 , 1) as members


-- ----- 15번 풀이

select
    pct.name,
    count(foi.member_id) as members,
    round(count(*) / sum(count(*)) over() * 100, 1) as pct
from
    (
select
    od.member_id,
    min(oi.order_item_id) as first_order_item_id
from
    orders od
    inner join order_items oi on oi.order_id = od.order_id and od.status = '배송완료'
group by
    od.member_id
    ) foi
    left outer join order_items oi on oi.order_item_id = foi.first_order_item_id
    left outer join products pd on pd.product_id = oi.product_id
    left outer join categories ct on ct.category_id = pd.category_id
    left outer join categories pct on pct.category_id = ct.parent_id
group by
    pct.category_id,
    pct.name
order by
    pct.category_id;


-- ---- 17

with union_1 as (
select
    joined_at,
    0 as is_withdrawn
from
    members

union all

select
    joined_at,
    1 as is_withdrawn
from
    withdrawn_members
)

select
    concat(year(joined_at), '-Q', quarter(joined_at)) as join_quarter,
    count(*) as joined,
    sum(is_withdrawn) as withdrawn
from
    union_1
group by join_quarter
order by join_quarter;


-- ----- 17번 풀이

select
    join_quarter,
    count(joined_at) as joined,
    count(withdrawn_at) as withdrawn
from
    (
select
    concat(year(joined_at), '-Q',
           case
               when month(joined_at) < 4 then '1'
               when month(joined_at) < 7 then '2'
               when month(joined_at) < 10 then '3'
               else '4'
            end) as join_quarter,
    joined_at,
    null as withdrawn_at
from
    members
union all
select
    concat(year(joined_at), '-Q',
           case
               when month(joined_at) < 4 then '1'
               when month(joined_at) < 7 then '2'
               when month(joined_at) < 10 then '3'
               else '4'
               end) as join_quarter,
    joined_at,
    withdrawn_at
from
    withdrawn_members
    ) join_quarter
group by
    join_quarter
order by
    join_quarter;


-- ------ 19

with all_rows as (
    select
        member_id,
        product_id
    from
        carts

    union all

    select
        member_id,
        product_id
    from
        wishlists
)

select
    count(*) as union_all_rows,
    count(distinct member_id, product_id) as union_rows,
    count(*) - count(distinct member_id, product_id) as in_both
from
    all_rows;


with all_rows as (
select
    member_id,
    product_id
from
    wishlists
union all
select
    member_id,
    product_id
from
    carts
),

union_rows as (
select
    member_id,
    product_id
from
    wishlists
union
select
    member_id,
    product_id
from
    carts
    )
select
    (select count(*) from all_rows) as union_all_rows,
    (select count(*) from union_rows) as union_rows,
    (select count(*) from wishlists w
                     where exists(select 1 from carts c
                                           where c.member_id = w.member_id
                                           and c.product_id = w.product_id)) as in_both;

/*
select
    '합계' as region,
    ___ as orders,
    ___ as revenue,
    ___ as avg_order,
    100.0 as share_pct
from
    amount1;

*/

-- -------- 20


with amount1 as (
select
    o.order_id,
    o.member_id,
    sum(oi.quantity * oi.unit_price) + o.shipping_fee - o.coupon_discount as amount
from
    orders o
inner join order_items oi on oi.order_id = o.order_id
where
    o.status = '배송완료'
group by
    o.order_id
)

select
    m.region,
    count(*) as orders,
    sum(a.amount) as revenue,
    round(avg(a.amount)) as avg_order,
    round(sum(a.amount) / sum(sum(a.amount)) over () * 100, 1) as share_pct
from
    amount1 a
    inner join members m on m.member_id = a.member_id
group by m.region

union all

select
    '합계' as region,
    count(*) as orders,
    sum(a.amount) as revenue,
    round(avg(a.amount)) as avg_order,
    100.0 as share_pct
from
    amount1 a
order by
    region = '합계', revenue desc;

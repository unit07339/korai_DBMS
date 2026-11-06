-- 1

SELECT column_name AS column_name,
       data_type AS data_type
FROM information_schema.columns
WHERE table_schema = DATABASE()
  AND table_name = 'orders'
  AND is_nullable = 'YES'
ORDER BY ordinal_position;

-- 2

SELECT column_name AS column_name,
       data_type AS data_type
FROM information_schema.columns
WHERE table_schema = DATABASE()
  AND table_name = 'orders'
  AND is_nullable = 'YES'
ORDER BY ordinal_position;

-- 3



-- 4

CREATE TABLE notices (
 notice_id    INT          NOT NULL AUTO_INCREMENT,
 title        VARCHAR(100) NOT NULL,
 content      TEXT         NOT NULL,
 is_pinned    BOOLEAN      NOT NULL DEFAULT FALSE,
 published_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT pk_notices PRIMARY KEY (notice_id)
);

INSERT INTO notices (title, content, is_pinned) VALUES
    ('7월 정산일 안내', '7월 정산은 10일에 진행됩니다.', TRUE);
INSERT INTO notices (title, content) VALUES
    ('배달팁 정책 변경', '8월부터 5만 원 이상 무료 배달 기준이 4만 원으로 바뀝니다.');

SELECT notice_id, title, is_pinned
FROM notices
ORDER BY notice_id;


-- 5

CREATE TABLE restaurant_holidays (
 holiday_id    INT         NOT NULL AUTO_INCREMENT,
 restaurant_id INT         NOT NULL,
 holiday_date  DATE        NOT NULL,
 reason        VARCHAR(50)     NULL,
 CONSTRAINT pk_restaurant_holidays PRIMARY KEY (holiday_id),
 CONSTRAINT fk_holidays_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants (restaurant_id),
 CONSTRAINT uq_holidays_date UNIQUE (restaurant_id, holiday_date)
);

INSERT INTO restaurant_holidays (restaurant_id, holiday_date, reason) VALUES
  (1, '2026-07-15', '내부 수리'),
  (6, '2026-07-15', NULL),
  (1, '2026-07-16', '내부 수리');

SELECT h.holiday_date,
       r.name AS restaurant_name,
       h.reason
FROM restaurant_holidays h
         JOIN restaurants r ON h.restaurant_id = r.restaurant_id
ORDER BY h.holiday_date, r.restaurant_id;


-- 6

-- (가)
INSERT INTO restaurant_holidays (restaurant_id, holiday_date) VALUES (6, '2026-07-16');
-- (나)
INSERT INTO restaurant_holidays (restaurant_id, holiday_date) VALUES (1, '2026-07-15');
-- (다)
INSERT INTO restaurant_holidays (restaurant_id, holiday_date) VALUES (99, '2026-07-20');
-- (라)
INSERT INTO restaurant_holidays (restaurant_id, reason) VALUES (2, '명절');



-- 7

CREATE TABLE menu_options (
      option_id    INT         NOT NULL AUTO_INCREMENT,
      menu_id      INT         NOT NULL,
      name         VARCHAR(30) NOT NULL,
      extra_price  INT         NOT NULL DEFAULT 0,
      CONSTRAINT pk_menu_options PRIMARY KEY (option_id),
      CONSTRAINT fk_options_menu FOREIGN KEY (menu_id) REFERENCES menus (menu_id) ON DELETE CASCADE,
      CONSTRAINT uq_options_name UNIQUE (menu_id, name),
      CONSTRAINT ck_options_price CHECK (extra_price >= 0)
);

INSERT INTO menu_options (menu_id, name, extra_price) VALUES
          (35, '곱빼기', 1000),
          (35, '계란 프라이', 1500),
          (35, '면 추가 없음', 0);

SELECT m.name AS menu_name,
       mo.name AS option_name,
       m.price + mo.extra_price AS price_with_option
FROM menu_options mo
         JOIN menus m ON mo.menu_id = m.menu_id
ORDER BY price_with_option, mo.option_id;


-- 8

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

SELECT constraint_name AS constraint_name,
       constraint_type AS constraint_type
FROM information_schema.table_constraints
WHERE table_schema = DATABASE()
  AND table_name = 'rider_settlements'
ORDER BY constraint_type, constraint_name;









use hanip_delivery07;

drop table if exists coupons_draft;

# DDL 문법
create table coupons_draft(
    coupon_id       int,
    code            varchar(20),
    name            varchar(50),
    discount_amount int
); # 컬럼 세팅

insert into coupons_draft values # () 하나가 튜플
    (1, 'WELCOME3000', '첫 주문 3,000원 할인', 3000),
    (1, 'WELCOME3000', null, -5000),
    (null, null, '이름만 있는 쿠폰', null);
select * from coupons_draft;


create table coupons(
    coupon_id int not null auto_increment,
    code varchar(20) not null,
    name varchar(50) not null,
    discount_type varchar(10) not null,
    discount_value int not null,
    min_order_amount int not null default 0,
    valid_days int not null default 30,
    is_active boolean not null default true,
    create_at datetime not null default current_timestamp,
    constraint pk_coupons primary key (coupon_id),
    constraint uq_coupons_code unique (code),
    constraint ck_coupons_type check (discount_type in ('정액', '정률')),
    constraint ck_coupons_value check(
        (discount_type = '정액' and discount_value > 0)
        or (discount_type = '정률' and discount_value between 1 and 50)),
    constraint ck_coupons_min check (min_order_amount >= 0),
    constraint ck_coupons_days check (valid_days > 0)
);

select * from coupons;

create table customer_coupons (
    customer_coupon_id int not null AUTO_INCREMENT,
    customer_id int not null,
    coupon_id int not null,
    issued_at datetime not null default current_timestamp,
    expires_at datetime not null,
    used_order_id int null,
    constraint pk_customer_coupons primary key (customer_coupon_id),
    constraint fk_cc_customer foreign key (customer_id) references customers (customer_id),
    constraint fk_cc_coupon foreign key (coupon_id) references coupons (coupon_id),
    constraint fk_cc_order foreign key (used_order_id) references orders (order_id),
    constraint uq_cc_customer_coupon unique (customer_id, coupon_id),
    constraint uq_cc_used_order unique (used_order_id),
    constraint ck_cc_period check ( expires_at > issued_at )
);


-- 1

select
    COLUMN_NAME,
    DATA_TYPE
from
    information_schema.COLUMNS
where
    TABLE_SCHEMA = database()
    and table_name = 'orders'
    and IS_NULLABLE = 'yes';

-- 2

select
    CONSTRAINT_NAME as constraint_name
from
    information_schema.TABLE_CONSTRAINTS
where
    TABLE_SCHEMA = database()
    and TABLE_NAME = 'orders'
    and CONSTRAINT_TYPE = 'CHECK'
order by CONSTRAINT_NAME;


select constraint_name as constraint_name
from information_schema.table_constraints
where
    table_schema = database()
    and table_name = 'orders'
    and constraint_type = 'check'
order by constraint_name;


-- 3

/*  1. char
    2. decimal
    3. varchar
    4. decimal
    5. datetime
    6. boolean   */



-- 4

create table notices (
    notice_id int not null auto_increment,
    title varchar(100) not null,
    content text not null,
    is_pinned boolean not null default false,
    published_at datetime not null default current_timestamp,
    constraint pk_notices primary key (notice_id)
);

insert into notices(title, content, is_pinned)
values ('7월 정산일 안내', '7월 정산은 10일에 진행됩니다.', true),
       ('배달팁 정책 변경', '8월부터 5만 원 이상 무료 배달 기준이 4만원으로 바뀝니다.', false);

select
    notice_id,
    title,
    is_pinned
from
    notices;



-- 5

drop table restaurant_holidays;

create table restaurant_holidays (
    holiday_id int not null auto_increment,
    restaurant_id int not null,
    holiday_date date not null,
    reason varchar(50) null,
    constraint pk_restaurant_holidays primary key (holiday_id),
    constraint fk_holidays_restaurant foreign key (restaurant_id) references restaurants (restaurant_id),
    constraint uq_holidays_date unique (restaurant_id, holiday_date)
);

insert into restaurant_holidays (restaurant_id, holiday_date, reason)
values
    (1, '2026-07-15', '내부수리'),
    (6, '2026-07-15', null),
    (1, '2026-07-16', '내부수리');


select
    holiday_date,
    r.name as restaurant_name,
    reason
from
    restaurant_holidays rh
inner join restaurants r on r.restaurant_id = rh.restaurant_id
order by
    holiday_date;


-- 7

drop table menu_option;

create table menu_option (
    option_id int not null auto_increment,
    option_name varchar(50) not null,
    extra_price int not null,
    menu_id int not null,
    constraint pk_menu_option primary key (option_id),
    constraint fk_options_menu foreign key (menu_id) references menus (menu_id) on delete cascade,
    constraint ck_options_price check (extra_price >= 0),
    constraint uq_options_name unique (menu_id, option_name)
);

insert into menu_option(menu_id, option_name, extra_price)
values
    (35, '곱빼기', 1000),
    (35, '계란프라이', 1500),
    (35, '면 추가 없음', 0);

select
    m.name as menu_name,
    mo.option_name,
    m.price + mo.extra_price as price_with_option
from
    menu_option mo
inner join menus m on m.menu_id = mo.menu_id
order by
    price_with_option;


-- 7 --

# create table menu_options(
#     menu_option_id int not null auto_increment,
#     menu_id int not null,
#     name varchar(255) not null,
#     option_price int not null default 0,
#     constraint pk_menu_option_id primary key(menu_option_id),
#     constraint uq_menu_option_name unique (name),
#     constraint ck_menu_option_price check ( option_price >= 0 ),
#     constraint fk_menu_id foreign key (menu_id) references menus (menu_id) on delete cascade
# );
#
# insert into menu_options
# values
#     (default, 35, '면 추가 없음', 0),
#     (default, 35, '곱빼기', 1000),
#     (default, 35, '계란 프라이', 1500);
#
#
# select
#     mn.name as menu_name,
#     mo.name as option_name,
#     mn.price + mo.option_price as price_with_option
# from
#     menus mn
#     inner join menu_option mo on mo.menu_id = mn.menu_id;
#

-- 8

create table rider_settlements (
    settlement_id int not null auto_increment,
    rider_id int not null,
    settlement_month char(7) not null,
    settlement_amount int not null,
    delivery_count int not null,
    is_paid boolean not null default false,
    paid_at datetime null,
    constraint pk_settlements primary key (settlement_id),
    constraint fk_settlements_rider foreign key (rider_id) references riders (rider_id),
    constraint uq_settlements_rider_month unique (rider_id, settlement_month),
    constraint ck_settlements_month check (settlement_month REGEXP '^[0-9]{4}-(0[1-9]|1[0-2])$'),
    constraint ck_settlements_count check ( delivery_count >= 0 ),
    constraint ck_settlements_amount check ( settlement_amount >= 0 ),
    constraint ck_settlements_paid check ((is_paid = true and paid_at is not null) or (is_paid = false and paid_at is null))
);

select
    CONSTRAINT_NAME as constraint_name,
    constraint_type as constraint_type
from information_schema.TABLE_CONSTRAINTS
where TABLE_SCHEMA = database()
    and table_name = 'rider_settlements'
order by
    constraint_type,
    CONSTRAINT_NAME;


#
# settlement_id
#     pk
#
# rider_id, 기사 아이디
#     riders 참조
#     unique
#
# settlement_month, 정산 월
#     2026-06 형식 '%Y-%m'
#     unique
#
# settlement_amount, 정산 금액
#     0 이상
#
# delivery_count, 배달 건수
#     0 이상
#
# is_paid,  지급 여부
#     boolean, false
#
# paid_at, 지급 일시
#     null
#


-- 8 --

create table rider_settlements(
    rider_settlement_id int not null primary key auto_increment,
    rider_id int not null,
    settlement_month varchar(10) not null check ( settlement_month regexp('^[0-9]{4}-(0[1-9]|1[0-2])$') ),
    settlements_count int not null default 0 check(settlements_count >= 0),
    settlements_amount int not null default 0 check ( settlements_amount >= 0 ),
    settlements_paid tinyint(1) not null default 0 check ( settlements_paid in (0,1) ),
    constraint fk_settlements_rider foreign key (rider_id) references riders (rider_id),
    constraint uq_settlements_month unique (rider_id, settlement_month)
);













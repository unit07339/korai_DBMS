use hanip_delivery09;

create table ex_rider_sheet_2(
    rider_id int primary key  auto_increment,
    rider_name varchar(20) not null,
    phone varchar(20) not null,
    zone varchar(20) not null
);

insert into ex_rider_sheet_2
values
    (default, '곽태호', '010-3105-2205', '해운대'),
    (default, '곽태호', '010-3105-2205', '송정'),
    (default, '노지환', '010-3102-2202', '서면'),
    (default, '노지환', '010-3102-2202', '부전');

-- 1정규화
insert into ex_rider_sheet_2
select
    0,
    rider_name,
    phone,
    substring_index(substring_index(ers.zones, ',', seq.n), ', ', -1) as zone
from
    ex_rider_sheet ers
    inner join (select 1 as n
                union all select 2
                union all select 3
                union all select 4
                union all select 5) seq
        on seq.n <= (char_length(ers.zones) - char_length(replace(ers.zones, ', ', ''))) / 2 + 1
;




select
    *
from
    ex_rider_sheet_2;


create table ex_riders(
    rider_id int primary key auto_increment,
    name varchar(20) not null,
    phone varchar(20) not null
);

-- 2 정규
-- 연결 테이블 (위아래가 부분종속)
create table ex_riding_zones(
    riding_zone_id int auto_increment primary key,
    rider_id int not null,
    zone_id int not null
);

-- 3 정규
create table ex_zones (
    zone_id int primary key auto_increment,
    name varchar(20) not null
);

-- ------------------------------------
select
    *
from
    ex_coupon_sheet;

create table ex_coupons (
    coupon_id int primary key auto_increment,
    coupon_code varchar(20) not null,
    coupon_name varchar(20) not null,
    discount_amount int not null
);


create table ex_customers (
    customer_id int primary key auto_increment,
    customer_name varchar(20) not null,
    customer_phone varchar(20) not null
);

create table ex_customer_coupons (
    customer_coupon_id int primary key auto_increment,
    customer_id int not null,
    coupon_id int not null,
    used_at datetime null
);

-- ----------------------------

show tables;

insert into ex_customers
select distinct
    null, # id 자리 만들어줘야함
    customer_name,
    customer_phone
from
    ex_coupon_sheet;

select
    *
from
    ex_customers;

-- -----------------

insert into ex_coupons
select distinct
    null,
    coupon_code,
    coupon_name,
    discount_amount
from
    ex_coupon_sheet;

select
    *
from
    ex_coupons;

-- ----------------------
insert into ex_customer_coupons
select
    null,
    ec.customer_id,
    e.coupon_id,
    ecs.used_at
from
    ex_coupon_sheet ecs
    left outer join ex_customers ec on ec.customer_name = ecs.customer_name and ec.customer_phone = ecs.customer_phone
    left outer join ex_coupons e on e.coupon_code = ecs.coupon_code;

select
    *
from
    ex_customer_coupons;


select
    *
from
    ex_coupon_sheet;


-- ---------------------------------------------------------------

-- 도서관(홈페이지) 도서(표준, 표지주소) 출판사 카테고리 / 도서 전체를 묶는 중간테이블은 기본 테이블


create table books(
    book_id int auto_increment primary key,
    book_type varchar(20) not null,
    isbn varchar(20) null,
    name varchar(50) not null,
    author_name varchar(20) not null,
    publisher_id int not null,
    poster_url text null
);

alter table books
modify column publisher_id int null;

alter table books modify column author_name varchar(100) null;
alter table books modify column name varchar(200) null;


insert into books
select
    null,
    `형식(전자책)`,
    국제표준도서번호,
    도서명,
    저자명,
    p.publisher_id,
    표지주소
from
    book_flat bf
    left outer join publishers p on p.name = bf.출판사
order by 도서명;

truncate books;
-- ---------------


create table libraries(
    library_id int auto_increment primary key,
    name varchar(50) not null,
    site_url text null
);


insert into libraries
select distinct
    null,
    도서관명,
    `도서관홈페이지 주소`
from
    book_flat;

select
    *
from
    libraries;

-- -------------


create table publishers(
    publisher_id int auto_increment primary key,
    name varchar(50) not null
);

insert into publishers
select distinct
    null,
    출판사
from
    book_flat
where 출판사 is not null
order by
    출판사;

select
    *
from
    publishers;

-- null 확인
select
    count(*)
from
    book_flat
where 출판사 is null;


-- ------------------


create table categories(
    category_id int auto_increment primary key,
    name varchar(20) not null
);

insert into categories
select distinct
    null,
    카테고리
from
    book_flat
order by 카테고리;

select
    *
from
    categories;

-- ---------------------



create table registration_books(
    registration_id int auto_increment primary key,
    library_id int not null,
    book_id int not null,
    category_id int not null
);


# foreign key(library_id) references libraries(library_id),
#     foreign key(book_id) references books(book_id),
#     foreign key(category_id) references categories(category_id)

select
    count(*)
from
    book_flat;

-- 위아래 같아야함

truncate table registration_books;

insert into registration_books
select
    null,
    lb.library_id,
    bk.book_id,
    ct.category_id
from
    book_flat bf
    left outer join libraries lb on lb.name = bf.도서관명
    left outer join books bk on bk.name = bf.도서명
                                    and ifnull(bk.author_name, '') = ifnull(bf.저자명, '')
                                    and ifnull(bk.isbn, '') =ifnull(bf.국제표준도서번호, '')
                                    and bk.poster_url = bf.표지주소
    inner join categories ct on ct.name = bf.카테고리
order by
    bk.book_id;

select
    *
from
    registration_books;

select
    *
from
    registration_books rb
    left outer join books bk on bk.book_id = rb.book_id;



-- ---------------------------------------


/*
```sql
CREATE TABLE opened_courses (
    academic_year        INT          NOT NULL COMMENT '년도',
    semester_type        VARCHAR(10)  NOT NULL COMMENT '학기구분 (1, 2, 하계, 동계)',
    course_code          VARCHAR(20)  NOT NULL COMMENT '교과목코드',
    class_section        VARCHAR(10)  NOT NULL COMMENT '분반',
    department_name      VARCHAR(50)  NOT NULL COMMENT '개설학과코드(학과명)',
    class_group_code     CHAR(1)      NOT NULL COMMENT '반코드구분',
    class_type           INT          NOT NULL COMMENT '반구분',
    course_name          VARCHAR(100) NULL     COMMENT '교과목명',
    day_night_type       VARCHAR(10)  NOT NULL COMMENT '주야구분',
    curriculum_type      VARCHAR(20)  NULL     COMMENT '교과구분',
    subject_type_code    INT          NULL     COMMENT '과목구분',
    eval_type_code       INT          NULL     COMMENT '강의평가유형구분',
    student_type         VARCHAR(20)  NOT NULL COMMENT '학생구분',
    credits              INT          NULL     COMMENT '학점',
    theory_hours         INT          NULL     COMMENT '이론시간',
    practice_hours       INT          NULL     COMMENT '실습시간',
    total_course_hours   INT          NULL     COMMENT '총수업시수(학기당)',
    instructor_id        VARCHAR(20)  NULL     COMMENT '대표교원번호',
    enrolled_count       INT          NULL     COMMENT '수강신청인원수',
    timetable_exc_code   INT          NULL     COMMENT '시간표예외허용구분',
    cancel_yn            CHAR(1)      NOT NULL COMMENT '폐강여부(폐강Y 개강N)',
    basic_supp_yn        CHAR(1)      NOT NULL COMMENT '기초학습전공보충과목여부(기초학습Y)',
    team_teaching_yn     CHAR(1)      NOT NULL COMMENT '팀티칭 과목여부(YN)',
    block_lecture_yn     CHAR(1)      NOT NULL COMMENT '통계 강좌부문만 제외(YN) 집중(블럭)강의',
    practice_exc_yn      CHAR(1)      NOT NULL COMMENT '실습과목예외여부(YN)',
    unused_col           VARCHAR(10)  NULL     COMMENT '미사용컬럼',
    competency_yn        CHAR(1)      NOT NULL COMMENT '역량강의여부(YN)',
    teaching_method_code INT          NULL     COMMENT '수업방법',
    confirm_yn           CHAR(1)      NULL     COMMENT '강의확정여부',
    ncs_yn               CHAR(1)      NOT NULL COMMENT 'NCS강의여부',
    syllabus_exc_yn      CHAR(1)      NOT NULL COMMENT '강의계획서예외여부',
    rel_eval_exc_yn      CHAR(1)      NOT NULL COMMENT '상대평가비율예외여부',
    custom_track_yn      CHAR(1)      NOT NULL COMMENT '사회맞춤형강의 여부'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='경남도립남해대학 개설과목';





- 교과목
교과목코드 (PK)
교과목명


- 개설강좌
년도 (PK)
학기구분 (PK)
교과목코드 (PK, FK → 교과목)
개설학과코드 (PK)
교과구분
학점
이론시간
실습시간
총수업시수(학기당)


- 분반
년도 (PK)
학기구분 (PK)
교과목코드 (PK)
개설학과코드 (PK)
반코드구분 (PK)
대표교원번호




- 개설강좌 (메인)
년도
학기구분
교과목코드 (FK → 교과목)
개설학과코드 (FK → 학과)
반코드구분
대표교원번호
→ PK: 년도 + 학기구분 + 교과목코드 + 개설학과코드 + 반코드구분


- 교과목
교과목코드 (PK)
교과목명
교과구분
학점
이론시간
실습시간
총수업시수(학기당)


- 학과
개설학과코드 (PK)




*/

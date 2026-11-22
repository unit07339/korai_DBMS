-- subject_flat
use hanip_delivery09;

/*

정규화X (main)
년도, 학기구분, 대표교원번호

- 학과
개설학과코드
반코드

- 교과목
교과목코드
교과목명
교과구분
학점
이론시간
실습시간
총수업시수(학기당)

-------------------------------------------


- 개설강좌 (메인) (opened_courses)
년도
학기구분
교과목코드
개설학과코드
반코드구분
대표교원번호


- 교과목 (courses)
교과목코드
교과목명
교과구분
학점
이론시간
실습시간
총수업시수(학기당)


- 학과 (departments)
개설학과코드



*/

-- --------------------------------------------------- courses (연습)
create table courses2 (
    course_id int primary key auto_increment,
    course_code varchar(20) not null,
    course_name varchar(50) null,
    curriculum_type varchar(20) null,
    credits int null,
    theory_hours int null,
    practice_hours int null,
    total_course_hours int null
);

insert into courses2
select distinct
    null,
    교과목코드,
    교과목명,
    교과구분,
    학점,
    이론시간,
    실습시간,
    `총수업시수(학기당)`
from
    subject_flat;


-- ------------------ 아래 course 풀이 (subjects)
drop table subjects;

create table subjects (
    subject_id int auto_increment primary key,
    subject_code varchar(20) not null,
    name varchar(50) not null,
    major_id int not null
);


insert into subjects
select distinct
    null,
    교과목코드,
    ifnull(교과목명, '교과목명없음'),
    mj.major_id
from
    subject_flat sf
    left outer join majors mj on mj.major_name = sf.개설학과코드;






-- ---------------------------------------------------- majors
create table majors (
    major_id int primary key auto_increment,
    major_name varchar(50) not null
);

insert into majors
select distinct
    null,
    개설학과코드
from
    subject_flat;

-- ----------------------------------------------------- professors
truncate table professors;

create table professors (
    professor_id int primary key auto_increment,
    professor_code varchar(50) not null
);

insert into professors
select distinct
    null,
    대표교원번호
from
    subject_flat
where
    대표교원번호 is not null;


-- ----------------------------------------------------- opened_courses
drop table courses;
truncate table courses;

create table courses (
    course_id int primary key auto_increment,
    year varchar(4) not null,
    semester varchar(10) not null,
    major_id int not null,
    subject_id int not null,
    professor_id int null,
    class_div varchar(10) not null,
    credit int null,
    theory_hour int null,
    practice_hour int null
);

insert into courses
select
    null,
    년도,
    학기구분,
    mj.major_id,
    subject_id,
    professor_id,
    반코드구분,
    학점,
    이론시간,
    실습시간
from
    subject_flat sf
    left outer join majors mj on mj.major_name = sf.개설학과코드
    left outer join subjects sj on sj.subject_code = sf.교과목코드 and sj.major_id = mj.major_id
    left outer join professors pf on pf.professor_code = sf.대표교원번호;


select
    count(*)
from
    courses
where professor_id is null;

select
    *
from
    courses;

use test;

drop table leads;

create table leads
(
   first_name   varchar(50),
   last_name    varchar(50),
   title        varchar(50),
   company      varchar(50),
   email        varchar(50) not null,
   create_date  date not null
) engine=tokudb;

load data infile '/home/tcallaghan/Downloads/report1393864533503.csv' 
into table leads 
fields enclosed by '"' terminated by ',' 
ignore 1 lines
(first_name, last_name, title, company, email, @var1)
set create_date = STR_TO_DATE(@var1, '%m/%d/%Y');

update leads set email = lower(email) where email != lower(email);

create index idx_email on leads (email);

select l.email as email, 
       concat(l.last_name,', ',l.first_name) name, 
       l.title as title, 
       l.company as company, 
       l.create_date as create_date 
from leads l 
where l.email in (select email from leads group by email having count(*) > 1)
order by 1,2
into outfile '/home/tcallaghan/Downloads/dupeleads.txt';

-- new leads by week
select str_to_date(concat(date_format(l.create_date,'%Y-%U'),' Sunday'),'%Y-%U %W') year_week_sunday,
       count(*) new_raw_leads
from leads l 
group by str_to_date(concat(date_format(l.create_date,'%Y-%U'),' Sunday'),'%Y-%U %W');

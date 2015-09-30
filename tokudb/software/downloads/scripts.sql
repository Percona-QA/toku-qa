-- registrations by month
--   '%Y-%U'    = year/week
--   '%Y-%m-%d' = year/month/day
-- select date_format(created,'%Y-%m') as month, count(*) as registrations from registrations where date_format(created,'%Y') in ('2013','2012') group by date_format(created,'%Y-%m') order by 1;



-- get the data, info available in schema.sql

-- quick pre scrub for anonymous downloaders
update downloads_tsv dt
set dt.first_name = 'anonymous',
    dt.last_name = 'anonymous',
    dt.company_name = 'anonymous',
    dt.email_address = concat('anonymous',dt.ip_address)
where dt.email_address is null;

-- a little more scrubbing
update downloads_tsv dt
set dt.company_name = 'unknown'
where dt.company_name is null;

-- move the data over to the raw table
insert into downloads_raw (filename, ip_address, email_address, last_name, first_name, company_name, download_datetime)
select dt.filename, dt.ip_address, dt.email_address, dt.last_name, dt.first_name, dt.company_name, dt.download_datetime from downloads_tsv dt;

-- hide rows we don't care about
alter table downloads_raw add column (is_valid varchar(1) not null default 'Y');

-- pull out enterprise downloads
alter table downloads_raw add column (is_enterprise varchar(1) not null default 'N');

-- remove leading/trailing spaces
update downloads_raw
set filename = trim(filename)
where filename != trim(filename);

-- exclude certain files
update downloads_raw
set is_valid = 'N'
where (filename like '%.md5' or
       filename like '%.pdf' or
       filename like '%.zip' or
       filename like 'tokufractaltree%' or
       filename like 'tokumysql%' or
       filename like '%.mov' or
       filename like '%-src.%' or
       filename like '%download.php%' or
       trim(filename) = '') and
      (is_valid = 'Y');

-- get rid of older "source" tarballs
update downloads_raw
set is_valid = 'N'
where is_valid = 'Y' and
      ((filename like 'mysql%' or
        filename like 'mariadb%') and
       (filename not like '%x86_64%'));

-- exclude hackers
update downloads_raw
set is_valid = 'N'
where (filename like '%../..%') and
      (is_valid = 'Y');
      
-- exclude certain downloaders
update downloads_raw
set is_valid = 'N'
where (email_address like '%@tokutek.com' or
       email_address = 'tmcallaghan@gmail.com') and
      (is_valid = 'Y');

-- show all recognized files by file
select filename, count(*) from downloads_raw where is_valid = 'Y' group by filename order by 2 desc;

-- update enterprise downloads as such
update downloads_raw
set is_enterprise = 'Y'
where filename like '%-e-%' and
      is_valid = 'Y';

-- select * from downloads_raw where is_enterprise = 'Y';

-- show all remaining files by email_address
select email_address, count(*) from downloads_raw where is_valid = 'Y' group by email_address order by 2 desc;

-- show all unrecognized files
select filename, count(*)
from downloads_raw
where is_valid = 'Y' and
      (filename not like '%mariadb-5.1%' and
       filename not like '%mariadb-5.2%' and
       filename not like '%mariadb-5.5%' and
       filename not like '%mysql-5.1%' and
       filename not like '%mysql-5.5%' and
       filename not like 'tokumx%')
group by filename
order by 2 desc;       

-- invalidate unrecognized files
update downloads_raw
set is_valid = 'N'
where is_valid = 'Y' and
      (filename not like '%mariadb-5.1%' and
       filename not like '%mariadb-5.2%' and
       filename not like '%mariadb-5.5%' and
       filename not like '%mysql-5.1%' and
       filename not like '%mysql-5.5%' and
       filename not like 'tokumx%');


-- do the rollup by downloader, year-week
create table downloads_year_week_person (
  email_address varchar(50) not null,
  download_year_week varchar(7) not null)
engine=tokudb;  

insert into downloads_year_week_person
select distinct x.email_address email_address,
                date_format(x.download_datetime,'%Y-%U')
from downloads_raw x
where x.is_valid = 'Y';

select * from downloads_year_week_person;

-- total downloaders by week
select download_year_week, count(*) from downloads_year_week_person group by download_year_week order by 1;

-- named vs. anonymous downloaders by week
select v_1.dyw,
       v_named.qty named,
       v_anonymous.qty anonymous
from (select distinct download_year_week dyw from downloads_year_week_person) v_1
left join (select download_year_week as dyw, count(*) as qty from downloads_year_week_person where email_address not like 'anonymous%' group by download_year_week) v_named on v_named.dyw = v_1.dyw
left join (select download_year_week as dyw, count(*) as qty from downloads_year_week_person where email_address like 'anonymous%' group by download_year_week) v_anonymous on v_anonymous.dyw = v_1.dyw
order by 1;


-- do the rollup by version, downloader, year-month
create table downloads_rollup (
  download_version varchar(20) not null,
  email_address varchar(50) not null,
  download_year_month varchar(7) not null)
engine=tokudb;  

insert into downloads_rollup
select distinct 'tokumx' which,
                x.email_address email_address,
                date_format(x.download_datetime,'%Y-%m')
from downloads_raw x
where x.is_valid = 'Y' and
      x.filename like 'tokumx%'
union       
select distinct 'maria-5.1' which,
                x.email_address email_address,
                date_format(x.download_datetime,'%Y-%m')
from downloads_raw x
where x.is_valid = 'Y' and
      x.filename like '%mariadb-5.1%'
union       
select distinct 'maria-5.2' which,
                x.email_address email_address,
                date_format(x.download_datetime,'%Y-%m')
from downloads_raw x
where x.is_valid = 'Y' and
      x.filename like '%mariadb-5.2%'
union       
select distinct 'maria-5.5' which,
                x.email_address email_address,
                date_format(x.download_datetime,'%Y-%m')
from downloads_raw x
where x.is_valid = 'Y' and
      x.filename like '%mariadb-5.5%'
union       
select distinct 'mysql-5.1' which,
                x.email_address email_address,
                date_format(x.download_datetime,'%Y-%m')
from downloads_raw x
where x.is_valid = 'Y' and
      x.filename like '%mysql-5.1%'
union       
select distinct 'mysql-5.5' which,
                x.email_address email_address,
                date_format(x.download_datetime,'%Y-%m')
from downloads_raw x
where x.is_valid = 'Y' and
      x.filename like '%mysql-5.5%';

-- select * from downloads_rollup;

create table downloads_totals (
  download_version varchar(20) not null,
  download_count int not null,
  download_year_month varchar(7) not null)
engine=tokudb;  

insert into downloads_totals
select download_version,
       count(*),
       download_year_month
from downloads_rollup
group by download_version,
         download_year_month;
         
-- select * from downloads_totals order by download_count desc;


create table downloads_year_month (
  download_year_month varchar(7) not null)
engine=tokudb;  

insert into downloads_year_month
select distinct download_year_month
from downloads_totals;

-- select * from downloads_year_month order by 1;




-- this is what we've been building up to : by version
select x.download_year_month as download_year_month,
       maria51.dl as maria51_dl,
       maria52.dl as maria52_dl,
       maria55.dl as maria55_dl,
       mysql51.dl as mysql51_dl,
       mysql55.dl as mysql55_dl,
       tokumx.dl as tokumx_dl
from downloads_year_month x
left join
(select y.download_year_month,
        y.download_count dl
 from downloads_totals y
 where y.download_version = 'maria-5.1') maria51 on maria51.download_year_month = x.download_year_month
left join
(select y.download_year_month,
        y.download_count dl
 from downloads_totals y
 where y.download_version = 'maria-5.2') maria52 on maria52.download_year_month = x.download_year_month
left join
(select y.download_year_month,
        y.download_count dl
 from downloads_totals y
 where y.download_version = 'maria-5.5') maria55 on maria55.download_year_month = x.download_year_month
left join
(select y.download_year_month,
        y.download_count dl
 from downloads_totals y
 where y.download_version = 'mysql-5.1') mysql51 on mysql51.download_year_month = x.download_year_month
left join
(select y.download_year_month,
        y.download_count dl
 from downloads_totals y
 where y.download_version = 'mysql-5.5') mysql55 on mysql55.download_year_month = x.download_year_month
left join
(select y.download_year_month,
        y.download_count dl
 from downloads_totals y
 where y.download_version = 'tokumx') tokumx on tokumx.download_year_month = x.download_year_month
order by 1;


-- this is what we've been building up to : by version : just mysql 5.5 and tokumx
select x.download_year_month as download_year_month,
       maria55.dl as maria55_dl,
       mysql55.dl as mysql55_dl,
       tokumx.dl as tokumx_dl
from downloads_year_month x
left join
(select y.download_year_month,
        y.download_count dl
 from downloads_totals y
 where y.download_version = 'maria-5.5') maria55 on maria55.download_year_month = x.download_year_month
left join
(select y.download_year_month,
        y.download_count dl
 from downloads_totals y
 where y.download_version = 'mysql-5.5') mysql55 on mysql55.download_year_month = x.download_year_month
left join
(select y.download_year_month,
        y.download_count dl
 from downloads_totals y
 where y.download_version = 'tokumx') tokumx on tokumx.download_year_month = x.download_year_month
order by 1;


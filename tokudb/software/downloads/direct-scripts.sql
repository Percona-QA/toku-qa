-- ALL raw downloads by week
select count(*) downloads, 
       date_format(pd.create_date,'%Y-%U') year_week
from t_product_downloads pd 
group by date_format(pd.create_date,'%Y-%U') 
order by 2;


-- Binary downloads (.tar.gz, .tgz, .deb, .rpm) by week
select count(*) downloads, 
       date_format(pd.create_date,'%Y-%U') year_week
from t_product_downloads pd 
where (pd.filename like '%.tgz' or pd.filename like '%.tar.gz' or pd.filename like '%.deb' or pd.filename like '%.rpm') 
group by date_format(pd.create_date,'%Y-%U') 
order by 2;


-- Binary downloads (.tar.gz, .tgz, .deb, .rpm) by week, de-duped by IP address
select count(*) downloads, 
       date_format(x.create_date,'%Y-%U') year_week
from (select pd.remote_address remote_address,
             pd.create_date create_date
      from t_product_downloads pd 
      where (pd.filename like '%.tgz' or pd.filename like '%.tar.gz' or pd.filename like '%.deb' or pd.filename like '%.rpm') 
      group by pd.remote_address,
               date_format(pd.create_date,'%Y-%U')) x
group by date_format(x.create_date,'%Y-%U') 
order by 2;


-- Binary downloads (.tar.gz, .tgz, .deb, .rpm) by week, de-duped by IP address
--   Breakdown of anonymous vs. registered
--   Community Edition only (removing "-e-" named files)
select str_to_date(concat(date_format(x.create_date,'%Y-%U'),' Sunday'),'%Y-%U %W') year_week_sunday,
       count(*) downloads,
       sum(if(ifnull(x.user_id,-1)>0,1,0)) info,
       sum(if(ifnull(x.user_id,-1)<0,1,0)) no_info,
       (sum(if(ifnull(x.user_id,-1)<0,1,0)) / count(*) * 100) pct_anonymous
from (select pd.remote_address remote_address,
             pd.create_date create_date,
             pd.user_id user_id
      from t_product_downloads pd 
      where (pd.filename like '%.tgz' or pd.filename like '%.tar.gz' or pd.filename like '%.deb' or pd.filename like '%.rpm') and
            pd.filename not like '%-e-%'
      group by pd.remote_address,
               pd.user_id,
               date_format(pd.create_date,'%Y-%U')) x
group by date_format(x.create_date,'%Y-%U') 
order by 1
into outfile '/tmp/anonymous-vs-registered.txt';


-- The big-bad query, show everything
select str_to_date(concat(x.year_week,' Sunday'),'%Y-%U %W') year_week_sunday,
       x.downloads deduped_binary_downloads,
       y.downloads binary_downloads,
       z.downloads raw_downloads
from (select count(*) downloads, 
             date_format(v1.create_date,'%Y-%U') year_week
      from (select pd.remote_address remote_address,
                   pd.create_date create_date
            from t_product_downloads pd 
            where (pd.filename like '%.tgz' or pd.filename like '%.tar.gz' or pd.filename like '%.deb' or pd.filename like '%.rpm') 
            group by pd.remote_address,
                     date_format(pd.create_date,'%Y-%U')) v1
      group by date_format(v1.create_date,'%Y-%U')) x,
     (select count(*) downloads, 
             date_format(pd.create_date,'%Y-%U') year_week
      from t_product_downloads pd 
      where (pd.filename like '%.tgz' or pd.filename like '%.tar.gz' or pd.filename like '%.deb' or pd.filename like '%.rpm') 
      group by date_format(pd.create_date,'%Y-%U')) y,
     (select count(*) downloads, 
             date_format(pd.create_date,'%Y-%U') year_week
      from t_product_downloads pd 
      group by date_format(pd.create_date,'%Y-%U')) z
where y.year_week = x.year_week and
      z.year_week = x.year_week
order by 1
into outfile '/tmp/download-breakdown.txt';

-- DB vs. MX
-- Binary downloads (.tar.gz, .tgz, .deb, .rpm) by week, de-duped by IP address
select str_to_date(concat(x.year_week,' Sunday'),'%Y-%U %W') year_week_sunday,
       sum(tokudb_dl) tokudb_downloads, 
       sum(tokumx_dl) tokumx_downloads
from (select pd.remote_address remote_address,
             date_format(pd.create_date,'%Y-%U') year_week,
             1 tokudb_dl,
             0 tokumx_dl
      from t_product_downloads pd 
      where (pd.filename like '%.tgz' or pd.filename like '%.tar.gz' or pd.filename like '%.deb' or pd.filename like '%.rpm') and
            lower(pd.filename) like '%tokudb%'
      group by pd.remote_address,
               date_format(pd.create_date,'%Y-%U')
      union
      select pd.remote_address remote_address,
             date_format(pd.create_date,'%Y-%U') year_week,
             0 tokudb_dl,
             1 tokumx_dl
      from t_product_downloads pd 
      where (pd.filename like '%.tgz' or pd.filename like '%.tar.gz' or pd.filename like '%.deb' or pd.filename like '%.rpm') and
            lower(pd.filename) like '%tokumx%'
      group by pd.remote_address,
               date_format(pd.create_date,'%Y-%U')) x
group by x.year_week
order by 1
into outfile '/tmp/db-vs-mx.txt';

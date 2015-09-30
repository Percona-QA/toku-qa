-- Package downloads : weekly
select str_to_date(concat(date_format(x.create_date,'%Y-%U'),' Sunday'),'%Y-%U %W') year_week_sunday,
       count(*) downloads
from (select pd.download_ip remote_address,
             pd.download_datetime create_date
      from package_downloads pd 
      group by pd.download_ip,
               date_format(pd.download_datetime,'%Y-%U')) x
group by date_format(x.create_date,'%Y-%U') 
order by 1
into outfile '~/mystuff/personal/tokutek/software/s3-downloads/results/package-downloads-weekly.txt';


-- Package downloads : monthly
select date_format(x.create_date,'%Y-%m') year_monthx,
       count(*) downloads
from (select pd.download_ip remote_address,
             pd.download_datetime create_date
      from package_downloads pd 
      group by pd.download_ip,
               date_format(pd.download_datetime,'%Y-%m')) x
group by date_format(x.create_date,'%Y-%m') 
order by 1
into outfile '~/mystuff/personal/tokutek/software/s3-downloads/results/package-downloads-monthly.txt';


-- Package downloads : alltime by month
select v_ym.ym year_monthx,
       count(distinct pd.download_ip) downloads
from package_downloads pd,
     (select '2014-03' ym
      union
      select '2014-04' ym
      union
      select '2014-05' ym
      union
      select '2014-06' ym
      union
      select '2014-07' ym
      union
      select '2014-08' ym
      union
      select '2014-09' ym
      union
      select '2014-10' ym
      union
      select '2014-11' ym) v_ym
where date_format(pd.download_datetime,'%Y-%m') <= v_ym.ym
group by v_ym.ym
order by 1
into outfile '~/mystuff/personal/tokutek/software/s3-downloads/results/package-downloads-alltime.txt';

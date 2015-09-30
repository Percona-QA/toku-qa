use test;

drop table if exists package_downloads;

create table package_downloads (
  pk bigint not null auto_increment primary key,
  download_datetime datetime not null,
  download_ip varchar(20) not null,
  download_filename varchar(200) not null
) engine=tokudb;

drop table if exists sbtest1;

CREATE TABLE sbtest1 (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  k int(10) unsigned NOT NULL DEFAULT '0',
  c char(120) NOT NULL DEFAULT '',
  pad char(60) NOT NULL DEFAULT '',
  PRIMARY KEY (id),
  KEY k (k)
) engine=tokudb;

CREATE TABLE sbvalid (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  table_name varchar(30) not null,
  table_id int(10) unsigned not null,
  c1 int not null,
  PRIMARY KEY (id)
) engine=tokudb;
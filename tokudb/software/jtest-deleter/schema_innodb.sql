use test;

drop table if exists t1;

CREATE TABLE t1 (
  c1 int(10) unsigned NOT NULL AUTO_INCREMENT,
  c2 int(10) unsigned NOT NULL,
  c3 int(10) unsigned NOT NULL,
  c4 char(120) NOT NULL,
  PRIMARY KEY (c1),
  KEY c2 (c2),
  KEY c3 (c3)
) engine=innodb;


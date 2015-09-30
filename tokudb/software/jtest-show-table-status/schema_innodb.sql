drop table if exists t1;

CREATE TABLE t1 (
  c1 int(10) unsigned NOT NULL AUTO_INCREMENT,
  c2 int(10) unsigned NOT NULL,
  c3 int(10) unsigned NOT NULL,
  c4 char(120) NOT NULL,
  PRIMARY KEY (c1),
  CLUSTERING KEY c2 (c2),
  KEY c3 (c3),
  KEY c4 (c4),
  KEY c2_c3 (c2,c3)
) engine=innodb;

drop table if exists t2;

CREATE TABLE t2 (
  c1 int(10) unsigned NOT NULL AUTO_INCREMENT,
  c2 int(10) unsigned NOT NULL,
  c3 int(10) unsigned NOT NULL,
  c4 char(120) NOT NULL,
  PRIMARY KEY (c1),
  CLUSTERING KEY c2 (c2),
  KEY c3 (c3),
  KEY c4 (c4),
  KEY c2_c3 (c2,c3)
) engine=innodb;

drop table if exists t3;

CREATE TABLE t3 (
  c1 int(10) unsigned NOT NULL AUTO_INCREMENT,
  c2 int(10) unsigned NOT NULL,
  c3 int(10) unsigned NOT NULL,
  c4 char(120) NOT NULL,
  PRIMARY KEY (c1),
  CLUSTERING KEY c2 (c2),
  KEY c3 (c3),
  KEY c4 (c4),
  KEY c2_c3 (c2,c3)
) engine=innodb;

drop table if exists t4;

CREATE TABLE t4 (
  c1 int(10) unsigned NOT NULL AUTO_INCREMENT,
  c2 int(10) unsigned NOT NULL,
  c3 int(10) unsigned NOT NULL,
  c4 char(120) NOT NULL,
  PRIMARY KEY (c1),
  CLUSTERING KEY c2 (c2),
  KEY c3 (c3),
  KEY c4 (c4),
  KEY c2_c3 (c2,c3)
) engine=innodb;

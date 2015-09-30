drop table if exists sbtest1;

CREATE TABLE sbtest1 (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  k int(10) unsigned NOT NULL DEFAULT '0',
  c char(120) NOT NULL DEFAULT '',
  pad char(60) NOT NULL DEFAULT '',
  PRIMARY KEY (id)
) engine=tokudb;

drop table if exists sbtest2;
create table sbtest2 like sbtest1;
drop table if exists sbtest3;
create table sbtest3 like sbtest1;
drop table if exists sbtest4;
create table sbtest4 like sbtest1;
drop table if exists sbtest5;
create table sbtest5 like sbtest1;
drop table if exists sbtest6;
create table sbtest6 like sbtest1;
drop table if exists sbtest7;
create table sbtest7 like sbtest1;
drop table if exists sbtest8;
create table sbtest8 like sbtest1;
drop table if exists sbtest9;
create table sbtest9 like sbtest1;
drop table if exists sbtest10;
create table sbtest10 like sbtest1;
drop table if exists sbtest11;
create table sbtest11 like sbtest1;
drop table if exists sbtest12;
create table sbtest12 like sbtest1;
drop table if exists sbtest13;
create table sbtest13 like sbtest1;
drop table if exists sbtest14;
create table sbtest14 like sbtest1;
drop table if exists sbtest15;
create table sbtest15 like sbtest1;
drop table if exists sbtest16;
create table sbtest16 like sbtest1;

drop table if exists tmc_plan_test;

create table tmc_plan_test (
  c_pk int not null auto_increment,
  c_1 int not null,  
  c_10 int not null,  
  c_100 int not null,  
  c_1000 int not null,  
  c_10000 int not null,  
  c_100000 int not null,  
  c_1000000 int not null,  
  c_10000000 int not null,  
  c_100000000 int not null,  
  c_big_varchar varchar(256) not null,
  primary key (c_pk),
  key c_1_key (c_1),
  key c_10_key (c_10),
  key c_100_key (c_100),
  key c_1000_key (c_1000),
  key c_10000_key (c_10000),
  key c_100000_key (c_100000),
  key c_1000000_key (c_1000000),
  key c_10000000_key (c_10000000),
  key c_100000000_key (c_100000000)
) engine=tokudb;

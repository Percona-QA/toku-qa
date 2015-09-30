drop table if exists purchases_index;

create table purchases_index (
  transactionid int not null auto_increment,
  dateandtime datetime,
  cashregisterid int not null,
  customerid int not null,
  productid int not null,
  price float not null,
  primary key (transactionid)
) engine=innodb;

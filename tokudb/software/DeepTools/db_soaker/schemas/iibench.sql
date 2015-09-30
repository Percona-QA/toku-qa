create table if not exists purchases_index (
  transactionid int not null auto_increment,
  dateandtime datetime,
  cashregisterid int not null,
  customerid int not null,
  productid int not null,
  price float not null,
  primary key (transactionid),
  index marketsegment (price, customerid),
  index registersegment (cashregisterid, price, customerid),
  index pdc (price, dateandtime, customerid)
);

alter table purchases_index add key marketsegment (price, customerid);
alter table purchases_index add key registersegment (cashregisterid, price, customerid);
alter table purchases_index add key pdc (price, dateandtime, customerid);

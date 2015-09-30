use sbtest;
begin;
    update sbtest1 set c='foo' where id=5;
    update sbtest1 set k=k+1 where id=6;
    select sleep(5);
    update sbtest1 set c1=c1+24 where id=7;
    insert into sbvalid (table_name, table_id, c1) values ('sbtest1', 7, 24);
commit;    
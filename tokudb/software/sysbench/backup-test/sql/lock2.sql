use sbtest;
begin;
    update sbtest1 set c='foo' where id=20;
    update sbtest1 set k=k+1 where id=7;
    select sleep(5);
    update sbtest1 set c1=c1+24 where id=6;
    insert into sbvalid (table_name, table_id, c1) values ('sbtest1', 6, 24);
commit;    
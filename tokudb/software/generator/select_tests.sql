use test;

-- c_1_key = 1, c_10000_key = 10000
--explain select * from tmc_plan_test t where t.c_1 = 50 and t.c_10000 = 50;

-- c_1_key = 51, c_10000_key = 30000
-- seems to use c_1_key because it was built first
explain select * from tmc_plan_test t where (t.c_1 >= 50 and t.c_1 <= 100) and (t.c_10000 >= 49 and t.c_10000 <= 51);

alter table tmc_plan_test drop key c_1_key;

create index c_1_key on tmc_plan_test (c_1);

-- now uses c_10000_key
explain select * from tmc_plan_test t where (t.c_1 >= 50 and t.c_1 <= 100) and (t.c_10000 >= 49 and t.c_10000 <= 51);

-- Purpose: Perform a user defined number of point queries using the secondary key that requires
--          a column not present in the secondary key
--
-- Input parameters
--   oltp-point-selects    : the number of point queries to perform for each "transaction"

pathtest = string.match(test, "(.*/)") or ""

dofile(pathtest .. "common.lua")

function thread_init(thread_id)
   set_vars()

end

function event(thread_id)
   local table_name
   table_name = "sbtest".. sb_rand_uniform(1, oltp_tables_count)

   for i=1, oltp_point_selects do
      rs = db_query("SELECT c FROM ".. table_name .." WHERE k=" .. sb_rand(1, oltp_table_size))
   end
end

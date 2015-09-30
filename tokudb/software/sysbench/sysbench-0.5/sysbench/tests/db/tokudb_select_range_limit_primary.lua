-- Purpose: Perform a user defined number of range/limit queries using the primary key
--
-- Input parameters
--   oltp-point_selects    : the number of range queries to perform for each "transaction"
--   oltp-range-size       : the number of rows for the between
--   oltp-simple-ranges    : number of rows for LIMIT

pathtest = string.match(test, "(.*/)") or ""

dofile(pathtest .. "common.lua")

function thread_init(thread_id)
   set_vars()
end

function event(thread_id)
   local rs
   local i
   local table_name
   local range_start

   table_name = "sbtest".. sb_rand_uniform(1, oltp_tables_count)

   for i=1, oltp_point_selects do
      range_start = sb_rand(1, oltp_table_size)
      rs = db_query("SELECT c FROM ".. table_name .." WHERE id BETWEEN " .. range_start .. " AND " .. range_start .. "+" .. oltp_range_size - 1 .. " ORDER BY id LIMIT " .. oltp_simple_ranges)
   end
end


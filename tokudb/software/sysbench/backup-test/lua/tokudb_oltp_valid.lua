pathtest = string.match(test, "(.*/)") or ""

dofile(pathtest .. "common.lua")

function thread_init(thread_id)
   set_vars()

   if (db_driver == "mysql" and mysql_table_engine == "myisam") then
      begin_query = "LOCK TABLES sbtest WRITE"
      commit_query = "UNLOCK TABLES"
   else
      begin_query = "BEGIN"
      commit_query = "COMMIT"
   end

end

function event(thread_id)
   local rs
   local i
   local table_name
   local range_start
   local c_val
   local pad_val
   local query

   table_name = "sbtest".. sb_rand_uniform(1, oltp_tables_count)
   db_query(begin_query)

   -- do some point queries to keep busy
   for i=1, oltp_point_selects do
      rs = db_query("SELECT c FROM ".. table_name .." WHERE id=" .. sb_rand(1, oltp_table_size))
   end

   -- do some sum queries to keep busy
   for i=1, oltp_sum_ranges do
      range_start = sb_rand(1, oltp_table_size)
      rs = db_query("SELECT SUM(K) FROM ".. table_name .." WHERE id BETWEEN " .. range_start .. " AND " .. range_start .. "+" .. oltp_range_size - 1)
   end
   
   if not oltp_read_only then
       -- just do a single update, we DO NOT want any deadlocks
       -- sbvalid allows us to keep track of what the running totals are by table
       c_val = sb_rand_str("###########-###########-###########-###########-###########-###########-###########-###########-###########-###########")
       inc_c1 = sb_rand_uniform(1, 32)
       inc_id = sb_rand(1, oltp_table_size)
       
       query1 = "UPDATE " .. table_name .. " SET k=k+1, c='" .. c_val .. "', c1=c1+ " .. inc_c1 .. " where id=" .. inc_id
       query2 = "insert into sbvalid (table_name,table_id,c1) values ('" .. table_name .. "'," .. inc_id .. "," .. inc_c1 .. ")"

       -- print(query1)
       
       rs=db_query(query1)
       if rs then
         -- based on the code, I'm not sure that you'd ever end up in here
         print(query1)
       end
       
       rs=db_query(query2)
       if rs then
         -- based on the code, I'm not sure that you'd ever end up in here
         print(query2)
       end
   end -- oltp_read_only

   db_query(commit_query)
   
end


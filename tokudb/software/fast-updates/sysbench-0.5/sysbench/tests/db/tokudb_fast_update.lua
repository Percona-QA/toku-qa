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
   local table_name

   table_name = "sbtest".. sb_rand_uniform(1, oltp_tables_count)
   
   db_query(begin_query)

   for i=1, oltp_non_index_updates do
      rs = db_query("UPDATE " .. table_name .. " SET k=k+1 WHERE id=" .. sb_rand(1, oltp_table_size))
   end

   db_query(commit_query)
end


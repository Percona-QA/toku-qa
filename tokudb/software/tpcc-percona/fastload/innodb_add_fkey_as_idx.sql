SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;


create index fkey_district_1 on district (d_w_id);
create index fkey_customer_1 on customer (c_w_id,c_d_id);
create index fkey_history_1 on history (h_c_w_id,h_c_d_id,h_c_id);
create index fkey_history_2 on history (h_w_id,h_d_id);
create index fkey_new_orders_1 on new_orders (no_w_id,no_d_id,no_o_id);
create index fkey_orders_1 on orders (o_w_id,o_d_id,o_c_id);
create index fkey_order_line_1 on order_line (ol_w_id,ol_d_id,ol_o_id);
create index fkey_order_line_2 on order_line (ol_supply_w_id,ol_i_id);
create index fkey_stock_1 on stock (s_w_id);
create index fkey_stock_2 on stock (s_i_id);


SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

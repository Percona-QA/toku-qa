package org.opensharding.tpcc;

import java.sql.Statement;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.Calendar;
import java.util.Date;

public class Load implements TpccConstants {
	private static boolean optionDebug = false;

	/*
	 * ==================================================================+ |
	 * ROUTINE NAME |      LoadItems | DESCRIPTION |      Loads the Item table |
	 * ARGUMENTS |      none
	 * +==================================================================
	 */
	public static void loadItems(Connection conn, int shardCount, boolean option_debug)
	{
		optionDebug = option_debug;
		int i_id = 0;
		int i_im_id = 0;
	    String i_name = null;
		float i_price = 0;
		String i_data = null;

		int idatasize = 0;
		int[] orig = new int[MAXITEMS+1];
		int pos = 0;
		int i = 0;
	    int retried = 0;
		Statement stmt;
		try {
			stmt = conn.createStatement();
		} catch (SQLException e) {
			throw new RuntimeException("Items statement creation error", e);
		}
		

		/* EXEC SQL WHENEVER SQLERROR GOTO sqlerr; */

		System.out.printf("Loading Item \n");

		for (i = 0; i < MAXITEMS / 10; i++)
			orig[i] = 0;
		for (i = 0; i < MAXITEMS / 10; i++) {
			do {
				pos = Util.randomNumber(0, MAXITEMS);
			} while (orig[pos] != 0); 
			orig[pos] = 1;
		}
		
	retry:
	    if (retried >= 1)
	        System.out.printf("Retrying ...\n");
	    retried = 1;
		for (i_id = 1; i_id <= MAXITEMS; i_id++) {

			/* Generate Item Data */
			i_im_id = Util.randomNumber(1, 10000);

	       i_name =  Util.makeAlphaString(14, 24);
	        if(i_name == null){
	        	System.out.println("I_name null.");
	        	System.exit(1);
	        }

			i_price = (float) ((int)( Util.randomNumber(100, 10000) ) / 100.0);

			i_data =  Util.makeAlphaString(26, 50);
			if (orig[i_id] != 0) {
				
				pos = Util.randomNumber(0, i_data.length() - 8);
				char[] tempData = new char[i_data.length() + 8];
				tempData[pos] = 'o';
				tempData[pos + 1] = 'r';
				tempData[pos + 2] = 'i';
				tempData[pos + 3] = 'g';
				tempData[pos + 4] = 'i';
				tempData[pos + 5] = 'n';
				tempData[pos + 6] = 'a';
				tempData[pos + 7] = 'l';
				i_data = tempData.toString();
			}
			
			/*System.out.printf("IID = %d, Name= %s, Price = %f\n",
				       i_id, i_name, i_price); *///DEBUG

			/* EXEC SQL INSERT INTO
			                item
			                values(:i_id,:i_im_id,:i_name,:i_price,:i_data); */
			try {
//				if (shardCount > 0){
//					stmt.addBatch("/*DBS_HINT: dbs_shard_action=global_write*/ INSERT INTO item (i_id, i_im_id, i_name, i_price, i_data) values(" + i_id + "," + i_im_id + "," 
//							+ "'" + i_name +"'" + "," + i_price + "," + "'"+i_data+"'" + ")");
//				}else{
//					stmt.addBatch("INSERT INTO item (i_id, i_im_id, i_name, i_price, i_data) values(" + i_id + "," + i_im_id + "," 
//							+ "'" + i_name +"'" + "," + i_price + "," + "'"+i_data+"'" + ")");
//				}
				
				stmt.addBatch("INSERT INTO item (i_id, i_im_id, i_name, i_price, i_data) values(" + i_id + "," + i_im_id + "," 
						+ "'" + i_name +"'" + "," + i_price + "," + "'"+i_data+"'" + ")");
			} catch (SQLException e) {
				throw new RuntimeException("Item insert error", e);
			}

			if ( (i_id % 100) == 0) {
				System.out.printf(".");
				if ( (i_id % 5000) == 0)
					System.out.printf(" %d\n", i_id);
			}
		}

		/* EXEC SQL COMMIT WORK; */
		
		try {
			stmt.executeBatch();
			stmt.close();
		} catch (SQLException e) {
			throw new RuntimeException("Item batch error", e);
		}
		
		System.out.printf("Item Done. \n");
		return;
	}
	
	/*
	 * ==================================================================+ |
	 * ROUTINE NAME |      LoadWare | DESCRIPTION |      Loads the Warehouse
	 * table |      Loads Stock, District as Warehouses are created | ARGUMENTS |
	 * none +==================================================================
	 */
	public static void loadWare(Connection conn, int shardCount, int min_ware, int max_ware, boolean option_debug, int shardId){

		int w_id;
	    String w_name = null;
	    String w_street_1 = null;
	    String w_street_2 = null;
	    String w_city = null;
	    String w_state = null;
	    String w_zip = null;
		double w_tax = 0;
		double w_ytd = 0;

		int tmp = 0;
	    boolean retried = false;
	    int currentShard = 0;
	    Statement stmt;
	    

    	try {
			stmt = conn.createStatement();
		} catch (SQLException e) {
			throw new RuntimeException("Creation of statement failed", e);
		}

		/* EXEC SQL WHENEVER SQLERROR GOTO sqlerr; */

		System.out.printf("Loading Warehouse \n");
	    w_id = (int) min_ware;
	
	   
	    retry:
		    if (retried )
		        System.out.printf("Retrying ....\n");
		    retried = true;
			for (w_id = 0; w_id < max_ware; w_id++) {
				
				if(shardCount > 0){
					currentShard = (w_id  % shardCount);
					if (currentShard == 0){
						currentShard = shardCount;
					}
				}
				
				if(shardId == currentShard){
					System.out.println("Current Shard: " + currentShard);
					/* Generate Warehouse Data */
		
			        w_name = Util.makeAlphaString(6, 10);
					w_street_1 =Util.makeAlphaString(10, 20);
					w_street_2 = Util.makeAlphaString(10, 20);
					w_city = Util.makeAlphaString(10, 20);
					w_state = Util.makeAlphaString(2, 2);
					w_zip = Util.makeAlphaString(9, 9);
		
					w_tax = ( (double) Util.randomNumber(10, 20) / 100.0);
					w_ytd =  3000000.00;
		
					//if (option_debug)
						System.out.printf("WID = %d, Name= %s, Tax = %f\n",
						       w_id, w_name, w_tax);
					/*EXEC SQL INSERT INTO
					                warehouse
					                values(:w_id,:w_name,
							       :w_street_1,:w_street_2,:w_city,:w_state,
							       :w_zip,:w_tax,:w_ytd);*/
					//   /*DBS_HINT: dbs_shard_action=shard_read, dbs_pshard=2 */
					try {
						if (shardCount > 0){
							stmt.addBatch("/*DBS_HINT: dbs_shard_action=shard_write, dbs_pshard="
									   + currentShard + "*/"
									   + "INSERT INTO warehouse (w_id, w_name, w_street_1, w_street_2, w_city, w_state, w_zip, w_tax, w_ytd) values("
								       + w_id + "," 
								       + "'" + w_name + "'" + "," 
								       + "'" + w_street_1 + "'" + "," 
								       + "'" + w_street_2 + "'" + ","
								       + "'" + w_city + "'" + ","
								       + "'" + w_state + "'" + ","
								       + "'"  + w_zip + "'" + ","
								       + w_tax + ","
								       + w_ytd + ")");
						}else{
							stmt.addBatch("INSERT INTO warehouse (w_id, w_name, w_street_1, w_street_2, w_city, w_state, w_zip, w_tax, w_ytd) values("
								       + w_id + "," 
								       + "'" + w_name + "'" + "," 
								       + "'" + w_street_1 + "'" + "," 
								       + "'" + w_street_2 + "'" + ","
								       + "'" + w_city + "'" + ","
								       + "'" + w_state + "'" + ","
								       + "'"  + w_zip + "'" + ","
								       + w_tax + ","
								       + w_ytd + ")");
						}
					
					} catch (SQLException e) {
						throw new RuntimeException("Warehouse insert error", e);
					}
				
					/** Make Rows associated with Warehouse **/
					stock(w_id, conn, shardCount, currentShard);
					district(w_id, conn, shardCount, currentShard);
				}
				
				

		}
		/* EXEC SQL COMMIT WORK; */
		//TODO: Throw an exception here
		
			try {
				stmt.executeBatch();
				stmt.close();
			} catch (SQLException e) {
				throw new RuntimeException("Warehouse batch error", e);
			}
			
		
		return;

	}
	
	/*
	 * ==================================================================+ |
	 * ROUTINE NAME |      LoadCust | DESCRIPTION |      Loads the Customer Table
	 * | ARGUMENTS |      none
	 * +==================================================================
	 */
	public static void loadCust(Connection conn, int shardCount, int min_ware, int max_ware, int shardId){

		int w_id = 0;
		int d_id = 0;
		
		/* EXEC SQL WHENEVER SQLERROR GOTO sqlerr; */

		for (; w_id < max_ware; w_id++)
			for (d_id = 1; d_id <= DIST_PER_WARE; d_id++)
				customer(d_id, w_id, conn, shardCount, shardId);

		return;
	}
	
	/*
	 * ==================================================================+ |
	 * ROUTINE NAME |      LoadOrd | DESCRIPTION |      Loads the Orders and
	 * Order_Line Tables | ARGUMENTS |      none
	 * +==================================================================
	 */
	public static void loadOrd(Connection conn, int shardCount, int min_ware, int max_ware, int shardId){

		int w_id = 0;
		float w_tax = 0;
		int d_id = 0;
		float d_tax = 0;

		/* EXEC SQL WHENEVER SQLERROR GOTO sqlerr;*/

		for (; w_id < max_ware; w_id++)
			for (d_id = 1; d_id <= DIST_PER_WARE; d_id++)
				orders(d_id, w_id, conn, shardCount, shardId);

		return;
	}
	
	/*
	 * ==================================================================+ |
	 * ROUTINE NAME |      Stock | DESCRIPTION |      Loads the Stock table |
	 * ARGUMENTS |      w_id - warehouse id
	 * +==================================================================
	 */
	public static boolean stock(int w_id, Connection conn, int shardCount, int currentShard){
		int s_i_id = 0;
		int s_w_id = 0;
		int s_quantity = 0;

		String s_dist_01 = null;
		String s_dist_02 = null;
		String s_dist_03 = null;
		String s_dist_04 = null;
		String s_dist_05 = null;
		String s_dist_06 = null;
		String s_dist_07 = null;
		String s_dist_08 = null;
		String s_dist_09 = null;
		String s_dist_10 = null;
		String s_data = null;

		int sdatasize = 0;
		int[] orig = new int[MAXITEMS+1];
		int pos = 0;
		int i = 0;
	    boolean error = false;
	    Statement stmt;
		try {
			stmt = conn.createStatement();
		} catch (SQLException e) {
			throw new RuntimeException("Stament creation error", e);
		}
	    
		/* EXEC SQL WHENEVER SQLERROR GOTO sqlerr;*/
		System.out.printf("Loading Stock Wid=%d\n", w_id);
		s_w_id = w_id;

		for (i = 0; i < MAXITEMS / 10; i++)
			orig[i] = 0;
		for (i = 0; i < MAXITEMS / 10; i++) {
			do {
				pos = Util.randomNumber(0, MAXITEMS);
			} while (orig[pos] != 0); //TODO: FIx later
			orig[pos] = 1;
		}

	retry:
		for (s_i_id = 1; s_i_id <= MAXITEMS; s_i_id++) {

			/* Generate Stock Data */
			s_quantity = Util.randomNumber(10, 100);

			s_dist_01 = Util.makeAlphaString(24, 24);
			s_dist_02 = Util.makeAlphaString(24, 24);
			s_dist_03 = Util.makeAlphaString(24, 24);
			s_dist_04 = Util.makeAlphaString(24, 24);
			s_dist_05 = Util.makeAlphaString(24, 24);
			s_dist_06 = Util.makeAlphaString(24, 24);
			s_dist_07 = Util.makeAlphaString(24, 24);
			s_dist_08 = Util.makeAlphaString(24, 24);
			s_dist_09 = Util.makeAlphaString(24, 24);
			s_dist_10 = Util.makeAlphaString(24, 24);

			
			s_data = Util.makeAlphaString(26, 50);
			sdatasize = s_data.length();
			if (orig[s_i_id] != 0) {//TODO:Change this later
				pos = Util.randomNumber(0, sdatasize - 8);
				s_data = "original";
			}
			/*EXEC SQL INSERT INTO
			                stock
			                values(:s_i_id,:s_w_id,:s_quantity,
					       :s_dist_01,:s_dist_02,:s_dist_03,:s_dist_04,:s_dist_05,
					       :s_dist_06,:s_dist_07,:s_dist_08,:s_dist_09,:s_dist_10,
					       0, 0, 0,:s_data);*/
			try {
				if(shardCount > 0){
					stmt.addBatch("/*DBS_HINT: dbs_shard_action=shard_write, dbs_pshard="
							  + currentShard + "*/"
							  + "INSERT INTO stock (s_i_id, s_w_id, s_quantity, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10, s_ytd, s_order_cnt, s_remote_cnt, s_data) values("
							  + s_i_id + ","
							  + s_w_id + ","
							  + s_quantity + ","
							  + "'" + s_dist_01 + "'" + ","
							  + "'" + s_dist_02 + "'" + ","
							  + "'" + s_dist_03 + "'" + ","
							  + "'" + s_dist_04 + "'" + ","
							  + "'" + s_dist_05 + "'" + ","
							  + "'" + s_dist_06 + "'" + ","
							  + "'" + s_dist_07 + "'" + ","
							  + "'" + s_dist_08 + "'" + ","
							  + "'" + s_dist_09 + "'" + ","
							  + "'" + s_dist_10 + "'" + ","
							  + 0 + ","
							  + 0 + ","
							  + 0 + ","
							  + "'" + s_data + "'" + ")");
				}else{
					stmt.addBatch("INSERT INTO stock (s_i_id, s_w_id, s_quantity, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10, s_ytd, s_order_cnt, s_remote_cnt, s_data) values("
							  + s_i_id + ","
							  + s_w_id + ","
							  + s_quantity + ","
							  + "'" + s_dist_01 + "'" + ","
							  + "'" + s_dist_02 + "'" + ","
							  + "'" + s_dist_03 + "'" + ","
							  + "'" + s_dist_04 + "'" + ","
							  + "'" + s_dist_05 + "'" + ","
							  + "'" + s_dist_06 + "'" + ","
							  + "'" + s_dist_07 + "'" + ","
							  + "'" + s_dist_08 + "'" + ","
							  + "'" + s_dist_09 + "'" + ","
							  + "'" + s_dist_10 + "'" + ","
							  + 0 + ","
							  + 0 + ","
							  + 0 + ","
							  + "'" + s_data + "'" + ")");
				}
				
			} catch (SQLException e) {
				throw new RuntimeException("Stock insert error", e);
			}

			if (optionDebug)
				System.out.printf("SID = %d, WID = %d, Quan = %d\n",
				       s_i_id, s_w_id, s_quantity);

			if ((s_i_id % 100) == 0) {
				System.out.printf(".");
				if ((s_i_id % 5000) == 0)
					System.out.printf(" %d\n", s_i_id);
			}
		}
		
		try {
			stmt.executeBatch();
			stmt.close();
		} catch (SQLException e) {
			throw new RuntimeException("Stock batch error", e);
		} 
		

		System.out.printf(" Stock Done.\n");
		return error;

	}
	
	/*
	 * ==================================================================+ |
	 * ROUTINE NAME |      District | DESCRIPTION |      Loads the District table
	 * | ARGUMENTS |      w_id - warehouse id
	 * +==================================================================
	 */
	public static boolean district(int w_id, Connection conn, int shardCount, int currentShard) {
		int d_id = 0;
		int d_w_id = 0;
		String d_name = null;
		String d_street_1 = null;
		String d_street_2 = null;
		String d_city = null;
		String d_state = null;
		String d_zip = null;;
		float d_tax = 0;
		float d_ytd = 0;
		int d_next_o_id = 0;
	    boolean error = false;
	    Statement stmt;
		try {
			stmt = conn.createStatement();
		} catch (SQLException e1) {
			throw new RuntimeException("District statemet creation error", e1);
		}

		System.out.printf("Loading District\n");
		d_w_id = w_id;
		d_ytd = (float) 30000.0;
		d_next_o_id = 3001;
		
	retry:
		for (d_id = 1; d_id <= DIST_PER_WARE; d_id++) {

			/* Generate District Data */

			d_name = Util.makeAlphaString(6, 10);
			d_street_1 = Util.makeAlphaString(10, 20);
			d_street_2 = Util.makeAlphaString(10, 20);
			d_city = Util.makeAlphaString(10, 20);
			d_state = Util.makeAlphaString(2, 2);
			d_zip = Util.makeAlphaString(9, 9);

			d_tax = (float) (((float) Util.randomNumber(10, 20)) / 100.0);

			/*EXEC SQL INSERT INTO
			                district
			                values(:d_id,:d_w_id,:d_name,
					       :d_street_1,:d_street_2,:d_city,:d_state,:d_zip,
					       :d_tax,:d_ytd,:d_next_o_id);*/
			try {
				if(shardCount > 0 ){
					stmt.addBatch("/*DBS_HINT: dbs_shard_action=shard_write, dbs_pshard="
							  + currentShard + "*/"
							  + "INSERT INTO district (d_id, d_w_id, d_name, d_street_1, d_street_2, d_city, d_state, d_zip, d_tax, d_ytd, d_next_o_id)  values("
							  + d_id + ","
							  + d_w_id + ","
							  + "'" + d_name + "'" + ","
							  + "'" + d_street_1 + "'" + ","
							  + "'" + d_street_2 + "'" + ","
							  + "'" + d_city + "'" + ","
							  + "'" + d_state + "'" + ","
							  + "'" + d_zip + "'" + ","
							  + d_tax + ","
							  + d_ytd + ","
							  + d_next_o_id + ")");
				}else{
					stmt.addBatch("INSERT INTO district (d_id, d_w_id, d_name, d_street_1, d_street_2, d_city, d_state, d_zip, d_tax, d_ytd, d_next_o_id)  values("
							  + d_id + ","
							  + d_w_id + ","
							  + "'" + d_name + "'" + ","
							  + "'" + d_street_1 + "'" + ","
							  + "'" + d_street_2 + "'" + ","
							  + "'" + d_city + "'" + ","
							  + "'" + d_state + "'" + ","
							  + "'" + d_zip + "'" + ","
							  + d_tax + ","
							  + d_ytd + ","
							  + d_next_o_id + ")");
				}
				
			} catch (SQLException e) {
				throw new RuntimeException("District insert batch error", e);
			}
			if (optionDebug)
				System.out.printf("DID = %d, WID = %d, Name = %s, Tax = %f\n",
				       d_id, d_w_id, d_name, d_tax);

		}
		
		try {
			stmt.executeBatch();
			stmt.close();
		} catch (SQLException e) {
			throw new RuntimeException("District execute batach error", e);
		} 
		
		return error;
	
	}
	
	/*
	 * ==================================================================+ |
	 * ROUTINE NAME |      Customer | DESCRIPTION |      Loads Customer Table |
	 * Also inserts corresponding history record | ARGUMENTS |      id   -
	 * customer id |      d_id - district id |      w_id - warehouse id
	 * +==================================================================
	 */
	public static void customer(int d_id, int w_id, Connection conn, int shardCount, int shardId){
		int c_id = 0;
		int c_d_id = 0;
		int c_w_id = 0;
		String c_first = null;
		String c_middle = null;
		String c_last = null;
		String c_street_1 = null;
		String c_street_2 = null;
		String c_city = null;
		String c_state = null;
		String c_zip = null;
		String c_phone = null;
		String c_since = null;
		String c_credit = null;

		int c_credit_lim = 0;
		float c_discount = 0;
		float c_balance = 0;
		String c_data = null;

		double h_amount = 0.0;

		String h_data = null;
	    boolean retried = false;
	    Statement stmtCust;
	    Statement stmtHist;
		try {
			stmtCust = conn.createStatement();
			stmtHist = conn.createStatement();
		} catch (SQLException e1) {
			throw new RuntimeException("Customer statemet creation error", e1);
		}
	    
		

		System.out.printf("Loading Customer for DID=%d, WID=%d\n", d_id, w_id);
		int currentShard = 0;
		if(shardCount > 0){
			currentShard = (w_id  % shardCount);
			if (currentShard == 0){
				currentShard = shardCount;
			}
		}
		
		if(shardId == currentShard){
			retry:
			    if (retried)
			        System.out.printf("Retrying ...\n");
			    retried = true;
				for (c_id = 1; c_id <= CUST_PER_DIST; c_id++) {

					/* Generate Customer Data */
					c_d_id = d_id;
					c_w_id = w_id;

					c_first = Util.makeAlphaString(8, 16);
					c_middle = "O" + "E";

					if (c_id <= 1000) {
						c_last = Util.lastName(c_id - 1);
					} else {
						c_last = Util.lastName(Util.nuRand(255, 0, 999));
					}

					c_street_1 = Util.makeAlphaString(10, 20);
					c_street_2 = Util.makeAlphaString(10, 20);
					c_city = Util.makeAlphaString(10, 20);
					c_state = Util.makeAlphaString(2, 2);
					c_zip = Util.makeAlphaString(9, 9);
					
					c_phone = Util.makeNumberString(16, 16);

					if (Util.randomNumber(0, 1) == 1)
						c_credit = "G";
					else
						c_credit = "B";
					c_credit += "C";

					c_credit_lim = 50000;
					c_discount = (float) (((float) Util.randomNumber(0, 50)) / 100.0);
					c_balance = (float) -10.0;

					c_data = Util.makeAlphaString(300, 500);
					//gettimestamp(datetime, STRFTIME_FORMAT, TIMESTAMP_LEN); Java Equivalent below?
					Calendar calendar = Calendar.getInstance();
					Date now = calendar.getTime();
					Timestamp currentTimeStamp = new Timestamp(now.getTime());
					Date date = new java.sql.Date(calendar.getTimeInMillis());
					/*EXEC SQL INSERT INTO
					                customer
					                values(:c_id,:c_d_id,:c_w_id,
							  :c_first,:c_middle,:c_last,
							  :c_street_1,:c_street_2,:c_city,:c_state,
							  :c_zip,
						          :c_phone, :timestamp,
							  :c_credit,
							  :c_credit_lim,:c_discount,:c_balance,
							  10.0, 1, 0,:c_data);*/
					try {
						if(shardCount > 0){
							stmtCust.addBatch("/*DBS_HINT: dbs_shard_action=shard_write, dbs_pshard="
									  + currentShard + "*/"
									  + "INSERT INTO customer (c_id, c_d_id, c_w_id, c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_since, c_credit, c_credit_lim, c_discount, c_balance, c_ytd_payment, c_payment_cnt, c_delivery_cnt, c_data) values("
									  + c_id + ","
									  + c_d_id + ","
									  + c_w_id + ","
									  + "'" + c_first + "'" + ","
									  + "'" + c_middle + "'" + ","
									  + "'" + c_last + "'" + ","
									  + "'" + c_street_1 + "'" + ","
									  + "'" + c_street_2 + "'" + ","
									  + "'" + c_city + "'" + ","
									  + "'" + c_state + "'" + ","
									  + "'" + c_zip + "'" + ","
									  + "'" + c_phone + "'" + ","
									  + "'" + date + "'" + ","
									  + "'" + c_credit + "'" + ","
									  + c_credit_lim + ","
									  + c_discount + ","
									  + c_balance + ","
									  + 10.0 + ","
									  + 1 + ","
									  + 0 + ","
									  + "'" + c_data + "'" + ")");
						}else{
							stmtCust.addBatch("INSERT INTO customer (c_id, c_d_id, c_w_id, c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_since, c_credit, c_credit_lim, c_discount, c_balance, c_ytd_payment, c_payment_cnt, c_delivery_cnt, c_data) values("
									  + c_id + ","
									  + c_d_id + ","
									  + c_w_id + ","
									  + "'" + c_first + "'" + ","
									  + "'" + c_middle + "'" + ","
									  + "'" + c_last + "'" + ","
									  + "'" + c_street_1 + "'" + ","
									  + "'" + c_street_2 + "'" + ","
									  + "'" + c_city + "'" + ","
									  + "'" + c_state + "'" + ","
									  + "'" + c_zip + "'" + ","
									  + "'" + c_phone + "'" + ","
									  + "'" + date + "'" + ","
									  + "'" + c_credit + "'" + ","
									  + c_credit_lim + ","
									  + c_discount + ","
									  + c_balance + ","
									  + 10.0 + ","
									  + 1 + ","
									  + 0 + ","
									  + "'" + c_data + "'" + ")");
						}
						
					} catch (SQLException e) {
						throw new RuntimeException("Customer insert error", e);
					}

					h_amount =  10.0;

					h_data = Util.makeAlphaString(12, 24);

					/*EXEC SQL INSERT INTO
					                history
					                values(:c_id,:c_d_id,:c_w_id,
							       :c_d_id,:c_w_id, :timestamp,
							       :h_amount,:h_data);*/
					try {
						if(shardCount > 0){
							stmtHist.addBatch("/*DBS_HINT: dbs_shard_action=shard_write, dbs_pshard="
								      + currentShard + "*/"
								      + "INSERT INTO history (h_c_id, h_c_d_id, h_c_w_id, h_d_id, h_w_id, h_date, h_amount, h_data) values("
								      + c_id + ","
								      + c_d_id + ","
								      + c_w_id + ","
								      + c_d_id + ","
								      + c_w_id + ","
								      + "'" + date + "'" + ","
								      + h_amount + ","
								      + "'" + h_data + "'" + ")");
						}else{
							stmtHist.addBatch( "INSERT INTO history (h_c_id, h_c_d_id, h_c_w_id, h_d_id, h_w_id, h_date, h_amount, h_data) values("
									 + c_id + ","
								      + c_d_id + ","
								      + c_w_id + ","
								      + c_d_id + ","
								      + c_w_id + ","
								      + "'" + date + "'" + ","
								      + h_amount + ","
								      + "'" + h_data + "'" + ")");
						}
						
					} catch (SQLException e) {
						throw new RuntimeException("Insert into History error", e);
					}
					if (optionDebug)
						System.out.printf("CID = %d, LST = %s, P# = %s\n",
						       c_id, c_last, c_phone);
					if ((c_id % 100) == 0) {
			 			System.out.printf(".");
						if ((c_id % 1000) == 0)
							System.out.printf(" %d\n", c_id);
					}
				}
				
				try {
					stmtCust.executeBatch();
					stmtCust.close();
				} catch (SQLException e) {
					throw new RuntimeException("Batch execution Customer error", e);
				}
				
				try {
					stmtHist.executeBatch();
					stmtHist.close();
				} catch (SQLException e) {
					throw new RuntimeException("Batch execution History error", e);
				}
		}
		
	
		
		System.out.printf("Customer Done.\n");

		return;
	}
	
	/*
	 * ==================================================================+ |
	 * ROUTINE NAME |      Orders | DESCRIPTION |      Loads the Orders table |
	 * Also loads the Order_Line table on the fly | ARGUMENTS |      w_id -
	 * warehouse id
	 * +==================================================================
	 */
	public static void orders(int d_id, int w_id, Connection conn, int shardCount, int shardId){
		int o_id = 0;
		int o_c_id = 0;
		int o_d_id = 0;
		int o_w_id = 0;
		int o_carrier_id = 0;
		int o_ol_cnt = 0;
		int ol = 0;
		int ol_i_id = 0;
		int ol_supply_w_id = 0;
		int ol_quantity = 0;
		float ol_amount = 0;
		String ol_dist_info = null;
		float i_price = 0;
		float c_discount = 0;
		float tmp_float = 0;
	    boolean retried = false;
	    Statement stmtOrd;
	    Statement stmtNewOrd;
	    Statement stmtOrdLn;
		try {
			stmtOrd = conn.createStatement();
			stmtNewOrd = conn.createStatement();
			stmtOrdLn = conn.createStatement();
		} catch (SQLException e1) {
			throw new RuntimeException("District statemet creation error", e1);
		}
		
		int currentShard =0;
		if(shardCount > 0){
			currentShard = (w_id  % shardCount);
			if (currentShard == 0){
				currentShard = shardCount;
			}
		}
		
		if(shardId == currentShard){
			System.out.printf("Loading Orders for D=%d, W= %d\n", d_id, w_id);
			o_d_id = d_id;
			o_w_id = w_id;
		retry:
		    if (retried)
		        System.out.printf("Retrying ...\n");
		    retried = true;
			Util.initPermutation();	/* initialize permutation of customer numbers */
			for (o_id = 1; o_id <= ORD_PER_DIST; o_id++) {

				/* Generate Order Data */
				o_c_id = Util.getPermutation();
				o_carrier_id = Util.randomNumber(1, 10);
				o_ol_cnt = Util.randomNumber(5, 15);
				
				//gettimestamp(datetime, STRFTIME_FORMAT, TIMESTAMP_LEN); Java Equivalent below?
				Calendar calendar = Calendar.getInstance();
				Date now = calendar.getTime();
				Timestamp currentTimeStamp = new Timestamp(now.getTime());
			    Date date = new java.sql.Date(calendar.getTimeInMillis());


				if (o_id > 2100) {	/* the last 900 orders have not been
							 * delivered) */
				    /*EXEC SQL INSERT INTO
					                orders
					                values(:o_id,:o_d_id,:o_w_id,:o_c_id,
							       :timestamp,
							       NULL,:o_ol_cnt, 1);*/
					try {
						if(shardCount > 0){
							stmtOrd.addBatch("/*DBS_HINT: dbs_shard_action=shard_write, dbs_pshard="
								      + currentShard + "*/"
								      + "INSERT INTO orders (o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_carrier_id, o_ol_cnt, o_all_local) values("
								      + o_id + ","
								      + o_d_id + ","
								      + o_w_id + ","
								      + o_c_id + ","
								      + "'" + date + "'" + ","
								      + "NULL" + ","
								      + o_ol_cnt + ","
								      + 1 + ")");
						}else{
							stmtOrd.addBatch("INSERT INTO orders (o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_carrier_id, o_ol_cnt, o_all_local) values("
								      + o_id + ","
								      + o_d_id + ","
								      + o_w_id + ","
								      + o_c_id + ","
								      + "'" + date + "'" + ","
								      + "NULL" + ","
								      + o_ol_cnt + ","
								      + 1 + ")");
						}
						
					} catch (SQLException e) {
						throw new RuntimeException("Orders insert error", e);
					}

				    /*EXEC SQL INSERT INTO
					                new_orders
					                values(:o_id,:o_d_id,:o_w_id);*/
					try {
						if(shardCount > 0){
							stmtNewOrd.addBatch("/*DBS_HINT: dbs_shard_action=shard_write, dbs_pshard="
								      + currentShard + "*/"
								      + "INSERT INTO new_orders (no_o_id, no_d_id, no_w_id) values("
								      + o_id + ","
								      + o_d_id + ","
								      + o_w_id + ")");
						}else{
							stmtNewOrd.addBatch("INSERT INTO new_orders (no_o_id, no_d_id, no_w_id) values("
								      + o_id + ","
								      + o_d_id + ","
								      + o_w_id + ")");
						}
						
					} catch (SQLException e) {
						throw new RuntimeException("New Orders insert error", e);
					}
				} else {
				    /*EXEC SQL INSERT INTO
					    orders
					    values(:o_id,:o_d_id,:o_w_id,:o_c_id,
						   :timestamp,
						   :o_carrier_id,:o_ol_cnt, 1);*/
					try {
						if(shardCount > 0){
							stmtOrd.addBatch("/*DBS_HINT: dbs_shard_action=shard_write, dbs_pshard="
								      + currentShard + "*/"
								      + "INSERT INTO orders (o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_carrier_id, o_ol_cnt, o_all_local) values("
								      + o_id + ","
								      + o_d_id + ","
								      + o_w_id + ","
								      + o_c_id + ","
								      + "'" + date + "'" + ","
								      + o_carrier_id + ","
								      + o_ol_cnt + "," 
								      + 1 + ")");
						}else{
							stmtOrd.addBatch("INSERT INTO orders (o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_carrier_id, o_ol_cnt, o_all_local) values("
								      + o_id + ","
								      + o_d_id + ","
								      + o_w_id + ","
								      + o_c_id + ","
								      + "'" + date + "'" + ","
								      + o_carrier_id + ","
								      + o_ol_cnt + "," 
								      + 1 + ")");
						}
						
					} catch (SQLException e) {
						throw new RuntimeException("Orders insert error", e);
					}

				}


				if (optionDebug)
					System.out.printf("OID = %d, CID = %d, DID = %d, WID = %d\n",
					       o_id, o_c_id, o_d_id, o_w_id);

				for (ol = 1; ol <= o_ol_cnt; ol++) {
					/* Generate Order Line Data */
					ol_i_id = Util.randomNumber(1, MAXITEMS);
					ol_supply_w_id = o_w_id;
					ol_quantity = 5;
					ol_amount = (float) 0.0;

					ol_dist_info = Util.makeAlphaString(24, 24);

					tmp_float = (float) ((float) (Util.randomNumber(10, 10000)) / 100.0);

					if (o_id > 2100) {
					    /*EXEC SQL INSERT INTO
						                order_line
						                values(:o_id,:o_d_id,:o_w_id,:ol,
								       :ol_i_id,:ol_supply_w_id, NULL,
								       :ol_quantity,:ol_amount,:ol_dist_info);*/
						try {
							if(shardCount > 0){
								stmtOrdLn.addBatch("/*DBS_HINT: dbs_shard_action=shard_write, dbs_pshard="
									      + currentShard + "*/"
									      + "INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_delivery_d, ol_quantity, ol_amount, ol_dist_info) values("
									      + o_id + ","
									      + o_d_id + ","
									      + o_w_id + ","
									      + ol + ","
									      + ol_i_id + ","
									      + ol_supply_w_id + ","
									      + "NULL" + ","
									      + ol_quantity + ","
									      + ol_amount + ","
									      + "'" + ol_dist_info + "'" + ")");
							}else{
								stmtOrdLn.addBatch("INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_delivery_d, ol_quantity, ol_amount, ol_dist_info) values("
									      + o_id + ","
									      + o_d_id + ","
									      + o_w_id + ","
									      + ol + ","
									      + ol_i_id + ","
									      + ol_supply_w_id + ","
									      + "NULL" + ","
									      + ol_quantity + ","
									      + ol_amount + ","
									      + "'" + ol_dist_info + "'" + ")");
							}
							
						} catch (SQLException e) {
							throw new RuntimeException("Order line insert error", e);
						}
					} else {
					    /*EXEC SQL INSERT INTO
						    order_line
						    values(:o_id,:o_d_id,:o_w_id,:ol,
							   :ol_i_id,:ol_supply_w_id, 
							   :timestamp,
							   :ol_quantity,:tmp_float,:ol_dist_info);*/
						try {
							if(shardCount > 0){
								stmtOrdLn.addBatch("/*DBS_HINT: dbs_shard_action=shard_write, dbs_pshard="
									      + currentShard + "*/"
									      + "INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_delivery_d, ol_quantity, ol_amount, ol_dist_info) values("
									      + o_id + ","
									      + o_d_id + ","
									      + o_w_id + ","
									      + ol + ","
									      + ol_i_id + ","
									      + ol_supply_w_id + ","
									      + "'" + date + "'" + ","
									      + ol_quantity + ","
									      + tmp_float + ","
									      + "'" + ol_dist_info + "'" + ")");
							}else{
								stmtOrdLn.addBatch("INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_delivery_d, ol_quantity, ol_amount, ol_dist_info) values("
									      + o_id + ","
									      + o_d_id + ","
									      + o_w_id + ","
									      + ol + ","
									      + ol_i_id + ","
									      + ol_supply_w_id + ","
									      + "'" + date + "'" + ","
									      + ol_quantity + ","
									      + tmp_float + ","
									      + "'" + ol_dist_info + "'" + ")");
							}
							
						} catch (SQLException e) {
							throw new RuntimeException("Order line insert error", e);
						}
					}

					if (optionDebug)
						System.out.printf("OL = %d, IID = %d, QUAN = %d, AMT = %f\n",
						       ol, ol_i_id, ol_quantity, ol_amount);

				}
				if ((o_id % 100) == 0) {
					System.out.printf(".");

		 			if ( (o_id % 1000) == 0)
						System.out.printf(" %d\n", o_id);
				}
			}
			try {
				stmtOrd.executeBatch();
				stmtOrd.close();

			} catch (SQLException e) {
				// TODO Auto-generated catch block
				throw new RuntimeException("Order batch execute error", e);
			}
			try {
				stmtNewOrd.executeBatch();
				stmtNewOrd.close();

			} catch (SQLException e) {
				// TODO Auto-generated catch block
				throw new RuntimeException("New Order batch execute error", e);
			}
			
			try {
				stmtOrdLn.executeBatch();
				stmtOrdLn.close();

			} catch (SQLException e) {
				throw new RuntimeException("Order line batch execute error", e);
			}
			
			
		}

		

		System.out.printf("Orders Done.\n");
		return;
	
	}

	

}

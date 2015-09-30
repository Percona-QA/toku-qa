package org.opensharding.tpcc;

import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Properties;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;


public class TpccLoad implements TpccConstants {
	/* Global SQL Variables */
	static int num_ware = 0;
	static int fd = 0;
	static int seed = 0;
	

	 int particle_flg = 0; /* "1" means particle mode */
	 int part_no = 0; /* 1:items 2:warehouse 3:customer 4:orders */
	 long min_ware = 1;
	 long max_ware;

	/* Global Variables */
	static int i = 0;
	static int is_local = 1;           /* "1" mean local */
	static int DB_STRING_MAX = 51;
	static boolean option_debug = false;	/* 1 if generating debug output    */
	
	private static final Logger logger = LogManager.getLogger(Tpcc.class);
	private static final boolean DEBUG = logger.isDebugEnabled();
	
	private static final String DRIVER = "DRIVER";
	private static final String WAREHOUSECOUNT = "WAREHOUSECOUNT";
	private static final String HOST = "HOST";
	private static final String DATABASE = "DATABASE";
	private static final String USER = "USER";
	private static final String PASSWORD = "PASSWORD";
	private static final String SHARDCOUNT = "SHARDCOUNT";
	private static final String JDBCURL = "JDBCURL";
	private static final String SHARDID = "SHARDID";
	
	private Properties properties;
	private InputStream inputStream;
	
	private static final String PROPERTIESFILE = "tpcc.properties";
	
	public TpccLoad() {
		// Empty.
	}
	
	private void init() {
		
		  
		  
		  logger.info("Loading properties from: " + PROPERTIESFILE);
		  
		  properties = new Properties();
		  inputStream = getClass().getClassLoader().getResourceAsStream(PROPERTIESFILE);
		  if(inputStream == null){
			  throw new RuntimeException("Failed to access properties.");
		  }
		  try{
			  properties.load(inputStream);
		  }catch (IOException e){
			  throw new RuntimeException("Error loading properties file", e);
		  }
		
	}


	
	private int runLoad(){
		String connect_string = null;
		String db_string = null;
		String db_user = null;
		String db_password = null;
	    int port= 3306;
	    int shardCount = 0;
	    int num_ware = 0;
	    String jdbcUrl = null;
	    String javaDriver = null;
	    int shardId = -1;

		System.out.printf("*************************************\n");
		System.out.printf("*** Java TPC-C Data Loader  ***\n");
		System.out.printf("*************************************\n");

		long start = System.currentTimeMillis();
		System.out.println("Execution time start: " + start);
		
		connect_string = properties.getProperty(HOST);
		db_string = properties.getProperty(DATABASE);
		db_user = properties.getProperty(USER);
		db_password = properties.getProperty(PASSWORD);
		num_ware = Integer.parseInt(properties.getProperty(WAREHOUSECOUNT));
		shardCount = Integer.parseInt(properties.getProperty(SHARDCOUNT));
		javaDriver = properties.getProperty(DRIVER);
		jdbcUrl = properties.getProperty(JDBCURL);
		shardId = Integer.parseInt(properties.getProperty(SHARDID));
		  
		if(connect_string == null){
			throw new RuntimeException("Host is null.");
		}
		if(db_string == null){
			  throw new RuntimeException("Database name is null.");
		}
		if(db_user == null){
			  throw new RuntimeException("User is null.");
		}
		if(db_password == null){
			  throw new RuntimeException("Password is null.");
		}
		if(num_ware < 1){
			  throw new RuntimeException("Warehouse count has to be greater than or equal to 1.");
		}
		if(javaDriver == null){
			  throw new RuntimeException("Java Driver is null.");
		}
		if(jdbcUrl == null){
			  throw new RuntimeException("JDBC Url is null.");
		}
		if(shardId == -1){
			throw new RuntimeException("ShardId was not obtained");
		}
		
		System.out.printf("<Parameters>\n");
		if(is_local==0) System.out.printf("     [server]: %s\n", connect_string);
		if(is_local==0) System.out.printf("     [port]: %d\n", port);
		System.out.printf("     [DBname]: %s\n", db_string);
		System.out.printf("       [user]: %s\n", db_user);
		System.out.printf("       [pass]: %s\n", db_password);

		System.out.printf("  [warehouse]: %d\n", num_ware);

		if(particle_flg==1){
		    System.out.printf("  [part(1-4)]: %d\n", part_no);
		    System.out.printf("     [MIN WH]: %d\n", min_ware);
		    System.out.printf("     [MAX WH]: %d\n", max_ware);
		}

		//TODO: Pass the seed in as a variable.
		Util.setSeed(seed);


		/* EXEC SQL WHENEVER SQLERROR GOTO Error_SqlCall; */
		try {
			Class.forName(javaDriver);
		} catch (ClassNotFoundException e1) {
			throw new RuntimeException("Class for mysql error", e1);
		}
		
		Connection conn;

		try {
			conn = DriverManager.getConnection (jdbcUrl, db_user, db_password);
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			throw new RuntimeException("Connection to local host error", e);
		}
	
		
		Statement stmt;
		try {
			stmt = conn.createStatement();
		} catch (SQLException e) {
			throw new RuntimeException("Could not create statement", e);
		}
		try {
			stmt.execute("SET UNIQUE_CHECKS=0");
		} catch (SQLException e) {
			throw new RuntimeException("Could not set unique checks error", e);
		}
		try {
			stmt.execute("SET FOREIGN_KEY_CHECKS=0");
			stmt.close();
		} catch (SQLException e) {
			throw new RuntimeException("Could not set foreign key checks error", e);
		}
	

		System.out.printf("TPCC Data Load Started...\n");
		max_ware = num_ware;
		if(particle_flg==0){
			System.out.printf("Particle flag: %d\n", particle_flg);
			Load.loadItems(conn, shardCount, option_debug);
			Load.loadWare(conn, shardCount, (int)min_ware, (int)max_ware, option_debug, shardId);
			Load.loadCust(conn, shardCount, (int)min_ware, (int)max_ware, shardId);
			Load.loadOrd(conn, shardCount, (int)min_ware, (int)max_ware, shardId);
		}else if(particle_flg==1){
		    switch(part_no){
			case 1:
				 Load.loadItems(conn, shardCount, option_debug);
				 break;
			case 2:
			    Load.loadWare(conn, shardCount, (int)min_ware, (int)max_ware, option_debug, shardId);
			    break;
			case 3:
			    Load.loadCust(conn, shardCount, (int)min_ware, (int)max_ware, shardId);
			    break;
			case 4:
			    Load.loadOrd(conn, shardCount, (int)min_ware, (int)max_ware, shardId);;
			    break;
			default:
			    System.out.printf("Unknown part_no\n");
			    System.out.printf("1:ITEMS 2:WAREHOUSE 3:CUSTOMER 4:ORDERS\n");
		    }
		}

		System.out.printf("\n...DATA LOADING COMPLETED SUCCESSFULLY.\n");

		long end = System.currentTimeMillis();
		System.out.println("Total execution time: " + (double)((((double)end-(double)start) / 1000.0))/60.0 + " Min");
		return 0;

	}
	
	public static void main(String[] argv){
		TpccLoad tpccLoad = new TpccLoad();
		tpccLoad.init();
		int ret = tpccLoad.runLoad();
		System.exit(ret);
	}



}

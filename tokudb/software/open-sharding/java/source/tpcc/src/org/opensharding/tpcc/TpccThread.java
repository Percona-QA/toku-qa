package org.opensharding.tpcc;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.text.DecimalFormat;
import java.util.Map;
import java.util.Properties;
import java.util.Set;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class TpccThread extends Thread {

	private static final Logger logger = LogManager.getLogger(TpccThread.class);
	private static final boolean DEBUG = logger.isDebugEnabled();
	
	int number;
	int port;
	int is_local;
	int num_ware;
	int num_conn;
	String connect_string;
	String db_user;
	String db_password;
	String db_string;
	String driverClassName;
	String jdbcUrl;
    int fetchSize;
	
	private int[] success;
	private int[] late;
	private int[] retry;
	private int[] failure;

	private int[][] success2;
	private int[][] late2;
	private int[][] retry2;
	private int[][] failure2;

	//TpccStatements pStmts;
	
	public TpccThread(int number, int port, int is_local, String connect_string, String db_user, String db_password, 
			String db_string, int num_ware, int num_conn, String driver, String dURL, int fetchSize,
			int[] success, int[] late, int[] retry, int[] failure, 
			int[][] success2, int[][] late2, int[][] retry2, int[][] failure2) {
		
        this.number = number;
        this.port = port;
        this.connect_string = connect_string;
        this.db_password = db_password;
        this.db_string = db_string;
        this.db_user = db_user;
        this.is_local = is_local;
        this.num_conn = num_conn;
        this.num_ware = num_ware;
        this.driverClassName = driver;
        this.jdbcUrl = dURL;
        this.fetchSize = fetchSize;
        
		this.success = success;
		this.late = late;
		this.retry = retry;
		this.failure = failure;
		
		this.success2 = success2;
		this.late2 = late2;
		this.retry2 = retry2;
		this.failure2 = failure2;

	}

    public void run() {
        logger.info("Connection to database: driver: " + driverClassName + " url: " + jdbcUrl);
        try {
            Class.forName(driverClassName);
        } catch (ClassNotFoundException e1) {
            throw new RuntimeException("Class for mysql error", e1);
        }

        Connection conn;

        try {

            Properties prop = new Properties();
            File connPropFile = new File("conf/jdbc-connection.properties");
            if (connPropFile.exists()) {
                logger.info("Loading JDBC connection properties from " + connPropFile.getAbsolutePath());
                try {
                    final FileInputStream is = new FileInputStream(connPropFile);
                    prop.load(is);
                    is.close();

                    if (logger.isDebugEnabled()) {
                        logger.debug("Connection properties: {");
                        final Set<Map.Entry<Object,Object>> entries = prop.entrySet();
                        for (Map.Entry<Object,Object> entry : entries) {
                            logger.debug(entry.getKey() + " = " + entry.getValue());
                        }

                        logger.debug("}");
                    }

                } catch (IOException e) {
                    logger.error("", e);
                }
            }
            else {
                logger.warn(connPropFile.getAbsolutePath() + " does not exist! Using default connection properties");
            }
            prop.put("user", db_user);
            prop.put("password", db_password);

            conn = DriverManager.getConnection(jdbcUrl, prop);
            conn.setTransactionIsolation(Connection.TRANSACTION_READ_COMMITTED); //TODO: make configurable
            conn.setAutoCommit(false);

        } catch (SQLException e) {
            // TODO Auto-generated catch block
            throw new RuntimeException("Connection to specific host error", e);
        }


        try {
            // Create a driver instance.
            Driver driver = new Driver(conn, fetchSize,
                    success, late, retry, failure,
                    success2, late2, retry2, failure2);

            if (DEBUG) {
                logger.debug("Starting driver with: number: " + number + " num_ware: " + num_ware + " num_conn: " + num_conn);
            }

            driver.runTransaction(number, num_ware, num_conn);

        } catch (Throwable e) {
            logger.error("Unhandled exception", e);
        }

    }
}


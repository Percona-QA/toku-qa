import java.sql.BatchUpdateException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.Timestamp;
import java.util.Date;
import java.util.Properties;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;
import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.File;
import java.io.Writer;
import java.io.FileNotFoundException;
import java.io.IOException;

public class TestRig {
    public static AtomicInteger globalInserts = new AtomicInteger();
    public static AtomicInteger globalBatches = new AtomicInteger();
    public static AtomicInteger globalWorkerThreads = new AtomicInteger();
    public static AtomicLong globalLatency = new AtomicLong();
    public static Integer numTables;
    public static Integer numRowsPerTable;
    public static Integer inListSize;
    
    
	public static int minutesToRun = 0;
    public static long secondsPerFeedback;
    public static Writer writer = null;
    public static boolean outputHeader = true;
	public static String connectionUrl = "jdbc:mysql://localhost:3306/test";
	public static String connectionUser = "root";
	public static String connectionPassword = "";

	public TestRig() {
	}

	public static void main (String[] args) throws Exception {
        if (args.length != 7) {
            logMe("*** ERROR : CONFIGURATION ISSUE ***");
            logMe("TestRig [number of threads] [number of tables] [number of rows per table] [seconds feedback] [IN list size] [minutes to run] [log file name]");
            System.exit(1);
        }

        int threadCount = Integer.valueOf(args[0]);
        numTables = Integer.valueOf(args[1]);
		numRowsPerTable = Integer.valueOf(args[2]);
		secondsPerFeedback = Long.valueOf(args[3]);
		inListSize = Integer.valueOf(args[4]);
	    minutesToRun = Integer.valueOf(args[5]);
	    String logFileName = args[6];
		
        logMe("Application Parameters");
        logMe("--------------------------------------------------");
        logMe("  Running with %d thread(s)",threadCount);
        logMe("  %,d table(s)",numTables);
        logMe("  %,d row(s) per table",numRowsPerTable);
        logMe("  Feedback every %,d seconds(s)",secondsPerFeedback);
        logMe("  %,d value(s) per IN list",inListSize);
        if (minutesToRun > 0)
            logMe("  Running for %,d minute(s)",minutesToRun);
        logMe("--------------------------------------------------");

        try {
            writer = new BufferedWriter(new FileWriter(new File(logFileName)));
        } catch (IOException e) {
            e.printStackTrace();
        }

		Class.forName("com.mysql.jdbc.Driver");

        logMe("Warming things up...");
        Connection conWarmup = getConnection();
        Statement statement = (com.mysql.jdbc.Statement)conWarmup.createStatement();
        
        for (Integer i=1; i<=numTables; i++) {
            logMe("table %d",i);
            statement.execute("select count(*) from sbtest" + i.toString());
        }
        conWarmup.close();

/*
        
		Connection con = null;
		
		Thread[] workerThreads = new Thread[threadCount];
		TestIndexForToku t = new TestIndexForToku();
		for (int i=0; i<threadCount; i++) {
			workerThreads[i] = new Thread(t.new MyRunner(con, threadCount, i, size, batchSize));
			workerThreads[i].start();
			globalWorkerThreads.incrementAndGet();
		}

		Thread reporterThread = new Thread(t.new MyReporter());
		reporterThread.start();
		
		for (int i=0; i<threadCount; i++) {
			workerThreads[i].join();
			globalWorkerThreads.decrementAndGet();
		}
		
		reporterThread.join();
		
        try {
            if (writer != null) {
                writer.close();
            }
        } catch (IOException e) {
            e.printStackTrace();
        }        
*/        
		
		logMe("Done!");
	}
	
	
	static Connection getConnection() throws Exception {
		Properties props = new Properties();
		props.setProperty("user",connectionUser);
		props.setProperty("password",connectionPassword);
		// tmc - multiple insert into <table> values () gets rewritten to insert into <table> values (),(),(),...
		props.setProperty("rewriteBatchedStatements","true");
		
		Connection con = DriverManager.getConnection(connectionUrl, props);
		con.setAutoCommit(false);
		
        // turn on/off tokudb_commit_sync?  setting to 1 fsync's at each commit
        Statement statement = (com.mysql.jdbc.Statement)con.createStatement();
        statement.execute("SET tokudb_commit_sync=" + tokudbCommitSync.toString());
		
		return con;
	}

    // reporting thread, outputs information to console and file
	class MyReporter implements Runnable {
		public void run()
		{
    		long t0 = System.currentTimeMillis();
    		int lastGlobalAdded = 0;
    		long lastGlobalLatency = 0;
    		int lastGlobalBatches = 0;
    		long lastMs = 0;
    		long intervalNumber = 0;
    		long nextFeedbackMillis = t0 + (1000 * secondsPerFeedback * (intervalNumber + 1));
    		long runEndMillis = Long.MAX_VALUE;
    		if (minutesToRun > 0)
    		    runEndMillis = t0 + (1000 * 60 * minutesToRun);
    		
    		while (System.currentTimeMillis() < runEndMillis)
    		{
    		    // tmc - should I sleep in here for a while?
    		    try {
    		        Thread.sleep(100);
       			} catch (Exception e) {
	    			e.printStackTrace();
		    	}
    		    
    			long now = System.currentTimeMillis();
    			if (now > nextFeedbackMillis)
    			{
    			    intervalNumber++;
                    nextFeedbackMillis = t0 + (1000 * secondsPerFeedback * (intervalNumber + 1));
                    
    				long elapsed = now - t0;
    				long thisIntervalMs = now - lastMs;
    				int thisGlobalInserts = globalInserts.get();
    				
    				int thisGlobalIntervalAdded = thisGlobalInserts - lastGlobalAdded;
    				double thisGlobalIntervalInsertsPerSecond = thisGlobalInserts/(double)elapsed*1000.0;
    				if (lastGlobalAdded != 0)
    				{
    				    thisGlobalIntervalInsertsPerSecond = thisGlobalIntervalAdded/(double)thisIntervalMs*1000.0;
    				}
    				long thisGlobalLatency = globalLatency.get();
    				int thisGlobalBatches = globalBatches.get();
    				double avgLatency = (double) thisGlobalLatency / (double) thisGlobalBatches;
    				double intervalAvgLatency = (double) thisGlobalLatency / (double) thisGlobalBatches;
    				if (lastGlobalBatches != 0)
    				{
    				    intervalAvgLatency = (double) (thisGlobalLatency - lastGlobalLatency) / (double) (thisGlobalBatches - lastGlobalBatches);
    				}
                    logMe("Added %,d rows so far, took %,d seconds, rate=%5.0f/s, interval=%5.0f/s, avg. latency=%.2f ms, interval=%.2f ms ", thisGlobalInserts, elapsed / 1000l, thisGlobalInserts/(double)elapsed*1000.0, thisGlobalIntervalInsertsPerSecond, avgLatency, intervalAvgLatency);
                    
                    try {
                        if (outputHeader)
                        {
                            writer.write("int_num\trow_count\telap_secs\tavg_rate\tint_rate\tavg_lat\tintl_lat\n");
                            outputHeader = false;
                        }
                            
                        // interval_num, row_count, elap_secs, avg_rate, interval_rate, avg_latency, interval_latency
                        String statusUpdate = String.format("%d\t%d\t%d\t%.0f\t%.0f\t%.2f\t%.2f\n",intervalNumber, thisGlobalInserts, elapsed / 1000l, thisGlobalInserts/(double)elapsed*1000.0, thisGlobalIntervalInsertsPerSecond, avgLatency, intervalAvgLatency);
                        writer.write(statusUpdate);
                        writer.flush();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                    
                    lastGlobalLatency = thisGlobalLatency;
                    lastGlobalBatches = thisGlobalBatches;
    
                    lastGlobalAdded = thisGlobalInserts;
                    lastMs = now;
                    
       			    if (globalWorkerThreads.get() == 0)
       			        break;
    			}
    		}
		}
	}

	
	class MyRunner implements Runnable {
		Connection con; 
		int threadCount; 
		int threadNumber; 
		int size;
		int batchSize;
		MyRunner(Connection con, int threadCount, int threadNumber, int size, int batchSize) {
			this.con = con;
			this.threadCount = threadCount;
			this.threadNumber = threadNumber;
			this.size = size;
			this.batchSize = batchSize;
		}
		public void run() {
			try {
				con = getConnection();
				
        		// turn off uniqueness checking?  setting to 0 in TokuDB will eliminate uniqueness checking on the PK during inserts
//                Statement statement = (com.mysql.jdbc.Statement)con.createStatement();
//                statement.execute("SET unique_checks=0 ");
				
				logMe("Thread %d starting insert test",threadNumber);
				testInsert(con, threadCount, threadNumber, size, batchSize);
				con.close();
				// tmc - commented out update portion
//				for (int i=0; i<0; i++) {
//					con = getConnection();
//					logMe("Loop #%d...", i);
//					testUpdate(con, threadCount, threadNumber, size);
//					con.close();
//				}
			} catch (Exception e) {
				e.printStackTrace();
			}
			
		}
	}


	public static void testInsert(Connection con, int threadCount, int threadNumber, int size, int batchSize) throws Exception {
		PreparedStatement stmt = con.prepareStatement(insertString);
		boolean hasMore = false;
		StringBuilder strb = new StringBuilder(1024*2);
		for (int i=0; i<strb.capacity(); i++) {
			strb.append("x");
		}
		long t0 = System.currentTimeMillis();
		String myString = strb.toString();
		int added = 0;
        byte[] bytes = new byte[]{1,2,3};
        Timestamp ts = new Timestamp(new Date().getTime());
        java.util.Random rand = new java.util.Random();
		long runEndMillis = Long.MAX_VALUE;
		if (minutesToRun > 0)
		    runEndMillis = System.currentTimeMillis() + (1000 * 60 * minutesToRun);
		
		for (int i=0; i<size; i++) {
			if (i%threadCount != threadNumber) {
				continue;
			}
			
			if (System.currentTimeMillis() > runEndMillis)
			    break;
			
			int col = 1;
			byte[] macId = createNicMacId(i);
			// tmc - pick either sequential or random PKs
            //stmt.setLong(col++, i);                  // sequential
            stmt.setLong(col++, rand.nextInt());     // random
            
            stmt.setLong(col++, i);
            stmt.setString(col++, "value-" + i);
            stmt.setBytes(col++, macId);
            stmt.setLong(col++, i);
            stmt.setInt(col++, i%10+1);
            stmt.setString(col++, "value-" + i);
            stmt.setBytes(col++, bytes);
            stmt.setInt(col++, i%20+1);
            stmt.setLong(col++, i%20+1);
            stmt.setInt(col++, i%20+1);
            stmt.setInt(col++, i%20+1);
            stmt.setString(col++, "value-" + i);
            stmt.setInt(col++, i%8+1);
            stmt.setInt(col++, i%8+1);
            
            // tmc - changed to use a BIG STRING
            //stmt.setString(col++, "Bad+" +i);
            stmt.setString(col++, new Integer(i).toString() + bigString);
            
            stmt.setString(col++, new Integer(i%22+1).toString());
            stmt.setLong(col++, i);
            stmt.setLong(col++, i);
            stmt.setLong(col++, i);
            stmt.setString(col++, "value-" + i);
            stmt.setLong(col++, i);
            stmt.setLong(col++, i);
            stmt.setTimestamp(col++, ts);
            stmt.setString(col++, "value-" + i);
            stmt.setString(col++, "value-" + i);
            stmt.setBytes(col++, bytes);
            stmt.setTimestamp(col++, ts);
            stmt.setTimestamp(col++, ts);
            stmt.setLong(col++, i%5+1);
            stmt.setTimestamp(col++, ts);
            stmt.setTimestamp(col++, ts);
            stmt.setTimestamp(col++, ts);
            stmt.setInt(col++, i%5+1);
            stmt.setInt(col++, i);
            stmt.setInt(col++, i);
            stmt.setString(col++, "value-" + i);
            stmt.setString(col++, "value-" + i);
            stmt.setInt(col++, i);
            stmt.setString(col++, "value-" + i);
            stmt.setInt(col++, i);
            stmt.setInt(col++, i);
            stmt.setInt(col++, i);
            stmt.setLong(col++, i);
            stmt.setString(col++, "value-" + i);
            stmt.setLong(col++, i);
            stmt.setBytes(col++, bytes);
            stmt.setBytes(col++, bytes);
            stmt.setTimestamp(col++, ts);
            stmt.setString(col++, "value-" + i);
            stmt.setLong(col++, i);
            stmt.setLong(col++, i);
            stmt.setLong(col++, i);
            stmt.setLong(col++, i);
            stmt.setLong(col++, i);
            stmt.setLong(col++, i);
            stmt.setLong(col++, i);
            stmt.setLong(col++, i);
            stmt.setLong(col++, i);
            stmt.setLong(col++, i);
            stmt.setLong(col++, i);
            stmt.setLong(col++, i);
            stmt.setString(col++, "value-" + i);
            stmt.setTimestamp(col++, ts);
            stmt.setString(col++, "value-" + i);
            stmt.setString(col++, "value-" + i);
            stmt.setString(col++, "value-" + i);
            stmt.setString(col++, "value-" + i);
            stmt.setString(col++, "value-" + i);
            stmt.setTimestamp(col++, ts);
            stmt.setLong(col++, i);
            stmt.setTimestamp(col++, ts);
            stmt.setLong(col++, i);
            
			stmt.addBatch();
			added++;
			int currentGlobalInserts = globalInserts.incrementAndGet();
			hasMore = true;
			if (added%batchSize == 0 && i>0) {
				try {
				    globalBatches.incrementAndGet();
				    // record transaction latency
				    long latencyStart = System.currentTimeMillis();
					stmt.executeBatch();
					con.commit();
					globalLatency.getAndAdd(System.currentTimeMillis() - latencyStart);
				} catch (Exception e) {
					e.printStackTrace();
					logMe("Got an exception: %s, reconnecting...", e.getMessage());
					con = getConnection();
					stmt = con.prepareStatement(insertString);
				}
				hasMore = false;
			}
		}
		if (hasMore) {
			stmt.executeBatch();
			con.commit();
			hasMore = false;
		}
		
		// long elapsed = System.currentTimeMillis() - t0;
        // logMe("Finished adding %d rows so far, took %d ms, rate=%5.0f/s ", added, elapsed, added/(double)elapsed*1000.0);
	}

	public static void logMe(String format, Object... args) {
		System.out.println(Thread.currentThread() + String.format(format, args));
	}
}

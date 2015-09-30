import java.sql.BatchUpdateException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.Timestamp;
import java.util.Date;
import java.util.Properties;
import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.File;
import java.io.Writer;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.locks.ReentrantLock;

public class iibench {
    public static ReentrantLock lockDDL = new ReentrantLock();
    public static AtomicLong globalInserts = new AtomicLong(0);
    public static AtomicInteger globalQueries = new AtomicInteger(0);
    public static AtomicInteger globalDDL = new AtomicInteger(0);
    public static AtomicInteger globalQueryThreads = new AtomicInteger(0);
    public static AtomicInteger globalWriterThreads = new AtomicInteger(0);
    
    public static long rowsPerFeedback;
    public static long secondsPerFeedback;
    
    public static int numCashRegisters = 1000;
    public static int numProducts = 10000;
    public static int numCustomers = 100000;
    public static float maxPrice = 500.0f;
    public static int minutesToRun = 10000;
    public static long rowsToRun = 1000000000;
    public static long maxInsertsPerSecond = -1;
    
    public static Writer writer = null;
    public static boolean outputHeader = true;
    public static String connectionUrl = "jdbc:mysql://localhost:11000/test";
    public static String connectionUser = "root";
    public static String connectionPassword = "";
    public static int queryThreads = 0;
    public static int writerThreads = 1;
    public static int shutItDown = 0;
    public static final int insertsPerBatch = 1000;
    public static final int updatesPerBatch = 0;
    public static final int deletesPerBatch = 0;
    public static int ddlMinutesDelay = 10;
    public static String engineName = "tokudb";
    
    static String insertString = "insert into purchases_index (dateandtime,cashregisterid,customerid,productid,price) values (?,?,?,?,?)";

    public iibench() {
    }

    public static void main (String[] args) throws Exception {
        if (args.length != 8) {
            logMe("*** ERROR : CONFIGURATION ISSUE ***");
            logMe("iibench [log file name] [engine_name] [rows per report] [seconds per report] [max inserts per second] [run minutes] [run rows] [minutes until HCA]");
            System.exit(1);
        }

        String logFileName = args[0];
        engineName = args[1];
        rowsPerFeedback = Long.valueOf(args[2]);
        secondsPerFeedback = Long.valueOf(args[3]);
        maxInsertsPerSecond = Integer.valueOf(args[4]);
        minutesToRun = Integer.valueOf(args[5]);
        rowsToRun = Long.valueOf(args[6]);
        ddlMinutesDelay = Integer.valueOf(args[7]);

        logMe("Application Parameters");
        logMe("--------------------------------------------------");
        logMe("  logging to             : %s",logFileName);
        logMe("  storage engine         : %s",engineName);
        logMe("  feedback rows          : %,d",rowsPerFeedback);
        logMe("  feedback seconds       : %,d",secondsPerFeedback);
        logMe("  run duration (minutes) : %,d",minutesToRun);
        logMe("  run duration (rows)    : %,d",rowsToRun);
        logMe("  max inserts per second : %,d",maxInsertsPerSecond);
        logMe("  minutes until HCA      : %,d",ddlMinutesDelay);
        logMe("--------------------------------------------------");

        try {
            writer = new BufferedWriter(new FileWriter(new File(logFileName)));
        } catch (IOException e) {
            e.printStackTrace();
        }

        Class.forName("com.mysql.jdbc.Driver");

        Connection con = null;
        
        iibench t = new iibench();
        
        Thread[] tQueryThreads = new Thread[queryThreads];
        for (int i=0; i<queryThreads; i++) {
            tQueryThreads[i] = new Thread(t.new MyQuery(con, queryThreads, i));
            tQueryThreads[i].start();
        }

        Thread[] tWriterThreads = new Thread[writerThreads];
        for (int i=0; i<writerThreads; i++) {
            tWriterThreads[i] = new Thread(t.new MyWriter(con, writerThreads, i));
            tWriterThreads[i].start();
        }
        
        Thread ddlThread = new Thread(t.new MyDDL(con));
        if (ddlMinutesDelay > 0) {
            ddlThread.start();
        }

        Thread reporterThread = new Thread(t.new MyReporter());
        reporterThread.start();
        reporterThread.join();
        shutItDown = 1;

        // join ddl thread, it will terminate itself
        if (ddlThread.isAlive())
            ddlThread.join();

        // wait for query threads to terminate
        for (int i=0; i<queryThreads; i++) {
            if (tQueryThreads[i].isAlive())
                tQueryThreads[i].join();
        }

        // wait for writer threads to terminate
        for (int i=0; i<writerThreads; i++) {
            if (tWriterThreads[i].isAlive())
                tWriterThreads[i].join();
        }
        
        try {
            if (writer != null) {
                writer.close();
            }
        } catch (IOException e) {
            e.printStackTrace();
        }

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
        //Statement statement = (com.mysql.jdbc.Statement)con.createStatement();
        //statement.execute("SET tokudb_commit_sync=" + tokudbCommitSync.toString());

        return con;
    }


    // reporting thread, outputs information to console and file
    class MyReporter implements Runnable {
        public void run()
        {
            long t0 = System.currentTimeMillis();
            long lastInserts = 0;
            int lastQueries = 0;
            long lastMs = t0;
            long intervalNumber = 0;
            long nextFeedbackMillis = t0 + (1000 * secondsPerFeedback * (intervalNumber + 1));
            long nextFeedbackInserts = 0 + rowsPerFeedback;
            long runEndMillis = Long.MAX_VALUE;
            if (minutesToRun > 0)
                runEndMillis = t0 + (1000 * 60 * minutesToRun);

            while ((System.currentTimeMillis() < runEndMillis) && ((long)globalInserts.get() < rowsToRun))
            {
                long now = System.currentTimeMillis();
                if ((now > nextFeedbackMillis) || (globalInserts.get() >= nextFeedbackInserts))
                {
                    intervalNumber++;
                    nextFeedbackMillis = t0 + (1000 * secondsPerFeedback * (intervalNumber + 1));
                    nextFeedbackInserts = nextFeedbackInserts + rowsPerFeedback;

                    long elapsed = now - t0;
                    long thisIntervalMs = now - lastMs;
                    
                    long thisInserts = globalInserts.get();
                    int thisQueries = globalQueries.get();
                    int thisDDL = globalDDL.get();

                    long thisIntervalInserts = thisInserts - lastInserts;
                    int thisIntervalQueries = thisQueries - lastQueries;

                    double thisIntervalInsertsPerSecond = thisIntervalInserts/(double)thisIntervalMs*1000.0;
                    double thisIntervalQueriesPerSecond = thisIntervalQueries/(double)thisIntervalMs*1000.0;

                    double thisInsertsPerSecond = thisInserts/(double)elapsed*1000.0;
                    double thisQueriesPerSecond = thisQueries/(double)elapsed*1000.0;
                    
                    logMe("%,d seconds, cum xps=%,.2f, int xps=%,.2f, cum qps=%,.2f, int qps=%,.2f, ddl=%,d", elapsed / 1000l, thisInsertsPerSecond, thisIntervalInsertsPerSecond, thisQueriesPerSecond, thisIntervalQueriesPerSecond, thisDDL);
                    
                    try {
                        if (outputHeader)
                        {
                            writer.write("elap_secs\tcum_xps\tint_xps\tcum_qps\tint_qps\n");
                            outputHeader = false;
                        }
                            
                        String statusUpdate = String.format("%d\t%.2f\t%.2f\t%.2f\t%.2f\n",elapsed / 1000l, thisInsertsPerSecond, thisIntervalInsertsPerSecond, thisQueriesPerSecond, thisIntervalQueriesPerSecond);
                        writer.write(statusUpdate);
                        writer.flush();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }

                    lastInserts = thisInserts;
                    lastQueries = thisQueries;

                    lastMs = now;
                }
                
                try {
                    Thread.sleep(100);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }
    }
    
    
    // ddl thread, adds a column to the table
    class MyDDL implements Runnable {
        Connection con; 
        java.util.Random rand = new java.util.Random();
        
        MyDDL(Connection con) {
            this.con = con;
        }
        public void run()
        {
            long t0 = System.currentTimeMillis();
            long lastMs = t0;
            long intervalNumber = 0;
            long nextDDLMillis = t0 + (1000 * 60 * ddlMinutesDelay);
            boolean ddlCompleted = false;
            
            try {
                logMe("DDL thread : started");
                
                con = getConnection();

                Statement statement = (com.mysql.jdbc.Statement)con.createStatement();
                
                if (engineName == "tokudb")
                    statement.execute("set tokudb_disable_slow_alter=on");

                while ((shutItDown == 0) && !ddlCompleted)
                {
                    try {
                        Thread.sleep(1000);
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    
                    long now = System.currentTimeMillis();
                    if (now > nextDDLMillis)
                    {
                        lockDDL.lock();
                        try {
                            boolean bSuccess = false;
                            int iAttempt = 0;
                            
                            String thisDDL = "alter table purchases_index add column new_column bigint default 20 not null;";
                            while (! bSuccess) {
                                try {
                                    iAttempt++;
                                    logMe("DDL thread : performing : %s : attempt : %d",thisDDL,iAttempt);
                                    statement.execute(thisDDL);
                                    bSuccess = true;
                                    ddlCompleted = true;
                                } catch (Exception e) {
                                    logMe("DDL thread : EXCEPTION");
                                    e.printStackTrace();
                                    Thread.sleep(100);
                                }
                            }
                                
                            con.commit();
    
                            globalDDL.incrementAndGet();
                        } finally {
                            lockDDL.unlock();
                        }
                    }
                }

                logMe("DDL thread : shutting down");

                con.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }


    class MyQuery implements Runnable {
        Connection con; 
        int threadCount; 
        int threadNumber; 
        java.util.Random rand = new java.util.Random();
        
        MyQuery(Connection con, int threadCount, int threadNumber) {
            this.con = con;
            this.threadCount = threadCount;
            this.threadNumber = threadNumber;
        }
        public void run() {
            globalQueryThreads.incrementAndGet();

            try {
                logMe("Query thread %d : started",threadNumber);
                
                /*
                con = getConnection();
                con.setAutoCommit(true);

                Statement statement = (com.mysql.jdbc.Statement)con.createStatement();

                while (shutItDown == 0)
                {
                    // issue random query against random table
                    Integer whichTable = rand.nextInt(numTables) + 1;
                    Integer whichColumn = rand.nextInt(3) + 1;
                    Integer whichValue = rand.nextInt(numMaxTableValue) + 1;
                    String thisSelect = "select * from t" + whichTable.toString() + " where c" + whichColumn.toString() + " = " + whichValue.toString();

                    //logMe("Query thread %d : performing : %s",threadNumber,thisSelect);
                    
                    try {
                        ResultSet rs  = statement.executeQuery(thisSelect);
                    } catch (java.sql.SQLException e) {
                        logMe("Query thread %d : SQL EXCEPTION : error_code = %d",threadNumber,e.getErrorCode());
                    } catch (Exception e) {
                        logMe("Query thread %d : EXCEPTION",threadNumber);
                        e.printStackTrace();
                    }

                    //rs.last();
                    //int numRows = rs.getRow();
                    //if (numRows > 0) {
                    //    logMe("Query thread %d : found %,d rows",threadNumber,numRows);
                    //}

                    // TODO: point query vs. range query vs. others???

                    globalQueries.incrementAndGet();
                }

*/
                logMe("Query thread %d : shutting down",threadNumber);

                con.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
            
            globalQueryThreads.decrementAndGet();
        }
    }


    class MyWriter implements Runnable {
        Connection con; 
        int threadCount; 
        int threadNumber; 
        java.util.Random rand = new java.util.Random();
        
        MyWriter(Connection con, int threadCount, int threadNumber) {
            this.con = con;
            this.threadCount = threadCount;
            this.threadNumber = threadNumber;
        }
        public void run() {
            globalWriterThreads.incrementAndGet();
            
            Integer cashRegisterId = 0;
            Integer productId = 0;
            Integer customerId = 0;
            Float price = 0.0f;
            Timestamp ts = new Timestamp(new Date().getTime());
            int insertsThisSecond = 0;
            
            try {
                logMe("Writer thread %d : started",threadNumber);
                
                con = getConnection();

                PreparedStatement stmt = con.prepareStatement(insertString);

                long nextCheckMillis = System.currentTimeMillis() + 1000;

                while (shutItDown == 0)
                {
                    // check if we are going too fast
                    if ((insertsThisSecond >= maxInsertsPerSecond) && (maxInsertsPerSecond > 0)) {
                        long t0 = System.currentTimeMillis();
                        if (t0 > nextCheckMillis) {
                            nextCheckMillis = t0 + 1000;
                            insertsThisSecond = 0;
                        }
                        else
                        {
                            while (t0 < nextCheckMillis) {
                                // logMe("Running too fast, slowing down...");
                                try {
                                    Thread.sleep(5);
                                } catch (Exception e) {
                                    e.printStackTrace();
                                }
                                t0 = System.currentTimeMillis();
                            }
    
                            nextCheckMillis = t0 + 1000;
                            insertsThisSecond = 0;
                        }
                    }

                    if (lockDDL.isLocked()) {
                        logMe("DDL lock is held, writer thread %d skipping",threadNumber);
                        Thread.sleep(500);
                    }
                    else
                    {
                        boolean rolledBack = false;
                        String thisInsert = "insert into purchases_index (dateandtime,cashregisterid,customerid,productid,price) values ";
                        
                        try {
                            // insert random rows
                            for (int i=0; i<insertsPerBatch; i++) {
                                cashRegisterId = rand.nextInt(numCashRegisters) + 1;
                                productId = rand.nextInt(numProducts) + 1;
                                customerId = rand.nextInt(numCustomers) + 1;
                                price = ((rand.nextFloat() * maxPrice) + (float)customerId) / 100.0f;
                                ts = new Timestamp(new Date().getTime());

                                int col = 1;
                                stmt.setTimestamp(col++, ts);
                                stmt.setInt(col++, cashRegisterId);
                                stmt.setInt(col++, productId);
                                stmt.setInt(col++, customerId);
                                stmt.setFloat(col++, price);
                                stmt.addBatch();
                            }
                            //logMe("Writer thread %d : performing : %s",threadNumber,thisInsert);
                            stmt.executeBatch();
                        } catch (Exception e) {
                            logMe("Writer thread %d : EXCEPTION",threadNumber);
                            e.printStackTrace();
                            con.rollback();
                            rolledBack = true;
                        }

                        if (! rolledBack) {
                            con.commit();
                            globalInserts.addAndGet(insertsPerBatch);
                            insertsThisSecond += (long)insertsPerBatch;
                        }
                    }
                }

                logMe("Writer thread %d : shutting down",threadNumber);

                con.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
            
            globalWriterThreads.decrementAndGet();
        }
    }


    public static void logMe(String format, Object... args) {
        System.out.println(Thread.currentThread() + String.format(format, args));
    }
}

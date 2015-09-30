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

public class jtest {
    public static ReentrantLock lockDeleter = new ReentrantLock();
    public static AtomicInteger globalInserts = new AtomicInteger(0);
    public static AtomicInteger globalQueries = new AtomicInteger(0);
    public static AtomicInteger globalDeletes = new AtomicInteger(0);
    public static AtomicInteger globalQueryThreads = new AtomicInteger(0);
    public static AtomicInteger globalWriterThreads = new AtomicInteger(0);
    public static AtomicLong globalCurrentRowCount = new AtomicLong(0);
    public static AtomicLong globalCurrentC1 = new AtomicLong(0);
    public static Integer numTables;
    public static Integer maxTableSize;
    public static Integer numMaxTableValue;
    public static int minutesToRun = 0;
    public static long secondsPerFeedback;
    public static Writer writer = null;
    public static boolean outputHeader = true;
    public static String connectionUrl = "jdbc:mysql://localhost:3306/test";
    public static String connectionUser = "root";
    public static String connectionPassword = "";
    public static int queryThreads = 0;
    public static int writerThreads = 0;
    public static int shutItDown = 0;
    public static int deletePercent = 0;
    public static final String varcharData = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    public static final int varcharDataLength = varcharData.length();
    public static final int varcharLength = 120;
    public static final int insertsPerBatch = 1000;
    public static final int updatesPerBatch = 0;
    public static final int deletesPerBatch = 0;

    public jtest() {
    }

    public static void main (String[] args) throws Exception {
        if (args.length != 9) {
            logMe("*** ERROR : CONFIGURATION ISSUE ***");
            logMe("jtest [number of query threads] [number of writer threads] [number of tables] [max size per table] [deletion percent] [max table value] [seconds feedback] [minutes to run] [log file name]");
            System.exit(1);
        }

        queryThreads = Integer.valueOf(args[0]);
        writerThreads = Integer.valueOf(args[1]);
        numTables = Integer.valueOf(args[2]);
        maxTableSize = Integer.valueOf(args[3]);
        deletePercent = Integer.valueOf(args[4]);
        numMaxTableValue = Integer.valueOf(args[5]);
        secondsPerFeedback = Long.valueOf(args[6]);
        minutesToRun = Integer.valueOf(args[7]);
        String logFileName = args[8];

        logMe("Application Parameters");
        logMe("--------------------------------------------------");
        logMe("  %d query thread(s)",queryThreads);
        logMe("  %d writer thread(s)",writerThreads);
        logMe("  %,d table(s)",numTables);
        logMe("  %,d max table size",maxTableSize);
        logMe("  %,d delete percent",deletePercent);
        logMe("  %,d is maximum table value",numMaxTableValue);
        logMe("  Feedback every %,d seconds(s)",secondsPerFeedback);
        if (minutesToRun > 0)
            logMe("  Running for %,d minute(s)",minutesToRun);
        logMe("--------------------------------------------------");

        try {
            writer = new BufferedWriter(new FileWriter(new File(logFileName)));
        } catch (IOException e) {
            e.printStackTrace();
        }

        Class.forName("com.mysql.jdbc.Driver");

        /*
        logMe("Warming things up...");
        Connection conWarmup = getConnection();
        Statement statement = (com.mysql.jdbc.Statement)conWarmup.createStatement();
        
        for (Integer i=1; i<=numTables; i++) {
            logMe("table %d",i);
            statement.execute("select count(*) from sbtest" + i.toString());
        }
        conWarmup.close();
        */

        Connection con = null;
        
        jtest t = new jtest();
        
        Thread[] tQueryThreads = new Thread[queryThreads];
        for (int i=0; i<queryThreads; i++) {
            tQueryThreads[i] = new Thread(t.new MyQuery(con, queryThreads, i, numTables, numMaxTableValue));
            tQueryThreads[i].start();
        }

        Thread[] tWriterThreads = new Thread[writerThreads];
        for (int i=0; i<writerThreads; i++) {
            tWriterThreads[i] = new Thread(t.new MyWriter(con, writerThreads, i, numTables, numMaxTableValue));
            tWriterThreads[i].start();
        }
        
        Thread deleteThread = new Thread(t.new MyDelete(con));
        deleteThread.start();

        Thread reporterThread = new Thread(t.new MyReporter());
        reporterThread.start();
        reporterThread.join();
        shutItDown = 1;

        // join delete thread, it will terminate itself
        if (deleteThread.isAlive())
            deleteThread.join();

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
            int lastInserts = 0;
            int lastQueries = 0;
            long lastMs = t0;
            long intervalNumber = 0;
            long nextFeedbackMillis = t0 + (1000 * secondsPerFeedback * (intervalNumber + 1));
            long runEndMillis = Long.MAX_VALUE;
            if (minutesToRun > 0)
                runEndMillis = t0 + (1000 * 60 * minutesToRun);

            while (System.currentTimeMillis() < runEndMillis)
            {
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
                    
                    int thisInserts = globalInserts.get();
                    int thisQueries = globalQueries.get();
                    int thisDeletes = globalDeletes.get();

                    int thisIntervalInserts = thisInserts - lastInserts;
                    int thisIntervalQueries = thisQueries - lastQueries;

                    double thisIntervalInsertsPerSecond = thisIntervalInserts/(double)thisIntervalMs*1000.0;
                    double thisIntervalQueriesPerSecond = thisIntervalQueries/(double)thisIntervalMs*1000.0;

                    double thisInsertsPerSecond = thisInserts/(double)elapsed*1000.0;
                    double thisQueriesPerSecond = thisQueries/(double)elapsed*1000.0;
                    
                    logMe("%,d seconds, cum xps=%,.2f, int xps=%,.2f, cum qps=%,.2f, int qps=%,.2f, size=%,d, deletes=%,d", elapsed / 1000l, thisInsertsPerSecond, thisIntervalInsertsPerSecond, thisQueriesPerSecond, thisIntervalQueriesPerSecond, globalCurrentRowCount.get(), thisDeletes);
                    
                    try {
                        if (outputHeader)
                        {
                            writer.write("elap_secs\tcum_xps\tint_xps\tcum_qps\tint_qps\n");
                            outputHeader = false;
                        }
                            
                        String statusUpdate = String.format("%d\t%.2f\t%.2f\t%.2f\t%.2f\t%,d\t%,d\n",elapsed / 1000l, thisInsertsPerSecond, thisIntervalInsertsPerSecond, thisQueriesPerSecond, thisIntervalQueriesPerSecond, globalCurrentRowCount.get(), thisDeletes);
                        writer.write(statusUpdate);
                        writer.flush();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }

                    lastInserts = thisInserts;
                    lastQueries = thisQueries;

                    lastMs = now;
                }
            }
        }
    }
    
    
    // delete a percentage of the table when we reach maximum size
    //tmc
    class MyDelete implements Runnable {
        Connection con; 
        java.util.Random rand = new java.util.Random();
        
        MyDelete(Connection con) {
            this.con = con;
        }
        public void run()
        {
            try {
                logMe("Delete thread : started");
                
                con = getConnection();

                Statement statement = (com.mysql.jdbc.Statement)con.createStatement();
                
                //statement.execute("set tokudb_create_index_online=on");
                //statement.execute("set tokudb_disable_slow_alter=on");

                while (shutItDown == 0)
                {
                    try {
                        Thread.sleep(1000);
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    
                    Long currentRowCount = globalCurrentRowCount.get();
                    if (currentRowCount >= maxTableSize)
                    {
                        Integer deleteWhere = (int) globalCurrentC1.get() - (int) ((double) currentRowCount * (double) (100 - deletePercent) / (double) 100.0);
                        long numDeletedRows = (long) ((double) currentRowCount * (double) deletePercent / (double) 100.0);
                        globalCurrentRowCount.addAndGet(-1 * numDeletedRows);
                       
                        lockDeleter.lock();
                        try {
                            boolean bSuccess = false;
                            int iAttempt = 0;
                            
                            // drop an index from a random table
                            Integer whichTable = rand.nextInt(numTables) + 1;
                            
                            String thisDDL = "delete from t" + whichTable.toString() + " where c1 <= " + deleteWhere.toString();
                            while (! bSuccess) {
                                try {
                                    iAttempt++;
                                    logMe("Delete thread : performing : %s : attempt : %d",thisDDL,iAttempt);
                                    statement.execute(thisDDL);
                                    bSuccess = true;
                                } catch (Exception e) {
                                    logMe("DDL thread : EXCEPTION");
                                    e.printStackTrace();
                                    Thread.sleep(100);
                                }
                            }
                                
                            con.commit();
    
                            globalDeletes.incrementAndGet();
                        } finally {
                            lockDeleter.unlock();
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
        int numTables;
        int numMaxTableValue;
        java.util.Random rand = new java.util.Random();
        
        MyQuery(Connection con, int threadCount, int threadNumber, int numTables, int numMaxTableValue) {
            this.con = con;
            this.threadCount = threadCount;
            this.threadNumber = threadNumber;
            this.numTables = numTables;
            this.numMaxTableValue = numMaxTableValue;
        }
        public void run() {
            globalQueryThreads.incrementAndGet();

            try {
                logMe("Query thread %d : started",threadNumber);
                
                con = getConnection();
                con.setAutoCommit(true);

                Statement statement = (com.mysql.jdbc.Statement)con.createStatement();

                while (shutItDown == 0)
                {
                    // issue random query against random table
                    Integer whichTable = rand.nextInt(numTables) + 1;
                    Integer whichColumn = rand.nextInt(1) + 2;
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

                    // sleep?
                    Thread.sleep(50);
                }

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
        int numTables;
        int numMaxTableValue;
        java.util.Random rand = new java.util.Random();
        
        MyWriter(Connection con, int threadCount, int threadNumber, int numTables, int numMaxTableValue) {
            this.con = con;
            this.threadCount = threadCount;
            this.threadNumber = threadNumber;
            this.numTables = numTables;
            this.numMaxTableValue = numMaxTableValue;
        }
        public void run() {
            globalWriterThreads.incrementAndGet();

            try {
                logMe("Writer thread %d : started",threadNumber);
                
                con = getConnection();

                Statement statement = (com.mysql.jdbc.Statement)con.createStatement();

                while (shutItDown == 0)
                {
                    if (false) {
                    //if (lockDeleter.isLocked()) {
                        logMe("DDL lock is held, writer thread %d skipping",threadNumber);
                        Thread.sleep(500);
                    }
                    else
                    {
                        boolean rolledBack = false;
                        
                        try {
                            // insert random rows
                            for (int i=0; i<insertsPerBatch; i++) {
                                Integer whichTable = rand.nextInt(numTables) + 1;
                                Integer valC2 = rand.nextInt(numMaxTableValue) + 1;
                                Integer valC3 = rand.nextInt(numMaxTableValue) + 1;
                                StringBuilder valC4 = new StringBuilder(varcharLength);
                                for(int x=0;x<varcharLength;x++) 
                                    valC4.append(varcharData.charAt(rand.nextInt(varcharDataLength)));
                                String thisInsert = "insert into t" + whichTable.toString() + " (c2,c3,c4) values (" + valC2.toString() + "," + valC3.toString() + ",'" + valC4.toString() + "')";
                                //logMe("Writer thread %d : performing : %s",threadNumber,thisInsert);
                                statement.execute(thisInsert);
                            }

                            // update random rows
                            for (int i=0; i<updatesPerBatch; i++) {
                                Integer oldC2 = rand.nextInt(numMaxTableValue) + 1;
                                Integer whichTable = rand.nextInt(numTables) + 1;
                                Integer valC2 = rand.nextInt(numMaxTableValue) + 1;
                                StringBuilder valC4 = new StringBuilder(varcharLength);
                                for(int x=0;x<varcharLength;x++) 
                                    valC4.append(varcharData.charAt(rand.nextInt(varcharDataLength)));
                                String thisUpdate = "update t" + whichTable.toString() + " set c2=" + valC2.toString() + ", c3=c3+1, c4='" + valC4.toString() + "' where c2=" + oldC2.toString();
                                //logMe("Writer thread %d : performing : %s",threadNumber,thisUpdate);
                                statement.execute(thisUpdate);
                            }
    
                            // delete random rows
                            for (int i=0; i<deletesPerBatch; i++) {
                                Integer oldC2 = rand.nextInt(numMaxTableValue) + 1;
                                Integer whichTable = rand.nextInt(numTables) + 1;
                                String thisDelete = "delete from t" + whichTable.toString() + " where c2=" + oldC2.toString();
                                //logMe("Writer thread %d : performing : %s",threadNumber,thisDelete);
                                statement.execute(thisDelete);
                            }
                        } catch (Exception e) {
                            logMe("Writer thread %d : EXCEPTION",threadNumber);
                            e.printStackTrace();
                            con.rollback();
                            rolledBack = true;
                        }

                        if (! rolledBack) {
                            con.commit();
                            globalInserts.addAndGet(insertsPerBatch+updatesPerBatch+deletesPerBatch);
                            globalCurrentRowCount.addAndGet(insertsPerBatch);
                            globalCurrentC1.addAndGet(insertsPerBatch);
                        }
                    }

                    // sleep?
                    Thread.sleep(50);
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

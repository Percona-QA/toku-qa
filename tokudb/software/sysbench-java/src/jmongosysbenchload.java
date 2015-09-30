//import com.mongodb.Mongo;
import com.mongodb.MongoClient;
import com.mongodb.MongoClientOptions;
import com.mongodb.DB;
import com.mongodb.DBCollection;
import com.mongodb.DBCursor;
import com.mongodb.BasicDBObject;
import com.mongodb.DBObject;
import com.mongodb.DBCursor;
import com.mongodb.ServerAddress;
import com.mongodb.WriteConcern;
import com.mongodb.CommandResult;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.Types;

import java.util.Arrays;
import java.util.ArrayList;
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

public class jmongosysbenchload {
    public static AtomicLong globalInserts = new AtomicLong(0);
    public static AtomicLong globalWriterThreads = new AtomicLong(0);
    
    public static Writer writer = null;
    public static boolean outputHeader = true;

    public static int numCollections;
    public static String dbName;
    public static int writerThreads;
    public static Integer numMaxInserts;
    public static int documentsPerInsert;
    public static long insertsPerFeedback;
    public static long secondsPerFeedback;
    public static String logFileName;
    public static String indexTechnology;
    public static String mysqlPort;
    
    public static int allDone = 0;
    
    public jmongosysbenchload() {
    }

    public static void main (String[] args) throws Exception {
        if (args.length != 9) {
            logMe("*** ERROR : CONFIGURATION ISSUE ***");
            logMe("jsysbenchload [number of collections] [database name] [number of writer threads] [documents per collection] [documents per insert] [inserts feedback] [seconds feedback] [log file name] [mysql port]");
            System.exit(1);
        }
        
        numCollections = Integer.valueOf(args[0]);
        dbName = args[1];
        writerThreads = Integer.valueOf(args[2]);
        numMaxInserts = Integer.valueOf(args[3]);
        documentsPerInsert = Integer.valueOf(args[4]);
        insertsPerFeedback = Long.valueOf(args[5]);
        secondsPerFeedback = Long.valueOf(args[6]);
        logFileName = args[7];
        mysqlPort = args[8];
        
        logMe("Application Parameters");
        logMe("--------------------------------------------------");
        logMe("  %d collections",numCollections);
        logMe("  database name = %s",dbName);
        logMe("  %d writer thread(s)",writerThreads);
        logMe("  %,d documents per collection",numMaxInserts);
        logMe("  Documents Per Insert = %d",documentsPerInsert);
        logMe("  Feedback every %,d seconds(s)",secondsPerFeedback);
        logMe("  Feedback every %,d inserts(s)",insertsPerFeedback);
        logMe("  logging to file %s",logFileName);
        logMe("  MySQL Port= %s",mysqlPort);
        logMe("--------------------------------------------------");

        try {
            // The newInstance() call is a work around for some broken Java implementations
            Class.forName("com.mysql.jdbc.Driver").newInstance();
        } catch (Exception ex) {
            // handle the error
            ex.printStackTrace();
        }
        
        try {
            writer = new BufferedWriter(new FileWriter(new File(logFileName)));
        } catch (IOException e) {
            e.printStackTrace();
        }

        jmongosysbenchload t = new jmongosysbenchload();

        Thread reporterThread = new Thread(t.new MyReporter());
        reporterThread.start();

        Thread[] tWriterThreads = new Thread[writerThreads];
        
        for (int collectionNumber = 0; collectionNumber < numCollections; collectionNumber++) {
            // if necessary, wait for an available slot for this loader
            boolean waitingForSlot = true;
            while (globalWriterThreads.get() >= writerThreads) {
                if (waitingForSlot) {
                    logMe("  collection %d is waiting for an available loader slot",collectionNumber+1);
                    waitingForSlot = false;
                }
                try {
                    Thread.sleep(5000);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }

            // start the loader
            for (int i=0; i<writerThreads; i++) {
                if ((tWriterThreads[i] == null) || (!tWriterThreads[i].isAlive())) {
                    globalWriterThreads.incrementAndGet();
                    tWriterThreads[i] = new Thread(t.new MyWriter(collectionNumber+1, writerThreads, i, numMaxInserts));
                    tWriterThreads[i].start();
                    break;
                }
            }

        }

        // sleep a bit, then wait for all the writers to complete
        try {
            Thread.sleep(10000);
        } catch (Exception e) {
            e.printStackTrace();
        }
        while (globalWriterThreads.get() > 0) {
            try {
                Thread.sleep(5000);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        // all the writers are finished
        allDone = 1;
        
        if (reporterThread.isAlive())
            reporterThread.join();
        
        try {
            if (writer != null) {
                writer.close();
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        
        logMe("Done!");
    }
    
    class MyWriter implements Runnable {
        int collectionNumber;
        int threadCount; 
        int threadNumber; 
        int numTables;
        int numMaxInserts;
        
        java.util.Random rand;
        
        MyWriter(int collectionNumber, int threadCount, int threadNumber, int numMaxInserts) {
            this.collectionNumber = collectionNumber;
            this.threadCount = threadCount;
            this.threadNumber = threadNumber;
            this.numMaxInserts = numMaxInserts;
            rand = new java.util.Random((long) collectionNumber);
        }
        public void run() {
            String tableName = "sbtest" + Integer.toString(collectionNumber);

            Connection conn = null;
            PreparedStatement pstmt = null;
            
            try {
                conn = DriverManager.getConnection("jdbc:mysql://localhost:"+mysqlPort+"/"+dbName+"?user=root&password=&rewriteBatchedStatements=true");
                pstmt = conn.prepareStatement("INSERT INTO "+tableName+"(k,c,pad) VALUES (?, ?, ?)");
            } catch (SQLException ex) {
                // handle any errors
                System.out.println("SQLException: " + ex.getMessage());
                System.out.println("SQLState: " + ex.getSQLState());
                System.out.println("VendorError: " + ex.getErrorCode());
            }

            long numInserts = 0;

            try {
                logMe("Writer thread %d : started to load table %s",threadNumber, tableName);
                
                conn.setAutoCommit(false);
                
                int numRounds = numMaxInserts / documentsPerInsert;
                
                for (int roundNum = 0; roundNum < numRounds; roundNum++) {
                    for (int i = 0; i < documentsPerInsert; i++) {
                        int kVal = rand.nextInt(numMaxInserts)+1;
                        String cVal = sysbenchString(rand, "###########-###########-###########-###########-###########-###########-###########-###########-###########-###########");
                        String padVal = sysbenchString(rand, "###########-###########-###########-###########-###########");
                        
                        pstmt.setObject(1, kVal, Types.INTEGER);
                        pstmt.setObject(2, cVal, Types.VARCHAR);
                        pstmt.setObject(3, padVal, Types.VARCHAR);
                        pstmt.addBatch();
                    }
                    
                    pstmt.executeBatch();
                    conn.commit();

                    numInserts += documentsPerInsert;
                    globalInserts.addAndGet(documentsPerInsert);
                }

            } catch (Exception e) {
                logMe("Writer thread %d : EXCEPTION",threadNumber);
                e.printStackTrace();
            }
            
            globalWriterThreads.decrementAndGet();
        }
    }
    
    
    
    public static String sysbenchString(java.util.Random rand, String thisMask) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0, n = thisMask.length() ; i < n ; i++) { 
            char c = thisMask.charAt(i); 
            if (c == '#') {
                sb.append(String.valueOf(rand.nextInt(10)));
            } else if (c == '@') {
                sb.append((char) (rand.nextInt(26) + 'a'));
            } else {
                sb.append(c);
            }
        }
        return sb.toString();
    }


    // reporting thread, outputs information to console and file
    class MyReporter implements Runnable {
        public void run()
        {
            long t0 = System.currentTimeMillis();
            long lastInserts = 0;
            long lastMs = t0;
            long intervalNumber = 0;
            long nextFeedbackMillis = t0 + (1000 * secondsPerFeedback * (intervalNumber + 1));
            long nextFeedbackInserts = lastInserts + insertsPerFeedback;
            long thisInserts = 0;

            while (allDone == 0)
            {
                try {
                    Thread.sleep(100);
                } catch (Exception e) {
                    e.printStackTrace();
                }
                
                long now = System.currentTimeMillis();
                thisInserts = globalInserts.get();
                if (((now > nextFeedbackMillis) && (secondsPerFeedback > 0)) ||
                    ((thisInserts >= nextFeedbackInserts) && (insertsPerFeedback > 0)))
                {
                    intervalNumber++;
                    nextFeedbackMillis = t0 + (1000 * secondsPerFeedback * (intervalNumber + 1));
                    nextFeedbackInserts = (intervalNumber + 1) * insertsPerFeedback;

                    long elapsed = now - t0;
                    long thisIntervalMs = now - lastMs;
                    
                    long thisIntervalInserts = thisInserts - lastInserts;
                    double thisIntervalInsertsPerSecond = thisIntervalInserts/(double)thisIntervalMs*1000.0;
                    double thisInsertsPerSecond = thisInserts/(double)elapsed*1000.0;
                    
                    if (secondsPerFeedback > 0)
                    {
                        logMe("%,d inserts : %,d seconds : cum ips=%,.2f : int ips=%,.2f", thisInserts, elapsed / 1000l, thisInsertsPerSecond, thisIntervalInsertsPerSecond);
                    } else {
                        logMe("%,d inserts : %,d seconds : cum ips=%,.2f : int ips=%,.2f", intervalNumber * insertsPerFeedback, elapsed / 1000l, thisInsertsPerSecond, thisIntervalInsertsPerSecond);
                    }
                    
                    try {
                        if (outputHeader)
                        {
                            writer.write("tot_inserts\telap_secs\tcum_ips\tint_ips\n");
                            outputHeader = false;
                        }
                            
                        String statusUpdate = "";
                        
                        if (secondsPerFeedback > 0)
                        {
                            statusUpdate = String.format("%d\t%d\t%.2f\t%.2f\n",thisInserts, elapsed / 1000l, thisInsertsPerSecond, thisIntervalInsertsPerSecond);
                        } else {
                            statusUpdate = String.format("%d\t%d\t%.2f\t%.2f\n",intervalNumber * insertsPerFeedback, elapsed / 1000l, thisInsertsPerSecond, thisIntervalInsertsPerSecond);
                        }
                        writer.write(statusUpdate);
                        writer.flush();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }

                    lastInserts = thisInserts;

                    lastMs = now;
                }
            }
            
            // output final numbers...
            long now = System.currentTimeMillis();
            thisInserts = globalInserts.get();
            intervalNumber++;
            nextFeedbackMillis = t0 + (1000 * secondsPerFeedback * (intervalNumber + 1));
            nextFeedbackInserts = (intervalNumber + 1) * insertsPerFeedback;
            long elapsed = now - t0;
            long thisIntervalMs = now - lastMs;
            long thisIntervalInserts = thisInserts - lastInserts;
            double thisIntervalInsertsPerSecond = thisIntervalInserts/(double)thisIntervalMs*1000.0;
            double thisInsertsPerSecond = thisInserts/(double)elapsed*1000.0;
            if (secondsPerFeedback > 0)
            {
                logMe("%,d inserts : %,d seconds : cum ips=%,.2f : int ips=%,.2f", thisInserts, elapsed / 1000l, thisInsertsPerSecond, thisIntervalInsertsPerSecond);
            } else {
                logMe("%,d inserts : %,d seconds : cum ips=%,.2f : int ips=%,.2f", intervalNumber * insertsPerFeedback, elapsed / 1000l, thisInsertsPerSecond, thisIntervalInsertsPerSecond);
            }
            try {
                if (outputHeader)
                {
                    writer.write("tot_inserts\telap_secs\tcum_ips\tint_ips\n");
                    outputHeader = false;
                }
                String statusUpdate = "";
                if (secondsPerFeedback > 0)
                {
                    statusUpdate = String.format("%d\t%d\t%.2f\t%.2f\n",thisInserts, elapsed / 1000l, thisInsertsPerSecond, thisIntervalInsertsPerSecond);
                } else {
                    statusUpdate = String.format("%d\t%d\t%.2f\t%.2f\n",intervalNumber * insertsPerFeedback, elapsed / 1000l, thisInsertsPerSecond, thisIntervalInsertsPerSecond);
                }
                writer.write(statusUpdate);
                writer.flush();
            } catch (IOException e) {
                e.printStackTrace();
            }
            
        }
    }


    public static void logMe(String format, Object... args) {
        System.out.println(Thread.currentThread() + String.format(format, args));
    }
}

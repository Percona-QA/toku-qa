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
import com.mongodb.AggregationOutput;
import com.mongodb.WriteResult;

import java.util.Arrays;
import java.util.ArrayList;
import java.util.Date;
import java.util.Properties;
import java.util.List;
import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.File;
import java.io.Writer;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.locks.ReentrantLock;

public class jmongosysbenchexecute {
    public static AtomicLong globalInserts = new AtomicLong(0);
    public static AtomicLong globalDeletes = new AtomicLong(0);
    public static AtomicLong globalUpdates = new AtomicLong(0);
    public static AtomicLong globalPointQueries = new AtomicLong(0);
    public static AtomicLong globalRangeQueries = new AtomicLong(0);
    public static AtomicLong globalSysbenchTransactions = new AtomicLong(0);
    public static AtomicLong globalWriterThreads = new AtomicLong(0);
    
    public static Writer writer = null;
    public static boolean outputHeader = true;

    public static int numCollections;
    public static String dbName;
    public static int writerThreads;
    public static Integer numMaxInserts;
    public static long secondsPerFeedback;
    public static String logFileName;
    public static String indexTechnology;
    public static String readOnly;
    public static int runSeconds;
    public static String myWriteConcern;
    public static Integer maxTPS;
    public static Integer maxThreadTPS;
    public static String serverName;
    public static int serverPort;
    
    public static int oltpRangeSize;
    public static int oltpPointSelects;
    public static int oltpSimpleRanges;
    public static int oltpSumRanges;
    public static int oltpOrderRanges;
    public static int oltpDistinctRanges;
    public static int oltpIndexUpdates;
    public static int oltpNonIndexUpdates;
    
    public static int numCompressibleCharacters = 3*1024;
    public static int numUncompressibleCharacters = 1*1024;
    public static int lengthCharField = numCompressibleCharacters + numUncompressibleCharacters;
    
    public static int randomStringLength = 16*1024*1024;
    public static String randomStringHolder;
    public static int compressibleStringLength =  16*1024*1024;
    public static String compressibleStringHolder;

    public static boolean bIsTokuMX = false;
    
    public static int allDone = 0;
    
    public jmongosysbenchexecute() {
    }

    public static void main (String[] args) throws Exception {
        if (args.length != 20) {
            logMe("*** ERROR : CONFIGURATION ISSUE ***");
            logMe("jsysbenchexecute [number of collections] [database name] [number of writer threads] [documents per collection] [seconds feedback] "+
                                   "[log file name] [read only Y/N] [runtime (seconds)] [range size] [point selects] "+
                                   "[simple ranges] [sum ranges] [order ranges] [distinct ranges] [index updates] [non index updates] [writeconcern] [max tps] [server] [port]");
            System.exit(1);
        }
        
        numCollections = Integer.valueOf(args[0]);
        dbName = args[1];
        writerThreads = Integer.valueOf(args[2]);
        numMaxInserts = Integer.valueOf(args[3]);
        secondsPerFeedback = Long.valueOf(args[4]);
        logFileName = args[5];
        readOnly = args[6];
        runSeconds = Integer.valueOf(args[7]);
        oltpRangeSize = Integer.valueOf(args[8]);
        oltpPointSelects = Integer.valueOf(args[9]);
        oltpSimpleRanges = Integer.valueOf(args[10]);
        oltpSumRanges = Integer.valueOf(args[11]);
        oltpOrderRanges = Integer.valueOf(args[12]);
        oltpDistinctRanges = Integer.valueOf(args[13]);
        oltpIndexUpdates = Integer.valueOf(args[14]);
        oltpNonIndexUpdates = Integer.valueOf(args[15]);
        myWriteConcern = args[16];
        maxTPS = Integer.valueOf(args[17]);
        serverName = args[18];
        serverPort = Integer.valueOf(args[19]);

        maxThreadTPS = (maxTPS / writerThreads) + 1;
        
        WriteConcern myWC = new WriteConcern();
        if (myWriteConcern.toLowerCase().equals("fsync_safe")) {
            myWC = WriteConcern.FSYNC_SAFE;
        }
        else if ((myWriteConcern.toLowerCase().equals("none"))) {
            myWC = WriteConcern.NONE;
        }
        else if ((myWriteConcern.toLowerCase().equals("normal"))) {
            myWC = WriteConcern.NORMAL;
        }
        else if ((myWriteConcern.toLowerCase().equals("replicas_safe"))) {
            myWC = WriteConcern.REPLICAS_SAFE;
        }
        else if ((myWriteConcern.toLowerCase().equals("safe"))) {
            myWC = WriteConcern.SAFE;
        } 
        else {
            logMe("*** ERROR : WRITE CONCERN ISSUE ***");
            logMe("  write concern %s is not supported",myWriteConcern);
            System.exit(1);
        }
    
        logMe("Application Parameters");
        logMe("-------------------------------------------------------------------------------------------------");
        logMe("  collections              = %d",numCollections);
        logMe("  database name            = %s",dbName);
        logMe("  writer threads           = %d",writerThreads);
        logMe("  documents per collection = %,d",numMaxInserts);
        logMe("  feedback seconds         = %,d",secondsPerFeedback);
        logMe("  log file                 = %s",logFileName);
        logMe("  read only                = %s",readOnly);
        logMe("  run seconds              = %d",runSeconds);
        logMe("  oltp range size          = %d",oltpRangeSize);
        logMe("  oltp point selects       = %d",oltpPointSelects);
        logMe("  oltp simple ranges       = %d",oltpSimpleRanges);
        logMe("  oltp sum ranges          = %d",oltpSumRanges);
        logMe("  oltp order ranges        = %d",oltpOrderRanges);
        logMe("  oltp distinct ranges     = %d",oltpDistinctRanges);
        logMe("  oltp index updates       = %d",oltpIndexUpdates);
        logMe("  oltp non index updates   = %d",oltpNonIndexUpdates);
        logMe("  write concern            = %s",myWriteConcern);
        logMe("  maximum tps (global)     = %d",maxTPS);
        logMe("  maximum tps (per thread) = %d",maxThreadTPS);
        logMe("  Server:Port = %s:%d",serverName,serverPort);

        MongoClientOptions clientOptions = new MongoClientOptions.Builder().connectionsPerHost(2048).socketTimeout(60000).writeConcern(myWC).build();
        ServerAddress srvrAdd = new ServerAddress(serverName,serverPort);
        MongoClient m = new MongoClient(srvrAdd, clientOptions);

        logMe("mongoOptions | " + m.getMongoOptions().toString());
        logMe("mongoWriteConcern | " + m.getWriteConcern().toString());

        DB db = m.getDB(dbName);

        // determine server type : mongo or tokumx
        DBObject checkServerCmd = new BasicDBObject();
        CommandResult commandResult = db.command("buildInfo");

        // check if tokumxVersion exists, otherwise assume mongo
        if (commandResult.toString().contains("tokumxVersion")) {
            indexTechnology = "tokumx";
        }
        else
        {
            indexTechnology = "mongo";
        }

        logMe("  index technology         = %s",indexTechnology);
        logMe("-------------------------------------------------------------------------------------------------");

        try {
            writer = new BufferedWriter(new FileWriter(new File(logFileName)));
        } catch (IOException e) {
            e.printStackTrace();
        }

        if ((!indexTechnology.toLowerCase().equals("tokumx")) && (!indexTechnology.toLowerCase().equals("mongo"))) {
            // unknown index technology, abort
            logMe(" *** Unknown Indexing Technology %s, shutting down",indexTechnology);
            System.exit(1);
        }
        
        if (indexTechnology.toLowerCase().equals("tokumx")) {
            bIsTokuMX = true;
        }
        
        java.util.Random rand = new java.util.Random();

        // create random string holder
        logMe("  creating %,d bytes of random character data...",randomStringLength);
        char[] tempString = new char[randomStringLength];
        for (int i = 0 ; i < randomStringLength ; i++) { 
            tempString[i] = (char) (rand.nextInt(26) + 'a');
        }
        randomStringHolder = new String(tempString);

        // create compressible string holder
        logMe("  creating %,d bytes of compressible character data...",compressibleStringLength);
        char[] tempStringCompressible = new char[compressibleStringLength];
        for (int i = 0 ; i < compressibleStringLength ; i++) { 
            tempStringCompressible[i] = 'a';
        }
        compressibleStringHolder = new String(tempStringCompressible);

        jmongosysbenchexecute t = new jmongosysbenchexecute();

        Thread[] tWriterThreads = new Thread[writerThreads];
        
        for (int i=0; i<writerThreads; i++) {
            tWriterThreads[i] = new Thread(t.new MyWriter(writerThreads, i, numMaxInserts, db, numCollections));
            tWriterThreads[i].start();
        }
        
        Thread reporterThread = new Thread(t.new MyReporter());
        reporterThread.start();
        reporterThread.join();

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
        
        m.close();
        
        long totalSysbenchTransactions = globalSysbenchTransactions.get();
        logMe("total: %,d operations", totalSysbenchTransactions);
        
        logMe("Done!");
    }
    
    class MyWriter implements Runnable {
        int threadCount; 
        int threadNumber; 
        int numTables;
        int numMaxInserts;
        int numCollections;
        DB db;
        
        long numInserts = 0;
        long numDeletes = 0;
        long numUpdates = 0;
        long numPointQueries = 0;
        long numRangeQueries = 0;
        
        java.util.Random rand;
        
        MyWriter(int threadCount, int threadNumber, int numMaxInserts, DB db, int numCollections) {
            this.threadCount = threadCount;
            this.threadNumber = threadNumber;
            this.numMaxInserts = numMaxInserts;
            this.db = db;
            this.numCollections = numCollections;
            rand = new java.util.Random((long) threadNumber);
        }
        public void run() {
            logMe("Writer thread %d : started",threadNumber);
            globalWriterThreads.incrementAndGet();

            long numTransactions = 0;
            long numLastTransactions = 0;
            long nextMs = System.currentTimeMillis() + 1000;
            
            while (allDone == 0) {
                if ((numTransactions - numLastTransactions) >= maxThreadTPS) {
                    // pause until a second has passed
                    while (System.currentTimeMillis() < nextMs) {
                        try {
                            Thread.sleep(20);
                        } catch (Exception e) {
                            e.printStackTrace();
                        }
                    }
                    numLastTransactions = numTransactions;
                    nextMs = System.currentTimeMillis() + 1000;
                }

                String collectionName = "sbtest" + Integer.toString(rand.nextInt(numCollections)+1);
                DBCollection coll = db.getCollection(collectionName);
                
                try {
                    if (readOnly.toLowerCase().equals("n")) {
                        for (int i=1; i <= oltpNonIndexUpdates; i++) {
                            int startId = rand.nextInt(numMaxInserts)+1;
                            //int startPosition = rand.nextInt(randomStringLength-lengthCharField);
                            //String cVal = randomStringHolder.substring(startPosition,startPosition+numUncompressibleCharacters) + compressibleStringHolder.substring(startPosition,startPosition+numCompressibleCharacters);
                            //WriteResult wrUpdate = coll.update(new BasicDBObject("_id", startId), new BasicDBObject("$set", new BasicDBObject("c",cVal)), false, false);
                            WriteResult wrUpdate = coll.update(new BasicDBObject("_id", startId), new BasicDBObject("$inc", new BasicDBObject("counter",1)), false, false);
                        }
                    }
                
                    globalSysbenchTransactions.incrementAndGet();
                    numTransactions += 1;
               
                } finally {
                }
            }

            //} catch (Exception e) {
            //    logMe("Writer thread %d : EXCEPTION",threadNumber);
            //    e.printStackTrace();
            //}
            
            globalWriterThreads.decrementAndGet();
        }
    }
    
    
    public static String sysbenchString(java.util.Random rand, String thisMask) {
        String returnString = "";
        for (int i = 0, n = thisMask.length() ; i < n ; i++) { 
            char c = thisMask.charAt(i); 
            if (c == '#') {
                returnString += String.valueOf(rand.nextInt(10));
            } else if (c == '@') {
                returnString += (char) (rand.nextInt(26) + 'a');
            } else {
                returnString += c;
            }
        }
        return returnString;
    }


    // reporting thread, outputs information to console and file
    class MyReporter implements Runnable {
        public void run()
        {
            long t0 = System.currentTimeMillis();
            long lastInserts = 0;
            long thisInserts = 0;
            long lastDeletes = 0;
            long thisDeletes = 0;
            long lastUpdates = 0;
            long thisUpdates = 0;
            long lastPointQueries = 0;
            long thisPointQueries = 0;
            long lastRangeQueries = 0;
            long thisRangeQueries = 0;
            long lastSysbenchTransactions = 0;
            long thisSysbenchTransactions = 0;
            long lastMs = t0;
            long intervalNumber = 0;
            long nextFeedbackMillis = t0 + (1000 * secondsPerFeedback * (intervalNumber + 1));
            long runEndMillis = Long.MAX_VALUE;
            if (runSeconds > 0)
                runEndMillis = t0 + (1000 * runSeconds);
            
            while ((System.currentTimeMillis() < runEndMillis) && (thisInserts < numMaxInserts))
            {
                try {
                    Thread.sleep(100);
                } catch (Exception e) {
                    e.printStackTrace();
                }
                
                long now = System.currentTimeMillis();
                
                
//    public static AtomicLong globalDeletes = new AtomicLong(0);
//    public static AtomicLong globalUpdates = new AtomicLong(0);
//    public static AtomicLong globalPointQueries = new AtomicLong(0);
//    public static AtomicLong globalRangeQueries = new AtomicLong(0);

                
                thisInserts = globalInserts.get();
                thisSysbenchTransactions = globalSysbenchTransactions.get();
                
                if ((now > nextFeedbackMillis) && (secondsPerFeedback > 0))
                {
                    intervalNumber++;
                    nextFeedbackMillis = t0 + (1000 * secondsPerFeedback * (intervalNumber + 1));

                    long elapsed = now - t0;
                    long thisIntervalMs = now - lastMs;

                    long thisIntervalSysbenchTransactions = thisSysbenchTransactions - lastSysbenchTransactions;
                    double thisIntervalSysbenchTransactionsPerSecond = thisIntervalSysbenchTransactions/(double)thisIntervalMs*1000.0;
                    double thisSysbenchTransactionsPerSecond = thisSysbenchTransactions/(double)elapsed*1000.0;

                    long thisIntervalInserts = thisInserts - lastInserts;
                    double thisIntervalInsertsPerSecond = thisIntervalInserts/(double)thisIntervalMs*1000.0;
                    double thisInsertsPerSecond = thisInserts/(double)elapsed*1000.0;
                    
                    logMe("%,d seconds : cum tps=%,.2f : int tps=%,.2f : cum ips=%,.2f : int ips=%,.2f", elapsed / 1000l, thisSysbenchTransactionsPerSecond, thisIntervalSysbenchTransactionsPerSecond, thisInsertsPerSecond, thisIntervalInsertsPerSecond);
                    
                    try {
                        if (outputHeader)
                        {
                            writer.write("elap_secs\tcum_tps\tint_tps\tcum_ips\tint_ips\n");
                            outputHeader = false;
                        }
                            
                        String statusUpdate = "";
                        
                        statusUpdate = String.format("%d\t%.2f\t%.2f\t%.2f\t%.2f\n", elapsed / 1000l, thisSysbenchTransactionsPerSecond, thisIntervalSysbenchTransactionsPerSecond, thisInsertsPerSecond, thisIntervalInsertsPerSecond);
                            
                        writer.write(statusUpdate);
                        writer.flush();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }

                    lastInserts = thisInserts;
                    lastSysbenchTransactions = thisSysbenchTransactions;

                    lastMs = now;
                }
            }
            
            // shutdown all the writers
            allDone = 1;
        }
    }


    public static void logMe(String format, Object... args) {
        System.out.println(Thread.currentThread() + String.format(format, args));
    }
}

//import com.mongodb.Mongo;
import com.mongodb.MongoClient;
import com.mongodb.MongoCredential;
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
import java.util.concurrent.atomic.AtomicLongArray;
import java.util.concurrent.locks.ReentrantLock;

public class jmongosysbenchpileup {
    public static int latencyBuckets = 1002;
    
    public static AtomicLong globalQueries = new AtomicLong(0);
    public static AtomicLong globalWriterThreads = new AtomicLong(0);
    
    public static Writer writer = null;
    public static boolean outputHeader = true;

    public static int numCollections;
    public static String dbName;
    public static int readerThreads;
    public static Integer numMaxInserts;
    public static long secondsPerFeedback;
    public static String logFileName;
    public static String indexTechnology;
    public static String pileupType;
    public static int runSeconds;
    public static String myWriteConcern;
    public static Integer maxTPS;
    public static Integer maxThreadTPS;
    public static String serverName;
    public static int serverPort;
    public static String userName;
    public static String passWord;
    
    public static int oltpPointSelects;
    public static int oltpRangeSize;
    public static int oltpRangeLimit;
    
    public static boolean bIsTokuMX = false;
    
    public static int allDone = 0;
    
    public jmongosysbenchpileup() {
    }

    public static void main (String[] args) throws Exception {
        if (args.length != 17) {
            logMe("*** ERROR : CONFIGURATION ISSUE ***");
            logMe("jsysbenchpileup [number of collections] [database name] [number of writer threads] [documents per collection] [seconds feedback] "+
                                   "[log file name] [pileup type PP/PS/RP/RS] [runtime (seconds)] [queries] [range size] [range limit] "+
                                   "[writeconcern] [max tps] [server] [port] [username] [password]");
            System.exit(1);
        }
        
        numCollections = Integer.valueOf(args[0]);
        dbName = args[1];
        readerThreads = Integer.valueOf(args[2]);
        numMaxInserts = Integer.valueOf(args[3]);
        secondsPerFeedback = Long.valueOf(args[4]);
        logFileName = args[5];
        pileupType = args[6];
        runSeconds = Integer.valueOf(args[7]);
        oltpPointSelects = Integer.valueOf(args[8]);
        oltpRangeSize = Integer.valueOf(args[9]);
        oltpRangeLimit = Integer.valueOf(args[10]);
        myWriteConcern = args[11];
        maxTPS = Integer.valueOf(args[12]);
        serverName = args[13];
        serverPort = Integer.valueOf(args[14]);
        userName = args[15];
        passWord = args[16];

        maxThreadTPS = (maxTPS / readerThreads) + 1;
        
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
        
        MongoClientOptions clientOptions = new MongoClientOptions.Builder().connectionsPerHost(2048).socketTimeout(60000).writeConcern(myWC).build();
        ServerAddress srvrAdd = new ServerAddress(serverName,serverPort);
        //MongoClient m = new MongoClient(srvrAdd, clientOptions);
        MongoCredential credential = MongoCredential.createCredential(userName, dbName, passWord.toCharArray());
        MongoClient m = new MongoClient(srvrAdd, Arrays.asList(credential), clientOptions);
        
        logMe("mongoOptions | " + m.getMongoOptions().toString());
        logMe("mongoWriteConcern | " + m.getWriteConcern().toString());
        
        DB db = m.getDB(dbName);
        
        // determine server type : mongo or tokumx
        DBObject checkServerCmd = new BasicDBObject();
        CommandResult commandResult = db.command("buildInfo");
        
        // check if tokumxVersion exists, otherwise assume mongo
        if (commandResult.toString().contains("tokumxVersion")) {
            indexTechnology = "tokumx";
            bIsTokuMX = true;
        }
        else
        {
            indexTechnology = "mongo";
        }
        
        if ((!indexTechnology.toLowerCase().equals("tokumx")) && (!indexTechnology.toLowerCase().equals("mongo"))) {
            // unknown index technology, abort
            logMe(" *** Unknown Indexing Technology %s, shutting down",indexTechnology);
            System.exit(1);
        }
        
        logMe("Application Parameters");
        logMe("-------------------------------------------------------------------------------------------------");
        logMe("  collections              = %d",numCollections);
        logMe("  database name            = %s",dbName);
        logMe("  reader threads           = %d",readerThreads);
        logMe("  documents per collection = %,d",numMaxInserts);
        logMe("  feedback seconds         = %,d",secondsPerFeedback);
        logMe("  log file                 = %s",logFileName);
        logMe("  index technology         = %s",indexTechnology);
        logMe("  pileup type              = %s",pileupType);
        logMe("  run seconds              = %d",runSeconds);
        logMe("  queries                  = %d",oltpPointSelects);
        if ((pileupType.toLowerCase().equals("rp")) || (pileupType.toLowerCase().equals("rs"))) {
            logMe("  range size               = %d",oltpRangeSize);
            logMe("  range limit              = %d",oltpRangeLimit);
        }
        logMe("  write concern            = %s",myWriteConcern);
        logMe("  maximum tps (global)     = %d",maxTPS);
        logMe("  maximum tps (per thread) = %d",maxThreadTPS);
        logMe("  Server:Port = %s:%d",serverName,serverPort);
        logMe("-------------------------------------------------------------------------------------------------");

        try {
            writer = new BufferedWriter(new FileWriter(new File(logFileName)));
        } catch (IOException e) {
            e.printStackTrace();
        }

        jmongosysbenchpileup t = new jmongosysbenchpileup();

        Thread[] tWriterThreads = new Thread[readerThreads];
        
        for (int i=0; i<readerThreads; i++) {
            tWriterThreads[i] = new Thread(t.new MyWriter(readerThreads, i, numMaxInserts, db, numCollections));
            tWriterThreads[i].start();
        }
        
        Thread reporterThread = new Thread(t.new MyReporter());
        reporterThread.start();
        reporterThread.join();

        // wait for writer threads to terminate
        for (int i=0; i<readerThreads; i++) {
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
            logMe("Query thread %d : started",threadNumber);
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

                // if TokuMX, lock onto current connection (do not pool)
                //    ** query only benchmark, not necessary
                //if (bIsTokuMX) {
                //    db.requestStart();
                //    db.command("beginTransaction");
                //}
                
                String collectionName = "sbtest" + Integer.toString(rand.nextInt(numCollections)+1);
                DBCollection coll = db.getCollection(collectionName);
                
                try {
                    //if (bIsTokuMX) {
                    //    // make sure a connection is available, given that we are not pooling
                    //    db.requestEnsureConnection();
                    //}
                    
                    if (pileupType.toLowerCase().equals("pp")) {
                        // point query, primary key
                        for (int i=1; i <= oltpPointSelects; i++) {
                            //for i=1, oltp_point_selects do
                            //   rs = db_query("SELECT c FROM ".. table_name .." WHERE id=" .. sb_rand(1, oltp_table_size))
                            //end
                            // db.sbtest8.find({_id: 554312}, {c: 1, _id: 0})
                            
                            int startId = rand.nextInt(numMaxInserts)+1;
        
                            BasicDBObject query = new BasicDBObject("_id", startId);
                            BasicDBObject columns = new BasicDBObject("c", 1).append("_id", 0);

                            DBObject myDoc = coll.findOne(query, columns);
                            
                            globalQueries.incrementAndGet();
                        }
                    } else if (pileupType.toLowerCase().equals("ps")) {
                        // point query, secondary key
                        for (int i=1; i <= oltpPointSelects; i++) {
                            //for i=1, oltp_point_selects do
                            //    rs = db_query("SELECT c FROM ".. table_name .." WHERE k=" .. sb_rand(1, oltp_table_size))
                            //end
                            // db.sbtest8.find({k: 554312}, {c: 1, _id: 0})
                            
                            int startId = rand.nextInt(numMaxInserts)+1;
        
                            BasicDBObject query = new BasicDBObject("k", startId);
                            BasicDBObject columns = new BasicDBObject("c", 1).append("_id", 0);
                            
                            DBObject myDoc = coll.findOne(query, columns);
                            
                            globalQueries.incrementAndGet();
                        }
                    } else if (pileupType.toLowerCase().equals("rp")) {
                        // range/limit query, primary key
                        for (int i=1; i <= oltpPointSelects; i++) {
                            //for i=1, oltp_point_selects do
                            //   range_start = sb_rand(1, oltp_table_size)
                            //   rs = db_query("SELECT c FROM ".. table_name .." WHERE id BETWEEN " .. range_start .. " AND " .. range_start .. "+" .. oltp_range_size - 1 .. " ORDER BY id LIMIT " .. oltp_simple_ranges)
                            //end
                            //db.sbtest8.find({_id: {$gte: 5523412, $lte: 5523512}}, {c: 1, _id: 0})
                            
                            int startId = rand.nextInt(numMaxInserts)+1;
                            int endId = startId + oltpRangeSize - 1;
                            
                            BasicDBObject query = new BasicDBObject("_id", new BasicDBObject("$gte", startId).append("$lte", endId));
                            BasicDBObject columns = new BasicDBObject("c", 1).append("_id", 0);
                            DBCursor cursor = coll.find(query, columns).limit(oltpRangeLimit);
                            try {
                                while(cursor.hasNext()) {
                                    cursor.next();
                                    //System.out.println(cursor.next());
                                }
                            } finally {
                                cursor.close();
                            }
                            
                            globalQueries.incrementAndGet();
                        }
                    } else if (pileupType.toLowerCase().equals("rs")) {
                        // range/limit query, secondary key
                        for (int i=1; i <= oltpPointSelects; i++) {
                            //for i=1, oltp_point_selects do
                            //   range_start = sb_rand(1, oltp_table_size)
                            //   rs = db_query("SELECT c FROM ".. table_name .." WHERE k BETWEEN " .. range_start .. " AND " .. range_start .. "+" .. oltp_range_size - 1 .. " ORDER BY k LIMIT " .. oltp_simple_ranges)
                            //end
                            //db.sbtest8.find({k: {$gte: 5523412, $lte: 5523512}}, {c: 1, _id: 0})
                            
                            int startId = rand.nextInt(numMaxInserts)+1;
                            int endId = startId + oltpRangeSize - 1;
                            
                            BasicDBObject query = new BasicDBObject("k", new BasicDBObject("$gte", startId).append("$lte", endId));
                            BasicDBObject columns = new BasicDBObject("c", 1).append("_id", 0);
                            DBCursor cursor = coll.find(query, columns).limit(oltpRangeLimit);
                            try {
                                while(cursor.hasNext()) {
                                    cursor.next();
                                    //System.out.println(cursor.next());
                                }
                            } finally {
                                cursor.close();
                            }
                            
                            globalQueries.incrementAndGet();
                        }
                    }

                    numTransactions += 1;
               
                } finally {
                    //    ** query only benchmark, not necessary
                    //if (bIsTokuMX) {
                    //    // commit the transaction and release current connection in the pool
                    //    db.command("commitTransaction");
                    //    //--db.command("rollbackTransaction")
                    //    db.requestDone();
                    //}
                }
            }

            //} catch (Exception e) {
            //    logMe("Writer thread %d : EXCEPTION",threadNumber);
            //    e.printStackTrace();
            //}
            
            globalWriterThreads.decrementAndGet();
        }
    }
    
    
    // reporting thread, outputs information to console and file
    class MyReporter implements Runnable {
        public void run()
        {
            long t0 = System.currentTimeMillis();
            long lastQueries = 0;
            long thisQueries = 0;
            long lastMs = t0;
            long intervalNumber = 0;
            long nextFeedbackMillis = t0 + (1000 * secondsPerFeedback * (intervalNumber + 1));
            long runEndMillis = Long.MAX_VALUE;
            if (runSeconds > 0)
                runEndMillis = t0 + (1000 * runSeconds);
            
            while (System.currentTimeMillis() < runEndMillis)
            {
                try {
                    Thread.sleep(100);
                } catch (Exception e) {
                    e.printStackTrace();
                }
                
                long now = System.currentTimeMillis();
                
                if ((now > nextFeedbackMillis) && (secondsPerFeedback > 0))
                {
                    intervalNumber++;
                    nextFeedbackMillis = t0 + (1000 * secondsPerFeedback * (intervalNumber + 1));

                    long elapsed = now - t0;
                    long thisIntervalMs = now - lastMs;
                    
                    thisQueries = globalQueries.get();

                    long thisIntervalQueries = thisQueries - lastQueries;
                    double thisIntervalQueriesPerSecond = thisIntervalQueries/(double)thisIntervalMs*1000.0;
                    double thisQueriesPerSecond = thisQueries/(double)elapsed*1000.0;

                    logMe("%,d seconds : cum qps=%,.2f : int qps=%,.2f", elapsed / 1000l, thisQueriesPerSecond, thisIntervalQueriesPerSecond);
                    
                    try {
                        if (outputHeader)
                        {
                            writer.write("elap_secs\tcum_qps\tint_qps\n");
                            outputHeader = false;
                        }
                            
                        String statusUpdate = "";
                        
                        statusUpdate = String.format("%d\t%.2f\t%.2f\n", elapsed / 1000l, thisQueriesPerSecond, thisIntervalQueriesPerSecond);
                            
                        writer.write(statusUpdate);
                        writer.flush();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }

                    lastQueries = thisQueries;

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

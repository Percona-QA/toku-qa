import com.mongodb.Mongo;
import com.mongodb.DB;
import com.mongodb.DBCollection;
import com.mongodb.DBCursor;
import com.mongodb.BasicDBObject;
import com.mongodb.DBObject;
import com.mongodb.DBCursor;
import com.mongodb.ServerAddress;
import com.mongodb.WriteConcern;

import java.util.Arrays;
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
    public static ReentrantLock lockDDL = new ReentrantLock();
    public static AtomicLong globalInserts = new AtomicLong(0);
    public static AtomicInteger globalQueries = new AtomicInteger(0);
    public static AtomicLong globalQueriesMs = new AtomicLong(0);
    public static AtomicInteger globalQueryThreads = new AtomicInteger(0);
    public static AtomicInteger globalWriterThreads = new AtomicInteger(0);
    public static Integer numTables;
    public static Integer numMaxInserts;
    public static int minutesToRun = 0;
    public static long secondsPerFeedback;
    public static long insertsPerFeedback;
    public static Writer writer = null;
    public static boolean outputHeader = true;
    public static int queryThreads = 0;
    public static int writerThreads = 0;
    public static int shutItDown = 0;
    public static int secondsBetweenQueries = 1;
    public static int documentsPerQuery = 1;
    public static String createIndexes = "Y";

    public static String[] uriArray = {
      "romoore", "poke", "esmet", "rmartin", "lincoln",
      "washington", "robcar", "kangcar", "johndonthaveacar",
       "coffee-mug", "coffee-mug", "robscoffeemug",
      "richscofeemug", "kangsphone", "johnsphone", "robsphone",
      "ilabdoor", "ilabdoor2", "corebackdoor", "corefrontdoor",
      "coreelavator", "hillelavator", "cavepenguin"
    };

    public static String[] nameArray = {
      "xloc", "yloc", "zloc", "temp", "depth", "angle",
      "acceleration", "power", "status", "awake", "fallen",
      "sleeping", "alive", "active", "state", "working"
    };

    public static String[] originArray = {
      "hill-sensor", "hill-sensor", "core-mon", "core-mon",
      "rob's backpack", "john's apt", "kang's car", "ilab-sensor",
      "winlab-sensor", "hallway-sensor", "secret-cave-heat-camera", 
      "core-parking-lot", "gym-parking-lot", "core-roof-camera"
    };
    
    public jtest() {
    }

    public static void main (String[] args) throws Exception {
        if (args.length != 13) {
            logMe("*** ERROR : CONFIGURATION ISSUE ***");
            logMe("jtest [number of query threads] [number of writer threads] [number of tables] [max inserts] [seconds feedback] [inserts feedback] [minutes to run] [log file name] [index version] [clustering indexes] [seconds between queries] [documents per query] [create indexes]");
            System.exit(1);
        }

        queryThreads = Integer.valueOf(args[0]);
        writerThreads = Integer.valueOf(args[1]);
        numTables = Integer.valueOf(args[2]);
        numMaxInserts = Integer.valueOf(args[3]);
        secondsPerFeedback = Long.valueOf(args[4]);
        insertsPerFeedback = Long.valueOf(args[5]);
        minutesToRun = Integer.valueOf(args[6]);
        String logFileName = args[7];
        int indexVersion = Integer.valueOf(args[8]);
        String clusteringIndexes = args[9];
        secondsBetweenQueries = Integer.valueOf(args[10]);
        documentsPerQuery = Integer.valueOf(args[11]);
        createIndexes = args[12];

        logMe("Application Parameters");
        logMe("--------------------------------------------------");
        logMe("  %d query thread(s)",queryThreads);
        logMe("  %d writer thread(s)",writerThreads);
        logMe("  %d tables",numTables);
        logMe("  %,d is maximum inserts",numMaxInserts);
        logMe("  Feedback every %,d seconds(s)",secondsPerFeedback);
        logMe("  Feedback every %,d inserts(s)",insertsPerFeedback);
        if (minutesToRun > 0)
            logMe("  Running for %,d minute(s)",minutesToRun);
        logMe("  Index version = %d",indexVersion);
        if (clusteringIndexes.equals("Y") && (indexVersion == 2))
          logMe("  Creating clustering indexes");
        logMe("  Seconds Between Queries = %d",secondsBetweenQueries);
        logMe("  Documents Per Query = %d",documentsPerQuery);
        if (createIndexes.equals("N"))
          logMe("  *** NOTE *** NOT CREATING SECONDARY INDEXES");
        logMe("--------------------------------------------------");

        try {
            writer = new BufferedWriter(new FileWriter(new File(logFileName)));
        } catch (IOException e) {
            e.printStackTrace();
        }

        Mongo m = new Mongo();
//        m.setWriteConcern(WriteConcern.SAFE);
        
        DB db = m.getDB("mydb");

        // background   true/false                                                    false. see doc page for caveats
        // dropDups     true/false                                                    false
        // sparse       true/false                                                    false
        // unique       true/false                                                    false
        // v            index version. 0 = pre-v2.0, 1 = smaller/faster (current)     1 in v2.0. Default is used except in unusual situations. 
        
        DBCollection coll = db.getCollection("tokubench");
        
        BasicDBObject idxOptions = new BasicDBObject();
        idxOptions.put("background",false);
        idxOptions.put("v",indexVersion);

        if (createIndexes.equals("Y")) {
            // create secondary indexes
            coll.ensureIndex(new BasicDBObject("creation", 1), idxOptions);
            coll.ensureIndex(new BasicDBObject("name", 1), idxOptions);
            coll.ensureIndex(new BasicDBObject("origin", 1), idxOptions);
            
            if (clusteringIndexes.equals("Y") && (indexVersion == 2)) {
                logMe("  Creating clustered fractal tree index on URI.");
                idxOptions.put("clustering","true");
                coll.ensureIndex(new BasicDBObject("URI", 1), idxOptions);
            } else if (clusteringIndexes.equals("Y") && (indexVersion == 1)) {
                // create a covering mongodb index
                logMe("  Creating covering mongodb index on URI.");
                coll.ensureIndex(new BasicDBObject("URI", 1).append("creation", 1).append("name", 1).append("origin", 1), idxOptions);
            } else {
                // create a "standard" mongodb or fractal tree index
                coll.ensureIndex(new BasicDBObject("URI", 1), idxOptions);
            }
        }
        
        jtest t = new jtest();

        Thread[] tQueryThreads = new Thread[queryThreads];
        for (int i=0; i<queryThreads; i++) {
            tQueryThreads[i] = new Thread(t.new MyQuery(coll, queryThreads, i, numTables, numMaxInserts));
            tQueryThreads[i].start();
        }

        // add writer threads here
        Thread[] tWriterThreads = new Thread[writerThreads];
        for (int i=0; i<writerThreads; i++) {
            tWriterThreads[i] = new Thread(t.new MyWriter(coll, writerThreads, i, numTables, numMaxInserts));
            tWriterThreads[i].start();
        }
        
        Thread reporterThread = new Thread(t.new MyReporter());
        reporterThread.start();
        reporterThread.join();
        shutItDown = 1;

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
        
        // m.dropDatabase("mydb");

        m.close();
        
        logMe("Done!");
    }


    // reporting thread, outputs information to console and file
    class MyReporter implements Runnable {
        public void run()
        {
            long t0 = System.currentTimeMillis();
            long lastInserts = 0;
            int lastQueries = 0;
            long lastQueriesMs = 0;
            long lastMs = t0;
            long intervalNumber = 0;
            long nextFeedbackMillis = t0 + (1000 * secondsPerFeedback * (intervalNumber + 1));
            long nextFeedbackInserts = lastInserts + insertsPerFeedback;
            long runEndMillis = Long.MAX_VALUE;
            if (minutesToRun > 0)
                runEndMillis = t0 + (1000 * 60 * minutesToRun);
            long thisInserts = 0;

            while ((System.currentTimeMillis() < runEndMillis) && (thisInserts < numMaxInserts))
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
                    
                    int thisQueries = globalQueries.get();
                    long thisQueriesMs = globalQueriesMs.get();

                    long thisIntervalInserts = thisInserts - lastInserts;
                    int thisIntervalQueries = thisQueries - lastQueries;
                    long thisIntervalQueriesMs = thisQueriesMs - lastQueriesMs;

                    double thisIntervalInsertsPerSecond = thisIntervalInserts/(double)thisIntervalMs*1000.0;
                    double thisIntervalQueriesPerSecond = thisIntervalQueries/(double)thisIntervalMs*1000.0;
                    double thisIntervalQueriesMsAvg = (double)thisIntervalQueriesMs/thisIntervalQueries;

                    double thisInsertsPerSecond = thisInserts/(double)elapsed*1000.0;
                    double thisQueriesPerSecond = thisQueries/(double)elapsed*1000.0;
                    double thisQueriesMsAvg = (double)thisQueriesMs/thisQueries;
                    
                    if (secondsPerFeedback > 0)
                    {
                        logMe("%,d inserts : %,d seconds : cum ips=%,.2f : int ips=%,.2f : cum q=%,d : int q=%,d : cum qlat=%,.2f : int qlat=%,.2f", thisInserts, elapsed / 1000l, thisInsertsPerSecond, thisIntervalInsertsPerSecond, thisQueries, thisIntervalQueries, thisQueriesMsAvg, thisIntervalQueriesMsAvg);
                    } else {
                        logMe("%,d inserts : %,d seconds : cum ips=%,.2f : int ips=%,.2f : cum q=%,d : int q=%,d : cum qlat=%,.2f : int qlat=%,.2f", intervalNumber * insertsPerFeedback, elapsed / 1000l, thisInsertsPerSecond, thisIntervalInsertsPerSecond, thisQueries, thisIntervalQueries, thisQueriesMsAvg, thisIntervalQueriesMsAvg);
                    }
                    
                    try {
                        if (outputHeader)
                        {
                            writer.write("tot_inserts\telap_secs\tcum_ips\tint_ips\tcum_q\tint_q\tcum_lat\tint_lat\n");
                            outputHeader = false;
                        }
                            
                        String statusUpdate = "";
                        
                        if (secondsPerFeedback > 0)
                        {
                            statusUpdate = String.format("%d\t%d\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\n",thisInserts, elapsed / 1000l, thisInsertsPerSecond, thisIntervalInsertsPerSecond, thisQueriesPerSecond, thisIntervalQueriesPerSecond, thisQueriesMsAvg, thisIntervalQueriesMsAvg);
                        } else {
                            statusUpdate = String.format("%d\t%d\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\n",intervalNumber * insertsPerFeedback, elapsed / 1000l, thisInsertsPerSecond, thisIntervalInsertsPerSecond, thisQueriesPerSecond, thisIntervalQueriesPerSecond, thisQueriesMsAvg, thisIntervalQueriesMsAvg);
                        }
                        writer.write(statusUpdate);
                        writer.flush();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }

                    lastInserts = thisInserts;
                    lastQueries = thisQueries;
                    lastQueriesMs = thisQueriesMs;

                    lastMs = now;
                }
            }
        }
    }


    class MyQuery implements Runnable {
        DBCollection coll; 
        int threadCount; 
        int threadNumber; 
        int numTables;
        int numMaxInserts;
        java.util.Random rand = new java.util.Random();
        
        int uriArraySize = uriArray.length;
        int nameArraySize = nameArray.length;
        int originArraySize = originArray.length;
        
        MyQuery(DBCollection coll, int threadCount, int threadNumber, int numTables, int numMaxInserts) {
            this.coll = coll;
            this.threadCount = threadCount;
            this.threadNumber = threadNumber;
            this.numTables = numTables;
            this.numMaxInserts = numMaxInserts;
        }
        public void run() {
            globalQueryThreads.incrementAndGet();

            try {
                logMe("Query thread %d : started",threadNumber);
                
                while (shutItDown == 0)
                {
                    // randomly pick our query path
                    //int whichField = rand.nextInt(3);
                    String querySearchField = "";
                    String querySearchValue = "";
                    
                    //if (whichField == 0) {
                        // query on URI
                        querySearchField = "URI";
                        querySearchValue = uriArray[rand.nextInt(uriArraySize)]+String.valueOf(Math.abs(rand.nextLong()));
                    //} else if (whichField == 1) {
                    //    // query on name
                    //    querySearchField = "name";
                    //    querySearchValue = nameArray[rand.nextInt(nameArraySize)]+String.valueOf(Math.abs(rand.nextLong()));
                    //} else {
                    //    // query on origin
                    //    querySearchField = "origin";
                    //    querySearchValue = originArray[rand.nextInt(originArraySize)]+String.valueOf(Math.abs(rand.nextLong()));
                    //}
                    
//                    System.out.println("looking for " + querySearchField + " = " + querySearchValue);
                    
                    // exact equality search, all fields
                    //BasicDBObject query = new BasicDBObject();
                    //query.put(querySearchField, querySearchValue);

                    // greater than or equal to search, all fields
/*                    
                    BasicDBObject keys = new BasicDBObject();
                    query.put(querySearchField, new BasicDBObject("$gte", querySearchValue));
                    long now = System.currentTimeMillis();
                    DBCursor cursor = coll.find(query).limit(documentsPerQuery);
                    try {
                        while(cursor.hasNext()) {
//                            System.out.println(cursor.next());
                            cursor.next();
                        }
                    } finally {
                        cursor.close();
                    }
                    long elapsed = System.currentTimeMillis() - now;
*/
                    
                    // greater than or equal to search, exclude _id field
                    BasicDBObject query = new BasicDBObject();
                    BasicDBObject keys = new BasicDBObject();
                    query.put(querySearchField, new BasicDBObject("$gte", querySearchValue));
                    // here is how you include particular fields
                    //keys.put("URI",1);
                    keys.put("name",1);
                    // here is how you exclude particular fields
                    keys.put("_id",0);
                    long now = System.currentTimeMillis();
                    DBCursor cursor = coll.find(query,keys).limit(documentsPerQuery);
                    try {
                        while(cursor.hasNext()) {
//                            System.out.println(cursor.next());
                            cursor.next();
                        }
                    } finally {
                        cursor.close();
                    }
                    long elapsed = System.currentTimeMillis() - now;
                    
                    //logMe("Query thread %d : performing : %s",threadNumber,thisSelect);
                    
                    globalQueries.incrementAndGet();
                    globalQueriesMs.addAndGet(elapsed);

                    // sleep?
                    Thread.sleep(secondsBetweenQueries * 1000);
                }

                logMe("Query thread %d : shutting down",threadNumber);
            } catch (Exception e) {
                e.printStackTrace();
            }
            
            globalQueryThreads.decrementAndGet();
        }
    }


    class MyWriter implements Runnable {
        DBCollection coll; 
        int threadCount; 
        int threadNumber; 
        int numTables;
        int numMaxInserts;
        java.util.Random rand = new java.util.Random();
        
        int uriArraySize = uriArray.length;
        int nameArraySize = nameArray.length;
        int originArraySize = originArray.length;
        
        MyWriter(DBCollection coll, int threadCount, int threadNumber, int numTables, int numMaxInserts) {
            this.coll = coll;
            this.threadCount = threadCount;
            this.threadNumber = threadNumber;
            this.numTables = numTables;
            this.numMaxInserts = numMaxInserts;
        }
        public void run() {
            globalWriterThreads.incrementAndGet();
            long numInserts = 0;

            try {
                logMe("Writer thread %d : started",threadNumber);
                
                while (shutItDown == 0)
                {
                    try {
                        // insert random rows
                        long sysNanoTime = System.nanoTime();
                        
                        BasicDBObject doc = new BasicDBObject();
                        doc.put("URI",uriArray[rand.nextInt(uriArraySize)]+String.valueOf(Math.abs(rand.nextLong())));
                        doc.put("name",nameArray[rand.nextInt(nameArraySize)]+String.valueOf(Math.abs(rand.nextLong())));
                        doc.put("creation",sysNanoTime);
                        doc.put("expiration",sysNanoTime + 5000000l);
                        doc.put("origin",originArray[rand.nextInt(originArraySize)]+String.valueOf(Math.abs(rand.nextLong())));
                        doc.put("data","tokutek");
                        coll.insert(doc);
                        
                        numInserts++;
                        globalInserts.addAndGet(1);
                    } catch (Exception e) {
                        logMe("Writer thread %d : EXCEPTION",threadNumber);
                        e.printStackTrace();
                    }

                    // sleep?
//                    Thread.sleep(50);
                }

                logMe("Writer thread %d : shutting down",threadNumber);
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

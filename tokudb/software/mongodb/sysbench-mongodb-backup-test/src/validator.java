//import com.mongodb.Mongo;
import com.mongodb.MongoClient;
import com.mongodb.MongoClientOptions;
import com.mongodb.DB;
import com.mongodb.DBCollection;
import com.mongodb.DBCursor;
import com.mongodb.BasicDBObject;
import com.mongodb.BasicDBList;
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

public class validator {
    public static int numCollections;
    public static String dbName;
    
    //public validator() {
    //}

    public static void main (String[] args) throws Exception {
        if (args.length != 2) {
            logMe("*** ERROR : CONFIGURATION ISSUE ***");
            logMe("validator [number of collections] [database name]");
            System.exit(1);
        }
        
        numCollections = Integer.valueOf(args[0]);
        dbName = args[1];
        
        //logMe("Application Parameters");
        //logMe("-------------------------------------------------------------------------------------------------");
        //logMe("  collections              = %d",numCollections);
        //logMe("  database name            = %s",dbName);
        //logMe("-------------------------------------------------------------------------------------------------");

        MongoClientOptions clientOptions = new MongoClientOptions.Builder().connectionsPerHost(2048).build();
        MongoClient m = null;
        try {
            m = new MongoClient("localhost", clientOptions);

            //logMe("mongoOptions | " + m.getMongoOptions().toString());
            //logMe("mongoWriteConcern | " + m.getWriteConcern().toString());
        } catch (Exception e) {
            // e.printStackTrace();
            logMe("  - SOMETHING WENT HORRIBLY WRONG, CHECK THE SERVERS LOG FILE");
            logMe("*** I CANT EVEN CONNECT TO THE SERVER");
            System.exit(1);
        }

        DB db = m.getDB(dbName);
        
        DBCollection coll2 = db.getCollection("sbvalid");
        
        for (int i=1; i <= numCollections; i++) {
            String collectionName = "sbtest" + Integer.toString(i);

            try {
                logMe("validating collection %s",collectionName);

                DBCollection coll1 = db.getCollection(collectionName);
                
                // get the checksum from the sbtext<n> collection
                // db.sbtest<n>.aggregate([{$group: { _id: null, total: {$sum:"$c1"}}}])
                DBObject groupFields1 = new BasicDBObject( "_id", null);
                groupFields1.put("total", new BasicDBObject( "$sum", "$c1"));
                DBObject group1 = new BasicDBObject("$group", groupFields1);
                AggregationOutput output1 = coll1.aggregate(group1);
                //System.out.println(output1.getCommandResult());
                BasicDBList results1 = (BasicDBList) output1.getCommandResult().get("result");
                //System.out.println(results1);
                BasicDBObject timbo1 = (BasicDBObject) results1.get("0");
                //System.out.println(timbo1);
                int check1 = timbo1.getInt("total");
                //System.out.println(check1);

                // get the checksum from the sbvalid collection
                // db.sbvalid.aggregate([{ $match: { collection_name: "${thisTable}" } }, {$group: { _id: null, total: {$sum:"$c1"}}}])
                DBObject match2 = new BasicDBObject("$match", new BasicDBObject("collection_name", collectionName));
                DBObject groupFields2 = new BasicDBObject( "_id", null);
                groupFields2.put("total", new BasicDBObject( "$sum", "$c1"));
                DBObject group2 = new BasicDBObject("$group", groupFields2);
                AggregationOutput output2 = coll2.aggregate(match2, group2);
                //System.out.println(output2.getCommandResult());
                BasicDBList results2 = (BasicDBList) output2.getCommandResult().get("result");
                BasicDBObject timbo2 = (BasicDBObject) results2.get("0");
                int check2 = timbo2.getInt("total");
                //System.out.println(check2);
                
                if (check1 == check2) {
                    logMe("  - collection %s passed checksum validation",collectionName);
                } else {
                    logMe("  - collection %s FAILED checksum validation, collection checksum = %d, validator checksum = %d",collectionName,check1,check2);
                }
            } catch (Exception e) {
                // e.printStackTrace();
                logMe("  - SOMETHING WENT HORRIBLY WRONG, CHECK THE SERVERS LOG FILE");
                logMe("*** ISSUE DETECTED, NO MORE VALIDATIONS WILL RUN");
                System.exit(1);
            }
        }

        m.close();
        
        logMe("Done!");
    }
    
    
    public static void logMe(String format, Object... args) {
        System.out.println(Thread.currentThread() + String.format(format, args));
    }
}

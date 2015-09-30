package com.facebook.LinkBench;

import java.util.Properties;
import java.util.Random;

/*
 * Muli-threaded loader for loading data into hbase.
 * The range from startid1 to maxid1 is chunked up into equal sized
 * disjoint ranges so that each loader can work on its range.
 * The #links generated for an id1 is random but based on probablities
 * given in nlinks_choices and odds_in_billion. The actual counts of
 * #links generated is tracked in nlinks_counts.
 */

public class LinkBenchLoad extends Thread {

  private static final long BILLION = 1000 * 1000 * 1000;

  private long randomid2max; // whether id2 should be generated randomly
  private Random random_id2; // random number generator for id2 if needed

  private long maxid1;   // max id1 to generate
  private long startid1; // id1 at which to start
  private int  loaderID; // ID for this loader
  private int  nloaders; // #loaders
  private LinkStore store;// store interface (several possible implementations
                          // like mysql, hbase etc)
  private int datasize; // 'data' column size for one (id1, type, id2)
  private LinkBenchStats stats;
  long displayfreq;
  int maxsamples;

  int debuglevel;
  String dbid;

  int nlinks_func; // distribution function for #links
  int nlinks_config; // any additional config to go with above the above func
  int nlinks_default; // default value of #links - expected to be 0 or 1

  long linksloaded;

  public LinkBenchLoad(LinkStore input_store,
                       Properties props,
                       int input_loaderID,
                       int input_nloaders) {
    linksloaded = 0;
    loaderID = input_loaderID;

    // random number generator for id2 if needed
    randomid2max = Long.parseLong(props.getProperty("randomid2max"));
    random_id2 = (randomid2max > 0) ? (new Random()) : null;

    maxid1 = Long.parseLong(props.getProperty("maxid1"));
    startid1 = Long.parseLong(props.getProperty("startid1"));

    // math functions may cause problems for id1 = 0. Start at 1.
    if (startid1 <= 0) {
      startid1 = 1;
    }

    debuglevel = Integer.parseInt(props.getProperty("debuglevel"));
    nloaders = input_nloaders;
    store = input_store;
    datasize = Integer.parseInt(props.getProperty("datasize"));

    nlinks_func = Integer.parseInt(props.getProperty("nlinks_func"));
    nlinks_config = Integer.parseInt(props.getProperty("nlinks_config"));
    nlinks_default = Integer.parseInt(props.getProperty("nlinks_default"));
    if (nlinks_func == -2) {//real distribution has it own initialization
      System.err.println("Real distribution (nlinks_func == -2) not supported");
      System.exit(1);
      /*
      try {
        //load staticical data into RealDistribution
        RealDistribution.loadOneShot(props);
      } catch (Exception e) {
        e.printStackTrace();
        System.exit(1);
      }
      */
    }

    displayfreq = Long.parseLong(props.getProperty("displayfreq"));
    maxsamples = Integer.parseInt(props.getProperty("maxsamples"));
    stats = null;
    dbid = props.getProperty("dbid");
  }

  public long getLinksLoaded() {
    return linksloaded;
  }

  // Gets the #links to generate for an id1 based on distribution specified
  // by nlinks_func, nlinks_config and nlinks_default.
  public static long getNlinks(long id1, long startid1, long maxid1,
                               int nlinks_func, int nlinks_config,
                               int nlinks_default) {
    long nlinks = nlinks_default; // start with nlinks_default
    long temp;

    switch(nlinks_func) {
    case -2 :
      // real distribution
      System.err.println("Real distribution (nlinks_func == -2) not supported");
      System.exit(1);
      /*
      nlinks = RealDistribution.getNlinks(id1, startid1, maxid1);
      break;
      */
    case -1 :
      // Corresponds to function 1/x
      nlinks += (long)Math.ceil((double)maxid1/(double)id1);
      break;
    case 0 :
      // if id1 is multiple of nlinks_config, then add nlinks_config
      nlinks += (id1 % nlinks_config == 0 ? nlinks_config : 0);
      break;

    case 100 :
      // Corresponds to exponential distribution
      // If id1 is nlinks_config^k, then add
      // nlinks_config^k - nlinks_config^(k-1) more links
      long log = (long)Math.ceil(Math.log(id1)/Math.log(nlinks_config));
      temp = (long)Math.pow(nlinks_config, log);
      nlinks += (temp == id1 ?
                 (id1 - (long)Math.pow(nlinks_config, log - 1)) :
                 0);
      break;

    default:
      // if nlinks_func is 2 then
      //   if id1 is K * K, then add K * K - (K - 1) * (K - 1) more links.
      //   The idea is to give more #links to perfect squares. The larger
      //   the perfect square is, the more #links it will get.
      // Generalize the above for nlinks_func is n:
      //   if id1 is K^n, then add K^n - (K - 1)^n more links
      long nthroot = (long)Math.ceil(Math.pow(id1, (1.0)/nlinks_func));
      temp = (long)Math.pow(nthroot, nlinks_func);
      nlinks += (temp == id1 ?
                (id1 - (long)Math.pow(nthroot - 1, nlinks_func)) :
                0);
      break;
    }

    return nlinks;
  }

  @Override
  public void run() {
    System.out.println("Hello from loaderID = " + loaderID);

    // partition the range from startid1 to maxid1 into nloaders chunks
    // the last partition could be shorter than others
    long chunksize = (maxid1 - startid1)%nloaders == 0 ?
                     (maxid1 - startid1)/nloaders :
                     (maxid1 - startid1)/nloaders + 1;
    long startid = startid1 + (chunksize * loaderID);
    long endid = Math.min(startid + chunksize, maxid1); //exclusive

    // Random number generators for #links
    Random random_links = new Random();

    stats = new LinkBenchStats(loaderID,
                               displayfreq,
                               maxsamples);


    if (chunksize <= 0) {
      // this can happen if nloaders > range of id1. Have each loader process
      // atleast one id1
      chunksize = 1;
    }

    Link link = new Link();

    for (long id1 = startid; id1 < endid; id1++) {
      long nlinks = getNlinks(id1, startid1, maxid1,
          nlinks_func, nlinks_config, nlinks_default);

      if (debuglevel > 0) {
        System.out.println("id1 = " + id1 + " nlinks = " + nlinks);
      }

      for (long j = 0; j < nlinks; j++) {

        link.id1 = id1;
        link.link_type = LinkStore.LINK_TYPE;

        // Using random number generator for id2 means we won't know
        // which id2s exist. So link id1 to
        // maxid1 + id1 + 1 thru maxid1 + id1 + nlinks(id1) UNLESS
        // config randomid2max is nonzero.
        link.id2 = (randomid2max == 0 ?
                     (maxid1 + id1 + j) :
                     random_id2.nextInt((int)randomid2max));

        if (debuglevel > 0) {
          System.out.println("id2 chosen is " + link.id2);
        }

        link.id1_type = LinkStore.ID1_TYPE;
        link.id2_type = LinkStore.ID2_TYPE;
        link.visibility = LinkStore.VISIBILITY_DEFAULT;
        link.version = 0;

        // generate data as a sequence of random characters from 'a' to 'd'
        Random random_data = new Random();
        link.data = new byte[datasize];
        for (int k = 0; k < datasize; k++) {
          link.data[k] = (byte)('a' + Math.abs(random_data.nextInt()) % 4);
        }

        link.time = System.currentTimeMillis();
        long timestart = System.nanoTime();
        try {
          // no inverses for now
          store.addLink(dbid, link, true);
          linksloaded++;

          // convert to microseconds
          long timetaken = (System.nanoTime() - timestart) / 1000;

          stats.addStats(LinkStore.LOAD_LINK, timetaken, false);

        } catch (Throwable e){//Catch exception if any
            long endtime2 = System.nanoTime();
            long timetaken2 = (endtime2 - timestart)/1000;
            e.printStackTrace();
            System.err.println("Error: " + e.getMessage());
            stats.addStats(LinkStore.LOAD_LINK, timetaken2, true);
            store.clearErrors(loaderID);
            continue;
        }

      }

    }

    stats.displayStatsAll();
  }


}

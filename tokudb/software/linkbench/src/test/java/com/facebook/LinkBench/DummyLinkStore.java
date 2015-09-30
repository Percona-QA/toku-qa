/*
 * Copyright 2012, Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.facebook.LinkBench;

import java.io.IOException;
import java.util.List;
import java.util.Properties;

import com.facebook.LinkBench.Link;
import com.facebook.LinkBench.LinkCount;
import com.facebook.LinkBench.LinkStore;
import com.facebook.LinkBench.Phase;

/**
 * Can either be used as a wrapper around an existing LinkStore instance that
 * logs operations, or as a dummy linkstore instance that does nothing
 *
 */
public class DummyLinkStore extends GraphStore {

  public LinkStore wrappedStore;
  public GraphStore wrappedGraphStore;

  public DummyLinkStore() {
    this(null);
  }

  public DummyLinkStore(LinkStore wrappedStore) {
    this(wrappedStore, false);
  }

  public DummyLinkStore(LinkStore wrappedStore, boolean alreadyInitialized) {
    this.wrappedStore = wrappedStore;
    if (wrappedStore instanceof GraphStore) {
      wrappedGraphStore = (GraphStore) wrappedStore;
    }
    this.initialized = alreadyInitialized;
  }

  /**
   * @return true if real data is written and can be queried
   */
  public boolean isRealLinkStore() {
    return wrappedStore != null;
  }

  /**
   * @return true if real node data is written and can be queried
   */
  public boolean isRealGraphStore() {
    return wrappedGraphStore != null;
  }

  public boolean initialized = false;

  public long adds = 0;
  public long deletes = 0;
  public long updates = 0;
  public long multigetLinks = 0;
  public long getLinks = 0;
  public long getLinkLists = 0;
  public long getLinkListsHistory = 0;
  public long countLinks = 0;

  public long addNodes = 0;
  public long updateNodes = 0;
  public long deleteNodes = 0;
  public long getNodes = 0;

  public int bulkLoadBatchSize;
  public long bulkLoadLinkOps;
  public long bulkLoadLinkRows;
  public long bulkLoadCountOps;
  public long bulkLoadCountRows;

  @Override
  public void initialize(Properties p, Phase currentPhase, int threadId)
      throws IOException, Exception {
    if (initialized) {
      throw new Exception("Double initialization");
    }
    initialized = true;
    if (wrappedStore != null) {
      wrappedStore.initialize(p, currentPhase, threadId);
    }
  }

  @Override
  public void close() {
    checkInitialized();
    initialized = false;
    if (wrappedStore != null) {
      wrappedStore.close();
    }
  }

  @Override
  public void clearErrors(int threadID) {
    checkInitialized();
    if (wrappedStore != null) {
      wrappedStore.clearErrors(threadID);
    }
  }

  @Override
  public boolean addLink(String dbid, Link a, boolean noinverse) throws Exception {
    checkInitialized();
    adds++;
    if (wrappedStore != null) {
      return wrappedStore.addLink(dbid, a, noinverse);
    } else {
      return true;
    }
  }

  @Override
  public boolean deleteLink(String dbid, long id1, long link_type, long id2,
      boolean noinverse, boolean expunge) throws Exception {
    checkInitialized();
    deletes++;

    if (wrappedStore != null) {
      return wrappedStore.deleteLink(dbid, id1, link_type, id2, noinverse, expunge);
    } else {
      return true;
    }
  }

  @Override
  public boolean updateLink(String dbid, Link a, boolean noinverse)
      throws Exception {
    checkInitialized();
    updates++;

    if (wrappedStore != null) {
      return wrappedStore.updateLink(dbid, a, noinverse);
    } else {
      return true;
    }
  }

  @Override
  public Link[] multigetLinks(String dbid, long id1, long link_type, long[] id2s)
      throws Exception {
    checkInitialized();
    multigetLinks++;
    if (wrappedStore != null) {
      return wrappedStore.multigetLinks(dbid, id1, link_type, id2s);
    } else {
      return null;
    }
  }

  @Override
  public Link getLink(String dbid, long id1, long link_type, long id2)
      throws Exception {
    checkInitialized();
    getLinks++;
    if (wrappedStore != null) {
      return wrappedStore.getLink(dbid, id1, link_type, id2);
    } else {
      return null;
    }
  }

  @Override
  public Link[] getLinkList(String dbid, long id1, long link_type)
      throws Exception {
    checkInitialized();
    getLinkLists++;
    if (wrappedStore != null) {
      return wrappedStore.getLinkList(dbid, id1, link_type);
    } else {
      return null;
    }
  }

  @Override
  public Link[] getLinkList(String dbid, long id1, long link_type,
      long minTimestamp, long maxTimestamp, int offset, int limit)
      throws Exception {
    checkInitialized();
    getLinkLists++;
    getLinkListsHistory++;
    if (wrappedStore != null) {
      return wrappedStore.getLinkList(dbid, id1, link_type, minTimestamp,
                                      maxTimestamp, offset, limit);
    } else {
      return null;
    }
  }

  @Override
  public long countLinks(String dbid, long id1, long link_type)
      throws Exception {
    checkInitialized();
    countLinks++;
    if (wrappedStore != null) {
      return wrappedStore.countLinks(dbid, id1, link_type);
    } else {
      return 0;
    }
  }

  private void checkInitialized() {
    if (!initialized) {
      throw new RuntimeException("Expected store to be initialized");
    }
  }

  @Override
  public int bulkLoadBatchSize() {
    if (wrappedStore != null) {
      return wrappedStore.bulkLoadBatchSize();
    } else{
      return bulkLoadBatchSize;
    }
  }

  @Override
  public void addBulkLinks(String dbid, List<Link> a, boolean noinverse)
      throws Exception {
    bulkLoadLinkOps++;
    bulkLoadLinkRows += a.size();
    if (wrappedStore != null) {
      wrappedStore.addBulkLinks(dbid, a, noinverse);
    }
  }

  @Override
  public void addBulkCounts(String dbid, List<LinkCount> a) throws Exception {
    bulkLoadCountOps++;
    bulkLoadCountRows += a.size();
    if (wrappedStore != null) {
      wrappedStore.addBulkCounts(dbid, a);
    }
  }

  @Override
  public int getRangeLimit() {
    if (wrappedStore != null) {
      return wrappedStore.getRangeLimit();
    } else {
      return rangeLimit;
    }
  }

  @Override
  public void setRangeLimit(int rangeLimit) {
    if (wrappedStore != null) {
      wrappedStore.setRangeLimit(rangeLimit);
    } else {
      this.rangeLimit = rangeLimit;
    }
  }

  @Override
  public void resetNodeStore(String dbid, long startID) throws Exception {
    if (wrappedGraphStore != null) {
      wrappedGraphStore.resetNodeStore(dbid, startID);
    }
  }

  @Override
  public long addNode(String dbid, Node node) throws Exception {
    addNodes++;
    if (wrappedGraphStore != null) {
      return wrappedGraphStore.addNode(dbid, node);
    }
    return 0;
  }

  @Override
  public Node getNode(String dbid, int type, long id) throws Exception {
    getNodes++;
    if (wrappedGraphStore != null) {
      return wrappedGraphStore.getNode(dbid, type, id);
    }
    return null;
  }

  @Override
  public boolean updateNode(String dbid, Node node) throws Exception {
    updateNodes++;
    if (wrappedGraphStore != null) {
      return wrappedGraphStore.updateNode(dbid, node);
    }
    return false;
  }

  @Override
  public boolean deleteNode(String dbid, int type, long id) throws Exception {
    deleteNodes++;
    if (wrappedGraphStore != null) {
      return wrappedGraphStore.deleteNode(dbid, type, id);
    }
    return false;
  }
}

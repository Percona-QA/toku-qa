drop table if exists apavlo;

CREATE TABLE apavlo 
(
  id                        int not null,
  peer_id                   int not null,
  torrent_snapshot_id       int not null,
  upload_speed              decimal(10,4) not null,
  download_speed            decimal(10,4) not null,
  payload_upload_speed      decimal(10,4) not null,
  payload_download_speed    decimal(10,4) not null,
  total_upload              int not null,
  total_download            int not null,
  fail_count                int not null,
  hashfail_count            int not null,
  progress                  decimal(10,7) not null,
  created                   timestamp not null,
  primary key (id),
  key idx_1 (peer_id, created),
  key idx_2 (torrent_snapshot_id, created),
  key idx_3 (created)
) ENGINE=innodb
ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=2;

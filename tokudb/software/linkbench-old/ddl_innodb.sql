drop database if exists linkdb;

create database linkdb;

use linkdb;

CREATE TABLE `linktable` (
  `id1` bigint(20) unsigned NOT NULL DEFAULT '0',
  `id1_type` int(10) unsigned NOT NULL DEFAULT '0',
  `id2` bigint(20) unsigned NOT NULL DEFAULT '0',
  `id2_type` int(10) unsigned NOT NULL DEFAULT '0',
  `link_type` bigint(20) unsigned NOT NULL DEFAULT '0',
  `visibility` tinyint(3) NOT NULL DEFAULT '0',
  `data` varchar(255) NOT NULL DEFAULT '',
  `time` bigint(20) unsigned NOT NULL DEFAULT '0',
  `version` int(11) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id1`,`id2`,`link_type`),
  KEY `id2_vis` (`id2`,`visibility`),
  KEY `id1_type` (`id1`,`link_type`,`visibility`,`time`,`version`,`data`)
) ENGINE=innodb DEFAULT CHARSET=latin1;

CREATE TABLE `counttable` (
  `id` bigint(20) unsigned NOT NULL DEFAULT '0',
  `id_type` int(10) unsigned NOT NULL DEFAULT '0',
  `link_type` bigint(20) unsigned NOT NULL DEFAULT '0',
  `count` int(10) unsigned NOT NULL DEFAULT '0',
  `time` bigint(20) unsigned NOT NULL DEFAULT '0',
  `version` bigint(20) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`,`link_type`)
) ENGINE=innodb DEFAULT CHARSET=latin1


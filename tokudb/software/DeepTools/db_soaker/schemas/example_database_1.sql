CREATE TABLE IF NOT EXISTS `table1` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `column1` int(10) unsigned NOT NULL,
  `column2` varchar(40) NOT NULL,
  `column3` date NOT NULL,
  `column4` datetime NOT NULL,
  `column5` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `column6` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `column7` char(6) NOT NULL,
  `column8` tinytext NOT NULL,
  `column9` binary(16) NOT NULL,
  `column10` tinyblob NOT NULL,
  `column11` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index1` (`column1`,`column9`,`column5`),
  KEY `column4` (`column4`),
  KEY `index2` (`column9`,`column5`)
);

CREATE TABLE IF NOT EXISTS `table2` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `column1` varchar(100) NOT NULL DEFAULT '',
  `column2` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `column3` int(11) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `column1` (`column1`),
  KEY `column2` (`column2`),
  KEY `column3` (`column3`)
);

CREATE TABLE IF NOT EXISTS `table3` (
  `column1` binary(16) NOT NULL,
  `column2` varchar(20) NOT NULL,
  `column3` double NOT NULL,
  `column4` float NOT NULL,
  `column5` double NOT NULL,
  `column6` bit(32) NOT NULL,
  KEY `column2` (`column2`),
  KEY `column5` (`column5`),
  KEY `column1` (`column1`)
);

CREATE TABLE IF NOT EXISTS `table4` (
  `id` int(10) unsigned NOT NULL,
  `column1` int(11) NOT NULL,
  `column2` longtext NOT NULL,
  PRIMARY KEY (`id`),
  KEY `column1` (`column1`)
);

CREATE TABLE IF NOT EXISTS `table5` (
  `id` bigint(20) unsigned NOT NULL,
  `column1` int(11) NOT NULL,
  `column2` datetime DEFAULT NULL,
  `column3` float NOT NULL,
  `column4` varchar(20) NOT NULL,
  `column5` binary(16) NOT NULL,
  UNIQUE KEY `id` (`id`),
  KEY `column1` (`column1`),
  KEY `index1` (`column4`,`column2`),
  KEY `column4` (`column4`),
  KEY `column5` (`column5`)
);

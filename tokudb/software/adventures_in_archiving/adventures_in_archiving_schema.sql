-- MySQL dump 10.13  Distrib 5.5.29, for Linux (x86_64)
--
-- Host: localhost    Database: adventures_in_archiving
-- ------------------------------------------------------
-- Server version	5.5.29-29.4

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `archive_table`
--

DROP TABLE IF EXISTS `archive_table`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `archive_table` (
  `id` int(11) NOT NULL,
  `dat` varchar(1000) DEFAULT NULL
) ENGINE=ARCHIVE DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `compressed_data`
--

DROP TABLE IF EXISTS `compressed_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `compressed_data` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dat` blob,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `compressed_row`
--

DROP TABLE IF EXISTS `compressed_row`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `compressed_row` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dat` varchar(1000) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `non_compressed_data`
--

DROP TABLE IF EXISTS `non_compressed_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `non_compressed_data` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dat` varchar(1000) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


DROP TABLE IF EXISTS `tokudb_lzma`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tokudb_lzma` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dat` varchar(1000) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=TokuDB row_format=tokudb_lzma DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `tokudb_quicklz`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tokudb_quicklz` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dat` varchar(1000) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=TokuDB row_format=tokudb_quicklz DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `tokudb_zlib`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tokudb_zlib` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dat` varchar(1000) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=TokuDB row_format=tokudb_zlib DEFAULT CHARSET=latin1;


/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2013-01-31 13:07:45

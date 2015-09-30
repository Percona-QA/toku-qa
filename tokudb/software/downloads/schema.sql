drop table if exists downloads_tsv;

create table downloads_tsv (
  download_id        int(11) not null primary key,
  filename           varchar(100) not null,
  ip_address         varchar(20) not null,
  download_datetime  datetime not null,
  first_name         varchar(50),
  last_name          varchar(50),
  company_name       varchar(50),
  email_address      varchar(50)
) engine=tokudb;

drop table if exists downloads_raw;

create table downloads_raw (
  filename          varchar(100) not null,
  ip_address        varchar(20) not null,
  email_address     varchar(100) not null,
  last_name         varchar(50) not null,
  first_name        varchar(50) not null,
  company_name      varchar(50) not null,
  download_datetime datetime not null
) engine=tokudb;

-- mysql> describe t_product_downloads;
-- +----------------+--------------+------+-----+---------+----------------+
-- | Field          | Type         | Null | Key | Default | Extra          |
-- +----------------+--------------+------+-----+---------+----------------+
-- | download_id    | int(11)      | NO   | PRI | NULL    | auto_increment |
-- | user_id        | int(11)      | YES  |     | NULL    |                |
-- | filename       | varchar(255) | NO   |     | NULL    |                |
-- | remote_address | varchar(255) | NO   |     | NULL    |                |
-- | create_date    | datetime     | NO   |     | NULL    |                |
-- +----------------+--------------+------+-----+---------+----------------+

-- mysql> describe t_customers;
-- +--------------+--------------+------+-----+---------+----------------+
-- | Field        | Type         | Null | Key | Default | Extra          |
-- +--------------+--------------+------+-----+---------+----------------+
-- | userID       | int(11)      | NO   | PRI | NULL    | auto_increment |
-- | username     | varchar(255) | NO   |     | NULL    |                |
-- | password     | varchar(41)  | YES  |     | NULL    |                |
-- | created      | datetime     | NO   |     | NULL    |                |
-- | updated      | datetime     | YES  |     | NULL    |                |
-- | lastLoggedIn | datetime     | YES  |     | NULL    |                |
-- | firstName    | varchar(255) | YES  |     | NULL    |                |
-- | lastName     | varchar(255) | YES  |     | NULL    |                |
-- | active       | tinyint(4)   | NO   |     | 1       |                |
-- | company      | varchar(100) | YES  |     | NULL    |                |
-- | title        | varchar(255) | YES  |     | NULL    |                |
-- | phone        | varchar(255) | YES  |     | NULL    |                |
-- | source       | varchar(50)  | YES  |     | NULL    |                |
-- | guid         | varchar(255) | YES  |     | NULL    |                |
-- | regform      | varchar(100) | YES  |     | NULL    |                |
-- | country      | varchar(255) | YES  |     | NULL    |                |
-- +--------------+--------------+------+-----+---------+----------------+

drop table if exists registrations;

create table registrations (
  userid         int(11) NOT NULL AUTO_INCREMENT,
  username       varchar(255) NOT NULL,
  created        datetime NOT NULL,
  lastLoggedIn   datetime DEFAULT NULL,
  firstname      varchar(255) DEFAULT NULL,
  lastname       varchar(255) DEFAULT NULL,
  company        varchar(100) DEFAULT NULL,
  title          varchar(255) DEFAULT NULL,
  phone          varchar(255) DEFAULT NULL,
  source         varchar(50) DEFAULT NULL,
  regform        varchar(100) DEFAULT NULL,
  country        varchar(255) DEFAULT NULL,
  primary key (userid)
) engine=tokudb;

-- mysql> describe t_customers;
-- +--------------+--------------+------+-----+---------+----------------+
-- | Field        | Type         | Null | Key | Default | Extra          |
-- +--------------+--------------+------+-----+---------+----------------+
-- | userID       | int(11)      | NO   | PRI | NULL    | auto_increment |
-- | username     | varchar(255) | NO   |     | NULL    |                |
-- | password     | varchar(41)  | YES  |     | NULL    |                |
-- | created      | datetime     | NO   |     | NULL    |                |
-- | updated      | datetime     | YES  |     | NULL    |                |
-- | lastLoggedIn | datetime     | YES  |     | NULL    |                |
-- | firstName    | varchar(255) | YES  |     | NULL    |                |
-- | lastName     | varchar(255) | YES  |     | NULL    |                |
-- | active       | tinyint(4)   | NO   |     | 1       |                |
-- | company      | varchar(100) | YES  |     | NULL    |                |
-- | title        | varchar(255) | YES  |     | NULL    |                |
-- | phone        | varchar(255) | YES  |     | NULL    |                |
-- | source       | varchar(50)  | YES  |     | NULL    |                |
-- | guid         | varchar(255) | YES  |     | NULL    |                |
-- | regform      | varchar(100) | YES  |     | NULL    |                |
-- | country      | varchar(255) | YES  |     | NULL    |                |
-- +--------------+--------------+------+-----+---------+----------------+

-- select date_format(created,'%Y-%m') as month, count(*) as registrations from registrations where date_format(created,'%Y') in ('2013','2012') group by date_format(created,'%Y-%m') order by 1;
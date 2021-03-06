# Copyright (C) 2008-2009 Sun Microsystems, Inc. All rights reserved.
# Use is subject to license terms.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301
# USA

package GenTest::Executor::MySQL;

require Exporter;

@ISA = qw(GenTest::Executor);

use strict;
use DBI;
use GenTest;
use GenTest::Constants;
use GenTest::Result;
use GenTest::Executor;
use Time::HiRes;

use constant RARE_QUERY_THRESHOLD	=> 5;

my %reported_errors;

my @errors = (
	"The target table .*? of the .*? is",
	"Duplicate entry '.*?' for key '.*?'",
	"Can't DROP '.*?'",
	"Duplicate key name '.*?'",
	"Duplicate column name '.*?'",
	"Record has changed since last read in table '.*?'",
	"savepoint does not exist",
	"'.*?' doesn't exist",
	" .*? does not exist",
	"'.*?' already exists",
	"Unknown database '.*?'",
	"Unknown table '.*?'",
	"Unknown column '.*?'",
	"Unknown event '.*?'",
	"Column '.*?' specified twice",
	"Column '.*?' cannot be null",
	"Column '.*?' in .*? clause is ambiguous",
	"Duplicate partition name .*?",
	"Tablespace '.*?' not empty",
	"Tablespace '.*?' already exists",
	"Tablespace data file '.*?' already exists",
	"Can't find file: '.*?'",
	"Table '.*?' already exists",
	"You can't specify target table '.*?' for update",
	"Illegal mix of collations .*?, .*?, .*? for operation '.*?'",
	"Illegal mix of collations .*? and .*? for operation '.*?'",
	"Invalid .*? character string: '.*?'",
	"This version of MySQL doesn't yet support '.*?'",
	"PROCEDURE .*? already exists",
	"FUNCTION .*? already exists",
	"'.*?' isn't in GROUP BY",
	"non-grouping field '.*?' is used in HAVING clause",
	"Table has no partition for value .*?",
	"Unknown prepared statement handler (.*?) given to EXECUTE",
	"Unknown prepared statement handler (.*?) given to DEALLOCATE PREPARE",
	"Can't execute the query because you have a conflicting read lock",
	"Can't execute the given command because you have active locked tables or an active transaction",
	"Not unique table/alias: '.*?'",
	"View .* references invalid table(s) or column(s) or function(s) or definer/invoker of view lack rights to use them",
	"Unknown thread id: .*?" ,
	"Unknown table '.*?' in .*?",
	"Table '.*?' is read only",
	"Duplicate condition: .*?",
	"Duplicate condition information item '.*?'",
	"Undefined CONDITION: .*?",
	"Incorrect .*? value '.*?'",
	"Recursive limit \d+ (as set by the max_sp_recursion_depth variable) was exceeded for routine .*?",
        "There is no such grant defined for user '.*?' on host '.*?' on table '.*?'",
	"There is no such grant defined for user '.*?' on host '.*?'",
	"'.*?' is not a .*?",
	"Incorrect usage of .*? and .*?",
	"Can't reopen table: '.*?'",
	"Trigger's '.*?' is view or temporary table",
	"Column '.*?' is not updatable"
);

my @patterns = map { qr{$_}i } @errors;

use constant EXECUTOR_MYSQL_AUTOCOMMIT => 20;

#
# Column positions for SHOW SLAVES
# 

use constant SLAVE_INFO_HOST => 1;
use constant SLAVE_INFO_PORT => 2;

#
# MySQL status codes taken from errmsg.h
#

# Server has crashed

use constant	ER_CONNECTION_ERROR	=> 2002;
use constant 	ER_CONN_HOST_ERROR	=> 2003;
use constant	ER_SERVER_GONE_ERROR	=> 2006;
use constant	ER_SERVER_LOST_EXTENDED	=> 2055;
use constant	ER_SERVER_LOST		=> 2013;

# Syntax error

use constant	ER_PARSE_ERROR		=> 1064;
use constant	ER_SYNTAX_ERROR		=> 1149;

# Semantic errors

use constant	ER_UPDATE_TABLE_USED	=> 1093;
use constant	ER_BAD_FIELD_ERROR	=> 1054;
use constant	ER_NO_SUCH_TABLE	=> 1146;
use constant	ER_BAD_TABLE_ERROR	=> 1051;
use constant 	ER_CANT_DROP_FIELD_OR_KEY	=> 1091;
use constant	ER_FIELD_SPECIFIED_TWICE	=> 1110;
use constant	ER_MULTIPLE_PRI_KEY	=> 1068;
use constant	ER_DUP_FIELDNAME	=> 1060;
use constant	ER_DUP_KEYNAME		=> 1061;
use constant	ER_SAME_NAME_PARTITION	=> 1517;
use constant	ER_PARTITION_WRONG_VALUES_ERROR	=> 1480;
use constant	ER_CANT_LOCK		=> 1015;
use constant	ER_TABLESPACE_EXIST	=> 1683;
use constant	ER_NO_SUCH_TABLESPACE	=> 1684;
use constant	ER_SP_DOES_NOT_EXIST	=> 1305;
use constant	ER_TABLESPACE_NOT_EMPTY	=> 1721;
use constant	ER_TABLESPACE_DATAFILE_EXIST => 1726;
use constant	ER_BAD_DB_ERROR		=> 1049;
use constant	ER_PARTITION_MGMT_ON_NONPARTITIONED	=> 1505;
use constant	ER_UNKNOWN_SYSTEM_VARIABLE	=> 1193;
use constant	ER_VAR_CANT_BE_READ	=> 1233;
use constant	ER_TRG_DOES_NOT_EXIST	=> 1360;
use constant	ER_NO_DB_ERROR		=> 1046;
use constant	ER_KEY_COLUMN_DOES_NOT_EXIST => 1072;
use constant	ER_SP_DOES_NOT_EXIST	=> 1305;
use constant	ER_BAD_NULL_ERROR	=> 1048;
use constant	ER_SAME_NAME_PARTITION	=> 1517;
use constant	ER_TABLE_EXISTS_ERROR	=> 1050;
use constant	ER_MULTIPLE_PRI_KEY	=> 1068;
use constant	ER_STMT_NOT_ALLOWED_IN_SF_OR_TRG	=> 1336;
use constant	ER_NOT_SUPPORTED_YET	=> 1235;
use constant	ER_STORED_FUNCTION_PREVENTS_SWITCH_BINLOG_FORMAT	=> 1560;
use constant	ER_EVENT_INTERVAL_NOT_POSITIVE_OR_TOO_BIG	=> 1542;
use constant	ER_COMMIT_NOT_ALLOWED_IN_SF_OR_TRG => 1422;
use constant	ER_CANNOT_USER		=> 1396;
use constant	ER_CHECK_NOT_IMPLEMENTED=> 1178;
use constant	ER_CANT_AGGREGATE_2COLLATIONS	=> 1267;
use constant	ER_CANT_AGGREGATE_3COLLATIONS	=> 1270;
use constant	ER_CANT_AGGREGATE_NCOLLATIONS 	=> 1271;
use constant	ER_INVALID_CHARACTER_STRING	=> 1300;
use constant	ER_UNKNOWN_SYSTEM_VARIABLE	=> 1193;
use constant	ER_SP_ALREADY_EXISTS		=> 1304;
use constant	ER_EVENT_ALREADY_EXISTS		=> 1537;
use constant	ER_TRG_ALREADY_EXISTS		=> 1359;
use constant	ER_WRONG_FIELD_WITH_GROUP	=> 1055;
use constant	ER_NON_GROUPING_FIELD_USED	=> 1463;
use constant	ER_NON_UNIQ_ERROR		=> 1052;
use constant	ER_EVENT_DOES_NOT_EXIST		=> 1539;
use constant 	ER_NONEXISTING_GRANT		=> 1141;
use constant	ER_NONEXISTING_TABLE_GRANT	=> 1147;
use constant	ER_WRONG_AUTO_KEY		=> 1075;
use constant	ER_SP_DUP_PARAM			=> 1330;
use constant	ER_WRONG_OBJECT			=> 1347;
use constant	ER_WRONG_USAGE			=> 1221;
use constant	ER_VIEW_SELECT_DERIVED		=> 1349;
use constant	ER_DB_CREATE_EXISTS		=> 1007;
use constant	ER_CANT_REOPEN_TABLE		=> 1137;
use constant	ER_TRG_ON_VIEW_OR_TEMP_TABLE	=> 1361;
use constant	ER_VIEW_SELECT_TMPTABLE		=> 1352;
use constant	ER_NONUPDATEABLE_COLUMN		=> 1348;

use constant	ER_PARTITION_MGMT_ON_NONPARTITIONED	=> 1505;
use constant	ER_DROP_PARTITION_NON_EXISTENT		=> 1507;
use constant	ER_DROP_LAST_PARTITION			=> 1508;
use constant	ER_COALESCE_ONLY_ON_HASH_PARTITION	=> 1509;
use constant	ER_REORG_HASH_ONLY_ON_SAME_NO		=> 1510;
use constant	ER_REORG_NO_PARAM_ERROR			=> 1511;
use constant	ER_ONLY_ON_RANGE_LIST_PARTITION		=> 1512;
use constant	ER_NO_PARTITION_FOR_GIVEN_VALUE		=> 1526;
use constant	ER_PARTITION_MAXVALUE_ERROR		=> 1481;
use constant	ER_WRONG_PARTITION_NAME			=> 1567;
use constant	ER_NO_PARTS_ERROR			=> 1504;

use constant	ER_NON_INSERTABLE_TABLE			=> 1471;
use constant	ER_NON_UPDATABLE_TABLE			=> 1288;

use constant	ER_UNKNOWN_KEY_CACHE			=> 1284;

use constant 	ER_CANT_CHANGE_TX_ISOLATION		=> 1568;

# The PREPARE already failed
use constant  	ER_UNKNOWN_STMT_HANDLER => 1243 ;
# Table mentioned more than once in statement processing a table list.
use constant  	ER_NONUNIQ_TABLE	=> 1066 ;
# Base table of a view was modified or dropped or ..
use constant  	ER_VIEW_INVALID	=> 1356 ;

use constant	ER_NO_SUCH_THREAD			=> 1094;
use constant	ER_QUERY_INTERRUPTED			=> 1317;

use constant	ER_UNKNOWN_TABLE			=> 1109;
use constant	ER_FILE_NOT_FOUND			=> 1017;
use constant 	ER_WRONG_MRG_TABLE			=> 1168;

use constant	ER_OPEN_AS_READONLY			=> 1036;

use constant	ER_SP_DUP_COND				=> 1332;
use constant	ER_SP_DUP_HANDLER			=> 1413;
use constant	ER_SIGNAL_BAD_CONDITION_TYPE		=> 1646;
use constant	ER_SP_COND_MISMATCH			=> 1319;
use constant	ER_DUP_SIGNAL_SET			=> 1641;
use constant	ER_WRONG_VALUE				=> 1525;
use constant	ER_SP_NO_RECURSION			=> 1424;
use constant	ER_SIGNAL_EXCEPTION			=> 1644;
use constant	ER_RESIGNAL_WITHOUT_ACTIVE_HANDLER	=> 1645;
use constant	ER_WRONG_VALUE_FOR_VAR			=> 1231;
use constant	ER_SP_NO_RETSET				=> 1415;
use constant	ER_SP_NORETURNEND			=> 1321;
use constant	ER_CANT_UPDATE_USED_TABLE_IN_SF_OR_TRG	=> 1442;
use constant	ER_SP_RECURSION_LIMIT			=> 1456;

# Transaction errors

use constant	ER_LOCK_DEADLOCK	=> 1213;
use constant	ER_LOCK_WAIT_TIMEOUT	=> 1205;
use constant	ER_CHECKREAD		=> 1020;
use constant	ER_DUP_KEY		=> 1022;
use constant	ER_DUP_ENTRY		=> 1062;
use constant	ER_LOCK_OR_ACTIVE_TRANSACTION	=> 1192;
# The table is already read locked by the same seeion.
use constant  	ER_CANT_UPDATE_WITH_READLOCK => 1223 ;

# Storage engine failures

use constant	ER_GET_ERRNO			=> 1030;
use constant	ER_UNKNOWN_STORAGE_ENGINE 	=> 1286;

# Database corruption

use constant	ER_CRASHED1		=> 126;
use constant	ER_CRASHED2		=> 145;
use constant	ER_CRASHED_ON_USAGE	=> 1194;
use constant	ER_NOT_KEYFILE		=> 1034;
use constant	ER_UNEXPECTED_EOF	=> 1039;
use constant	ER_SP_PROC_TABLE_CORRUPT=> 1457;
# Backup

use constant	ER_BACKUP_NOT_ENABLED	=> 1789;
use constant	ER_BACKUP_SEND_DATA1	=> 1670;
use constant	ER_BACKUP_SEND_DATA2	=> 1687;
use constant	ER_BACKUP_PROGRESS_TABLES => 1691;
use constant	ER_BACKUP_RUNNING	=> 1651;

# Out of disk space, quotas, etc.

use constant	ER_RECORD_FILE_FULL     => 1114;
use constant	ER_DISK_FULL            => 1021;
use constant	ER_OUTOFMEMORY		=> 1037;
use constant	ER_CON_COUNT_ERROR	=> 1040;
use constant	ER_OUT_OF_RESOURCES	=> 1041;
use constant	ER_CANT_CREATE_THREAD	=> 1135;
use constant	ER_STACK_OVERRUN	=> 1119;

use constant	ER_SERVER_SHUTDOWN      => 1053;

use constant	ER_FEATURE_DISABLED	=> 1289;
use constant	ER_OPTION_PREVENTS_STATEMENT	=> 1290;

my %err2type = (

	ER_GET_ERRNO()		=> STATUS_SEMANTIC_ERROR,

	ER_CONNECTION_ERROR()	=> STATUS_SERVER_CRASHED,
	ER_CONN_HOST_ERROR()	=> STATUS_SERVER_CRASHED,
	ER_SERVER_GONE_ERROR()	=> STATUS_SERVER_CRASHED,
	ER_SERVER_LOST_EXTENDED()	=> STATUS_SERVER_CRASHED,
	ER_SERVER_LOST()	=> STATUS_SERVER_CRASHED,

	ER_PARSE_ERROR()	=> STATUS_SYNTAX_ERROR,
	ER_SYNTAX_ERROR()	=> STATUS_SYNTAX_ERROR,

	ER_UPDATE_TABLE_USED()	=> STATUS_SEMANTIC_ERROR,
	ER_NO_SUCH_TABLE()	=> STATUS_SEMANTIC_ERROR,
	ER_BAD_TABLE_ERROR()	=> STATUS_SEMANTIC_ERROR,
	ER_BAD_FIELD_ERROR()	=> STATUS_SEMANTIC_ERROR,
	ER_CANT_DROP_FIELD_OR_KEY()	=> STATUS_SEMANTIC_ERROR,
	ER_FIELD_SPECIFIED_TWICE()	=> STATUS_SEMANTIC_ERROR,
	ER_MULTIPLE_PRI_KEY()	=> STATUS_SEMANTIC_ERROR,
	ER_DUP_FIELDNAME()	=> STATUS_SEMANTIC_ERROR,
	ER_DUP_KEYNAME()	=> STATUS_SEMANTIC_ERROR,
	ER_SAME_NAME_PARTITION()=> STATUS_SEMANTIC_ERROR,
	ER_PARTITION_WRONG_VALUES_ERROR() => STATUS_SEMANTIC_ERROR,
	ER_CANT_LOCK()		=> STATUS_SEMANTIC_ERROR,
	ER_TABLESPACE_EXIST()	=> STATUS_SEMANTIC_ERROR,
	ER_NO_SUCH_TABLESPACE()	=> STATUS_SEMANTIC_ERROR,
	ER_SP_DOES_NOT_EXIST()	=> STATUS_SEMANTIC_ERROR,
	ER_TABLESPACE_NOT_EMPTY()	=> STATUS_SEMANTIC_ERROR,
	ER_TABLESPACE_DATAFILE_EXIST()	=> STATUS_SEMANTIC_ERROR,
	ER_BAD_DB_ERROR()	=> STATUS_SEMANTIC_ERROR,
	ER_PARTITION_MGMT_ON_NONPARTITIONED()	=> STATUS_SEMANTIC_ERROR,
	ER_UNKNOWN_SYSTEM_VARIABLE() => STATUS_SEMANTIC_ERROR,
	ER_VAR_CANT_BE_READ()	=> STATUS_SEMANTIC_ERROR,
	ER_TRG_DOES_NOT_EXIST() => STATUS_SEMANTIC_ERROR,
	ER_NO_DB_ERROR()	=> STATUS_SEMANTIC_ERROR,
	ER_KEY_COLUMN_DOES_NOT_EXIST()	=> STATUS_SEMANTIC_ERROR,
	ER_SP_DOES_NOT_EXIST()	=> STATUS_SEMANTIC_ERROR,
	ER_BAD_NULL_ERROR()	=> STATUS_SEMANTIC_ERROR,
	ER_SAME_NAME_PARTITION() => STATUS_SEMANTIC_ERROR,
	ER_TABLE_EXISTS_ERROR() => STATUS_SEMANTIC_ERROR,
	ER_MULTIPLE_PRI_KEY()	=> STATUS_SEMANTIC_ERROR,
	ER_STMT_NOT_ALLOWED_IN_SF_OR_TRG() => STATUS_SEMANTIC_ERROR,
	ER_NOT_SUPPORTED_YET()	=> STATUS_SEMANTIC_ERROR,
	ER_STORED_FUNCTION_PREVENTS_SWITCH_BINLOG_FORMAT() => STATUS_SEMANTIC_ERROR,
	ER_EVENT_INTERVAL_NOT_POSITIVE_OR_TOO_BIG() => STATUS_SEMANTIC_ERROR,
	ER_COMMIT_NOT_ALLOWED_IN_SF_OR_TRG() => STATUS_SEMANTIC_ERROR,
	ER_CANNOT_USER() => STATUS_SEMANTIC_ERROR,
	ER_CHECK_NOT_IMPLEMENTED() => STATUS_SEMANTIC_ERROR,
	ER_CANT_AGGREGATE_2COLLATIONS() => STATUS_SEMANTIC_ERROR,
	ER_CANT_AGGREGATE_3COLLATIONS() => STATUS_SEMANTIC_ERROR,
	ER_CANT_AGGREGATE_NCOLLATIONS() => STATUS_SEMANTIC_ERROR,
	ER_INVALID_CHARACTER_STRING()	=> STATUS_SEMANTIC_ERROR,
	ER_UNKNOWN_SYSTEM_VARIABLE()	=> STATUS_SEMANTIC_ERROR,
	ER_SP_ALREADY_EXISTS() 		=> STATUS_SEMANTIC_ERROR,
	ER_EVENT_ALREADY_EXISTS()	=> STATUS_SEMANTIC_ERROR,
	ER_TRG_ALREADY_EXISTS()		=> STATUS_SEMANTIC_ERROR,
	ER_WRONG_FIELD_WITH_GROUP()	=> STATUS_SEMANTIC_ERROR,
	ER_NON_GROUPING_FIELD_USED()	=> STATUS_SEMANTIC_ERROR,
	ER_NON_UNIQ_ERROR()		=> STATUS_SEMANTIC_ERROR,
	ER_EVENT_DOES_NOT_EXIST()	=> STATUS_SEMANTIC_ERROR,
	ER_NONEXISTING_GRANT()		=> STATUS_SEMANTIC_ERROR,
	ER_NONEXISTING_TABLE_GRANT()	=> STATUS_SEMANTIC_ERROR,
	ER_WRONG_AUTO_KEY()		=> STATUS_SEMANTIC_ERROR,
	ER_SP_DUP_PARAM()		=> STATUS_SEMANTIC_ERROR,
	ER_WRONG_OBJECT()		=> STATUS_SEMANTIC_ERROR,
	ER_WRONG_USAGE()		=> STATUS_SEMANTIC_ERROR,
	ER_VIEW_SELECT_DERIVED()	=> STATUS_SEMANTIC_ERROR,
	ER_DB_CREATE_EXISTS()		=> STATUS_SEMANTIC_ERROR,
	ER_CANT_REOPEN_TABLE()		=> STATUS_SEMANTIC_ERROR,
	ER_TRG_ON_VIEW_OR_TEMP_TABLE()	=> STATUS_SEMANTIC_ERROR,
	ER_VIEW_SELECT_TMPTABLE()	=> STATUS_SEMANTIC_ERROR,
	ER_NONUPDATEABLE_COLUMN()	=> STATUS_SEMANTIC_ERROR,

	ER_PARTITION_MGMT_ON_NONPARTITIONED()	=> STATUS_SEMANTIC_ERROR,
	ER_DROP_LAST_PARTITION()		=> STATUS_SEMANTIC_ERROR,
	ER_COALESCE_ONLY_ON_HASH_PARTITION()	=> STATUS_SEMANTIC_ERROR,
	ER_REORG_HASH_ONLY_ON_SAME_NO()		=> STATUS_SEMANTIC_ERROR,
	ER_REORG_NO_PARAM_ERROR()		=> STATUS_SEMANTIC_ERROR,
	ER_ONLY_ON_RANGE_LIST_PARTITION()	=> STATUS_SEMANTIC_ERROR,
	ER_NO_PARTITION_FOR_GIVEN_VALUE()	=> STATUS_SEMANTIC_ERROR,
	ER_DROP_PARTITION_NON_EXISTENT()	=> STATUS_SEMANTIC_ERROR,
	ER_PARTITION_MAXVALUE_ERROR()		=> STATUS_SEMANTIC_ERROR,
	ER_WRONG_PARTITION_NAME()		=> STATUS_SEMANTIC_ERROR,
	ER_NO_PARTS_ERROR()			=> STATUS_SEMANTIC_ERROR,

	ER_NON_INSERTABLE_TABLE()		=> STATUS_SEMANTIC_ERROR,
	ER_NON_UPDATABLE_TABLE()		=> STATUS_SEMANTIC_ERROR,

	ER_UNKNOWN_KEY_CACHE()			=> STATUS_SEMANTIC_ERROR,
	
	ER_CANT_CHANGE_TX_ISOLATION()		=> STATUS_SEMANTIC_ERROR,

	ER_UNKNOWN_STMT_HANDLER()		=> STATUS_SEMANTIC_ERROR,
	ER_CANT_UPDATE_WITH_READLOCK()		=> STATUS_SEMANTIC_ERROR,
	ER_NONUNIQ_TABLE()			=> STATUS_SEMANTIC_ERROR,
	ER_VIEW_INVALID()			=> STATUS_SEMANTIC_ERROR,

	ER_NO_SUCH_THREAD()			=> STATUS_SEMANTIC_ERROR,
	ER_QUERY_INTERRUPTED()			=> STATUS_SEMANTIC_ERROR,

	ER_UNKNOWN_TABLE()			=> STATUS_SEMANTIC_ERROR,
	ER_FILE_NOT_FOUND()			=> STATUS_SEMANTIC_ERROR,
	ER_WRONG_MRG_TABLE()			=> STATUS_SEMANTIC_ERROR,
	ER_OPEN_AS_READONLY()			=> STATUS_SEMANTIC_ERROR,

	ER_SP_DUP_COND()			=> STATUS_SEMANTIC_ERROR,
	ER_SP_DUP_HANDLER()			=> STATUS_SEMANTIC_ERROR,
	ER_SIGNAL_BAD_CONDITION_TYPE()		=> STATUS_SEMANTIC_ERROR,
	ER_SP_COND_MISMATCH()			=> STATUS_SEMANTIC_ERROR,
	ER_DUP_SIGNAL_SET()			=> STATUS_SEMANTIC_ERROR,
	ER_WRONG_VALUE()			=> STATUS_SEMANTIC_ERROR,
	ER_SP_NO_RECURSION()			=> STATUS_SEMANTIC_ERROR,
	ER_SIGNAL_EXCEPTION()			=> STATUS_SEMANTIC_ERROR,
	ER_RESIGNAL_WITHOUT_ACTIVE_HANDLER()	=> STATUS_SEMANTIC_ERROR,
	ER_WRONG_VALUE_FOR_VAR()		=> STATUS_SEMANTIC_ERROR,
	ER_SP_NO_RETSET()			=> STATUS_SEMANTIC_ERROR,
	ER_SP_NORETURNEND()			=> STATUS_SEMANTIC_ERROR,
	ER_CANT_UPDATE_USED_TABLE_IN_SF_OR_TRG()=> STATUS_SEMANTIC_ERROR,
	ER_SP_RECURSION_LIMIT()			=> STATUS_SEMANTIC_ERROR,

	ER_LOCK_OR_ACTIVE_TRANSACTION => STATUS_TRANSACTION_ERROR,

	ER_LOCK_DEADLOCK()	=> STATUS_TRANSACTION_ERROR,
	ER_LOCK_WAIT_TIMEOUT()	=> STATUS_TRANSACTION_ERROR,
	ER_CHECKREAD()		=> STATUS_TRANSACTION_ERROR,
	ER_DUP_KEY()		=> STATUS_TRANSACTION_ERROR,
	ER_DUP_ENTRY()		=> STATUS_TRANSACTION_ERROR,
	
	ER_NOT_KEYFILE()	=> STATUS_DATABASE_CORRUPTION,
	ER_CRASHED_ON_USAGE()	=> STATUS_DATABASE_CORRUPTION,
	ER_CRASHED1()		=> STATUS_DATABASE_CORRUPTION,
	ER_CRASHED2()		=> STATUS_DATABASE_CORRUPTION,
	ER_UNEXPECTED_EOF()	=> STATUS_DATABASE_CORRUPTION,
#	ER_SP_PROC_TABLE_CORRUPT() => STATUS_DATABASE_CORRUPTION,	# this error is bogus due to bug # 47870

	ER_BACKUP_SEND_DATA1()	=> STATUS_BACKUP_FAILURE,
	ER_BACKUP_SEND_DATA2()	=> STATUS_BACKUP_FAILURE,
	ER_BACKUP_PROGRESS_TABLES() => STATUS_BACKUP_FAILURE,
	ER_BACKUP_RUNNING()	=> STATUS_SEMANTIC_ERROR,

	ER_CANT_CREATE_THREAD()	=> STATUS_ENVIRONMENT_FAILURE,
	ER_OUT_OF_RESOURCES()	=> STATUS_ENVIRONMENT_FAILURE,
	ER_CON_COUNT_ERROR()	=> STATUS_ENVIRONMENT_FAILURE,
	ER_RECORD_FILE_FULL()   => STATUS_ENVIRONMENT_FAILURE,
	ER_DISK_FULL()          => STATUS_ENVIRONMENT_FAILURE,
	ER_OUTOFMEMORY()	=> STATUS_ENVIRONMENT_FAILURE,
	ER_STACK_OVERRUN()	=> STATUS_ENVIRONMENT_FAILURE,
	ER_UNKNOWN_STORAGE_ENGINE() => STATUS_ENVIRONMENT_FAILURE,
	ER_BACKUP_NOT_ENABLED()	=> STATUS_ENVIRONMENT_FAILURE,
	ER_FEATURE_DISABLED()	=> STATUS_ENVIRONMENT_FAILURE,
	ER_OPTION_PREVENTS_STATEMENT() => STATUS_ENVIRONMENT_FAILURE,

	ER_SERVER_SHUTDOWN()    => STATUS_SERVER_KILLED
);

sub init {
	my $executor = shift;
	my $dbh = DBI->connect($executor->dsn(), undef, undef, {
		PrintError => 0,
		RaiseError => 0,
		AutoCommit => 1,
		mysql_multi_statements => 1
	} );

	if (not defined $dbh) {
		say("connect() to dsn ".$executor->dsn()." failed: ".$DBI::errstr);
		return STATUS_ENVIRONMENT_FAILURE;
	}

	$executor->setDbh($dbh);

	# 
	# Hack around bug 35676, optiimzer_switch must be set sesson-wide in order to have effect
	# So we read it from the GLOBAL_VARIABLE table and set it locally to the session
	#

	$dbh->do("
		SET optimizer_switch = (
			SELECT variable_value
			FROM INFORMATION_SCHEMA.GLOBAL_VARIABLES
			WHERE VARIABLE_NAME = 'optimizer_switch'
		)
	");

#	say("Executor initialized, id ".$executor->id());

    $executor->defaultSchema($executor->currentSchema());
    say "Default schema: ".$executor->defaultSchema();

	return STATUS_OK;
}

sub reportError {
    my ($self, $query, $err, $errstr, $silent) = @_;
    
    my $msg = [$query,$err,$errstr];
    
    if (defined $self->channel) {
        $self->sendError($msg) if !$silent;
    } elsif (not defined $reported_errors{$errstr}) {
        say("Query: $query failed: $err $errstr. Further errors of this kind will be suppressed.") if !$silent;
        $reported_errors{$errstr}++;
    }
}

sub execute {
	my ($executor, $query, $silent) = @_;

	my $dbh = $executor->dbh();

	return GenTest::Result->new( query => $query, status => STATUS_UNKNOWN_ERROR ) if not defined $dbh;

    $query = $executor->preprocess($query);

	if (
		(not defined $executor->[EXECUTOR_MYSQL_AUTOCOMMIT]) &&
		(
			($query =~ m{^\s*start\s+transaction}io) ||
			($query =~ m{^\s*begin}io) 
		)
	) {	
		$dbh->do("SET AUTOCOMMIT=OFF");
		$executor->[EXECUTOR_MYSQL_AUTOCOMMIT] = 0;
	}

	my $start_time = Time::HiRes::time();
	my $sth = $dbh->prepare($query);

	if (not defined $sth) {			# Error on PREPARE
		my $errstr = $executor->normalizeError($sth->errstr());
		$executor->[EXECUTOR_ERROR_COUNTS]->{$errstr}++ if rqg_debug() && !$silent;
		return GenTest::Result->new(
			query		=> $query,
			status		=> $executor->getStatusFromErr($dbh->err()) || STATUS_UNKNOWN_ERROR,
			err		=> $dbh->err(),
			errstr	 	=> $dbh->errstr(),
			sqlstate	=> $dbh->state(),
			start_time	=> $start_time,
			end_time	=> Time::HiRes::time()
		);
	}

	my $affected_rows = $sth->execute();

	my $end_time = Time::HiRes::time();

	my $err = $sth->err();
	my $result;

	if (defined $err) {			# Error on EXECUTE
		my $err_type = $err2type{$err};

		if (
			($err_type == STATUS_SYNTAX_ERROR) ||
			($err_type == STATUS_SEMANTIC_ERROR) ||
			($err_type == STATUS_TRANSACTION_ERROR)
		) {
			my $errstr = $executor->normalizeError($sth->errstr());
			$executor->[EXECUTOR_ERROR_COUNTS]->{$errstr}++ if rqg_debug() && !$silent;
            $executor->reportError($query, $err, $errstr, $silent);
		} elsif (
			($err_type == STATUS_SERVER_CRASHED) ||
			($err_type == STATUS_SERVER_KILLED)
		) {
			$dbh = DBI->connect($executor->dsn(), undef, undef, {
				PrintError => 0,
				RaiseError => 0,
				AutoCommit => 1,
				mysql_multi_statements => 1
			} );

			# If server is still connectable, it is not a real crash, but most likely a KILL query

			if (defined $dbh) {
				$err_type = STATUS_SEMANTIC_ERROR;
				$executor->setDbh($dbh);
			}

			say("Query: $query failed: $err ".$sth->errstr()) if !$silent;
		} else {
			$executor->[EXECUTOR_ERROR_COUNTS]->{$sth->errstr()}++ if rqg_debug() && !$silent;
			say("Query: $query failed: $err ".$sth->errstr()) if !$silent;
		}

		$result = GenTest::Result->new(
			query		=> $query,
			status		=> $err_type || STATUS_UNKNOWN_ERROR,
			err		=> $err,
			errstr		=> $sth->errstr(),
			sqlstate	=> $sth->state(),
			start_time	=> $start_time,
			end_time	=> $end_time
		);
	} elsif ((not defined $sth->{NUM_OF_FIELDS}) || ($sth->{NUM_OF_FIELDS} == 0)) {
		$result = GenTest::Result->new(
			query		=> $query,
			status		=> STATUS_OK,
			affected_rows	=> $affected_rows,
			start_time	=> $start_time,
			end_time	=> $end_time
		);
		$executor->[EXECUTOR_ERROR_COUNTS]->{'(no error)'}++ if rqg_debug() && !$silent;
	} else {
		#
		# We do not use fetchall_arrayref() due to a memory leak
		# We also copy the row explicitly into a fresh array
		# otherwise the entire @data array ends up referencing row #1 only
		#
		my @data;
		while (my $row = $sth->fetchrow_arrayref()) {
			my @row = @$row;
			push @data, \@row;
		}	

		$result = GenTest::Result->new(
			query		=> $query,
			status		=> STATUS_OK,
			affected_rows 	=> $affected_rows,
			data		=> \@data,
			start_time	=> $start_time,
			end_time	=> $end_time
		);

		$executor->[EXECUTOR_ERROR_COUNTS]->{'(no error)'}++ if rqg_debug() && !$silent;
	}

	$sth->finish();

	if ($sth->{mysql_warning_count} > 0) {
		my $warnings = $dbh->selectall_arrayref("SHOW WARNINGS");
		$result->setWarnings($warnings);
	}

	if (
		(rqg_debug()) &&
		($query =~ m{^\s*select}sio) &&
		(!$silent)
	) {
		$executor->explain($query);
		my $row_group = $sth->rows() > 100 ? '>100' : ($sth->rows() > 10 ? ">10" : sprintf("%5d",$sth->rows()) );
		$executor->[EXECUTOR_ROW_COUNTS]->{$row_group}++;
	}

	return $result;
}

#
# Run EXPLAIN on the query in question, recording all notes in the EXPLAIN's Extra field into the statistics
#

sub id {
	my $executor = shift;

	# if no ID string has been defined yet, define one.

	if ($executor->SUPER::id() eq '') {
		my $dbh = $executor->dbh();
		my $version = $dbh->selectrow_array("SELECT VERSION()");

		my @capabilities;

		push @capabilities, "master" if $dbh->selectrow_array("SHOW SLAVE HOSTS");
		push @capabilities, "slave" if $dbh->selectrow_array("SHOW SLAVE STATUS");
		push @capabilities, "no_semijoin" if $dbh->selectrow_array('SELECT @@optimizer_switch') =~ m{no_semijoin}sio;
		push @capabilities, "no_materialization" if $dbh->selectrow_array('SELECT @@optimizer_switch') =~ m{no_materialization}sio;
		push @capabilities, "mo_mrr" if $dbh->selectrow_array('SELECT @@optimizer_use_mrr') eq '0';
		push @capabilities, "no_condition_pushdown" if $dbh->selectrow_array('SELECT @@engine_condition_pushdown') eq '0';
		$executor->setId(ref($executor)." ".$version." (".join('; ', @capabilities).")");
	}
	
	# Pass the call back to the parent class. It will respond with the id that was (just) defined.

	return $executor->SUPER::id();
}

sub version {
	my $executor = shift;
	my $dbh = $executor->dbh();
	return $dbh->selectrow_array("SELECT VERSION()");
}

sub slaveInfo {
	my $executor = shift;
	my $slave_info = $executor->dbh()->selectrow_arrayref("SHOW SLAVE HOSTS");
	return ($slave_info->[SLAVE_INFO_HOST], $slave_info->[SLAVE_INFO_PORT]);
}

sub masterStatus {
	my $executor = shift;
	return $executor->dbh()->selectrow_array("SHOW MASTER STATUS");
}

sub explain {
	my ($executor, $query) = @_;

	my $sth_output = $executor->dbh()->prepare("EXPLAIN /*!50100 PARTITIONS */ $query");

	$sth_output->execute();

	my @explain_fragments;

	while (my $explain_row = $sth_output->fetchrow_hashref()) {
		push @explain_fragments, "select_type: ".($explain_row->{select_type} || '(empty)');

		push @explain_fragments, "type: ".($explain_row->{type} || '(empty)');

		push @explain_fragments, "partitions: ".$explain_row->{table}.":".$explain_row->{partitions} if defined $explain_row->{partitions};

		foreach my $extra_item (split('; ', ($explain_row->{Extra} || '(empty)')) ) {
			$extra_item =~ s{0x.*?\)}{%d\)}sgio;
			$extra_item =~ s{PRIMARY|[a-z_]+_key}{%s}sgio;
			push @explain_fragments, "extra: ".$extra_item;
		}
	}
	
	foreach my $explain_fragment (@explain_fragments) {
		$executor->[EXECUTOR_EXPLAIN_COUNTS]->{$explain_fragment}++;
		if ($executor->[EXECUTOR_EXPLAIN_COUNTS]->{$explain_fragment} > RARE_QUERY_THRESHOLD) {
			delete $executor->[EXECUTOR_EXPLAIN_QUERIES]->{$explain_fragment};
		} else {
			push @{$executor->[EXECUTOR_EXPLAIN_QUERIES]->{$explain_fragment}}, $query;
		}
	}

}

sub DESTROY {
	my $executor = shift;
	if (rqg_debug()) {
		say("Statistics for Executor ".$executor->dsn());
		use Data::Dumper;
		$Data::Dumper::Sortkeys = 1;
		say("Rows returned:");
		print Dumper $executor->[EXECUTOR_ROW_COUNTS];
		say("Explain items:");
		print Dumper $executor->[EXECUTOR_EXPLAIN_COUNTS];
		say("Errors:");
		print Dumper $executor->[EXECUTOR_ERROR_COUNTS];
		say("Rare EXPLAIN items:");
		print Dumper $executor->[EXECUTOR_EXPLAIN_QUERIES];
	}
	$executor->dbh()->disconnect();
}

sub currentSchema {
	my ($executor,$schema) = @_;

	return undef if not defined $executor->dbh();

    if (defined $schema) {
        $executor->execute("USE $schema");
    }
    
	return $executor->dbh()->selectrow_array("SELECT DATABASE()");
}


sub errorType {
	return undef if not defined $_[0];
	return $err2type{$_[0]} || STATUS_UNKNOWN_ERROR ;
}

sub normalizeError {
	my ($executor, $errstr) = @_;

	foreach my $i (0..$#errors) {
		last if $errstr =~ s{$patterns[$i]}{$errors[$i]}si;
	}

	$errstr =~ s{\d+}{%d}sgio if $errstr !~ m{from storage engine}sio; # Make all errors involving numbers the same, e.g. duplicate key errors

	$errstr =~ s{\.\*\?}{%s}sgio;

	return $errstr;
}


sub getSchemaMetaData {
    ## Return the result from a query with the following columns:
    ## 1. Schema (aka database) name
    ## 2. Table name
    ## 3. TABLE for tables VIEW for views and MISC for other stuff
    ## 4. Column name
    ## 5. PRIMARY for primary key, INDEXED for indexed column and "ORDINARY" for all other columns
    my ($self) = @_;
    my $query = 
        "SELECT CASE WHEN table_schema = 'information_schema' ".
                     "THEN 'INFORMATION_SCHEMA' ".  ## Hack due to
                                                    ## weird MySQL
                                                    ## behaviour on
                                                    ## schema names
                                                    ## (See Bug#49708)
                     "ELSE table_schema END, ".
               "table_name, ".
               "CASE WHEN table_type = 'BASE TABLE' THEN 'table' ".
                    "WHEN table_type = 'VIEW' THEN 'view' ".
                    "WHEN table_type = 'SYSTEM VIEW' then 'view' ".
                    "ELSE 'misc' END, ".
               "column_name, ".
               "CASE WHEN column_key = 'PRI' THEN 'primary' ".
                    "WHEN column_key = 'MUL' THEN 'indexed' ".
                    "WHEN column_key = 'UNI' THEN 'indexed' ".
                    "ELSE 'ordinary' END ".
         "FROM information_schema.tables INNER JOIN ".
              "information_schema.columns USING(table_schema, table_name) ".
          "WHERE table_name <> 'DUMMY'"; 

    return $self->dbh()->selectall_arrayref($query);
}

sub getCollationMetaData {
    ## Return the result from a query with the following columns:
    ## 1. Collation name
    ## 2. Character set
    my ($self) = @_;
    my $query = 
        "SELECT collation_name,character_set_name FROM information_schema.collations";

    return $self->dbh()->selectall_arrayref($query);
}

1;

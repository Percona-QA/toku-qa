#! /usr/bin/php
<?php
date_default_timezone_set('America/New_York');
$STDERR = fopen('php://stderr', 'w+');

$shortopts  = "u:p:h:";  // mysql username, pass and host
$longopts  = array(
    "config:",     				// php config file used.
    "extended_insert_size:",	// transaction size for extended inserts
    "min_transaction_size:",	// min size of a transaction
    "max_transaction_size:",	// max size of a transaction
    "rollback_chance:",			// one out of x chance to rollback a transaction instead of commiting it.
    "select_lock_in_share_mode_chance:", // one out of x chance to add a LOCK IN SHARE MODE to a select statement.
    "output_dir:",         		// dir_to_put_files
    "table:",					// table to operate on
    "database:",				// database to use
    "seed:",					// database to use    
    "write_sql_to_disk" 		// write successful run sql statments to disk.
);
$options = getopt($shortopts, $longopts);
shift_argv($options);
if (count($argv) != 4) {
	usage();
	exit(1);
}

$table_arg = $argv[1];

$total_rows = $argv[2];
if (!my_is_int($total_rows)) {
	echo "2nd parameter iterations must be an integer. $total_rows given\n";
	usage();
	exit(1);
} 

$mode = $argv[3];
if ($mode != "insert" && $mode != "tab_del_dump") {
	echo "3rd parameter, action, must be either insert or tab_del_dump\n";
	usage();
	exit(1);
}

if (isset($options['config']))
	$config = $options['config'];
else
	$config	= 'config.php';

if (isset($options['u']))
	$mysql_user = $options['u'];
else
	$mysql_user	= get_current_user();

if (isset($options['p']))
	$mysql_pass = $options['p'];
else
	$mysql_pass	= '';

if (isset($options['h']))
	$mysql_host = $options['h'];
else
	$mysql_host	= 'localhost';

if (isset($options['extended_insert_size']))
	$rows_per_file = $options['extended_insert_size'];
else
	$rows_per_file = 100;

if (isset($options['min_transaction_size']))
	$min_transaction_size = $options['min_transaction_size'];
else
	$min_transaction_size = 1;

if (isset($options['max_transaction_size']))
	$max_transaction_size = $options['max_transaction_size'];
else
	$max_transaction_size = 1;

if (isset($options['rollback_chance']))
	$rollback_chance = $options['rollback_chance'];
else
	$rollback_chance = 0;

if (isset($options['select_lock_in_share_mode_chance']))
	$select_lock_in_share_mode_chance = $options['select_lock_in_share_mode_chance'];
else
	$select_lock_in_share_mode_chance = 0;

if (isset($options['output_dir']))
	$dir_to_put_files = $options['output_dir'];
else
	$dir_to_put_files = '/tmp';

if (isset($options['database']))
	$mysql_db = $options['database'];
else
	$mysql_db = '';

if (isset($options['seed']))
	$seed = $options['seed'];
else
	$seed = 0;

if (isset($options['write_sql_to_disk'])) {
	$write_successful_sql_to_disk = true;
	if (!file_exists(dirname(__FILE__).'/../sql_out'))
		mkdir(dirname(__FILE__).'/../sql_out', 0755, true);
	$tmpfname_replay = tempnam(dirname(__FILE__)."/../sql_out", "$mysql_db.");
} else {
	$write_successful_sql_to_disk = false;
}

$int_types              = array('tinyint','smallint','mediumint','int','bigint','bit');
$float_types    		= array('float','double','decimal');
$date_types             = array('date','datetime','timestamp','time','year');
$text_types             = array('char','varchar','tinytext','text','blob','mediumtext','mediumblob','longtext','longblob','tinyblob','enum','set','binary');

if (is_readable(dirname(__FILE__) . "/../configs/$config"))
	include dirname(__FILE__) . "/../configs/$config";
else {
	echo "config file $config does not exist or is not readable.\n";
	exit(1);
}

$column_size = 85;
$rows = intval(`tput lines`);
$window_length = $rows - 11;
$stderr_start_row = $rows - 10;
$stderr_cursor_pos = "\033[${stderr_start_row};0f";
$cols = floor(intval(`tput cols`) / $column_size);
$number_of_display_slots = $window_length * $cols;

if ($mode == 'insert') {
	$db_link=mysql_connect($mysql_host,$mysql_user,$mysql_pass);
	if (!$db_link) {
  		fwrite($STDERR, "ERROR - Could not connect to mysql host $mysql_host\n". mysql_error()."\n");
		exit();
	}
	if (!mysql_selectdb($mysql_db,$db_link)) {
		echo "ERROR - Could not select database $mysql_db \n". mysql_error()."\n";
		exit();
	}
}

$shared_cache 		= array();
$begin_sql_insert 	= array();
$index_info 		= array();
$potential_tables 	= array();
$insert_sql			= array();
if ($table_arg == '*')
	$potential_tables = array_keys($what_to_do);
else
	$potential_tables[] = $table_arg;

if ($mode == 'insert') {
	//build the beginning of the insert statement
	foreach ($potential_tables as $table_name) {
		//$begin_sql_insert[$table_name] = "INSERT IGNORE INTO `$table_name` (";
		$begin_sql_insert[$table_name] = "INTO `$table_name` (";
		foreach ($meta_data[$table_name] as $key => $value ) {
			if ($value['method'] == "ignore")
				continue;
			$begin_sql_insert[$table_name] .= "`".$value['col_name']."`";
			$begin_sql_insert[$table_name] .= ",";
		}
		$begin_sql_insert[$table_name] = rtrim($begin_sql_insert[$table_name],',');
		$begin_sql_insert[$table_name] .= ") VALUES ";
		$insert_sql[$table_name] = $begin_sql_insert[$table_name];

		// lets fill a datastructure with the tables index information so we can use it to construct useful where clauses later on.
		$res = mysql_query("SHOW INDEX FROM $table_name FROM $mysql_db", $db_link);
		$prev_index_name = "";
		while ($row = mysql_fetch_assoc($res)) {
			if ($prev_index_name != $row['Key_name'])
				$index_info[$table_name][$row['Key_name']][] = $row['Column_name'];
		}
	}
} elseif ($mode == 'tab_del_dump') {
	$tmpfname 	= tempnam($dir_to_put_files, "$table_name.");
	$handle 	= fopen($tmpfname, "w");
} else {
	echo "Unknown mode. exiting...";
	exit();
}

$i 			= 1;	
$deletes 	= 0;
$updates 	= 0;
$inserts 	= 0;
$reads   	= 0;

// print the column headers
for ($i=0; $i < $cols; $i++) {
	$hor_pos = $i * $column_size;
	$cursor_pos = "\033[5;${hor_pos}f";
	$mask = "${cursor_pos}|%-40s |%7s |%7s |%7s |%7s|\r";
	printf($mask, 'table.db.seed (pid)', 'inserts','selects','updates','deletes');
}
$cursor_pos = "\033[6;0f";
echo $cursor_pos . str_repeat('_', $cols * $column_size);


if ($min_transaction_size == 1 && $max_transaction_size == 1) {
	$transaction_size = 1;
} else {
	$transaction_size =  rand($min_transaction_size,$max_transaction_size);
	mysql_query("BEGIN;", $db_link);
	if ($write_successful_sql_to_disk)
		logToReplayLog("BEGIN;\n",$tmpfname_replay);
}
$transaction_count = 1;

while ($i <= $total_rows) {
	
	if ($table_arg == '*')
		$table_name = array_rand($what_to_do);
	else 
 		$table_name = $table_arg;

 	get_shared_cache_info($shared_cache,$mysql_db,$table_name,$seed);
	$pos = $shared_cache[$table_name.'.'.$mysql_db.'.'.$seed] + (8 * $cols);


	if ($what_to_do[$table_name]['CRUD']['INSERT'] == array_sum($what_to_do[$table_name]['CRUD']) ) 
		$todo = 'INSERT';
	elseif ($what_to_do[$table_name]['CRUD']['SELECT'] == array_sum($what_to_do[$table_name]['CRUD']) ) 
		$todo = 'SELECT';
	elseif ($what_to_do[$table_name]['CRUD']['UPDATE'] == array_sum($what_to_do[$table_name]['CRUD']) ) 
		$todo = 'UPDATE';
	elseif ($what_to_do[$table_name]['CRUD']['DELETE'] == array_sum($what_to_do[$table_name]['CRUD']) ) 
		$todo = 'DELETE';
	elseif ($what_to_do[$table_name]['CRUD']['REPLACE'] == array_sum($what_to_do[$table_name]['CRUD']) ) 
		$todo = 'REPLACE';			
	else { //let's randomly pick something to do. crud
		$weights 	= array_values($what_to_do[$table_name]['CRUD']);
		$strings 	= array_keys($what_to_do[$table_name]['CRUD']);
		$index 		= grabWeightedIndex($weights);
		$todo 		= $strings[$index];
	}
	if ($what_to_do[$table_name]['SLEEP']['MAX'] > 0)
		usleep(rand($what_to_do[$table_name]['SLEEP']['MIN'], $what_to_do[$table_name]['SLEEP']['MAX']));

	if ($todo == 'INSERT' || $todo == 'REPLACE') {  // create

		$raw_data_array = array();
		foreach ($meta_data[$table_name] as $key => $value ) {
			$type = $value['datatype'];
			// if the table.column has some potential fixed data, use it ,unless you randomly picked a wildcard (*), then give it some random data
			if (isset($fixed_data[$table_name.".".$value['col_name']]) && "*" != $d = $fixed_data[$table_name.".".$value['col_name']][rand(0,max(array_keys($fixed_data[$table_name.".".$value['col_name']])))])
				$raw_data_array[] = $d;
			else 
				if ($value['method'] == "autoinc")
					$raw_data_array[] = $i + ($total_rows * $seed);
				elseif ($value['method'] == "ignore")
					continue;
				else
					$raw_data_array[] = generateRandomValue($table_name,$value['col_name'],$config);
		}

		if ($mode == 'insert') {
		    if ($insert_sql[$table_name] != $begin_sql_insert[$table_name]) 
		        $insert_sql[$table_name] .= ",";
		                        
		    //$insert_sql .= "('" . implode("','", $raw_data_array) . "')";    // old slick way, couldnt use it when we added the binary datatype containing md5 hex data
			$insert_sql[$table_name] .= "(";
			foreach ($raw_data_array as $key => $data) {
				if ($key != 0)
					$insert_sql[$table_name] .= ",";
				if ((substr($data,0,1) == 'x' || substr($data,0,1) == 'b') && substr($data,1,1) == "'")
					$insert_sql[$table_name] .= $data;
				else
					$insert_sql[$table_name] .= var_export($data, true);
			}
			$insert_sql[$table_name] .= ")";

		    
			if ($i % $rows_per_file == 0 || $total_rows-$i < $rows_per_file) {
				// lets end the extended insert statement and insert it.
				if ($todo == 'INSERT' ) {
					//$insert_sql[$table_name] .= " ON DUPLICATE KEY UPDATE id=LAST_INSERT_ID(id);\n";   // TODO need to make this configurable
					$insert_sql[$table_name] .= ";\n";
				} else {
					$insert_sql[$table_name] .= ";\n";
				}

				mysql_selectdb($mysql_db,$db_link);
				$insert_result = mysql_query($todo . ' ' . $insert_sql[$table_name],$db_link);
				
				if (!$insert_result) {
					fwrite($STDERR, $stderr_cursor_pos."Error(".mysql_errno().") on Insert to $table_name.$mysql_db:".mysql_error()."\n"."sql:" . $todo . ' ' . substr($insert_sql[$table_name],0,50).'...' . "\n");
				} else {
					if ($write_successful_sql_to_disk)
						logToReplayLog($todo . ' ' . $insert_sql[$table_name],$tmpfname_replay);
					$inserts++;
				}
				$insert_sql[$table_name] = $begin_sql_insert[$table_name];
			} else {
				$transaction_count--;
			}
		} elseif ($mode == 'tab_del_dump') {
			if ($i % $rows_per_file == 1 && $i != 1) {
				fclose($handle);
				$tmpfname = tempnam($dir_to_put_files, "$table_name.");
				$handle = fopen($tmpfname, "w");
			}
			fwrite($handle, implode("\t", $raw_data_array)."\n");
		}

	} elseif ($todo == 'SELECT') {  //read

		//find foreign key relationships, if we have some, randomly select some or none and fold it into the where clause.
		$the_joins = array();
		findForeignKeyRelationships($table_name,$config,$the_joins);
		$the_joins = array_slice($the_joins,0,rand(1,count($the_joins)));

		$colums_to_select = array();
		$infinity_check = 0;
		while (count($colums_to_select) == 0) { 
			foreach ($meta_data[$table_name] as $value) {
				if ($value['method'] != "ignore" && rand(0,3) == 0) {
					if ($value['datatype'] == 'binary')
						$colums_to_select[] = "HEX(".$table_name.".".$value['col_name'].")";
					else 
						$colums_to_select[] = $table_name.".".$value['col_name'];
				}
			}
			$infinity_check++;
			if ($infinity_check > 50) {
				echo "Infinite loop when looking for columns to update for table $table_name. exiting.\n";
				exit();
			}
		}

		if (rand(0,1) == 0)
			$sql = "SELECT ".implode(',', $colums_to_select)." FROM $table_name " . makeRandomWhereClause($index_info[$table_name],$table_name,$db_link,$config);
		elseif (rand(0,1) == 0)
			$sql = "SELECT ".implode(',', $colums_to_select)." FROM $table_name " .implode(' ', $the_joins) . makeRandomWhereClause($index_info[$table_name],$table_name,$db_link,$config);
		else 
			$sql = "SELECT ".implode(',', $colums_to_select)." FROM $table_name " .implode(' ', $the_joins);

		if ($select_lock_in_share_mode_chance != 0 && rand(1,$select_lock_in_share_mode_chance) == 1 && $transaction_size > 1)
			$sql .= " LOCK IN SHARE MODE";

		mysql_selectdb($mysql_db,$db_link);
		$result = mysql_query($sql, $db_link);
		if (!$result) {
			fwrite($STDERR, $stderr_cursor_pos."Error(".mysql_errno().") on SELECT to $table_name.$mysql_db:".mysql_error()."\n"."sql:" . $todo . ' ' . substr($sql,0,75).'...' . "\n");
		} else {
			if ($write_successful_sql_to_disk)
				logToReplayLog($sql.";\n",$tmpfname_replay);
			$reads++;
		}
	} elseif ($todo == 'UPDATE') {  //update
		// update some random fields for some of the rows
		//find foreign key relationships, if we have some, randomly select some or none and fold it into the where clause.
		$the_joins = array();
		findForeignKeyRelationships($table_name,$config,$the_joins);
		$the_joins = array_slice($the_joins,0,rand(1,count($the_joins)));

		$colums_to_update = array();
		$infinity_check = 0;
		while (count($colums_to_update) == 0) { 
			foreach ($meta_data[$table_name] as $value) {
				if ($value['method'] != "ignore" && rand(0,3) == 0)
					$colums_to_update[] = $value;
			}
			$infinity_check++;
			if ($infinity_check > 50) {
				echo "Infinite loop when looking for columns to update for table $table_name. exiting.\n";
				exit();
			}

		}

		// check for gap lock potential
		// if primary key is in the colums_to_update lets remove it for now
		foreach ($colums_to_update as $key => $value) {
			if ($value['col_name'] == 'id')
				unset($colums_to_update[$key]);
		}
		shuffle($colums_to_update);

		$raw_data_array=array();
		foreach ($colums_to_update as $key => $value)
			$raw_data_array[] = generateRandomValue($table_name,$value['col_name'],$config);

		$where_clause_array = makeRandomWhereClause($index_info[$table_name],$table_name,$db_link,$config,true);

		//$update_sql = "UPDATE $table_name " . implode(' ', $the_joins) . " SET ";
		$update_sql = "UPDATE $table_name SET ";
		foreach ($colums_to_update as $key => $value) {
			if ($key != 0)
				$update_sql .= ",";
			$update_sql .= "`$table_name`.".$value['col_name'] . "=";
			if ((substr($raw_data_array[$key],0,1) == 'x' || substr($raw_data_array[$key],0,1) == 'b') && substr($raw_data_array[$key],1,1) == "'")
				$update_sql .= $raw_data_array[$key];
			else
				$update_sql .= var_export($raw_data_array[$key], true);
		}

		$update_sql .= " WHERE " . implode(" AND ", $where_clause_array);


		mysql_selectdb($mysql_db,$db_link);
		$result = mysql_query($update_sql, $db_link);
		if (!$result) {
			fwrite($STDERR, $stderr_cursor_pos."Error(".mysql_errno().") on UPDATE to $table_name.$mysql_db:".mysql_error()."\n"."sql:" . $todo . ' ' . substr($update_sql,0,75).'...' . "\n");
		} else {
			if ($write_successful_sql_to_disk) 
				logToReplayLog($update_sql . ";\n",$tmpfname_replay);
			$updates++;
		}

	} elseif ($todo == 'DELETE') {  //delete
		$del_sql = "DELETE FROM $table_name" . makeRandomWhereClause($index_info[$table_name],$table_name,$db_link,$config);
		if (strpos($del_sql,'WHERE') !== false) {
			mysql_selectdb($mysql_db,$db_link);
			$result = mysql_query($del_sql, $db_link);
			if (!$result) {
				fwrite($STDERR, $stderr_cursor_pos."Error(".mysql_errno().") on DELETE to $table_name.$mysql_db:".mysql_error()."\n"."sql:" . $todo . ' ' . substr($del_sql,0,75).'...' . "\n");
			} else {
				if ($write_successful_sql_to_disk)
					logToReplayLog($del_sql . ";\n",$tmpfname_replay);
				$deletes++;
			}
		}
		
	} else {
		// do nothing
		echo "nothing to do...\n";
		exit();
	}

	if ($transaction_count >= $transaction_size && $transaction_size > 1) {
		$operation = 'COMMIT;';
		if ($rollback_chance != 0 && rand(1,$rollback_chance) == 1)
			$operation = 'ROLLBACK;';
		mysql_query($operation, $db_link);
		if ($write_successful_sql_to_disk)
			logToReplayLog("$operation\n",$tmpfname_replay);
		$transaction_size =  rand($min_transaction_size,$max_transaction_size);
		$transaction_count = 0;
		if ($transaction_size > 1) {
			mysql_query("BEGIN;", $db_link);
			if ($write_successful_sql_to_disk)
				logToReplayLog("BEGIN;\n",$tmpfname_replay);
		}
	} elseif ($transaction_size == 1)
		$transaction_size = rand($min_transaction_size,$max_transaction_size);

	$i++;
	$transaction_count++;

	// only refresh screen once every 100 times through the loop
	if (($i % 1) == 0) {
		$goto_top = "\033[0;0f";
		$col = $pos % $cols;
		$horizontal_offset = $col * $column_size;
		$vertical_offset = floor($pos / $cols);
		$cursor_pos = "\033[${vertical_offset};${horizontal_offset}f";
		//echo $table_name.'.'.$mysql_db.'.'.$seed."  inserts: $inserts reads:$reads  updates: $updates  deletes: $deletes \n";
		$mask = "${cursor_pos}|%-40s |%7s |%7s |%7s |%7s|\r";
		$output = $mysql_db.'.'.$table_name.'.'.$seed."(".getmypid().")";
		$output = substr($output,0,40);
		printf($mask,$output,$inserts,$reads,$updates,$deletes);
		echo $goto_top;
	}
}

mysql_query("COMMIT;", $db_link);
if ($write_successful_sql_to_disk)
	logToReplayLog("COMMIT;\n",$tmpfname_replay);

printf($mask, "                                        ", "       ","       ","       ","       ");
$fp = fopen(dirname(__FILE__) ."/tmp.cache",'c+');
while (!flock($fp, LOCK_EX)) 
	sleep(rand(1,2));   // wait on the file lock.
$tmp_cache = file_get_contents(dirname(__FILE__) ."/tmp.cache");
if (!$tmp_cache)
	$shared_cache = array();
else
	$shared_cache = (array)json_decode(trim(utf8_encode($tmp_cache)));
foreach ($shared_cache as $key => $value) {
	if ($key == $table_name.'.'.$mysql_db.'.'.$seed)
		unset($shared_cache[$key]);
}
file_put_contents(dirname(__FILE__) ."/tmp.cache",json_encode($shared_cache));
flock($fp, LOCK_UN);
fclose($fp);


function get_shared_cache_info(&$shared_cache,$mysql_db,$table_name,$seed)
{
	if (array_key_exists($table_name.'.'.$mysql_db.'.'.$seed, $shared_cache))
		return;
	$column_size = 85;
	$rows = intval(`tput lines`);
	$window_length = $rows - 11;
	$cols = floor(intval(`tput cols`) / $column_size);
	$number_of_display_slots = $window_length * $cols;

	$tmp_cache_file = dirname(__FILE__) ."/tmp.cache";
	$fp = fopen($tmp_cache_file,'c+');
	while (!flock($fp, LOCK_EX)) sleep(1);   // wait on the file lock.
	$tmp_cache = file_get_contents(dirname(__FILE__) ."/tmp.cache");
	if (!$tmp_cache)
		$shared_cache = array();
	else
		$shared_cache = (array)json_decode(trim(utf8_encode($tmp_cache)));

	if (!array_key_exists($table_name.'.'.$mysql_db.'.'.$seed, $shared_cache)) {
		for ($i=0; $i < $number_of_display_slots; $i++) { 
			if (array_search($i, $shared_cache) === false) {
				$shared_cache[$table_name.'.'.$mysql_db.'.'.$seed] = $i;
				break;
			}
		}
		if (!array_key_exists($table_name.'.'.$mysql_db.'.'.$seed, $shared_cache))
			$shared_cache[$table_name.'.'.$mysql_db.'.'.$seed] = 0;
	}
	file_put_contents($tmp_cache_file,json_encode($shared_cache));
	flock($fp, LOCK_UN);
	fclose($fp);
}


function generateRandomValue($table,$column,$config) 
{
	global $int_types,$float_types,$date_types,$text_types,$meta_data;

	foreach ($meta_data[$table] as $value) {
		if ($value['col_name'] == $column)
			break;
	}
	$type = $value['datatype'];
	if (in_array(strtolower($type), $int_types)) {
		if (strtolower($type) == 'bit')
			return "b'".decbin(rand($value['min'],$value['max']))."'";
		else
			return rand($value['min'],$value['max']);
	} elseif (in_array(strtolower($type), $float_types)) {
		return generateRandomFloat($value['min'],$value['max'],5);
	} elseif (in_array(strtolower($type), $date_types)) {
		if (strtolower($type) == 'date')
			$date_format = 'Y-m-d';
		elseif (strtolower($type) == 'datetime') 
			$date_format = 'Y-m-d H:i:s';
		elseif (strtolower($type) == 'timestamp') 
			$date_format = 'Y-m-d H:i:s';
		elseif (strtolower($type) == 'time') 
			$date_format = 'H:i:s';
		elseif (strtolower($type) == 'year') 
			$date_format = 'Y';
		return date( $date_format, rand(strtotime($value['min']),strtotime($value['max'])) );
	} elseif (in_array(strtolower($type), $text_types)) {
		if (strtolower($type) == 'binary')
			return "x'".md5(generateRandomString(rand($value['min'],$value['max'])))."'";
		else 
			return generateRandomString(rand($value['min'],$value['max']));
	} else {
		echo "Invalid type '$type'.";
		return "";
	}
}

function findForeignKeyRelationships($table,$config,&$fk_tables) 
{
	global $meta_data;
	foreach ($meta_data[$table] as $key => $value) {
		if (isset($value['foreign_keys'])) {
			foreach ($value['foreign_keys'] as $fks) {
				$tt = explode('.', $fks);
				$fk_table 	= $tt[0];
				$fk_col 	= $tt[1];
				$fk_tables[] = "INNER JOIN $fk_table ON $fks = $table." . $value['col_name'] ." ";
				findForeignKeyRelationships($fk_table,$config,$fk_tables);
			}
		}
	}
}

function findColumnsToUpdate($tables,$config)
{
	global $meta_data;
	$colums_to_update = array();
	$infinity_check = 0;
	while (count($colums_to_update) == 0) { 
		foreach ($meta_data[$table_name] as $value) {
			// dont pick the column if its marked as ignore
			if ($value['method'] != "ignore" && rand(0,2))
				$colums_to_update[] = $value;
		}
		$infinity_check++;
		if ($infinity_check > 100) {
			echo "Infinite loop when looking for columns to update for table $table_name. exiting.\n";
			return $colums_to_update;
		}
	}
	return $colums_to_update;
}

function makeRandomWhereClause($index_info,$table_name,$db_link, $config, $return_array = false)
{
		global $meta_data;
		// lets build a random where clause that uses random indexs from a given table
		if (sizeof($index_info) == 0) {
			echo "no index_info...\n";
			return " ";
		}
		$index 	= array_rand($index_info);
		$cols 	= $index_info[$index];
		$where_clause_array = array();
		foreach ($cols as $key => $col) {
			$offset_sql = "SELECT COUNT(*) FROM $table_name" . " WHERE " . implode(" AND ", $where_clause_array);
			$offset_sql = rtrim($offset_sql,'WHERE ');
			$res = mysql_query($offset_sql);   //if using innodb this will be too slow.
			$row = mysql_fetch_array($res);
			$offset = rand(0, $row[0]-1);
			$sql_grab_random_value = "SELECT $table_name.$col FROM $table_name "." WHERE " . implode(" AND ", $where_clause_array);
			$sql_grab_random_value = rtrim($sql_grab_random_value,'WHERE ');
			$sql_grab_random_value .= " LIMIT $offset,1";
			$result = mysql_query($sql_grab_random_value, $db_link);
			$stderr_cursor_pos = "\033[55;0f";
			if (!$result)
				echo $stderr_cursor_pos."select sql failed in makeRandomWhereClause error code:".mysql_errno()." - ".mysql_error()." \n sql:$sql_grab_random_value\n";
			$row = mysql_fetch_row($result);
			$where_clause_array[] = "$table_name.$col = '".mysql_real_escape_string($row[0])."'"; 
			// have a 1 in 2 chance to cut the where clause off where we are.
			if (rand(0,1) == 0) {
				break;
			}
		}

		if ($return_array)
			return $where_clause_array;
		else
			return " WHERE " . implode(" AND ", $where_clause_array);
}

function logToReplayLog($sql,$file_name)
{
	$reply_log_handle = fopen($file_name, "a");
	if ($reply_log_handle === false) {
		echo "failed to open $file_name";
	} else {
		$fwrite = fwrite($reply_log_handle, '/* ' . microtime(true) . ' */ ');
		$fwrite = fwrite($reply_log_handle, $sql);
		if ($fwrite === false)
			echo "failed to write to $file_name...\n";

		fclose($reply_log_handle);
	}
}

function generateRandomString($length=10)
{
	//$charset='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    //$str = '';
    //$count = strlen($charset);
    //while ($length--)
    //    $str .= $charset[mt_rand(0, $count-1)];
    //return $str;
    return str_shuffle(substr(str_repeat(md5(mt_rand()), 2+$length/32), 0, $length));  // faster way. not as random
}

function generateRandomFloat($minValue,$maxValue,$decimal){
	$intPowerTen = pow(10,$decimal);
	return mt_rand($minValue*$intPowerTen,$maxValue*$intPowerTen)/$intPowerTen;
}

function grabWeightedIndex($values) {

    $rand 		= (mt_rand(1, 1000) / 1000) * array_sum($values);
    $currTotal 	= 0;
    $index 		= 0;

    foreach ($values as $amount) {
        $currTotal += $amount;
        if ($rand > $currTotal) 
            $index++;
        else 
            break;
    }
    return $index;
}

function usage() {

	$un="\033[4m";
	$end="\033[00m";
	$bold="\033[1m";

    echo "${bold}USAGE:${end} ". $GLOBALS['argv'][0] ." [OPTIONS] [TABLE] [ITERATIONS] [ACTION (insert or tab_del_dump)\n"; 
    echo "\n${bold}ACTION${end}: ${un}insert${end} means we are connecting to a database and running sql commands directly, \n";
    echo "        ${un}tab_del_dump${end} means we are not connecting to a database, we are just writing out tab \n";
    echo "        delimited data files for use later in an infile data load to a database.\n";
    echo " \n" ;
    echo "${bold}ITERATIONS${end}:  number of operations to perform on given table.\n" ;
    echo " \n" ;
    echo "${bold}TABLE${end}:   mysql table to perform actions on.\n" ;
    echo " \n" ;
    echo "${bold}OPTIONS:${end}\n";
    echo " ${bold}-u${end} ${un}USER${end}\n";
    echo "            mysql username to be used. current user is used if not specified. Used for insert action only.\n";
    echo " ${bold}-p${end} ${un}PASSWORD${end}\n";
    echo "            mysql password to be used. Used for insert action only.\n"  ;
    echo " ${bold}-h${end}=${un}HOST${end}\n";
    echo "            mysql host. Used for insert action only.\n"   ;
    echo " ${bold}--config${end}=${un}CONFIG${end}\n";
    echo "            php config file to be used. default is config.php in configs dir\n" ;
    echo " ${bold}--database${end}=${un}DATABASE${end}\n";
    echo "            mysql database to use. Used for insert action only.\n";    
    echo " ${bold}--extended_insert_size${end}=${un}EXTENDED_INSERT_SIZE${end}\n";
    echo "            transaction size used for inserts and replace, using insert action (default is 100). \n";
    echo "            for tab_del_dump action this will denote the number of lines per file.\n";
    echo " ${bold}--min_transaction_size${end}=${un}MIN_TRANSACTION_SIZE${end}\n";
    echo "            min transaction size used when randomly generating a transaction size.(default is 1, meaning no transactions occur.) \n";
    echo " ${bold}--max_transaction_size${end}=${un}MAX_TRANSACTION_SIZE${end}\n";
    echo "            max transaction size used when randomly generating a transaction size. (default is 1, meaning no transactions occur.) \n";
    echo " ${bold}--rollback_chance${end}=${un}x${end}\n";
    echo "           one out of ${un}x${end} chance to rollback a transaction instead of commiting it. (default is 0, meaning never rollback) \n";
    echo " ${bold}--select_lock_in_share_mode_chance${end}=${un}x${end}\n";
    echo "           one out of ${un}x${end} chance to add a LOCK IN SHARE MODE to a select statement. (default is 0, meaning never) \n";
    echo " ${bold}--seed${end}=${un}SEED${end}\n";
    echo "            integer used for autoinc offset.  Used for insert action only. Used when running several times in parallel to prevent collisions\n"; 
    echo " ${bold}--output_dir${end}=${un}OUTPUT_DIR${end}\n";
    echo "            directory that tab delimited files are generated. Used for tab_del_dump action only. default is /tmp\n"; 
    echo " ${bold}--write_sql_to_disk${end}\n";
    echo "            write all successful sql queries to files in ./sql_out . Used for insert only action.\n"; 
    exit(0);
}

function shift_argv($options) {
	foreach( $options as $o => $a ) {
	    if ($k=array_search("-".$o.$a,$GLOBALS['argv']))
	            unset($GLOBALS['argv'][$k]);
	    if ($k=array_search("-".$o,$GLOBALS['argv'])) {
			unset($GLOBALS['argv'][$k]); 
			unset($GLOBALS['argv'][$k+1]);	
	    }
	    if ($k=array_search("--".$o.$a,$GLOBALS['argv']))
	       unset($GLOBALS['argv'][$k]);
	    if ($k=array_search("--".$o,$GLOBALS['argv'])) {
	       unset($GLOBALS['argv'][$k]); 
	       unset($GLOBALS['argv'][$k+1]);
	    }
	    if ($k=array_search("--".$o.'='.$a,$GLOBALS['argv']))
	            unset($GLOBALS['argv'][$k]);
	    if ($k=array_search("-".$o.'='.$a,$GLOBALS['argv']))
	            unset($GLOBALS['argv'][$k]); 
	}
	$GLOBALS['argv']=array_merge($GLOBALS['argv']);
}

function my_is_int($s) {
    return (is_numeric($s) ? intval($s) == $s : false);
}



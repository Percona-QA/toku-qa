#! /usr/bin/php
<?php
date_default_timezone_set('America/New_York');
//$mysql_host			= 'localhost:/tmp/mysqld-infile-load.sock';
$mysql_user			= $argv[1];
$mysql_pass			= $argv[2];
$mysql_host			= $argv[3];
$mysql_db 			= $argv[4];

$int_types 		= array('tinyint','smallint','mediumint','int','bigint');
$int_type_size 	= array('tinyint' => 1, 'smallint' => 2, 'mediumint' => 3, 'int' => 4, 'bigint' => 8);
$float_types	= array('float','double','decimal');
$date_types		= array('date','datetime','timestamp','time','year');
$text_types		= array('char','varchar','tinytext','text','blob','mediumtext','mediumblob','longtext','longblob','enum','set','binary');

$db_link=mysql_connect($mysql_host,$mysql_user,$mysql_pass);
if (!$db_link) {
	echo "ERROR - Could not connect to database...". mysql_error();
	exit();
}
$meta_data = array();

mysql_selectdb($mysql_db,$db_link);
$sql = "show tables";
$result = mysql_query($sql, $db_link);
if (!$result) {
	echo "error:" . mysql_error();
}
while ($row = mysql_fetch_row($result)) {
	$table = $row[0];
	$sql = "select * FROM information_schema.columns  WHERE table_name='$table'";
	$result1 = mysql_query($sql, $db_link);
	while ($row = mysql_fetch_assoc($result1))
		$meta_data[$table][$row['COLUMN_NAME']] = $row;
}

//print_r($meta_data);
//exit();
$text = "<?php\n\n\$meta_data = array(\n" ;
foreach ($meta_data as $table => $column_info) {
	$text .= "'".$table."'"." => array(\n";
	$max_column_length 		= 0;
	$max_datatype_length 	= 0;
	foreach ($column_info as $column => $values) {
		if (strlen($column) > $max_column_length)
			$max_column_length = strlen($column);
		if (strlen($values['DATA_TYPE']) > $max_datatype_length)
			$max_datatype_length = strlen($column);
	}
	$max_column_length = $max_column_length + 4;
	$max_datatype_length = $max_datatype_length + 2;
	foreach ($column_info as $column => $values) {
		if (strpos($values['EXTRA'], 'auto_increment') === false)
			$method = "random";
		else
			$method = "ignore";

		$text .= "\t\t\t\tarray('col_name' => '$column',";
		for ($i=0; $i < $max_column_length - strlen($column); $i++)
			$text .= " ";
		$text .= "'datatype' => '".$values['DATA_TYPE']."',";
		for ($i=0; $i < $max_datatype_length - strlen($values['DATA_TYPE']); $i++)
			$text .= " ";
		
		// determine min and max based on the datatype and char max length?
		$min = 0;
		$max = 1000000;
		if (in_array($values['DATA_TYPE'], $text_types)) 
			$max = $values['CHARACTER_MAXIMUM_LENGTH'];
		elseif (in_array($values['DATA_TYPE'], $int_types)) {
			if (strpos($values['COLUMN_TYPE'], "unsigned") === FALSE) {
				$min = pow(2, ($int_type_size[$values['DATA_TYPE']] * 8 ) - 1) * - 1; 
				$max = pow(2, ($int_type_size[$values['DATA_TYPE']] * 8 ) - 1) - 1;

			} else {
				$min = 0; 
				$max = pow(2, $int_type_size[$values['DATA_TYPE']] * 8) - 1;
			}

		} elseif (in_array($values['DATA_TYPE'], $date_types)) {
			if ($values['DATA_TYPE'] == 'date') {
				$min = date ("Y-m-d", strtotime("-4 years"));
				$max = date ("Y-m-d", strtotime("now"));
			} elseif ($values['DATA_TYPE'] == 'datetime' || $values['DATA_TYPE'] == 'timestamp') {
				$min = date ("Y-m-d H:i:s", strtotime("-4 years"));
				$max = date ("Y-m-d H:i:s", strtotime("now"));
			} elseif ($values['DATA_TYPE'] == 'time') {
				$min = '00:00:00';
				$max = '23:59:59';
			} elseif ($values['DATA_TYPE'] == 'year') {
				$min = date ("Y", strtotime("-100 years"));
				$max = date ("Y", strtotime("now"));
			}

		}
		
		if (in_array($values['DATA_TYPE'], $date_types)) 
			$text .= "'method' => '$method',\t'min' => '".$min."',\t'max' => '".$max."')";
		else
			$text .= "'method' => '$method',\t'min' => ".number_format($min, 0, '', '').",\t'max' => ".number_format($max, 0, '', '').")";

		if(end($column_info) === $values)
			$text .= ")";
		if (end($meta_data) === $column_info && end($column_info) === $values)
			$text .= "\n";
		else 
			$text .= ",\n";

		if (end($meta_data) === $column_info && end($column_info) === $values)
			$text .= ");\n";
//		foreach ($values as $key => $value) {
//			echo "table: $table column: $column key: $key value: $value \n";	
//		}
	}
}

echo $text;

echo "\n";
echo "\n";
echo "// having '*' for a piece of data is like saying if chosen this will be filled with random data. the more '*' in the array the more chance of inserting random data\n";
echo "// this helps with making psudo random data and also controlling the cardinality to a degree\n";
echo "\$fixed_data = 	array( 	'table1.col1' => array('INFO','WARNING','ERROR','DEBUG','FATAL'),\n";
echo "			'sometable.somecolumn' => array('thing','somethingelse','someotherthing','*'));\n";
echo "\n";

$text = "";
// use values between 0 and 1000 for the wieght of each crud item
$text = "\n\$what_to_do = array(\n";
foreach ($meta_data as $table => $column_info) {
	$text .= "\t\t\t'$table'\t\t => array('CRUD' => array('INSERT' => 100, 'SELECT' => 100, 'UPDATE' => 100, 'DELETE' => 10, 'REPLACE' => 100), 'SLEEP' => array('MIN' => 0, 'MAX' => 2000000)),\n";
}
$text = rtrim($text);
$text = rtrim($text,',');
$text .= ");\n\n\n";

echo $text;

?>

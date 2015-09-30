<?php

$meta_data = array(
'table1' => array(
				array('col_name' => 'id',          'datatype' => 'int',       'method' => 'ignore',	'min' => 0,	'max' => 4294967295),
				array('col_name' => 'column1',     'datatype' => 'int',       'method' => 'random',	'min' => 0,	'max' => 4294967295),
				array('col_name' => 'column2',     'datatype' => 'varchar',   'method' => 'random',	'min' => 0,	'max' => 40),
				array('col_name' => 'column3',     'datatype' => 'date',      'method' => 'random',	'min' => 0,	'max' => 1000000),
				array('col_name' => 'column4',     'datatype' => 'datetime',  'method' => 'random',	'min' => 0,	'max' => 1000000),
				array('col_name' => 'column5',     'datatype' => 'timestamp', 'method' => 'random',	'min' => 0,	'max' => 1000000),
				array('col_name' => 'column6',     'datatype' => 'timestamp', 'method' => 'random',	'min' => 0,	'max' => 1000000),
				array('col_name' => 'column7',     'datatype' => 'char',      'method' => 'random',	'min' => 0,	'max' => 6),
				array('col_name' => 'column8',     'datatype' => 'tinytext',  'method' => 'random',	'min' => 0,	'max' => 255),
				array('col_name' => 'column9',     'datatype' => 'binary',    'method' => 'random',	'min' => 0,	'max' => 16),
				array('col_name' => 'column10',    'datatype' => 'tinyblob',  'method' => 'random',	'min' => 0,	'max' => 1000),
				array('col_name' => 'column11',    'datatype' => 'tinyint',   'method' => 'random',	'min' => -128,	'max' => 127)),
'table2' => array(
				array('col_name' => 'id',         'datatype' => 'int',      'method' => 'ignore',	'min' => 0,	'max' => 4294967295),
				array('col_name' => 'column1',    'datatype' => 'varchar',  'method' => 'autoinc',	'min' => 0,	'max' => 100),
				array('col_name' => 'column2',    'datatype' => 'timestamp','method' => 'random',	'min' => 0,	'max' => 1000000)),
'table3' => array(
				array('col_name' => 'column1',    'datatype' => 'binary',   'method' => 'random',	'min' => 0,	'max' => 16),
				array('col_name' => 'column2',    'datatype' => 'varchar',  'method' => 'random',	'min' => 0,	'max' => 20),
				array('col_name' => 'column3',    'datatype' => 'double',   'method' => 'random',	'min' => 0,	'max' => 1000000),
				array('col_name' => 'column4',    'datatype' => 'float',    'method' => 'random',	'min' => 0,	'max' => 1000000),
				array('col_name' => 'column5',    'datatype' => 'double',   'method' => 'random',	'min' => 0,	'max' => 1000000),
				array('col_name' => 'column6',    'datatype' => 'bit',      'method' => 'random',	'min' => 0,	'max' => 1000000)),
'table4' => array(
				array('col_name' => 'id',         'datatype' => 'int',      'method' => 'autoinc',	'min' => 0,	'max' => 4294967295),
				array('col_name' => 'column1',    'datatype' => 'int',      'method' => 'random',	'min' => -2147483648,	'max' => 2147483647),
				array('col_name' => 'column2',    'datatype' => 'longtext', 'method' => 'random',	'min' => 0,	'max' => 4295)),
'table5' => array(
				array('col_name' => 'id',         'datatype' => 'bigint',   'method' => 'autoinc',	'min' => 0,	'max' => 18446744073709551616),
				array('col_name' => 'column1',    'datatype' => 'int',      'method' => 'random',	'min' => -2147483648,	'max' => 2147483647),
				array('col_name' => 'column2',    'datatype' => 'datetime', 'method' => 'random',	'min' => 0,	'max' => 1000000),
				array('col_name' => 'column3',    'datatype' => 'float',    'method' => 'random',	'min' => 0,	'max' => 1000000),
				array('col_name' => 'column4',    'datatype' => 'varchar',  'method' => 'random',	'min' => 0,	'max' => 20))
);


// having '*' for a piece of data is like saying if chosen this will be filled with random data. the more '*' in the array the more chance of inserting random data
// this helps with making psudo random data and also controlling the cardinality to a degree
$fixed_data = 	array( 	'table1.col1' => array('INFO','WARNING','ERROR','DEBUG','FATAL'),
			'sometable.somecolumn' => array('thing','somethingelse','someotherthing','*'));


$what_to_do = array(
			'table1'		 => array('CRUD' => array('INSERT' => 100, 'SELECT' => 0, 'UPDATE' => 0, 'DELETE' => 0, 'REPLACE' => 0), 'SLEEP' => array('MIN' => 0, 'MAX' => 0)),
			'table2'		 => array('CRUD' => array('INSERT' => 100, 'SELECT' => 0, 'UPDATE' => 0, 'DELETE' => 0, 'REPLACE' => 0), 'SLEEP' => array('MIN' => 0, 'MAX' => 0)),
			'table3'		 => array('CRUD' => array('INSERT' => 100, 'SELECT' => 0, 'UPDATE' => 0, 'DELETE' => 0, 'REPLACE' => 0), 'SLEEP' => array('MIN' => 0, 'MAX' => 0)),
			'table4'		 => array('CRUD' => array('INSERT' => 100, 'SELECT' => 0, 'UPDATE' => 0, 'DELETE' => 0, 'REPLACE' => 0), 'SLEEP' => array('MIN' => 0, 'MAX' => 0)),
			'table5'		 => array('CRUD' => array('INSERT' => 100, 'SELECT' => 0, 'UPDATE' => 0, 'DELETE' => 0, 'REPLACE' => 0), 'SLEEP' => array('MIN' => 0, 'MAX' => 0)));



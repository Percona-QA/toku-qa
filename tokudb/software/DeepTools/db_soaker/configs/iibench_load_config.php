<?php

$meta_data = array(
'purchases_index' => array(
				array('col_name' => 'transactionid',     'datatype' => 'int',       'method' => 'autoinc', 'min' => 0, 'max' => 4294967295),
				array('col_name' => 'cashregisterid',    'datatype' => 'int',       'method' => 'random',  'min' => 0, 'max' => 1000),
				array('col_name' => 'customerid',        'datatype' => 'int',       'method' => 'random',  'min' => 0, 'max' => 10000),
				array('col_name' => 'productid',         'datatype' => 'int',       'method' => 'random',  'min' => 0, 'max' => 100000),
				array('col_name' => 'dateandtime',       'datatype' => 'datetime',  'method' => 'random',  'min' => 1, 'max' => 1),
				array('col_name' => 'price',             'datatype' => 'float',     'method' => 'random',  'min' => 0, 'max' => 1000000))
);

$what_to_do = array(
			'purchases_index'		 => array('CRUD' => array('INSERT' => 100, 'SELECT' => 0, 'UPDATE' => 0, 'DELETE' => 0, 'REPLACE' => 0), 'SLEEP' => array('MIN' => 0, 'MAX' => 0)));



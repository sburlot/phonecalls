<?

	// Fetch list of calls from the DB, format in JSON
	
	$db_user = "batman";
	$db_pwd = "nanananana";

	$link = mysql_connect('localhost', $db_user, $db_pwd)
						or die(mysql_error());

	$db_selected = mysql_select_db('swisscom', $link);

	if (!$db_selected) {
		die ('Can\'t use foo : ' . mysql_error());
	}

	$response = array();
	$sql_query = "SELECT DATE_FORMAT(`date`,'%Y/%m/%d %H:%i:%S') as `date_formatted`, `number` FROM answered_calls ORDER by `date` DESC LIMIT 50";
	$result = mysql_query( $sql_query ) or die("SQL Error ".mysql_error());
	$answered_calls = array();

	while ($row = mysql_fetch_array($result,MYSQL_ASSOC)) {
		$answered_calls[] = array('date' => $row['date_formatted'], 'phone' => $row['number']);
	}
	$response['answered_calls'] = $answered_calls;

	$sql_query = "SELECT DATE_FORMAT(`date`,'%Y/%m/%d %H:%i:%S') as `date_formatted`, `number` FROM missed_calls ORDER by `date` DESC LIMIT 50";
	$result = mysql_query( $sql_query ) or die("SQL Error ".mysql_error());
	$missed_calls = array();
	while ($row = mysql_fetch_array($result,MYSQL_ASSOC)) {
		$missed_calls[] = array('date' => $row['date_formatted'], 'phone' => $row['number']);
	}
	$response['missed_calls'] = $missed_calls;
	$json = json_encode($response);
	mysql_close($link);

	header('Content-Type: application/json');
	print $json;

?>
<?php 
$mysql_connection = mysqli_connect('localhost', 'admin_default', 'PASSWORD', 'admin_default');
if (!$mysql_connection) {
  http_response_code(500);
  echo "MYSQL is down";
}
else {
  echo 'MYSQL is working';
}
mysqli_close($mysql_connection);
?>

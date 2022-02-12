#!/bin/bash -l
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/../config.ini

# This script will perform a series of tests on a given server. The remote server must be configured with this script collection
USAGE="check-remote-server.sh HOSTNAME"

if [[ -z $1 ]]; then
  echo "!!!!! This script needs at least 1 argument: Hostname"
  echo "---"
  echo "Usage example:"
  echo $USAGE
  exit 1
fi
URL=$1

# Set scripts
NGINX_FILE=check_nginx.html
PHP_FILE=check_php.php
MYSQL_FILE=check_mysql.php

# Set DOWN as default status
PING=DOWN
NGINX=DOWN
PHP=DOWN
MYSQL=DOWN

BODY="Sommething is wrong in the server $URL:<br><br>"

echo "Server status $URL:"

# Check ping status
if ping -c 2 -W 10 $URL 2>&1 >/dev/null; then
  PING=OK
  echo "Ping: OK"
else
  echo "Ping: SERVER DOWN!!!"
  BODY="${BODY}<b style='color: #f00'>!!! Ping: SERVER DOWN</b><br>"
fi

# Check if nginx is up
STATUS="$(curl -ILs --max-time 15 $URL/$NGINX_FILE)"
CODE="$(printf %s "$STATUS" | grep -m1 '^HTTP.*' | awk {'print $2'})"
FINAL_CODE="$(printf %s "$STATUS" | tac | grep -m1 '^HTTP.*' | awk {'print $2'})"

if [[ $FINAL_CODE = "200" ]]; then
  NGINX=OK
  echo "Nginx: OK"
else
  echo "Nginx: DOWN!!!"
  BODY="${BODY}<b style='color: #f00'>!!! Nginx: DOWN</b><br>"
fi

# Check if PHP is working
STATUS="$(curl -ILs --max-time 15 $URL/$PHP_FILE)"
CODE="$(printf %s "$STATUS" | grep -m1 '^HTTP.*' | awk {'print $2'})"
FINAL_CODE="$(printf %s "$STATUS" | tac | grep -m1 '^HTTP.*' | awk {'print $2'})"

if [[ $FINAL_CODE = "200" ]]; then
  PHP=OK
  echo "PHP: OK"
else
  echo "PHP: DOWN!!!"
  BODY="${BODY}<b style='color: #f00'>!!! PHP: DOWN</b><br>"
fi

# Check if mysql is up and running
STATUS="$(curl -ILs --max-time 15 $URL/$MYSQL_FILE)"
CODE="$(printf %s "$STATUS" | grep -m1 '^HTTP.*' | awk {'print $2'})"
FINAL_CODE="$(printf %s "$STATUS" | tac | grep -m1 '^HTTP.*' | awk {'print $2'})"

if [[ $FINAL_CODE = "200" ]]; then
  MYSQL=OK
  echo "MYSQL: OK"
else
  echo "MYSQL: DOWN!!!"
  BODY="${BODY}<b style='color: #f00'>!!! MYSQL: DOWN</b><br>"
fi

# Alert by email
IFS=',' read -a HOST_ALERTS_EMAILS <<< "$EMAILS"

if [ $PING = "DOWN" ] || [ $NGINX = "DOWN" ] || [ $PHP = "DOWN" ] || [ $MYSQL = "DOWN" ]; then
  echo "Sending alerts to:"
  for EMAIL in "${EMAILS_ARRAY[@]}"
  do
    echo $EMAIL
    echo -e $BODY | mail -s "URGENT: Problems found in $REMOTE_SERVER_NAME!" -a "Content-Type: text/html; charset=UTF-8" $EMAIL
  done
fi

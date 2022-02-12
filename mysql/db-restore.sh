#!/bin/bash
# This script will "empty" a database

CURRENT_DIR=`dirname $0`

DB=$1
DB_FILE=$2

$CURRENT_DIR/db-drop.sh $DB
$CURRENT_DIR/db-new.sh $DB

if [[ $DB_FILE = *".gz"* ]]; then
  gunzip < $DB_FILE | mysql $DB
else
  mysql $DB < $DB_FILE
fi


#!/bin/bash
# This script will create a database

if [ -z $1 ]; then
        echo "No database entered"
        exit 1
fi
DB=$1
mysql -e "CREATE DATABASE IF NOT EXISTS $DB"

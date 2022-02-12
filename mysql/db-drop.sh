#!/bin/bash
if [ -z $1 ]; then
        echo "No database entered"
        exit 1
fi
DB=$1
mysqladmin -f drop $DB

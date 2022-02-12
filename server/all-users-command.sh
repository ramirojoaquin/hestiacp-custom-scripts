#!/bin/bash
# This script will run a specific command on all users
USAGE="all-users-commend.sh COMMAND ARGUMENT"

if [ -z $1 ]; then
  echo "No command entered"
  exit 1
  echo $USAGE
fi

COMMAND=$1

if [ -z $2 ]; then
  ARGUMENT=""
else
  ARGUMENT=$2
fi

# Listamos usuarios
v-list-users | cut -d " " -f1 | awk '{if(NR>2)print}' | while read USER ; do
  $COMMAND $USER $ARGUMENT
  sleep 1s
  echo $USER
done


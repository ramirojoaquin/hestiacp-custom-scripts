#!/bin/bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/config.ini

# This script will restore a web domain from incremental backup
USAGE="restore-web.sh 2018-03-25 user domain.com database"

# Assign arguments
TIME=$1
USER=$2
WEB=$3

# Set script start time
START_TIME=`date +%s`

# Temp dir setup
TEMP_DIR=$CURRENT_DIR/tmp
mkdir -p $TEMP_DIR

# Set user repository
USER_REPO=$REPO_USERS_DIR/$USER

##### Validations #####

if [[ -z $1 || -z $2 || -z $3 ]]; then
  echo "!!!!! This script needs at least 3 arguments. Backup date, user name and web domain. Dadabase is optional"
  echo "---"
  echo "Usage example:"
  echo $USAGE
  exit 1
fi

if [ ! -d "$HOME_DIR/$USER" ]; then
  echo "!!!!! User $USER does not exist"
  echo "---"
  echo "Available users:"
  ls $HOME_DIR
  echo "---"
  echo "Usage example:"
  echo $USAGE
  exit 1
fi

if [ ! -d "$HOME_DIR/$USER/web/$WEB" ]; then
  echo "!!!!! The web domain $WEB does not exist under user $USER."
  echo "---"
  echo "User $USER has the following available web domains:"
  ls $HOME_DIR/$USER/web
  echo "---"
  echo "Usage example:"
  echo $USAGE
  exit 1
fi

if [ ! -d "$USER_REPO/data" ]; then
  echo "!!!!! User $USER has no backup repository or no backup has been executed yet. Aborting..."
  exit 1
fi

if ! borg list $USER_REPO | grep -q $TIME; then
  echo "!!!!! Backup archive $TIME not found, the following are available:"
  borg list $USER_REPO
  echo "Usage example:"
  echo $USAGE
  exit 1
fi


echo "########## BACKUP ARCHIVE $TIME FOUND, PROCEEDING WITH RESTORE ##########"

read -p "Are you sure you want to restore web $WEB owned by $USER with $TIME backup version? " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  [[ "$0" = "$BASH_SOURCE" ]]
  echo
  echo "########## PROCESS CANCELED ##########"
  exit 1
fi

# Set dir paths
WEB_DIR=$HOME_DIR/$USER/web/$WEB/$PUBLIC_HTML_DIR_NAME
BACKUP_WEB_DIR="${WEB_DIR:1}"

echo "-- Restoring web domain files from backup $USER_REPO::$TIME to temp dir"
cd $TEMP_DIR
borg extract --list $USER_REPO::$TIME $BACKUP_WEB_DIR

# Check that the files have been restored correctly
if [ ! -d "$BACKUP_WEB_DIR" ]; then
  echo "!!!!! $WEB is not present in backup archive $TIME. Aborting..."
  exit 1
fi
if [ -z "$(ls -A $BACKUP_WEB_DIR)" ]; then
  echo "!!!!! $WEB restored directory is empty, Aborting..."
  exit 1
fi

echo "-- Restoring files from temp dir to $WEB_DIR"
rsync -za --delete $BACKUP_WEB_DIR/ $WEB_DIR/

echo "-- Fixing permissions"
chown -R $USER:$USER $WEB_DIR/

# Check if database argument is present and proceed with database restore

if [ $4 ]; then
  DB=$4
  v-list-databases $USER | cut -d " " -f1 | awk '{if(NR>2)print}' | while read DATABASE ; do
    if [ "$DB" == "$DATABASE" ]; then
      echo "-- Restoring database $DB from backup $USER_REPO::$TIME"
      DB_DIR=$HOME_DIR/$USER/$DB_DUMP_DIR_NAME
      BACKUP_DB_DIR="${DB_DIR:1}"
      borg extract --list $USER_REPO::$TIME $BACKUP_DB_DIR
      # Check that the files have been restored correctly
      DB_FILE=$BACKUP_DB_DIR/$DB.sql.gz
      if [ ! -f "$DB_FILE" ]; then
        echo "!!!!! Database $DB files are not present in backup archive $TIME. Aborting database restoration..."
      else
        $CURRENT_DIR/inc/db-restore.sh $DB $DB_FILE
      fi
    else
      echo "!!!!! Database $DB not found under selected user. User $USER has the following databases:"
      v-list-databases $USER | cut -d " " -f1 | awk '{if(NR>2)print}'
    fi
  done
fi

echo "----- Cleaning temp dir"
if [ -d "$TEMP_DIR" ]; then
  rm -rf $TEMP_DIR/*
fi

echo
echo "$(date +'%F %T') ########## WEB $WEB OWNED BY $USER RESTORE COMPLETED ##########"

END_TIME=`date +%s`
RUN_TIME=$((END_TIME-START_TIME))

echo "-- Execution time: $(date -u -d @${RUN_TIME} +'%T')"
echo

# Log to file
source $CURRENT_DIR/inc/log_message.sh


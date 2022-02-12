#!/bin/bash -l
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/config.ini

# This script will update a single user mail from remote server

USAGE="update-mails.sh user"

##### Validations #####

if [[ -z $1 ]]; then
  echo "!!!!! This script needs at least 1 argument: username"
  echo "---"
  echo "Usage example:"
  echo $USAGE
  exit 1
fi

##### Script #####
USER=$1
echo "-------------------- Processing $USER"
echo "- Sync mails"
rsync -zav $SOURCE_DATA_HOME_DIR/$USER/mail/ /home/$USER/mail/
chown -R $USER:mail /home/$USER/mail/*
echo -e "-------------------- $USER mails updated
"


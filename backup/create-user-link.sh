#!/bin/bash -l

USER=$1
FILE=$USER.tar.gz
HOSTNAME=$(hostname)
BACKUP_DIR=/backup/offline
OWNER=admin
DOMAIN=archivo.$HOSTNAME
LINK="https://$DOMAIN/$FILE"

# Creamos el symlink
ln -s $BACKUP_DIR/$FILE /home/$OWNER/web/$DOMAIN/public_html/$FILE

echo "-----------------------------------"
echo "Link creado para usuario $USER"
echo "-----------------------------------"
echo "$BACKUP_DIR/$FILE -> $LINK"
echo "-----------------------------------"

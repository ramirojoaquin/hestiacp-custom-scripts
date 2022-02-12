#!/bin/bash -l
# Este script sirve para actualizar todos los sitios del server que utilicen drupal
# Aparte de actualizar el core y los modulos, también sirve para correr un determinado commando en todos los sitios.
CURRENT_DIR=`dirname $0`

HOME_DIR=/home
DRUSH=/usr/local/bin/drush

if [ $1 ]; then
  COMMAND=$1
else
  COMMAND=cron
fi

COUNT=0

# Listamos usuarios
while read USER ; do
  while read DOMAIN ; do
    WEB_DIR=$HOME_DIR/$USER/web/$DOMAIN/public_html
    if [[ -f "$WEB_DIR/sites/default/settings.php" ]] || [[ -f "$WEB_DIR/web/sites/default/settings.php" ]]; then
      if [ -d "$WEB_DIR/core" ] || [ -d "$WEB_DIR/web/core" ]; then
        CACHE_COMMAND="cr"
        UPGRADE_COMMAND="composer update; $DRUSH -y updatedb"
      else
        CACHE_COMMAND="cc all"
        UPGRADE_COMMAND="$DRUSH -y up"
      fi
      echo "$(date +'%Y-%m-%d_%H-%M-%S')----->> Ejecutando -$COMMAND- en $DOMAIN"
      cd $WEB_DIR
      if [ $COMMAND == "cron" ]; then
        su -c "$DRUSH -y cron" $USER
      elif [ $COMMAND == "up" ]; then
        su -c "$UPGRADE_COMMAND" $USER
        su -c "$DRUSH -y $CACHE_COMMAND" $USER
        rm -rf cache/*
      elif [ $COMMAND == "cc" ]; then
        su -c "$DRUSH -y $CACHE_COMMAND" $USER
        rm -rf cache/*
      elif [ $COMMAND == "version" ]; then
        su -c "$DRUSH core-status | grep 'Drupal version'" $USER
      elif [ $COMMAND == "uninstall" ]; then
        if [ $2 ]; then
          if [ -d "$WEB_DIR/core" ] || [ -d "$WEB_DIR/web/core" ]; then
            su -c "$DRUSH pm-uninstall -y $2" $USER
          else
            su -c "$DRUSH pm-disable -y $2" $USER
            su -c "$DRUSH pm-uninstall -y $2" $USER
          fi
        else
          echo "No se especifico modulo a desinstalar"
        fi
      fi
      let COUNT++
    fi
  done < <(v-list-web-domains $USER | cut -d " " -f1 | awk '{if(NR>2)print}')
done < <(v-list-users | cut -d " " -f1 | awk '{if(NR>2)print}')

echo -e "$(date +'%Y-%m-%d_%H-%M-%S')----->> Se ejecuto -$COMMAND- en $COUNT drupals"
#!/bin/bash
# Este script ejecuta un comando en todos los wordpress del server
# Si no se especifica el comando, hace un upgrade del core, plugins, themes y traducciones.
USAGE='wp-cli-all-webs.sh "command to execute" or upgrade'

# Comando upgrade por default
COMMAND="wp core update; wp plugin update --all; wp theme update --all; wp language plugin --all update; wp language theme --all update"
if [[ $1 ]]; then
  COMMAND=$1
fi

# Establecemos los contadores
USER_COUNT=0
DOMAIN_COUNT=0

# Tiempo de inicio
START_TIME=`date +%s`

# Hacemos el loop por usuarios y dominios
while read USER ; do
  # Incrementamos el count de usuarios
  let USER_COUNT++
  while read DOMAIN ; do
    # Seteamos el directorio public y el wp-config
    PUBLIC_HTML=/home/$USER/web/$DOMAIN/public_html
    WP_CONFIG=$PUBLIC_HTML/wp-config.php
    # Si existe wp-config dentro del public procedemos con el update
    if [[ -f $WP_CONFIG ]]; then
      echo "
$(date +'%F %T') -------------------- $USER - $DOMAIN"
      cd $PUBLIC_HTML
      su -c "$COMMAND" $USER
      # Incrementamos el count de dominios
      let DOMAIN_COUNT++
    fi
  done < <(v-list-web-domains $USER | cut -d " " -f1 | awk '{if(NR>2)print}')
done < <(v-list-users | cut -d " " -f1 | awk '{if(NR>2)print}')

# Calculamos tiempo total
END_TIME=`date +%s`
RUN_TIME=$((END_TIME-START_TIME))

# Resumen
echo "--------------------------------

Usuarios procesador: $USER_COUNT
Wordpress actualizados: $DOMAIN_COUNT
Tiempo transcurrido: $RUN_TIME
"

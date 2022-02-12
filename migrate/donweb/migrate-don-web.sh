#!/bin/bash

# Configuramos las variables de sistema
shopt -s dotglob

# Seteamos directorios globales
CURRENT_DIR=`dirname $0`

HOSTNAME=$(hostname)

DATA_DIR=$CURRENT_DIR/a-migrar
TEMP_DIR=$CURRENT_DIR/temp
DONE_DIR=$CURRENT_DIR/migrados

# Configuramos preferencias de creacion de usuarios y bases de datos
ADMIN_EMAIL="webmaster@$HOSTNAME"
HOST_IPS=$(hostname -I)
IP=$(hostname -I | awk {'print $1'})
DB_SUFFIX=bd
DB_USER_SUFFIX=us

# Limpiamos el directorio temporal
if [[ -d $TEMP_DIR ]]; then
  rm -rf $TEMP_DIR/*
fi

# Itineramos por los archivos tar.gz de don web
for FILE in $DATA_DIR/*; do
  if [[ $FILE == *".tar.gz"* ]]; then
    # Seteamos nombre de usuario basado en el nombre base del archivo tar
    FILE_BASENAME=${FILE##*/}
    USER=${FILE_BASENAME%.tar.gz}

    # Generamos la password
    PASS=$(openssl rand -base64 16 | cut -c1-10)

    # Seteamos nombre y usuario de base de datos
    DB=$USER"_"$DB_SUFFIX
    DB_USER=$USER"_"$DB_USER_SUFFIX

    # Generamos password de base de datos
    DB_PASS=$(openssl rand -base64 16 | cut -c1-10)

    # Establecemos y creamos el directorio temporal para el usuario, donde se extraerá el contenido del tar
    USER_TEMP_DIR=$TEMP_DIR/$USER
    mkdir -p $USER_TEMP_DIR
    
    # Comenzamos con el procesamiento
    echo "<<<<<<<<<< $USER >>>>>>>>>>"

    # Creamos el usuario en vesta
    v-add-user $USER $PASS $ADMIN_EMAIL

    # Imprimimos en pantalla las credenciales de acceso de usuario
    printf '\n'
    echo "--- ACCESO A VESTA, FTP Y SSH:"
    echo "Usuario: $USER"
    echo "Pass: $PASS"
    
    # Descomprimimos el archivo tar de donweb a la carpeta temporal del usuario
    tar -C $USER_TEMP_DIR -xf $FILE

    # Obtenemos el nombre del directorio raiz del usuario (que empieza con "package")
    for DIR in $USER_TEMP_DIR/*; do
      if [[ $DIR == *"package"* ]]; then
        # Seteamos directorios en donde encontramos la info dentro del tar
        PACKAGE_DIR=$DIR
        MAIL_DIR=$PACKAGE_DIR/home/mail
        PUBLIC_HTML_FILE=$PACKAGE_DIR/home/public_html.tar.gz
        DB_DIR=$PACKAGE_DIR/var/lib/mysql
        
        # Chequeamos si hay base de datos
        for DB_FILE in $DB_DIR/*struct.sql; do
          if [[ -f $DB_FILE ]]; then
            DB_PRESENT=true
          fi
        done

        # Si hay base procedemos a crearla e importarla
        if [[ $DB_PRESENT == true ]]; then
          # Creamos la base
          v-add-database $USER $DB_SUFFIX $DB_USER_SUFFIX $DB_PASS

          # Importamos base de datos
          for DB_FILE in $DB_DIR/*struct.sql; do
            mysql $DB < $DB_FILE
          done
          for DB_FILE in $DB_DIR/*data.sql; do
            mysql $DB < $DB_FILE
          done

          # Imprimimos las credenciales de la base en pantalla
          printf '\n'
          echo "--- BASE DE DATOS:"
          echo "Base: $DB"
          echo "Usuario: $DB_USER"
          echo "Pass: $DB_PASS"
        fi

        # Obtenemos el nombre del dominio desde la carpeta de mails
        for DIR in $MAIL_DIR/*; do
          # Validamos el nombre del directorio, excluyendo nombres que pueden estar dentro de esa carpeta
          if [[ -d $DIR && $DIR != *"ferozo"* && $DIR != *"cur"* && $DIR != *"new"* && $DIR != *"tmp"* ]]; then
            # Seteamos el nombre del dominio
            DOMAIN=$(basename -- $DIR)

            # Seteamos directorio raiz de casillas de email del dominio dentro del tar
            SOURCE_MAIL_DOMAIN_DIR=$DIR
            
            # Seteamos directorio web del dominio en vesta
            DOMAIN_WEB_DIR=/home/$USER/web/$DOMAIN

            # Seteamos directorio del public_html en vesta y wp-config de wordpress
            PUBLIC_HTML_DIR=$DOMAIN_WEB_DIR/public_html
            WP_CONFIG=$PUBLIC_HTML_DIR/wp-config.php
            
            # Seteamos directorio raiz de casillas de email del dominio en vesta
            MAIL_DOMAIN_DIR=/home/$USER/mail/$DOMAIN

            # Creamos el dominio web, mail y dns
            v-add-domain $USER $DOMAIN $IP no

            # Descomprimimos el public_html dentro del public_html de vesta
            tar -C $DOMAIN_WEB_DIR -xf $PUBLIC_HTML_FILE public_html
            
            # Chequeamos si es un wordpress
            if [[ -f $WP_CONFIG ]]; then
              # Si es wordpress conectamos a la base nueva modificando el wp-config.php
              sed -i "/DB_HOST/s/'[^']*'/'localhost'/2" $WP_CONFIG
              sed -i "/DB_NAME/s/'[^']*'/'$DB'/2" $WP_CONFIG
              sed -i "/DB_USER/s/'[^']*'/'$DB_USER'/2" $WP_CONFIG
              sed -i "/DB_PASSWORD/s/'[^']*'/'$DB_PASS'/2" $WP_CONFIG
              # Cambiamos el template del dominio
              v-change-web-domain-tpl $USER $DOMAIN wordpress_w3tc-PHP-73 no
            fi

            # Arreglamos permisos del public_html
            chown -R $USER:$USER $PUBLIC_HTML_DIR
            chmod -R 775 $PUBLIC_HTML_DIR
            
            
            # Chequeamos si hay casillas de correo
            if [ ! -z "$(ls -A $SOURCE_MAIL_DOMAIN_DIR)" ]; then
              # Migramos cada una de las casillas de email presentes en el tar
              printf '\n'
              echo "--- CASILLAS DE CORREO:"
              for DIR in $SOURCE_MAIL_DOMAIN_DIR/*; do
                # Chequeamos que no sea la casilla no-reply
                if [[ $DIR != *"no-reply"* ]]; then
                  # Seteamos variables de la casilla
                  MAIL_ACCOUNT_USER=$(basename -- $DIR)
                  MAIL_ACCOUNT_PASS=$(openssl rand -base64 16 | cut -c1-10)
                  MAIL_ACCOUNT="$MAIL_ACCOUNT_USER@$DOMAIN"
                  SOURCE_MAIL_ACCOUNT_DIR=$DIR/Maildir
                  MAIL_ACCOUNT_DIR=$MAIL_DOMAIN_DIR/$MAIL_ACCOUNT_USER
                  v-add-mail-account $USER $DOMAIN $MAIL_ACCOUNT_USER $MAIL_ACCOUNT_PASS
                  # Migramos correos de la INBOX
                  INBOX_DIR=$MAIL_ACCOUNT_DIR/cur
                  SOURCE_INBOX_DIR=$SOURCE_MAIL_ACCOUNT_DIR/cur
                  if [ ! -z "$(ls -A $SOURCE_INBOX_DIR)" ]; then
                    mkdir -p $INBOX_DIR
                    mv $SOURCE_INBOX_DIR/* $INBOX_DIR/
                  fi
                  # Migramos los correos de las carpetas
                  for DIR in $SOURCE_MAIL_ACCOUNT_DIR/*; do
                    if [[ -d $DIR ]]; then
                      FOLDER_NAME=$(basename -- $DIR)
                      if [[ "$FOLDER_NAME" =~ ^\. && $FOLDER_NAME != *"spam"* ]];then
                        SOURCE_CUR_DIR="$DIR/cur"
                        # Corregimos nombre de la carpeta enviados
                        if [[ $FOLDER_NAME == *"Sent"* ]];then
                          CUR_DIR="$MAIL_ACCOUNT_DIR/.Sent/cur"
                        else
                          CUR_DIR="$MAIL_ACCOUNT_DIR/$FOLDER_NAME/cur"
                        fi
                        # Chequeamos que la carpeta no este vacia antes de migrar
                        if [ ! -z '$(ls -A "$SOURCE_CUR_DIR")' ]; then
                          mkdir -p $CUR_DIR
                          mv "$SOURCE_CUR_DIR" "$CUR_DIR"
                        fi
                      fi
                    fi
                  done
                  # Imprimimos las credenciales de la cuenta de correo
                  echo "$MAIL_ACCOUNT / $MAIL_ACCOUNT_PASS"
                fi
              done
            fi
            # Corregimos permisos de emails
            chown -R $USER:mail $MAIL_DOMAIN_DIR
          fi
        done
      fi
    done
    printf '\n'
    printf '\n'
  fi
done


# Limpiamos el directorio temporal
if [[ -d $TEMP_DIR ]]; then
  rm -rf $TEMP_DIR/*
fi

# Movemos los archivos ya migrados a la carpeta de migrados
mv $DATA_DIR/*.tar.gz $DONE_DIR/

# Reiniciamos los servicios para que los cambios se apliquen
service nginx restart
v-restart-web-backend
service mysql restart

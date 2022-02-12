#!/bin/bash -l
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/../config.ini

echo "- Habilitamos bash por defecto para los nuevos usuarios"
v-change-user-shell admin bash
sed -i "s/nologin/bash/g" $HESTIA_DIR/data/packages/default.pkg

echo "- Preparamos los templates DNS"
cp $CURRENT_DIR/data/templates/dns/default.tpl $HESTIA_DIR/data/templates/dns/default.tpl
chown root:root $HESTIA_DIR/data/templates/dns/default.tpl
chmod 755 $HESTIA_DIR/data/templates/dns/default.tpl
sed -i "s/SPF_IPS/$SPF_IPS/g" $HESTIA_DIR/data/templates/dns/default.tpl
sed -i "s/HOST_DOMAIN/$HOST_DOMAIN/g" $HESTIA_DIR/data/templates/dns/default.tpl
sed -i "s/HOST_DNS_DOMAIN/$HOST_DNS_DOMAIN/g" $HESTIA_DIR/data/templates/dns/default.tpl
chown root:root $HESTIA_DIR/data/templates/dns/*
chmod 775 $HESTIA_DIR/data/templates/dns/*

echo "- Copiamos templates web personalizados"
rsync -av ./data/templates/web/nginx/php-fpm/ $HESTIA_DIR/data/templates/web/nginx/php-fpm/
chown -R root:root $HESTIA_DIR/data/templates/web/nginx/php-fpm/
chmod -R 644 $HESTIA_DIR/data/templates/web/nginx/php-fpm/

echo "- Configuramos el skel"
rsync -a --delete $CURRENT_DIR/data/templates/web/skel/$HOST_LANGUAGE/ $HESTIA_DIR/data/templates/web/skel/
chown -R root:root $HESTIA_DIR/data/templates/web/skel/

echo "- Configuramos default server"
rsync -a --delete $CURRENT_DIR/data/templates/web/skel/$HOST_LANGUAGE/document_errors/ /var/www/document_errors/
cp $CURRENT_DIR/host_public_html/index.html /var/www/html/index.html
sed -i "s/HOST_DOMAIN/$HOST_DOMAIN/g" /var/www/html/index.html
chown root:root /var/www/
chmod -R 755 /var/www/

echo "----- Customizamos con logo y nombre de la empresa"
# Hestia
HESTIA_IMAGES_DIR=/usr/local/hestia/web/images
cp $CURRENT_DIR/host_public_html/favicon.ico $HESTIA_IMAGES_DIR/favicon.ico
cp $CURRENT_DIR/host_public_html/logo.svg $HESTIA_IMAGES_DIR/logo.svg
cp $CURRENT_DIR/host_public_html/logo-header.svg $HESTIA_IMAGES_DIR/logo-header.svg
chown -R root:root $HESTIA_IMAGES_DIR
# Roundcube
WEBMAIL_LOGO="https://$HOST_DOMAIN/logo-webmail.png"
cp $CURRENT_DIR/etc/roundcube/config.inc.php /var/lib/roundcube/config/config.inc.php
sed -i "s/HOST_DOMAIN/$HOST_DOMAIN/g" /var/lib/roundcube/config/config.inc.php
sed -i "s,WEBMAIL_LOGO,$WEBMAIL_LOGO,g" /var/lib/roundcube/config/config.inc.php
chown root:www-data /var/lib/roundcube/config/config.inc.php


# Configuramos Nginx

echo "----- Configurando NGINX"
rsync -a $CURRENT_DIR/etc/nginx/ /etc/nginx/
chown -R root:root /etc/nginx/
sed -i "s/HOST_DOMAIN/$HOST_EMAIL_DOMAIN/g" /etc/nginx/conf.d/phpmyadmin.inc.common


# Configuramos PHP
echo "----- Configurando PHP"
for PHP_VERSION_DIR in /etc/php/*; do
   echo "- Aplicando configuración en $PHP_VERSION_DIR/fpm/php.ini"
   sed -i "s,^date.timezone =.*$,date.timezone = $HOST_TIMEZONE," $PHP_VERSION_DIR/fpm/php.ini
   sed -i "s,^memory_limit =.*$,memory_limit = $PHP_MEMORY_LIMIT," $PHP_VERSION_DIR/fpm/php.ini
   sed -i "s,^post_max_size =.*$,post_max_size = $PHP_POST_MAX_SIZE," $PHP_VERSION_DIR/fpm/php.ini
   sed -i "s,^upload_max_filesize =.*$,upload_max_filesize = $PHP_UPLOAD_MAX_FILESIZE," $PHP_VERSION_DIR/fpm/php.ini
   sed -i "s,^max_execution_time =.*$,max_execution_time = $PHP_MAX_EXECUTION_TIME," $PHP_VERSION_DIR/fpm/php.ini
   sed -i "s,^max_input_time =.*$,max_input_time = $PHP_MAX_INPUT_TIME," $PHP_VERSION_DIR/fpm/php.ini
done
sed -i "s,^;opcache.memory_consumption=.*$,opcache.memory_consumption=$PHP_OPCACHE_MEMORY," /etc/php/7.3/fpm/php.ini
sed -i "s,^;opcache.max_accelerated_files=.*$,opcache.max_accelerated_files=$PHP_OPCACHE_FILES," /etc/php/7.3/fpm/php.ini


# Configuramos los templates para el backend
echo "- Configuramos los templates para el backend PHP"
rsync -a --delete $CURRENT_DIR/data/templates/web/php-fpm/ $HESTIA_DIR/data/templates/web/php-fpm/
for TEMPLATE in $HESTIA_DIR/data/templates/web/php-fpm/*; do
   echo "- Aplicando configuración en $TEMPLATE"
   sed -i "s/PHPFPM_DEFAULT_MAX_CHILDRENS/$PHPFPM_DEFAULT_MAX_CHILDRENS/g" $TEMPLATE
   sed -i "s/PHPFPM_DEFAULT_START/$PHPFPM_DEFAULT_START/g" $TEMPLATE
   sed -i "s/PHPFPM_DEFAULT_MIN_SPARE/$PHPFPM_DEFAULT_MIN_SPARE/g" $TEMPLATE
   sed -i "s/PHPFPM_DEFAULT_MAX_SPARE/$PHPFPM_DEFAULT_MAX_SPARE/g" $TEMPLATE
   sed -i "s/PHPFPM_DEFAULT_REQS/$PHPFPM_DEFAULT_REQS/g" $TEMPLATE
   sed -i "s/PHPFPM_DEFAULT_TIMEOUT/$PHPFPM_DEFAULT_TIMEOUT/g" $TEMPLATE
   sed -i "s/PHPFPM_MEDIUM_MAX_CHILDRENS/$PHPFPM_MEDIUM_MAX_CHILDRENS/g" $TEMPLATE
   sed -i "s/PHPFPM_MEDIUM_START/$PHPFPM_MEDIUM_START/g" $TEMPLATE
   sed -i "s/PHPFPM_MEDIUM_MIN_SPARE/$PHPFPM_MEDIUM_MIN_SPARE/g" $TEMPLATE
   sed -i "s/PHPFPM_MEDIUM_MAX_SPARE/$PHPFPM_MEDIUM_MAX_SPARE/g" $TEMPLATE
   sed -i "s/PHPFPM_MEDIUM_REQS/$PHPFPM_MEDIUM_REQS/g" $TEMPLATE
   sed -i "s/PHPFPM_MEDIUM_TIMEOUT/$PHPFPM_MEDIUM_TIMEOUT/g" $TEMPLATE
   sed -i "s/PHPFPM_BIG_MAX_CHILDRENS/$PHPFPM_BIG_MAX_CHILDRENS/g" $TEMPLATE
   sed -i "s/PHPFPM_BIG_START/$PHPFPM_BIG_START/g" $TEMPLATE
   sed -i "s/PHPFPM_BIG_MIN_SPARE/$PHPFPM_BIG_MIN_SPARE/g" $TEMPLATE
   sed -i "s/PHPFPM_BIG_MAX_SPARE/$PHPFPM_BIG_MAX_SPARE/g" $TEMPLATE
   sed -i "s/PHPFPM_BIG_REQS/$PHPFPM_BIG_REQS/g" $TEMPLATE
   sed -i "s/PHPFPM_BIG_TIMEOUT/$PHPFPM_BIG_TIMEOUT/g" $TEMPLATE
   sed -i "s/PHPFPM_ONDEMAND_MAX_CHILDRENS/$PHPFPM_ONDEMAND_MAX_CHILDRENS/g" $TEMPLATE
   sed -i "s/PHPFPM_ONDEMAND_REQS/$PHPFPM_ONDEMAND_REQS/g" $TEMPLATE
   sed -i "s/PHPFPM_ONDEMAND_TIMEOUT/$PHPFPM_ONDEMAND_TIMEOUT/g" $TEMPLATE
done


echo "----- Configuramos MYSQL"
cp $CURRENT_DIR/etc/mysql/my.cnf /etc/mysql/my.cnf
sed -i "s,^key_buffer_size=.*$,key_buffer_size=$key_buffer_size," /etc/mysql/my.cnf
sed -i "s,^max_allowed_packet=.*$,max_allowed_packet=$max_allowed_packet," /etc/mysql/my.cnf
sed -i "s,^table_open_cache=.*$,table_open_cache=$table_open_cache," /etc/mysql/my.cnf
sed -i "s,^sort_buffer_size=.*$,sort_buffer_size=$sort_buffer_size," /etc/mysql/my.cnf
sed -i "s,^read_buffer_size=.*$,read_buffer_size=$read_buffer_size," /etc/mysql/my.cnf
sed -i "s,^read_rnd_buffer_size=.*$,read_rnd_buffer_size=$read_rnd_buffer_size," /etc/mysql/my.cnf
sed -i "s,^myisam_sort_buffer_size=.*$,myisam_sort_buffer_size=$myisam_sort_buffer_size," /etc/mysql/my.cnf
sed -i "s,^join_buffer_size=.*$,join_buffer_size=$join_buffer_size," /etc/mysql/my.cnf
sed -i "s,^thread_cache_size=.*$,thread_cache_size=$thread_cache_size," /etc/mysql/my.cnf
sed -i "s,^query_cache_size=.*$,query_cache_size=$query_cache_size," /etc/mysql/my.cnf
sed -i "s,^thread_concurrency=.*$,thread_concurrency=$thread_concurrency," /etc/mysql/my.cnf
sed -i "s,^max_heap_table_size=.*$,max_heap_table_size=$max_heap_table_size," /etc/mysql/my.cnf
sed -i "s,^tmp_table_size=.*$,tmp_table_size=$tmp_table_size," /etc/mysql/my.cnf
sed -i "s,^innodb_buffer_pool_size=.*$,innodb_buffer_pool_size=$innodb_buffer_pool_size," /etc/mysql/my.cnf
sed -i "s,^innodb_buffer_pool_instances=.*$,innodb_buffer_pool_instances=$innodb_buffer_pool_instances," /etc/mysql/my.cnf
sed -i "s,^innodb_log_file_size=.*$,innodb_log_file_size=$innodb_log_file_size," /etc/mysql/my.cnf
sed -i "s,^max_connections=.*$,max_connections=$max_connections," /etc/mysql/my.cnf
sed -i "s,^max_user_connections=.*$,max_user_connections=$max_user_connections," /etc/mysql/my.cnf
cp $CURRENT_DIR/etc/mysql/conf.d/mysqldump.cnf /etc/mysql/conf.d/mysqldump.cnf



if [[ $1 == 'no' ]]; then
   echo "----- Reconstruimos el usuario admin"
   v-rebuild-user admin
   echo "----- Reiniciamos servicios"
   service nginx restart
   service php5.6-fpm restart
   service php7.0-fpm restart
   service php7.1-fpm restart
   service php7.2-fpm restart
   service php7.3-fpm restart
   service php7.4-fpm restart
   service php8.0-fpm restart
   service php8.1-fpm restart
   service fail2ban restart
   service vsftpd restart
   service mysql restart
   service exim4 restart
   service dovecot restart
fi

; origin-src: deb/templates/web/php-fpm/default.tpl

[%backend%]
listen = /run/php/php%backend_version%-fpm-%domain%.sock
listen.owner = %user%
listen.group = www-data
listen.mode = 0660

user = %user%
group = %user%

pm = dynamic
pm.max_children = PHPFPM_MEDIUM_MAX_CHILDRENS
pm.start_servers = PHPFPM_MEDIUM_START
pm.min_spare_servers = PHPFPM_MEDIUM_MIN_SPARE
pm.max_spare_servers = PHPFPM_MEDIUM_MAX_SPARE
pm.max_requests = PHPFPM_MEDIUM_REQS
pm.process_idle_timeout = PHPFPM_MEDIUM_TIMEOUT
pm.status_path = /status

php_admin_value[upload_tmp_dir] = /home/%user%/tmp
php_admin_value[session.save_path] = /home/%user%/tmp
php_admin_value[open_basedir] = /home/%user%/web/%domain%/public_html:/home/%user%/web/%domain%/public_shtml:/home/%user%/tmp:/var/www/html:/etc/phpmyadmin:/var/lib/phpmyadmin:/etc/roundcube:/var/lib/roundcube:/tmp:/bin:/usr/bin:/usr/local/bin:/usr/share:/opt
php_admin_value[sendmail_path] = /usr/sbin/sendmail -t -i -f admin@%domain%

env[HOSTNAME] = $HOSTNAME
env[PATH] = /usr/local/bin:/usr/bin:/bin
env[TMP] = /home/%user%/tmp
env[TMPDIR] = /home/%user%/tmp
env[TEMP] = /home/%user%/tmp
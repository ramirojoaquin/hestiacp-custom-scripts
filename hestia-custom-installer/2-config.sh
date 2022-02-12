#!/bin/bash -l
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/../config.ini

# Validamos IPs si el dominio DNS esta seteado

if ! [[ $IP_SECONDARY =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ && $HOST_DNS_DOMAIN != '' ]]; then
   echo "Solo se puede habilitar el dominio DNS principal $HOST_DNS_DOMAIN si hay al menos 2 IPv4 en el server. Las IPs del servidor son: $HOST_IPS"
fi

################################# Configuramos Hestia por unica vez luego de instalar #################################


echo "----- Configurando Hestia"

echo "- Desactivamos el backup de hestia"
v-change-sys-config-value BACKUP_SYSTEM ''

echo "- Desactivamos actualizaciones automaticas"
v-delete-cron-hestia-autoupdate

echo "- Desactivamos el NAT en las IPs en $IP_PRIMARY y $IP_SECONDARY"
v-change-sys-ip-nat $IP_PRIMARY '' no
v-change-sys-ip-nat $IP_SECONDARY '' no

echo "- Configuramos bind como server DNS local, y configuramos resolv.conf para resolver los DNS de forma local"
cp $CURRENT_DIR/etc/bind/named.conf.options /etc/bind/named.conf.options
echo '// DNS RBLS
zone "dnswl.org" {
    type forward;
    forwarders {};
};

zone "uribl.com" {
    type forward;
    forwarders {};
};
' >> /etc/bind/named.conf.local
service bind9 restart
cp $CURRENT_DIR/etc/resolv.conf /etc/resolv.conf

echo "- Instalamos bad bot blocker para nginx"
wget https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/install-ngxblocker -O /usr/local/sbin/install-ngxblocker
chmod +x /usr/local/sbin/install-ngxblocker
/usr/local/sbin/install-ngxblocker -x
chmod +x /usr/local/sbin/setup-ngxblocker
chmod +x /usr/local/sbin/update-ngxblocker
command="/usr/local/sbin/update-ngxblocker"
job="00 22 * * * $command"
cat <(fgrep -i -v "$command" <(crontab -l)) <(echo "$job") | crontab -
sed -i "s/server_names_hash_bucket_size/#server_names_hash_bucket_size/g" /etc/nginx/conf.d/botblocker-nginx-settings.conf
sed -i "s/server_names_hash_max_size/#server_names_hash_max_size/g" /etc/nginx/conf.d/botblocker-nginx-settings.conf


echo "----- Configurando fail2ban webexploits"
cat $CURRENT_DIR/etc/fail2ban/jail.local >> /etc/fail2ban/jail.local
cp $CURRENT_DIR/etc/fail2ban/filter.d/webexploits.conf /etc/fail2ban/filter.d/webexploits.conf

echo "----- Deshabilitando puertos imap y pop3 no seguros"
v-add-firewall-rule DROP 0.0.0.0/0 110
v-add-firewall-rule DROP 0.0.0.0/0 143

echo "----- Deshabilitando FTP no seguro"
sed -i "s,^force_local_data_ssl=.*$,force_local_data_ssl=YES," /etc/vsftpd.conf
sed -i "s,^force_local_logins_ssl=.*$,force_local_logins_ssl=YES," /etc/vsftpd.conf

# Ejecutamos las customizaciones sobreescritas por hestia despues de un update
$CURRENT_DIR/3-update.sh no

# Configuramos el dominio DNS principal
if [[ $HOST_DNS_DOMAIN != '' ]]; then
   echo "----- Agregamos dominio DNS $HOST_DNS_DOMAIN"
   v-add-dns-domain admin $HOST_DNS_DOMAIN $IP_PRIMARY
   v-add-dns-record admin $HOST_DNS_DOMAIN ns1 A $IP_PRIMARY
   v-add-dns-record admin $HOST_DNS_DOMAIN ns2 A $IP_SECONDARY
   v-add-dns-record admin $HOST_DNS_DOMAIN "*" A $IP_PRIMARY
fi

echo "----- Recreamos el dominio web $HOST_DOMAIN"
v-delete-web-domain admin $HOST_DOMAIN
v-add-web-domain admin $HOST_DOMAIN
rsync -a $CURRENT_DIR/host_public_html/ /home/admin/web/$HOST_DOMAIN/public_html/
sed -i "s/PASSWORD/$HOST_ADMIN_EMAIL_PASS/g" /home/admin/web/$HOST_DOMAIN/public_html/check_mysql.php
sed -i "s/HOST_DOMAIN/$HOST_DOMAIN/g" /home/admin/web/$HOST_DOMAIN/public_html/index.html

echo "----- Agregamos base de datos default para testeos"
v-add-database admin default default $HOST_ADMIN_EMAIL_PASS

# Configuramos mails
echo "----- Configuramos emails para $HOST_EMAIL_DOMAIN"
cp $CURRENT_DIR/etc/exim4/exim4.conf.template /etc/exim4/exim4.conf.template
sed -i "s/HOST_EMAIL_DOMAIN/$HOST_EMAIL_DOMAIN/g" /etc/exim4/exim4.conf.template
touch /etc/exim4/mailhelo.conf
touch /etc/exim4/local_sender_whitelist
v-add-mail-domain admin $HOST_EMAIL_DOMAIN
v-add-mail-account admin $HOST_EMAIL_DOMAIN admin $HOST_ADMIN_EMAIL_PASS
v-add-mail-account-alias admin $HOST_EMAIL_DOMAIN admin root
v-add-mail-account admin $HOST_EMAIL_DOMAIN postmaster $HOST_ADMIN_EMAIL_PASS
v-add-mail-account-alias admin $HOST_EMAIL_DOMAIN postmaster abuse
v-add-mail-account admin $HOST_EMAIL_DOMAIN webmaster $HOST_ADMIN_EMAIL_PASS
v-add-mail-account admin $HOST_EMAIL_DOMAIN outgoing $HOST_ADMIN_EMAIL_PASS
echo "root: admin@$HOST_EMAIL_DOMAIN" >> /etc/aliasses

# Autodiscover para emails
echo "----- Configurando autodiscover para emails"
v-add-web-domain admin autodiscover.$HOST_DOMAIN $IP_PRIMARY no autoconfig.$HOST_DOMAIN
v-change-web-domain-backend-tpl admin autodiscover.$HOST_DOMAIN on-demand
rsync -a --delete $CURRENT_DIR/autodiscover/ /home/admin/web/autodiscover.$HOST_DOMAIN/public_html/
sed -i "s/HOST_DOMAIN/$HOST_DOMAIN/g" /home/admin/web/autodiscover.$HOST_DOMAIN/public_html/autodiscover.php
sed -i "s/HOST_DOMAIN/$HOST_DOMAIN/g" /home/admin/web/autodiscover.$HOST_DOMAIN/public_html/mail/config-v1.1.xml
chown -R admin:admin /home/admin/web/autodiscover.$HOST_DOMAIN/public_html/
newaliases


echo "----- Arreglamos limites de archivos abiertos"
echo "root                hard    nofile            10000000" >> /etc/security/limits.conf
echo "root                soft    nofile            10000000" >> /etc/security/limits.conf
echo "mysql               hard    nofile            10000000" >> /etc/security/limits.conf
echo "mysql               soft    nofile            10000000" >> /etc/security/limits.conf

sed -i "s,^#DefaultLimitNOFILE=.*$,DefaultLimitNOFILE=65536," /etc/systemd/system.conf
systemctl daemon-reload

echo "----- Configuramos directorios para logs de scripts personalizados"
mkdir -p /var/log/scripts/
mkdir -p /var/log/scripts/domains-status
mkdir -p /var/log/scripts/backup

echo "----- Configuramos crons en root"
command="/usr/bin/find /home/*/tmp -type f -name 'sess_*' -ctime +5 -delete"
job="0 0 * * * $command"
cat <(fgrep -i -v "$command" <(crontab -l)) <(echo "$job") | crontab -

command="/root/scripts/backup/backup-execute.sh > /var/log/scripts/backup/backup_\`date \"+\%Y-\%m-\%d\"\`.log 2>&1"
job="0 2 * * * $command"
cat <(fgrep -i -v "$command" <(crontab -l)) <(echo "$job") | crontab -

command="bash /root/scripts/mail/cron-reset-accounts.sh"
job="*/5 * * * * $command"
cat <(fgrep -i -v "$command" <(crontab -l)) <(echo "$job") | crontab -

command="bash /root/scripts/mail/clean-outgoing.sh"
job="0 1 * * * $command"
cat <(fgrep -i -v "$command" <(crontab -l)) <(echo "$job") | crontab -

command="/root/scripts/web/domains-status.sh > /var/log/scripts/domains-status/domain-status_\`date \"+\%Y-\%m-\%d_\%H-\%M-\%S\"\`.log 2>&1"
job="0 6 * * * $command"
cat <(fgrep -i -v "$command" <(crontab -l)) <(echo "$job") | crontab -

echo "----- Reconstruimos el usuario admin"
v-rebuild-user admin
echo "----- Reiniciamos servicios"
$CURRENT_DIR/../server/restart-services.sh
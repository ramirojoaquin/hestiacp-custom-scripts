#!/bin/bash -l
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CURRENT_DIR/../config.ini

# Seteamos nombre de host
echo "----- Configurando el hostname $HOST_DOMAIN"
hostnamectl set-hostname $HOST_DOMAIN
echo "127.0.0.1       $HOST_DOMAIN" >> /etc/hosts

# Seteamos el timezone
timedatectl set-timezone $HOST_TIMEZONE

# Actualizamos paquetes
echo "----- Actualizando paquetes"
apt update
apt upgrade -y

# Instalamos paquetes y herramientas necesarios
echo "----- Instalando paquetes y herramientas utiles"
apt install -y zip unzip figlet ncdu iftop aptitude borgbackup dnsutils html2text

# Configuramos mensaje de bienvenida SSH
echo "----- Configurando mensaje de bienvenida"
figlet $HOST_NAME > /etc/motd
echo "$WELCOME_MESSAGE" >> /etc/motd

################################# Instalamos hestia #################################
echo "----- Descargando Hestia installer"
wget https://raw.githubusercontent.com/hestiacp/hestiacp/release/install/hst-install.sh
echo "----- Ejecutando Hestia installer"
chmod +x hst-install.sh
./hst-install.sh -a no -o yes -l $HOST_LANGUAGE -y no -s $HOST_DOMAIN -e $HOST_ADMIN_EMAIL -p $HOST_ADMIN_PASS --force

echo "----- Salir de la sesión actual, y luego ejecutar la segunda parte del instalador"
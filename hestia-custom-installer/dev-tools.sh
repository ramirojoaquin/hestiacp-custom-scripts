# Instalamos herramientas de desarrollo
echo "----- Instalamos herramientas de desarrollo"
echo "- NODEJS"
apt-get install -y curl software-properties-common
curl -sL https://deb.nodesource.com/setup_14.x | bash -
apt-get install -y nodejs

echo "- Composer"
curl -sS https://getcomposer.org/installer -o composer-setup.php
chmod +x composer-setup.php
php composer-setup.php --install-dir=/usr/local/bin --filename=composer
rm composer-setup.php

# Drush
echo "- Drush y drush launcher"
wget -O drush.phar https://github.com/drush-ops/drush-launcher/releases/latest/download/drush.phar
chmod +x drush.phar
mv drush.phar /usr/local/bin/drush
# Fallback para drush 8
wget -O drush8 https://github.com/drush-ops/drush/releases/download/8.3.5/drush.phar
chmod +x drush8
mv drush8 /usr/local/bin/drush8
echo 'export DRUSH_LAUNCHER_FALLBACK="/usr/local/bin/drush8"' >> /etc/profile.d/00-aliases.sh

echo "- Grunt para los viejos themes de d7"
npm install -g grunt-cli

echo "- Imapsync para migrar correos"
# Instalamos imapsync
apt install -y libauthen-ntlm-perl libcgi-pm-perl libcrypt-openssl-rsa-perl libdata-uniqid-perl libencode-imaputf7-perl libfile-copy-recursive-perl libfile-tail-perl libio-socket-inet6-perl libio-socket-ssl-perl libio-tee-perl libhtml-parser-perl libjson-webtoken-perl libmail-imapclient-perl libparse-recdescent-perl libmodule-scandeps-perl libreadonly-perl libregexp-common-perl libsys-meminfo-perl libterm-readkey-perl libtest-mockobject-perl libtest-pod-perl libunicode-string-perl liburi-perl libwww-perl libtest-nowarnings-perl libtest-deep-perl libtest-warn-perl make cpanminus
wget -O /usr/bin/imapsync https://raw.githubusercontent.com/imapsync/imapsync/master/imapsync
chmod +x /usr/bin/imapsync


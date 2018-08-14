# Script para instalar a versão de produção (.tgz) e  desenvolvimeno (.zip) do GLPI
# LABEL maintainer="marcos.fr.rocha@gmail.com"
# telegram:ferreirarocha
# Uso
# bash   install-glpi.sh password  url-glpi
# Exemplo
# bash   install-glpi.sh password https://github.com/glpi-project/glpi/archive/9.2.1.zip

## Variáveis
APACHE_LOG_DIR=/var/log/apache2
downloadglpi=$2
versao=$(echo $downloadglpi | cut -d"/" -f9 )

export DEBCONF_NONINTERACTIVE_SEEN=true DEBIAN_FRONTEND=noninteractive
echo "America/Sao_Paulo" > /etc/timezone
dpkg-reconfigure tzdata

## Dependêcias PHP 
apt update ;\
apt install  -y \
php-soap \
php7.0	\
php7.0-apcu \
php7.0-cli \
php7.0-common \
php7.0-curl \
php7.0-gd \
php7.0-imap \
php7.0-ldap \
php7.0-mysql \
php7.0-snmp \
php7.0-xmlrpc \
php7.0-xml \
php7.0-mbstring \
php7.0-bcmath \
php-dev \
php-pear \
php-cas \
libapache2-mod-php7.0  

## Dependêcias para  o web server
apt install  -y \
apache2 \
mariadb-server \
libmariadbd-dev \
libmariadbd18 

## Dependẽncias para adminisração do sistema
apt install  -y \
bsdtar \
bzip2 \
curl  \
nano \
wget \
cron \
curl \
unzip \
tzdata 

## Limpando o sistema após a instalação
apt-get clean ;
rm -rf /var/lib/apt/lists/* /tmp/*

## Baixando o GLPI
wget -c  $downloadglpi
	
if [ ${downloadglpi: -4} == ".tgz" ]; then  

	tar -xzf $versao -C  /var/www/html/ ; 
	dir=/var/www/html/glpi
	echo 	"<meta http-equiv="refresh" content="0; url="glpi />" >>  /var/www/html/index.html

	else
	versao=$(echo $downloadglpi | cut -d"/" -f7 )
	head -3  log | cut -d":" -f2 | tail -1
	unzip $versao -d  /var/www/html/ | tee log ; 
	dir=$(head -3  log | cut -d":" -f2 | tail -1)
	versaodir=$(head -3  log | cut -d":" -f2 | tail -1 | cut -d"/" -f2)
	
	mv /var/www/html/$versaodir /var/www/html/glpi

	su $USER composer install --no-dev  $dir/.

fi
 
echo '<meta http-equiv="refresh" content="0; url=glpi " /> ' >>  /var/www/html/index.html

wget https://forge.glpi-project.org/attachments/download/2216/GLPI-dashboard_plugin-0.9.0_GLPI-9.2.x.tar.gz 
tar xfz GLPI-dashboard_plugin-0.9.0_GLPI-9.2.x.tar.gz -C  $dir/plugins/ 	

chmod 775 -Rf  $dir
chown www-data. -Rf  $dir  
rm -rf $versao GLPI-dashboard_plugin-0.9.0_GLPI-9.2.x.tar.gz

chown www-data:www-data -R  $dir
chmod 775 -R  $dir
echo -e "<Directory \"$dir\">\n\tAllowOverride All\n</Directory>" > /etc/apache2/conf-available/glpi.conf

echo -e "<VirtualHost *:80>\t
ServerAdmin admin@glpi\n\tServerName glpi\n\tServerAlias glpi\n\tDocumentRoot  $dir\n\tErrorLog $APACHE_LOG_DIR/error.log \n\tCustomLog $APACHE_LOG_DIR/access.log combined\n\n</VirtualHost>" > /etc/apache2/sites-available/glpi.conf

a2enconf glpi.conf \
&& a2enconf glpi2.conf \
&& echo "*/5 * * * * /usr/bin/php  $dir/front/cron.php &>/dev/null"  > /var/spool/cron/crontabs/root \
&& echo ' \n#!/bin/bash \n/etc/init.d/apache2 start \n/bin/bash' > /usr/bin/glpi \
&& chmod +x /usr/bin/glpi

a2enconf glpi.conf
a2enconf glpi
a2ensite glpi.conf
update-rc.d apache2 defaults
update-rc.d mysql   defaults
systemctl  restart apache2 || /etc/init.d/apache2 restart
/etc/init.d/mysql start

cd  /var/www/html/glpi

## Criando Banco de Dados GLPI
mysql -u root -e "create database glpi character set utf8";
mysql -u root -e "create user 'glpi'@'localhost' identified by '$1'";
mysql -u root -e "grant all on glpi.* to 'glpi'@'localhost'  with grant option";

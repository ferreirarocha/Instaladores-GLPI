#!/bin/bash
# Script para instalar a versão de produção (.tgz) e  desenvolvimeno (.zip) do GLPI
# LABEL maintainer="marcos.fr.rocha@gmail.com"
# telegram:ferreirarocha
# teste de  commit
# 3fd
# RR
while getopts ":a:b:d:l:p:u:" opt; do
  case $opt in
    l) url="$OPTARG"
    ;;
    p) pass="$OPTARG"
    ;;
    b) base="$OPTARG"
    ;;
    u) user="$OPTARG"
    ;;
    d) dir="$OPTARG"
    ;;
    a) automatic="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

	## Variáveis
	APACHE_LOG_DIR=/var/log/apache2
	downloadglpi="$url"
	versao=$(echo $downloadglpi | cut -d"/" -f9 )
	dir=/var/www/html/$dir
	mkdir -p $dir

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

	tar -xzf $versao -C  /tmp ;
#	dir=/var/www/html/glpi
	mv /tmp/glpi/*  $dir
	echo 	"<meta http-equiv="refresh" content="0; url="glpi />" >>  /var/www/html/index.html

	else
	versao=$(echo $downloadglpi | cut -d"/" -f7 )
	head -3  log | cut -d":" -f2 | tail -1
	unzip $versao -d  /var/www/html/ | tee log ;
	dir=$(head -3  log | cut -d":" -f2 | tail -1)
	versaodir=$(head -3  log | cut -d":" -f2 | tail -1 | cut -d"/" -f2)

	mv /var/www/html/$versaodir $dir

	su $USER composer install --no-dev  $dir/.

fi

	echo '<meta http-equiv="refresh" content="0; url=glpi " /> ' >>  /var/www/html/index.html

	wget -c https://forge.glpi-project.org/attachments/download/2216/GLPI-dashboard_plugin-0.9.0_GLPI-9.2.x.tar.gz
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
	systemctl  restart mysql || /etc/init.d/mysql start


	## Criando Banco de Dados GLPI
	mysql -u root -e "create database $base character set utf8";
	mysql -u root -e "create user '$user'@'localhost' identified by '$pass'";
	mysql -u root -e "grant all on $base.* to '$user'@'localhost'  with grant option";


if [ "$automatic" = "y" ];then

	printf "\nIniciando a configuração do GLPI \n\n"

	php  $dir/scripts/cliinstall.php \
	--db=$base \
	--lang=pt_BR \
	--user=$user \
	--pass=$pass

	rm $dir/install/install.php

else
    printf "\nFaça a instalação via web \n\n"
fi

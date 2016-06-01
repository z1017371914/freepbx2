#!/bin/bash

sudo apt-get update && apt-get upgrade -y
sudo apt-get install -y build-essential linux-headers-`uname -r` openssh-server mysql-client apache2\
  bison flex php5 php5-curl php5-cli php5-mysql php-pear php5-gd curl sox mysql-server\
  libncurses5-dev libssl-dev libmysqlclient-dev mpg123 libxml2-dev libnewt-dev sqlite3\
  libsqlite3-dev pkg-config automake libtool autoconf git unixodbc-dev uuid uuid-dev\
  libasound2-dev libogg-dev libvorbis-dev libcurl4-openssl-dev libical-dev libneon27-dev libsrtp0-dev\
  libspandsp-dev libmyodbc
  
sudo cp conf/my-small.cnf /etc/mysql/my.cnf
sudo cp conf/mpm_prefork.conf /etc/apache2/mods-available/mpm_prefork.conf
  
sudo pear install Console_Getopt
cd /usr/src
sudo wget http://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/dahdi-linux-complete-current.tar.gz
sudo wget http://downloads.asterisk.org/pub/telephony/libpri/libpri-1.4-current.tar.gz
sudo wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-13-current.tar.gz
sudo wget -O jansson.tar.gz https://github.com/akheron/jansson/archive/v2.7.tar.gz
sudo wget http://www.pjsip.org/release/2.4/pjproject-2.4.tar.bz2

cd /usr/src
sudo tar -xjvf pjproject-2.4.tar.bz2
sudo rm -f pjproject-2.4.tar.bz2
cd pjproject-2.4
sudo CFLAGS='-DPJ_HAS_IPV6=1' ./configure --enable-shared --disable-sound --disable-resample --disable-video --disable-opencore-amr
sudo make dep
sudo make
sudo make install

cd /usr/src
sudo tar vxfz jansson.tar.gz
sudo rm -f jansson.tar.gz
cd jansson-*
sudo autoreconf -i
sudo ./configure
sudo make
sudo make install

sudo curl -sf -o asterisk.tar.gz -L http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-13-current.tar.gz
sudo mkdir asterisk
sudo tar -xzf /usr/src/asterisk.tar.gz -C /usr/src/asterisk --strip-components=1
sudo rm asterisk.tar.gz
cd asterisk
sudo ./configure
sudo contrib/scripts/get_mp3_source.sh
sudo make menuselect.makeopts
sudo sed -i "s/format_mp3//" menuselect.makeopts
sudo sed -i "s/BUILD_NATIVE//" menuselect.makeopts
sudo make
sudo make install
sudo make config
sudo ldconfig
sudo update-rc.d -f asterisk remove
cd ~/freepbx
sudo cp conf/asterisk.conf /etc/asterisk/asterisk.conf

cd /var/lib/asterisk/sounds
sudo wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-en-wav-current.tar.gz
sudo wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-extra-sounds-en-wav-current.tar.gz
sudo tar xvf asterisk-core-sounds-en-wav-current.tar.gz
sudo rm -f asterisk-core-sounds-en-wav-current.tar.gz
sudo tar xfz asterisk-extra-sounds-en-wav-current.tar.gz
sudo rm -f asterisk-extra-sounds-en-wav-current.tar.gz

sudo wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-en-g722-current.tar.gz
sudo wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-extra-sounds-en-g722-current.tar.gz
sudo tar xfz asterisk-extra-sounds-en-g722-current.tar.gz
sudo rm -f asterisk-extra-sounds-en-g722-current.tar.gz
sudo tar xfz asterisk-core-sounds-en-g722-current.tar.gz
sudo rm -f asterisk-core-sounds-en-g722-current.tar.gz

sudo useradd -m asterisk
sudo chown asterisk. /var/run/asterisk
sudo chown -R asterisk. /etc/asterisk
sudo chown -R asterisk. /var/{lib,log,spool}/asterisk
sudo chown -R asterisk. /usr/lib/asterisk
sudo chown -R asterisk. /var/www/
sudo chown -R asterisk. /var/www/*
#sudo rm -rf /var/www/html

sudo sed -i 's/\(^upload_max_filesize = \).*/\120M/' /etc/php5/apache2/php.ini
sudo cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf_orig
sudo sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/apache2/apache2.conf
sudo sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf
sudo service apache2 restart

sudo /etc/init.d/mysql start
sudo mysqladmin -u root create asterisk
sudo mysqladmin -u root create asteriskcdrdb
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON asterisk.* TO $ASTERISKUSER@localhost IDENTIFIED BY '';"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON asteriskcdrdb.* TO $ASTERISKUSER@localhost IDENTIFIED BY '';"
sudo mysql -u root -e "flush privileges;"

sudo cat >> /etc/odbcinst.ini << EOF
[MySQL]
Description = ODBC for MySQL
Driver = /usr/lib/x86_64-linux-gnu/odbc/libmyodbc.so
Setup = /usr/lib/x86_64-linux-gnu/odbc/libodbcmyS.so
FileUsage = 1
  
EOF

sudo cat >> /etc/odbc.ini << EOF
[MySQL-asteriskcdrdb]
Description=MySQL connection to 'asteriskcdrdb' database
driver=MySQL
server=localhost
database=asteriskcdrdb
Port=3306
Socket=/var/run/mysqld/mysqld.sock
option=3
  
EOF

cd /usr/src
sudo wget http://mirror.freepbx.org/modules/packages/freepbx/freepbx-13.0-latest.tgz
sudo tar vxfz freepbx-13.0-latest.tgz
sudo rm -f freepbx-13.0-latest.tgz
cd freepbx
sudo ./start_asterisk start
sudo ./install -n


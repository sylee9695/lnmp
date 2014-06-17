#!/bin/bash
# coding: utf-8
################################################################
# @@ScriptName: lnmp.sh
# @@Author: lsy <88919695@qq.com>
# @@Modify Date: 2014-05-30 15:49
# @@Description:
#   this script is used for install nginx or nginx+php or nginx+php+mysql.
#   this script only test on centos6/redhat6 x64.
################################################################

if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install lnmp"
    exit 1
fi

clear
cat <<EOF
##########################################################################
#                                                                        #
# this script only test on centos6/redhat6 x64.                          #
#                                                                        #
# this script is used for install nginx or nginx+php or nginx+php+mysql. #
#                                                                        #
# nginx default version is 1.6.0,you can choice the version.             #
# php version is 5.3.28                                                  #
# mysql version is 5.1.72 or 5.5.37                                      #
##########################################################################
EOF
echo ""

#变量声明
base_dir=$(pwd)
dir_src=/usr/local/src
local_ip=`ifconfig |grep -m 1 "inet addr"|cut -d: -f2|cut -d" " -f1`

#选择需要安装的软件
function lnmp_selection() {
cat <<EOF
1. install nginx
2. install nginx+php
3. install nginx+php+mysql
EOF

while true; do
  echo -n "Pls input what you want to install(1 or 2 or 3) :"
  read i
  case $i in
    1)
      nginx_install 2>&1 | tee -a $base_dir/install.log
      break
      ;;
    2)
      nginx_php_install 2>&1 | tee -a $base_dir/install.log
      break
      ;;
    3)
      lnmp_install 2>&1 | tee -a $base_dir/install.log
      break
      ;;
    *)
      echo -n "Error Selection! "
      ;;
  esac
done

}

###################################################################################################
#安装nginx必要软件
function check_nginx() {

rpm -qa|grep httpd
rpm -e httpd
yum -y remove httpd*

cp -f etc/epel.repo /etc/yum.repos.d/epel.repo
cp -f etc/epel-testing.repo /etc/yum.repos.d/epel-testing.repo


if [ -s /etc/selinux/config ]; then
  sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
fi

yum -y install gcc gcc-c++ autoconf automake make zlib zlib-devel openssl openssl-devel pcre pcre-devel wget

iptables -A INPUT -p tcp --dport 80 -j ACCEPT

}

###################################################################################################
#安装php必要软件
function check_php() {

rpm -qa|grep php
rpm -e php

yum -y remove php*
yum -y remove php-mysql

yum -y install make apr autoconf automake curl curl-devel gcc gcc-c++ zlib zlib-devel openssl openssl-devel pcre pcre-devel gd perl mpfr cpp glibc glibc-devel glib2 glib2-devel libgomp libstdc++-devel ppl cloog-ppl keyutils-libs-devel libcom_err-devel libsepol-devel libselinux-devel krb5-devel libXpm libXpm-devel freetype freetype-devel fontconfig fontconfig-devel libjpeg libjpeg-devel libpng libpng-devel ncurses ncurses-devel libtool libxml2 libxml2-devel

}

###################################################################################################
#安装mysql必要软件
function check_mysql() {
rpm -qa|grep mysql
rpm -e mysql

yum -y remove mysql-server mysql
yum -y install bison gcc gcc-c++ cmake ncurses-devel
}

###################################################################################################
#nginx安装函数
function nginx_install() {

echo "============================Install Nginx=================================="
echo "###############################################################"
echo "nginx will be installed to /usr/local/nginx"
echo "###############################################################"

ng_dir="/usr/local/nginx"


#选择nginx版本
read -t 10 -p "Pls type which version you want to install(default version 1.6.0 eg: 1.6.0) :" ng_ver
ng_ver=${ng_ver:="1.6.0"}
check_nginx 2>&1 | tee -a $base_dir/install.log
wget http://nginx.org/download/nginx-$ng_ver.tar.gz -P $dir_src

#case $ng_ver in
#  "")
#    ng_ver=1.6.0
#    wget http://nginx.org/download/nginx-1.6.0.tar.gz -P $dir_src
#    ;;
#  1.4.*)
#    wget http://nginx.org/download/nginx-$ng_ver.tar.gz -P $dir_src
#    ;;
#  1.3.*)
#    wget http://nginx.org/download/nginx-$ng_ver.tar.gz -P $dir_src
#    ;;
#  *)
#    echo "type version error! Will install 1.6.0 version."
#    ng_ver=1.6.0
#    wget http://nginx.org/download/nginx-1.6.0.tar.gz -P $dir_src
#    ;;
#esac


#选择nginx安装路径
#while true;do
#  read -p "Pls type nignx installed dir(default /usr/local/nginx) :" ng_dir
#  if [[ -f $ng_dir ]];then
#    echo "$ng_dir is file,please input again!"
#  elif [[ $ng_dir = "" ]]; then
#    ng_dir=/usr/local/nginx
#    break
#  fi
#done


#nginx编译安装

cd $dir_src
if [[ -a $dir_src/nginx-$ng_ver.tar.gz ]];then
  tar zxvf $dir_src/nginx-$ng_ver.tar.gz
else
  echo "nginx src file is not exist!"
  exit 1
fi

id www &>/dev/null || useradd -M -s /sbin/nologin www
cd $dir_src/nginx-$ng_ver
./configure --user=www --group=www --prefix=$ng_dir --with-http_stub_status_module --with-http_ssl_module --with-http_gzip_static_module
make && make install

#判断nginx是否安装成功
if [ -s $ng_dir -a -s $ng_dir/sbin/nginx ]; then
  info_nginx="ok"
else
  echo "Error: /usr/local/nginx not found! nginx install failed!"
  exit 1
fi

#修改配置文件
cd $base_dir
ng_conf="$ng_dir/conf/nginx.conf"

#mv "$ng_conf" $(ng_conf)bak
cp etc/nginx.conf $ng_conf
echo "fastcgi_param  PHP_VALUE  \"open_basedir=\$document_root:/tmp/\";" >> $ng_dir/conf/fastcgi.conf
mkdir $ng_dir/conf/vhost > /dev/null 2>&1
cp etc/vhost.conf $ng_dir/conf/vhost/vhost.conf
cp etc/nginx /etc/init.d/nginx && chmod 755 /etc/init.d/nginx

mkdir /home/{wwwroot,wwwlogs} >/dev/null 2>&1
echo "Welcome to lnmp!!" > /home/wwwroot/index.htm
chown -R www:www /home/wwwlogs

/etc/init.d/nginx start
chkconfig nginx on

#nginx安装信息
echo "################## Nginx Install successfull ####################"
echo "nginx dir:  $ng_dir"
echo "virtual host dir:  /usr/local/nginx/conf/vhost"
echo "web dir:  /home/wwwroot"
echo "weblog dir:  /home/wwwlogs"
echo 'usage:  service nginx {start|stop|reload|restart|status}'
echo "you can open url:  http://$local_ip"
echo "#################################################################"

}

###################################################################################################
#nginx+php安装函数
function nginx_php_install() {

nginx_install 2>&1 | tee -a $base_dir/install.log
echo "============================Install php-5.3.28=================================="
echo "###############################################################"
echo "php will be installed to /usr/local/php"
echo "###############################################################"

check_php 2>&1 | tee -a $base_dir/install.log

#php下载
cd $dir_src
if [[ -s "libmcrypt-2.5.8.tar.gz" ]]; then
  echo "libmcrypt-2.5.8.tar.gz found"
  else
  wget http://nchc.dl.sourceforge.net/project/mcrypt/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz -P $dir_src
fi
tar zxvf libmcrypt-2.5.8.tar.gz
cd libmcrypt-2.5.8
./configure
make && make install

cd $dir_src
if [[ -s "php-5.3.28.tar.gz" ]]; then
  echo "php-5.3.28.tar.gz found"
else
  wget http://hk2.php.net/distributions/php-5.3.28.tar.gz -P $dir_src
fi

#php编译安装
if [[ -a  "php-5.3.28.tar.gz" ]]; then
  tar zxvf php-5.3.28.tar.gz
else
  echo "php src file is not exist! download again..."
  wget http://hk2.php.net/distributions/php-5.3.28.tar.gz -P $dir_src
fi

cd php-5.3.28
./configure --prefix=/usr/local/php \
--with-config-file-path=/usr/local/php/etc \
--enable-fpm --with-fpm-user=www --with-fpm-group=www \
--with-mysql=mysqlnd --with-mysqli=mysqlnd \
--with-pdo-mysql=mysqlnd --with-iconv-dir \
--with-freetype-dir --with-jpeg-dir \
--with-png-dir --with-zlib --with-libxml-dir \
--enable-xml --disable-rpath --enable-magic-quotes \
--enable-safe-mode --enable-bcmath --enable-shmop \
--enable-sysvsem --enable-inline-optimization \
--with-curl --with-curlwrappers --enable-mbregex \
--enable-mbstring --with-mcrypt --enable-ftp \
--with-gd --enable-gd-native-ttf --with-openssl \
--with-mhash --enable-pcntl --enable-sockets \
--with-xmlrpc --enable-zip --enable-soap \
--without-pear --with-gettext --disable-fileinfo
make -j 2 && make install

if [ -s /usr/local/php/sbin/php-fpm -a -s /usr/local/php/bin/php ]; then
  info_php="ok"
else
  echo "Error: /usr/local/php not found! PHP install failed."
  exit 1
fi


echo "Copy new php configure file."
rm -f /etc/php.ini
cp -f php.ini-production /usr/local/php/etc/php.ini
ln -s /usr/local/php/etc/php.ini /etc/php.ini

#修改php.ini文件
echo "Modify php.ini......"
sed -i 's/post_max_size = 8M/post_max_size = 200M/g' /usr/local/php/etc/php.ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 200M/g' /usr/local/php/etc/php.ini
sed -i 's/;date.timezone =/date.timezone = PRC/g' /usr/local/php/etc/php.ini
sed -i 's/short_open_tag = Off/short_open_tag = On/g' /usr/local/php/etc/php.ini
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /usr/local/php/etc/php.ini
sed -i 's/max_execution_time = 30/max_execution_time = 180/g' /usr/local/php/etc/php.ini
sed -i 's/register_long_arrays = On/;register_long_arrays = On/g' /usr/local/php/etc/php.ini
sed -i 's/display_errors = On/display_errors = Off/g' /usr/local/php/etc/php.ini
sed -i 's/expose_php = On/expose_php = Off/g' /usr/local/php/etc/php.ini
sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,scandir,chgrp,chown,shell_exec,proc_open,proc_get_status,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server/g' /usr/local/php/etc/php.ini

#安装ZendGuardLoader
echo "Install ZendGuardLoader for PHP 5.3.*"
cd $dir_src
if [ `getconf WORD_BIT` = '32' ] && [ `getconf LONG_BIT` = '64' ] ; then
  wget -c http://downloads.zend.com/guard/5.5.0/ZendGuardLoader-php-5.3-linux-glibc23-x86_64.tar.gz
  tar zxvf ZendGuardLoader-php-5.3-linux-glibc23-x86_64.tar.gz
  mkdir -p /usr/local/zend/
  cp ZendGuardLoader-php-5.3-linux-glibc23-x86_64/php-5.3.x/ZendGuardLoader.so /usr/local/zend/
else
  wget -c http://downloads.zend.com/guard/5.5.0/ZendGuardLoader-php-5.3-linux-glibc23-i386.tar.gz
  tar zxvf ZendGuardLoader-php-5.3-linux-glibc23-i386.tar.gz
  mkdir -p /usr/local/zend/
  cp ZendGuardLoader-php-5.3-linux-glibc23-i386/php-5.3.x/ZendGuardLoader.so /usr/local/zend/
fi

cat >>/usr/local/php/etc/php.ini<<EOF

[Zend Optimizer]
zend_extension=/usr/local/zend/ZendGuardLoader.so
EOF

#修改php-fpm配置文件
echo "Creating new php-fpm configure file......"
cat >/usr/local/php/etc/php-fpm.conf<<EOF
[global]
pid = /usr/local/php/var/run/php-fpm.pid
error_log = /usr/local/php/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi.sock
user = www
group = www
pm = dynamic
pm.max_children = 20
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
pm.max_requests = 500
request_terminate_timeout = 120
EOF


echo "Add php-fpm init.d file......"
cp $dir_src/php-5.3.28/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm && chmod 755 /etc/init.d/php-fpm
/etc/init.d/php-fpm start
chkconfig php-fpm on
cat >/home/wwwroot/info.php <<EOF
<?php
phpinfo();
?>
EOF

#php安装信息
echo "################## Nginx+php Install successfull ####################"
echo "nginx dir:  /usr/local/nginx"
echo "php dir: /usr/local/php"
echo "virtual host dir:  /usr/local/nginx/conf/vhost"
echo "web dir:  /home/wwwroot"
echo "weblog dir:  /home/wwwlogs"
echo 'usage:  service nginx {start|stop|reload|restart|status}'
echo '         service phh-fpm {start|stop|reload|restart|status}'
echo "phpinfo:  http://$local_ip/info.php"
echo "#################################################################"
}

###################################################################################################
#lnmp安装函数
function lnmp_install() {
#set mysql root passwd
echo "#################################################"
read -p "please input mysql root password(default password: root): " mysqlpwd
mysqlpwd=${mysqlpwd:=root}
echo "Your mysql root password is: $mysqlpwd"

echo "#################################################"
cat <<EOF
1. install mysql5.1.72
2. install mysql5.5.37

EOF

while true; do
  echo -n "Pls input which mysql version you want to install(1 or 2) :"
  read mysqlver
  case $mysqlver in
    1)
      mysql51_install 2>&1 | tee -a $base_dir/install.log
      break
      ;;
    2)
      mysql55_install 2>&1 | tee -a $base_dir/install.log
      break
      ;;
    *)
      echo -n "Error Selection! "
      ;;
  esac
done

}

function mysql51_install() {

nginx_php_install 2>&1 | tee -a $base_dir/install.log
check_mysql 2>&1 | tee -a $base_dir/install.log

wget http://cdn.mysql.com/archives/mysql-5.1/mysql-5.1.72.tar.gz -P $dir_src
cd $dir_src
if [[ -s "mysql-5.1.72.tar.gz" ]]; then
  echo "mysql-5.1.72.tar.gz found"
else
  wget http://cdn.mysql.com/archives/mysql-5.1/mysql-5.1.72.tar.gz -P $dir_src
fi
rm -f /etc/my.cnf
useradd -s /sbin/nologin -M mysql

tar zxvf mysql-5.1.72.tar.gz
cd mysql-5.1.72/
./configure --prefix=/usr/local/mysql \
--with-charset=utf8 \
--with-collation=utf8_general_ci \
--with-extra-charsets=complex \
--enable-thread-safe-client \
--enable-assembler \
--with-mysqld-ldflags=-all-static \
--enable-thread-safe-client \
--with-big-tables \
--with-readline \
--with-ssl \
--with-embedded-server \
--enable-local-infile \
--with-plugins=innobase \
--with-plugins=partition
make -j 2 && make install

#判断mysql是否安装成功
if [ -s /usr/local/mysql -a -s /usr/local/mysql/bin/mysql ]; then
  info_mysql="ok"
else
  echo "Error: /usr/local/mysql not found! mysql install failed!"
  exit 1
fi

cp /usr/local/mysql/share/mysql/my-medium.cnf /etc/my.cnf
sed -i 's/skip-locking/skip-external-locking/g' /etc/my.cnf
cp /usr/local/mysql/share/mysql/mysql.server /etc/init.d/mysql
chmod 755 /etc/init.d/mysql
chkconfig mysql on
/usr/local/mysql/bin/mysql_install_db --user=mysql
chown -R mysql /usr/local/mysql/var
chgrp -R mysql /usr/local/mysql/

cat > /etc/ld.so.conf.d/mysql.conf<<EOF
/usr/local/mysql/lib/mysql
/usr/local/lib
EOF
ldconfig

ln -s /usr/local/mysql/lib/mysql /usr/lib/mysql
ln -s /usr/local/mysql/include/mysql /usr/include/mysql
ln -s /usr/local/mysql/bin/mysql /usr/bin/mysql
ln -s /usr/local/mysql/bin/mysqldump /usr/bin/mysqldump
ln -s /usr/local/mysql/bin/myisamchk /usr/bin/myisamchk
ln -s /usr/local/mysql/bin/mysqld_safe /usr/bin/mysqld_safe

/etc/init.d/mysql start
/usr/local/mysql/bin/mysqladmin -u root password $mysqlpwd

#删除多余用户
cat > /tmp/mysql_sec_script<<EOF
use mysql;
delete from user where not (user='root') ;
delete from user where user='root' and password='';
drop database test;
DROP USER ''@'%';
flush privileges;
EOF

/usr/local/mysql/bin/mysql -u root -p$mysqlpwd -h localhost < /tmp/mysql_sec_script
rm -f /tmp/mysql_sec_script

/etc/init.d/mysql restart

#lnmp安装信息
echo "################## lnmp Install successfull #####################"
echo "nginx dir:  /usr/local/nginx"
echo "php dir: /usr/local/php"
echo "mysql dir: /usr/local/mysql"
echo "mysql datadir: /usr/local/mysql/var"
echo "virtual host dir:  /usr/local/nginx/conf/vhost"
echo "web dir:  /home/wwwroot"
echo "weblog dir:  /home/wwwlogs"
echo 'usage:  service nginx {start|stop|reload|restart|status}'
echo '         service phh-fpm {start|stop|reload|restart|status}'
echo '         service mysql {start|stop|reload|restart|status}'
echo "phpinfo:  http://$local_ip/info.php"
echo "#################################################################"

}

function mysql55_install() {

nginx_php_install 2>&1 | tee -a $base_dir/install.log
check_mysql 2>&1 | tee -a $base_dir/install.log

wget http://cdn.mysql.com/Downloads/MySQL-5.5/mysql-5.5.37.tar.gz -P $dir_src
cd $dir_src
if [[ -s "mysql-5.5.37.tar.gz" ]]; then
  echo "mysql-5.5.37.tar.gz found"
else
  wget http://cdn.mysql.com/Downloads/MySQL-5.5/mysql-5.5.37.tar.gz -P $dir_src
fi
rm -f /etc/my.cnf
useradd -s /sbin/nologin -M mysql

tar zxvf mysql-5.5.37.tar.gz
cd mysql-5.5.37
cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
-DMYSQL_USER=mysql \
-DEXTRA_CHARSETS=all \
-DDEFAULT_CHARSET=utf8 \
-DDEFAULT_COLLATION=utf8_general_ci \
-DWITH_READLINE=1 \
-DWITH_SSL=system \
-DWITH_ZLIB=system \
-DWITH_EMBEDDED_SERVER=1 \
-DENABLED_LOCAL_INFILE=1
make -j 2 && make install

#判断mysql是否安装成功
if [ -s /usr/local/mysql -a -s /usr/local/mysql/bin/mysql ]; then
  info_mysql="ok"
else
  echo "Error: /usr/local/mysql not found! mysql install failed!"
  exit 1
fi

chown -R mysql.mysql /usr/local/mysql/
cp support-files/my-medium.cnf /etc/my.cnf
sed '/skip-external-locking/i\datadir = /usr/local/mysql/var' -i /etc/my.cnf
sed '/skip-external-locking/i\default-storage-engine=MyISAM\nloose-skip-innodb' -i /etc/my.cnf

/usr/local/mysql/scripts/mysql_install_db --defaults-file=/etc/my.cnf --basedir=/usr/local/mysql --datadir=/usr/local/mysql/var --user=mysql

cp support-files/mysql.server /etc/init.d/mysql
chmod 755 /etc/init.d/mysql
chkconfig mysql on

cat > /etc/ld.so.conf.d/mysql.conf<<EOF
/usr/local/mysql/lib
/usr/local/lib
EOF
ldconfig

ln -s /usr/local/mysql/lib/mysql /usr/lib/mysql
ln -s /usr/local/mysql/include/mysql /usr/include/mysql
ln -s /usr/local/mysql/bin/mysql /usr/bin/mysql
ln -s /usr/local/mysql/bin/mysqldump /usr/bin/mysqldump
ln -s /usr/local/mysql/bin/myisamchk /usr/bin/myisamchk
ln -s /usr/local/mysql/bin/mysqld_safe /usr/bin/mysqld_safe

/etc/init.d/mysql start
/usr/local/mysql/bin/mysqladmin -u root password $mysqlpwd

#删除多余用户
cat > /tmp/mysql_sec_script<<EOF
use mysql;
delete from user where not (user='root') ;
delete from user where user='root' and password='';
drop database test;
DROP USER ''@'%';
flush privileges;
EOF

/usr/local/mysql/bin/mysql -u root -p$mysqlpwd -h localhost < /tmp/mysql_sec_script
rm -f /tmp/mysql_sec_script

/etc/init.d/mysql restart

#lnmp安装信息
echo "################## lnmp Install successfull #####################"
echo "nginx dir:  /usr/local/nginx"
echo "php dir: /usr/local/php"
echo "mysql dir: /usr/local/mysql"
echo "mysql datadir: /usr/local/mysql/var"
echo "virtual host dir:  /usr/local/nginx/conf/vhost"
echo "web dir:  /home/wwwroot"
echo "weblog dir:  /home/wwwlogs"
echo 'usage:  service nginx {start|stop|reload|restart|status}'
echo '         service phh-fpm {start|stop|reload|restart|status}'
echo '         service mysql {start|stop|reload|restart|status}'
echo "phpinfo:  http://$local_ip/info.php"
echo "#################################################################"

}

lnmp_selection 2>&1 | tee -a $base_dir/install.log
















lnmp scripts only test on centos6/redhat6 x64.
you can choose what you want to install,like that:

1. install nginx
2. install nginx+php
3. install nginx+php+mysql

nginx default version is 1.6.0,you could change the version.
php version is 5.3.28
mysql verison is 5.1.72 or 5.5.37,you could choose the version.

usage:
you should download lnmp.sh and etc dir into the same directory.

run lnmp.sh

#################################################
nginx dir:  /usr/local/nginx
php dir: /usr/local/php
mysql dir: /usr/local/mysql
mysql datadir: /usr/local/mysql/var
virtual host dir:  /usr/local/nginx/conf/vhost
web dir:  /home/wwwroot
weblog dir:  /home/wwwlogs

service nginx {start|stop|reload|restart|status}
service phh-fpm {start|stop|reload|restart|status}
service mysql {start|stop|reload|restart|status}

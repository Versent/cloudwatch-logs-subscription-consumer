#!/bin/bash -ex

if [ $1 = "" ]; then 
  echo 'please provide as parameter nginx version to download source and compile, eg 1.9.9'
  exit 1
fi
ver=$1
wget http://nginx.org/download/nginx-$ver.tar.gz
tar -xzf nginx-$ver.tar.gz
wget https://github.com/kvspb/nginx-auth-ldap/archive/master.zip
unzip master.zip
yum groupinstall 'Development Tools'
yum install openssl-devel pcre-devel openldap-devel
cd nginx-$ver
./configure --user=nginx --group=nginx --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --with-http_gzip_static_module --with-http_stub_status_module --with-http_ssl_module --with-pcre --with-file-aio --with-http_realip_module --add-module=../nginx-auth-ldap-master/ --with-ipv6 --with-debug
make && make install
service nginx restart

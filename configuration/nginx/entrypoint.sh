#!/bin/bash -ex

set -exu -o pipefail

CONFIG=/etc/nginx/nginx.conf

if [ "$NGINX_LDAP" = "1" ]; then
    if [ "${1:-}" = "" ]; then
      echo 'please provide as parameter nginx version to download source and compile, eg 1.9.9'
      exit 1
    fi

    cd "$(dirname "$0")"

    ver=$1
    until wget "http://nginx.org/download/nginx-$ver.tar.gz"; do sleep 5; done
    tar -xzf "nginx-$ver.tar.gz" --overwrite
    until wget "https://github.com/kvspb/nginx-auth-ldap/archive/master.zip"; do sleep 5; done
    unzip -o master.zip
    until yum groupinstall -y 'Development Tools'; do sleep 5; done
    until yum install -y openssl-devel pcre-devel openldap-devel; do sleep 5; done
    cd "nginx-$ver"
    ./configure \
        --user=nginx \
        --group=nginx \
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --with-http_gzip_static_module \
        --with-http_stub_status_module \
        --with-http_ssl_module \
        --with-pcre \
        --with-file-aio \
        --with-http_realip_module \
        --add-module=../nginx-auth-ldap-master/ \
        --with-ipv6 \
        --with-debug
    make && make install
    useradd nginx

    cd ..
    cp -f nginx.conf.ldap "$CONFIG"
    sed -i "s/__LDAPSRV__/$LDAPServer/" "$CONFIG"
    sed -i "s/__LDAPUSERDN__/$LDAPUsersDN/" "$CONFIG"
    sed -i "s/__LDAPBASEDN__/$LDAPBaseDN/" "$CONFIG"
    sed -i "s/__LDAPGROUP__/$LDAPGroup/" "$CONFIG"
    sed -i "s/__LDAPBINDDN__/$LDAPBindUser/" "$CONFIG"
    sed -i "s/__LDAPBINDPWD__/$LDAPBindPass/" "$CONFIG"

    cp -f nginx.service /etc/systemd/system/

else

    until yum install -y nginx; do sleep 5; done
    cp -f nginx.conf "$CONFIG"
fi

sed -i "s/__DNSDomain__/$DNSDomain/" "$CONFIG"
sed -i "s/__S3bucketSource__/$S3bucketSource/" "$CONFIG"
systemctl daemon-reload

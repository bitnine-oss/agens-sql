#!/bin/bash
# This is a script file to build agens-sql project which has a installer.

Agens_sql_version="Agens-SQL-1.0.0"
begin=$(date +%s)


# check root privileges
if [ $(id -u) != "0" ]; then
        echo "This script requires root privileges."
        exit 1
fi

# postgres 설치
yum update -y && yum upgrade -y
yum groupinstall -y "Development Tools"
yum install -y gcc zlib-devel.* readline-devel.*
yum install -y openjade.* docbook-style-dsssl.noarch

# --with-perl
yum install -y perl-YAML* perl-ExtUtils*
# --with-gssapi
yum install -y krb5-*
# --with-openssl
yum install -y openssl-devel.*
# --with-libxslt
yum install libxslt-devel.*
# --with-ldap
yum install openldap-devel.*
# --with-tcl
yum install tcl-devel.*



cd postgresql-9.4.1/
./configure --with-pgport=5456 --with-gssapi --with-ldap --with-tcl --with-openssl --enable-nls --enable-debug --enable-cassert --with-perl --with-python --with-libxml --with-libxslt;
make world; make install-world;
cd ..



# pgpool 설치
cd pgpool-II-3.4.1/
./configure --prefix=/usr/local/pgpool --with-pgsql=/usr/local/pgsql/
make; make install;
cd ..

# postgis 설치
yum install -y libtiff-devel.* json-c-devel.* libxml2-devel.* python-devel.*

cd geos-3.4.2/
./configure; make; make install;
cd ..

cd proj-4.9.1/
./configure; make; make install;
cd ..

cd gdal-1.11.2/
./configure; make; make install;
cd ..


cd postgis-2.1.6/
./configure --with-pgconfig=/usr/local/pgsql/bin/pg_config --with-geosconfig=/usr/local/bin/geos-config --with-gdalconfig=/usr/local/bin/gdal-config && make && make install
cp /usr/local/lib/libgeos_c.so.1.8.2 ./postgis/
cp /usr/local/lib/libproj.so.9.0.0 ./postgis/
cp /usr/local/lib/libgdal.so.1.18.2 ./postgis/
cp /usr/local/lib/libgeos-3.4.2.so ./postgis/
cd ..




# libevent(for pgbouncer)
cd libevent-2.0.22-stable/
./configure --prefix=/usr/local/libevent
make
make install
cd ..


# pgbouncer
git clone git://git.postgresql.org/git/pgbouncer.git
cd pgbouncer
git submodule init
git submodule update
./autogen.sh
LIBS=-lpthread ./configure --prefix=/usr/local/pgbouncer --with-libevent=/usr/local/libevent
make
make install
cd ..


# skytools
yum install -y python-devel.*
cd skytools-3.2
./configure --prefix=/usr/local/skytools --with-pgconfig=/usr/local/pgsql/bin/pg_config
make
make install
cd ..

# pg_plan_hint
cd pg_hint_plan94-1.1.3
make PG_CONFIG=/usr/local/pgsql/bin/pg_config # pg_config의 경로를 정해준다.
make install PG_CONFIG=/usr/local/pgsql/bin/pg_config
cd ..


# plproxy
git clone git://git.postgresql.org/git/plproxy.git
cd plproxy
make PG_CONFIG=/usr/local/pgsql/bin/pg_config
make install PG_CONFIG=/usr/local/pgsql/bin/pg_config
cd ..


# slony
cd slony1-2.2.4/
./configure --prefix=/usr/local/slony --with-pgconfigdir=/usr/local/pgsql/bin
make; make install;
cd ..


# postgres 재설치(인스톨러에서 postgres와 postgis를 구분 짓기 위함)
cd postgresql-9.4.1/
make clean; make distclean;
rm -rf /usr/local/pgsql
./configure; make world; make install-world;
cd ..


# initialize : useradd + mkdir + shown + initdb
username="postgres"
password=""
egrep "^$username" /etc/passwd >/dev/null
if [ $? -eq 0 ]; then
        echo "$username exists!"
else
        pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
        useradd -m -p $pass $username
        [ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
fi
mkdir /usr/local/pgsql/data
chown postgres /usr/local/pgsql/data
su - postgres -c "/usr/local/pgsql/bin/initdb -D /usr/local/pgsql/data"


# izpack을 구동하기 위해 필요한 java 설치
yum install -y java-1.7.0-openjdk-devel.* 
# izpack 실행
./izpack/bin/compile res/installer/install.xml -b ./ -o distributions/"$Agens_sql_version".jar -k standard




termin=$(date +"%s")
difftimelps=$(($termin-$begin))
echo "Total time : $(($difftimelps / 60)) minute $(($difftimelps % 60)) seconds"
echo "Finished at : "; date;

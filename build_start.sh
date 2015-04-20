#!/bin/bash
# This is a script file to build agens-sql project which has a installer.


begin=$(date +%s)


# check root privileges
if [ $(id -u) != "0" ]; then
        echo "This script requires root privileges."
        exit 1
fi

rm -r /usr/local/pgsql
rm -r /usr/local/pgpool

# postgres 설치
apt-get update && apt-get upgrade -y
apt-get install -y build-essential gcc libreadline-dev zlib1g-dev bison flex

cd postgresql-9.4.1/
./configure; make world; make install;
cd contrib
make
make install
cd ../..



# pgpool 설치
apt-get install -y libpq-dev 
cd pgpool-II-3.4.1/
./configure --prefix=/usr/local/pgpool; make; make install;
cd ..

# postgis 설치
apt-get install -y libtiff5-dev python libjson-c-dev libxml2-dev
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
./configure --with-pgconfig=/usr/local/pgsql/bin/pg_config; make; make install;
cd ..


# libevent(for pgbouncer)
apt-get install -y automake git autoconf libtool autoconf-archive asciidoc xmlto pkg-config
wget https://sourceforge.net/projects/levent/files/libevent/libevent-2.0/libevent-2.0.22-stable.tar.gz
tar xvf libevent-2.0.22-stable.tar.gz
cd libevent-2.0.22-stable/
./configure --prefix=/usr/local/libevent
make
make install
cd ..
rm -f libevent-2.0.22-stable.tar.gz*

# pgbouncer
git clone --branch pgbouncer_1_5_4 git://git.postgresql.org/git/pgbouncer.git
cd pgbouncer
git submodule init
git submodule update
./autogen.sh
./configure --prefix=/usr/local/pgbouncer --with-libevent=/usr/local/libevent
make
make install
cd ..

# skytools
apt-get install -y libpq-dev python python-dev autoconf asciidoc xmlto rsync
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



# orafce
git clone https://github.com/orafce/orafce.git
cd orafce
make PG_CONFIG=/usr/local/pgsql/bin/pg_config
make install PG_CONFIG=/usr/local/pgsql/bin/pg_config
cd ..

# plproxy
git clone git://git.postgresql.org/git/plproxy.git
cd plproxy
make PG_CONFIG=/usr/local/pgsql/bin/pg_config
make install PG_CONFIG=/usr/local/pgsql/bin/pg_config
cd ..


# postgres 재설치(인스톨러에서 postgres와 postgis를 구분 짓기 위함)
cd postgresql-9.4.1/
make clean; make distclean;
cd contrib
make clean; make distclean;
cd ..
rm -r /usr/local/pgsql
./configure; make world; make install;
cd contrib
make; make install;
cd ../..


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
apt-get install -y openjdk-7-jdk
# izpack 실행
./izpack/bin/compile res/installer/install.xml -b ./ -o distributions/Agens-SQL-1.0.0.jar -k standard




termin=$(date +"%s")
difftimelps=$(($termin-$begin))
echo "Total time : $(($difftimelps / 60)) minute $(($difftimelps % 60)) seconds"
echo "Finished at : "; date;


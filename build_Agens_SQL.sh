#!/bin/bash
# This is a script file to build agens-sql project which has a installer.

Agens_SQL_version="Agens_SQL_V1.0.0"
AGENS_TEMP_DIR=`pwd`/agens_temp

# postgresql
cd postgresql-9.4.4/
./configure --prefix=$AGENS_TEMP_DIR/pgsql --with-pgport=6179 --with-gssapi --with-ldap --with-tcl --with-openssl --enable-nls --enable-thread-safety --with-perl --with-python --with-libxml --with-libxslt --with-pam;
make world; make install-world;
cd ..

# pgpool 
cd pgpool-II-3.4.2/
PATH=$AGENS_TEMP_DIR/pgsql/bin:$PATH
./configure --prefix=$AGENS_TEMP_DIR/pgpool --with-pgsql=$AGENS_TEMP_DIR/pgsql/ --with-openssl --with-pam
make; make install;
cd src/sql
make
cd ../../..

# postgis  
cd geos-3.4.2/
./configure --prefix=$AGENS_TEMP_DIR/geos; make; make install;
cd ..

cd proj-4.9.1/
./configure --prefix=$AGENS_TEMP_DIR/proj; make; make install;
cd ..

cd gdal-1.11.2/
./configure --prefix=$AGENS_TEMP_DIR/gdal; make; make install;
cd ..

# json-c
cd json-c-0.11/
./configure --prefix=$AGENS_TEMP_DIR/json-c; make; make install;
cd ..

cd postgis-2.1.7/
LD_LIBRARY_PATH=$AGENS_TEMP_DIR/pgsql/lib:$LD_LIBRARY_PATH PATH=$AGENS_TEMP_DIR/pgsql/bin:$PATH ./configure --with-pgconfig=$AGENS_TEMP_DIR/pgsql/bin/pg_config --with-geosconfig=$AGENS_TEMP_DIR/geos/bin/geos-config --with-gdalconfig=$AGENS_TEMP_DIR/gdal/bin/gdal-config --with-projdir=$AGENS_TEMP_DIR/proj --with-jsondir=$AGENS_TEMP_DIR/json-c
make
cd ..

# libevent(for pgbouncer)
cd libevent-2.0.22-stable/
./configure --prefix=$AGENS_TEMP_DIR/libevent; make; make install;
cd ..

# pgbouncer
cd pgbouncer-1.5.5
./configure --prefix=$AGENS_TEMP_DIR/pgbouncer --with-libevent=$AGENS_TEMP_DIR/libevent
make; make install;
cd ..

# skytools
cd skytools-3.2
./configure --prefix=$AGENS_TEMP_DIR/skytools --with-pgconfig=$AGENS_TEMP_DIR/pgsql/bin/pg_config
./configure --prefix=$AGENS_TEMP_DIR/skytools --with-pgconfig=$AGENS_TEMP_DIR/pgsql/bin/pg_config --datarootdir=$AGENS_TEMP_DIR/skytools/share --datadir=$AGENS_TEMP_DIR/skytools --mandir=$AGENS_TEMP_DIR/skytools/man --docdir=$AGENS_TEMP_DIR/skytools/doc/skytools --with-skylog --with-sk3-subdir --with-libevent=$AGENS_TEMP_DIR/libevent
make; make install;
cd ..
mkdir -p $AGENS_TEMP_DIR/skytools/into_pg/lib
mv $AGENS_TEMP_DIR/pgsql/lib/pgq_* $AGENS_TEMP_DIR/skytools/into_pg/lib
mkdir -p $AGENS_TEMP_DIR/skytools/into_pg/share/contrib
mv $AGENS_TEMP_DIR/pgsql/share/contrib/pgq* $AGENS_TEMP_DIR/skytools/into_pg/share/contrib/
mv $AGENS_TEMP_DIR/pgsql/share/contrib/newgrants_* $AGENS_TEMP_DIR/skytools/into_pg/share/contrib/
mv $AGENS_TEMP_DIR/pgsql/share/contrib/oldgrants_* $AGENS_TEMP_DIR/skytools/into_pg/share/contrib/
mv $AGENS_TEMP_DIR/pgsql/share/contrib/londiste* $AGENS_TEMP_DIR/skytools/into_pg/share/contrib/
mv $AGENS_TEMP_DIR/pgsql/share/contrib/uninstall_pgq.sql $AGENS_TEMP_DIR/skytools/into_pg/share/contrib/
mv $AGENS_TEMP_DIR/pgsql/share/contrib/txid.sql $AGENS_TEMP_DIR/skytools/into_pg/share/contrib/
mkdir -p $AGENS_TEMP_DIR/skytools/into_pg/share/doc/extension
mv $AGENS_TEMP_DIR/pgsql/share/doc/extension/README.pgq* $AGENS_TEMP_DIR/skytools/into_pg/share/doc/extension/
mkdir -p $AGENS_TEMP_DIR/skytools/into_pg/share/extension
mv $AGENS_TEMP_DIR/pgsql/share/extension/londiste* $AGENS_TEMP_DIR/skytools/into_pg/share/extension/
mv $AGENS_TEMP_DIR/pgsql/share/extension/pgq* $AGENS_TEMP_DIR/skytools/into_pg/share/extension/


# pg_plan_hint
cd pg_hint_plan94-1.1.3
make PG_CONFIG=$AGENS_TEMP_DIR/pgsql/bin/pg_config # pg_config의 경로를 정해준다.
#make install PG_CONFIG=$AGENS_TEMP_DIR/pgsql/bin/pg_config
cd ..


# plproxy
cd plproxy-2.5/
make PG_CONFIG=$AGENS_TEMP_DIR/pgsql/bin/pg_config
#make install PG_CONFIG=$AGENS_TEMP_DIR/pgsql/bin/pg_config
cd ..


# slony
cd slony1-2.2.4/
./configure --prefix=$AGENS_TEMP_DIR/slon1 --with-pgconfigdir=$AGENS_TEMP_DIR/pgsql/bin --with-pgbindir=$AGENS_TEMP_DIR/pgsql/bin --with-pgincludedir=$AGENS_TEMP_DIR/pgsql/include --with-pgincludeserverdir=$AGENS_TEMP_DIR/pgsql/include/server --with-pglibdir=$AGENS_TEMP_DIR/pgsql/lib --with-pgpkglibdir=$AGENS_TEMP_DIR/pgsql/lib --with-pgsharedir=$AGENS_TEMP_DIR/pgsql/share --with-perltools=$AGENS_TEMP_DIR/slon1/perl_tools --with-pgport=yes --libexecdir=$AGENS_TEMP_DIR/slon1/exec --with-perlsharedir=$AGENS_TEMP_DIR/slon1/perl_sharedir
make;
cp ./src/backend/slony1_base.sql ./src/backend/slony1_base.2.2.4.sql
cp ./src/backend/slony1_base.v83.sql ./src/backend/slony1_base.v83.2.2.4.sql
cp ./src/backend/slony1_base.v84.sql ./src/backend/slony1_base.v84.2.2.4.sql
cp ./src/backend/slony1_funcs.sql ./src/backend/slony1_funcs.2.2.4.sql
cp ./src/backend/slony1_funcs.v83.sql ./src/backend/slony1_funcs.v83.2.2.4.sql
cp ./src/backend/slony1_funcs.v84.sql ./src/backend/slony1_funcs.v84.2.2.4.sql
#make install
cd ..

# orafce
cd orafce-3_1
make PG_CONFIG=$AGENS_TEMP_DIR/pgsql/bin/pg_config
make PG_CONFIG=$AGENS_TEMP_DIR/pgsql/bin/pg_config install

mkdir -p $AGENS_TEMP_DIR/orafce/lib
mkdir -p $AGENS_TEMP_DIR/orafce/share/extension
mkdir -p $AGENS_TEMP_DIR/orafce/share/doc/extension
mv $AGENS_TEMP_DIR/pgsql/lib/orafce.so $AGENS_TEMP_DIR/orafce/lib/
mv $AGENS_TEMP_DIR/pgsql/share/extension/orafce* $AGENS_TEMP_DIR/orafce/share/extension/
mv $AGENS_TEMP_DIR/pgsql/share/doc/extension/*.orafce $AGENS_TEMP_DIR/orafce/share/doc/extension/
mv $AGENS_TEMP_DIR/pgsql/share/doc/extension/README.asciidoc $AGENS_TEMP_DIR/orafce/share/doc/extension/
cd ..

# oracle_fdw
if [ -n "$ORACLE_HOME" ]; then
	cd oracle_fdw-ORACLE_FDW_1_2_0
	make PG_CONFIG=$AGENS_TEMP_DIR/pgsql/bin/pg_config

	mkdir -p $AGENS_TEMP_DIR/oracle_fdw/lib
	mkdir -p $AGENS_TEMP_DIR/oracle_fdw/share/doc/extension
	mkdir -p $AGENS_TEMP_DIR/oracle_fdw/share/extension

	mv ./README.oracle_fdw $AGENS_TEMP_DIR/oracle_fdw/share/doc/extension/
	mv ./oracle_fdw.so $AGENS_TEMP_DIR/oracle_fdw/lib/
	mv ./oracle_fdw--1.0--1.1.sql $AGENS_TEMP_DIR/oracle_fdw/share/extension
	mv ./oracle_fdw--1.1.sql $AGENS_TEMP_DIR/oracle_fdw/share/extension
	mv ./oracle_fdw.control $AGENS_TEMP_DIR/oracle_fdw/share/extension
fi

# powa
cd powa-archivist-REL_2_0_0/
make PG_CONFIG=$AGENS_TEMP_DIR/pgsql/bin/pg_config
cd pg_qualstats-master/
make PG_CONFIG=$AGENS_TEMP_DIR/pgsql/bin/pg_config
cd ..
cd pg_stat_kcache-master/
make PG_CONFIG=$AGENS_TEMP_DIR/pgsql/bin/pg_config
cd ..
cd ..



# izpack 실행
if [ ! -d "./distributions" ]; then
	mkdir -p distributions
fi

./izpack/bin/compile res/installer/install_enterprise.xml -b ./ -o distributions/"$Agens_SQL_version"_Enterprise_Edition.jar -k standard
./izpack/bin/compile res/installer/install_standard.xml -b ./ -o distributions/"$Agens_SQL_version"_Standard_Edition.jar -k standard




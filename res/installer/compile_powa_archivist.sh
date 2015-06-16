#!/bin/bash
LD_LIBRARY_PATH=$INSTALL_PATH/pgsql/lib

# add shared_preload_libraries
sed -e "s@#shared_preload_libraries = ''@shared_preload_libraries='pg_stat_statements,powa,pg_stat_kcache,pg_qualstats'@" $agens_sql.data_path/postgresql.conf > $agens_sql.data_path/postgresql.conf.$$
    mv $agens_sql.data_path/postgresql.conf.$$ $agens_sql.data_path/postgresql.conf
    chmod 600 $agens_sql.data_path/postgresql.conf

# server restart
$INSTALL_PATH/pgsql/bin/pg_ctl -D $agens_sql.data_path -m smart stop
$INSTALL_PATH/pgsql/bin/pg_ctl -w -D $agens_sql.data_path -l $agens_sql.data_path/server_log.txt start

# create extensions
$INSTALL_PATH/pgsql/bin/createdb -U agens -p $agens_sql.port powa
$INSTALL_PATH/pgsql/bin/psql -U agens -p $agens_sql.port -d powa -c "CREATE EXTENSION btree_gist;"
$INSTALL_PATH/pgsql/bin/psql -U agens -p $agens_sql.port -d powa -c "CREATE EXTENSION pg_stat_statements;"
$INSTALL_PATH/pgsql/bin/psql -U agens -p $agens_sql.port -d powa -c "CREATE EXTENSION pg_qualstats;"
$INSTALL_PATH/pgsql/bin/psql -U agens -p $agens_sql.port -d powa -c "CREATE EXTENSION pg_stat_kcache;"
$INSTALL_PATH/pgsql/bin/psql -U agens -p $agens_sql.port -d powa -c "CREATE EXTENSION powa;"
$INSTALL_PATH/pgsql/bin/psql -U agens -p $agens_sql.port -d powa -c "SELECT powa_qualstats_register();"
$INSTALL_PATH/pgsql/bin/psql -U agens -p $agens_sql.port -d powa -c "SELECT powa_kcache_register();"


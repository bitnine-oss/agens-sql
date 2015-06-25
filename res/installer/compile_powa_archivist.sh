#!/bin/bash

# add shared_preload_libraries
sed -e "s@#shared_preload_libraries = ''@shared_preload_libraries='pg_stat_statements,powa,pg_stat_kcache,pg_qualstats'@" $agens_sql.data_path/postgresql.conf > $agens_sql.data_path/postgresql.conf.$$
    mv $agens_sql.data_path/postgresql.conf.$$ $agens_sql.data_path/postgresql.conf
    chmod 600 $agens_sql.data_path/postgresql.conf

# server restart
LD_LIBRARY_PATH=$INSTALL_PATH/pgsql/lib $INSTALL_PATH/pgsql/bin/pg_ctl -D $agens_sql.data_path -m smart stop
LD_LIBRARY_PATH=$INSTALL_PATH/pgsql/lib $INSTALL_PATH/pgsql/bin/pg_ctl -w -D $agens_sql.data_path -l $agens_sql.data_path/server_log.txt start

# create extensions
LD_LIBRARY_PATH=$INSTALL_PATH/pgsql/lib $INSTALL_PATH/pgsql/bin/createdb -U agens -p $agens_sql.port powa
LD_LIBRARY_PATH=$INSTALL_PATH/pgsql/lib $INSTALL_PATH/pgsql/bin/psql -U agens -p $agens_sql.port -d powa -c "CREATE EXTENSION btree_gist;"
LD_LIBRARY_PATH=$INSTALL_PATH/pgsql/lib $INSTALL_PATH/pgsql/bin/psql -U agens -p $agens_sql.port -d powa -c "CREATE EXTENSION pg_stat_statements;"
LD_LIBRARY_PATH=$INSTALL_PATH/pgsql/lib $INSTALL_PATH/pgsql/bin/psql -U agens -p $agens_sql.port -d powa -c "CREATE EXTENSION pg_qualstats;"
LD_LIBRARY_PATH=$INSTALL_PATH/pgsql/lib $INSTALL_PATH/pgsql/bin/psql -U agens -p $agens_sql.port -d powa -c "CREATE EXTENSION pg_stat_kcache;"
LD_LIBRARY_PATH=$INSTALL_PATH/pgsql/lib $INSTALL_PATH/pgsql/bin/psql -U agens -p $agens_sql.port -d powa -c "CREATE EXTENSION powa;"
LD_LIBRARY_PATH=$INSTALL_PATH/pgsql/lib $INSTALL_PATH/pgsql/bin/psql -U agens -p $agens_sql.port -d powa -c "SELECT powa_qualstats_register();"
LD_LIBRARY_PATH=$INSTALL_PATH/pgsql/lib $INSTALL_PATH/pgsql/bin/psql -U agens -p $agens_sql.port -d powa -c "SELECT powa_kcache_register();"


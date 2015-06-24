#!/bin/bash

if [ ! -f $INSTALL_PATH/pgsql/bin/postmaster ]; then ln -s $INSTALL_PATH/pgsql/bin/postgres $INSTALL_PATH/pgsql/bin/postmaster; fi
if [ ! -f $INSTALL_PATH/pgsql/lib/libecpg.so.6 ]; then ln -s $INSTALL_PATH/pgsql/lib/libecpg.so.6.6 $INSTALL_PATH/pgsql/lib/libecpg.so.6; fi
if [ ! -f $INSTALL_PATH/pgsql/lib/libecpg.so ]; then ln -s $INSTALL_PATH/pgsql/lib/libecpg.so.6.6 $INSTALL_PATH/pgsql/lib/libecpg.so; fi
if [ ! -f $INSTALL_PATH/pgsql/lib/libecpg_compat.so.3 ]; then ln -s $INSTALL_PATH/pgsql/lib/libecpg_compat.so.3.6 $INSTALL_PATH/pgsql/lib/libecpg_compat.so.3; fi
if [ ! -f $INSTALL_PATH/pgsql/lib/libecpg_compat.so ]; then ln -s $INSTALL_PATH/pgsql/lib/libecpg_compat.so.3.6 $INSTALL_PATH/pgsql/lib/libecpg_compat.so; fi
if [ ! -f $INSTALL_PATH/pgsql/lib/libpgtypes.so ]; then ln -s $INSTALL_PATH/pgsql/lib/libpgtypes.so.3.5 $INSTALL_PATH/pgsql/lib/libpgtypes.so; fi
if [ ! -f $INSTALL_PATH/pgsql/lib/libpgtypes.so.3 ]; then ln -s $INSTALL_PATH/pgsql/lib/libpgtypes.so.3.5 $INSTALL_PATH/pgsql/lib/libpgtypes.so.3; fi
if [ ! -f $INSTALL_PATH/pgsql/lib/libpq.so ]; then ln -s $INSTALL_PATH/pgsql/lib/libpq.so.5.7 $INSTALL_PATH/pgsql/lib/libpq.so; fi
if [ ! -f $INSTALL_PATH/pgsql/lib/libpq.so.5 ]; then ln -s $INSTALL_PATH/pgsql/lib/libpq.so.5.7 $INSTALL_PATH/pgsql/lib/libpq.so.5; fi

AGENS_HOME="$INSTALL_PATH"
agens_passwd_file=$AGENS_HOME/pgsql/dbuser_passwd
port="$agens_sql.port"
DATA_DIR="$agens_sql.data_path"

# initialize agens database
$AGENS_HOME/pgsql/bin/initdb -U agens -D $DATA_DIR

# edit postgresql.conf
if [ $port -ne "5456" ]; then
    sed -e 's/#port = 5456/port = $agens_sql.port/g' $DATA_DIR/postgresql.conf > $DATA_DIR/postgresql.conf.$$
    mv $DATA_DIR/postgresql.conf.$$ $DATA_DIR/postgresql.conf
    chmod 600 $DATA_DIR/postgresql.conf
fi


# operate server
LD_LIBRARY_PATH=$AGENS_HOME/pgsql/lib:$LD_LIBRARY_PATH $AGENS_HOME/pgsql/bin/pg_ctl -w -D $DATA_DIR -l $DATA_DIR/server_log.txt start

# createdb
$AGENS_HOME/pgsql/bin/createdb -p $port -U agens agens


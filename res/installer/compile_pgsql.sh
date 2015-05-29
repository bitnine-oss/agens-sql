#!/bin/bash

ln -s $INSTALL_PATH/pgsql/bin/postgres $INSTALL_PATH/pgsql/bin/postmaster

AGENS_HOME="$INSTALL_PATH"
agens_passwd_file=$AGENS_HOME/pgsql/dbuser_passwd
USER="$agens-sql.superuser"
DATABASE="$agens-sql.login_db"
password="$agens.password"
port="$agens-sql.port"
DATA_DIR="$agens-sql.data_path"



# create password file
echo "$password" > $agens_passwd_file
chmod 600 $agens_passwd_file

# initialize agens database
mkdir $DATA_DIR
if [ -z $password ]; then
	LD_LIBRARY_PATH=$AGENS_HOME/pgsql/lib $AGENS_HOME/pgsql/bin/initdb -U $USER -D $DATA_DIR
else
	LD_LIBRARY_PATH=$AGENS_HOME/pgsql/lib $AGENS_HOME/pgsql/bin/initdb --pwfile=$agens_passwd_file -A md5 -U $USER -D $DATA_DIR
fi

# edit postgresql.conf
if [ $port -ne "5456" ]; then
    sed -e 's/#port = 5456/port = $agens-sql.port/g' $DATA_DIR/postgresql.conf > $DATA_DIR/postgresql.conf.$$
    mv $DATA_DIR/postgresql.conf.$$ $DATA_DIR/postgresql.conf
    chmod 600 $DATA_DIR/postgresql.conf
fi



# operate server
LD_LIBRARY_PATH=$AGENS_HOME/pgsql/lib $AGENS_HOME/pgsql/bin/pg_ctl -D $DATA_DIR -l $DATA_DIR/server_log.txt start

# wait for booting postmaster process
sleep 3

# createdb
if [ -z $password ]; then
	$AGENS_HOME/pgsql/bin/createdb -p $port -U $USER $DATABASE
else
	$AGENS_HOME/pgsql/bin/createdb -p $port -U $USER $DATABASE < $agens_passwd_file
fi

# remove password file
rm -f $agens_passwd_file


# run psql
# $AGENS_HOME/pgsql/bin/psql -p $port -U $USER $DATABASE



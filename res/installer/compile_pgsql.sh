#!/bin/bash
if [ $(id -u) != "0" ]; then
	echo "This script requires root privileges."
	exit 1
fi

AGENS_HOME="$INSTALL_PATH"
agens_passwd_file=$AGENS_HOME/pgsql/dbuser_passwd
USER="$agens-sql.superuser"
DATABASE="$agens-sql.login_db"
password="$agens.password"
port="$agens-sql.port"
DATA_DIR="$agens-sql.data_path"


# adduser agens
egrep "^$USER" /etc/passwd >/dev/null
if [ $? -eq 0 ]; then
	echo "$USER exists!"
else
	pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
	useradd -m -p $pass $USER
	[ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
fi



# bin
chmod -R a+x $AGENS_HOME/pgsql/bin
rm $AGENS_HOME/pgsql/bin/postmaster
ln -s postgres $AGENS_HOME/pgsql/bin/postmaster

# create password file
echo "$password" > $agens_passwd_file
chown $USER:$USER $agens_passwd_file
chmod 600 $agens_passwd_file

# initialize agens database
mkdir $DATA_DIR
chown $USER:$USER $DATA_DIR
if [ -z $password ]; then
	su - $USER -c "LD_LIBRARY_PATH=$AGENS_HOME/pgsql/lib $AGENS_HOME/pgsql/bin/initdb -U $USER -D $DATA_DIR"
else
	su - $USER -c "LD_LIBRARY_PATH=$AGENS_HOME/pgsql/lib $AGENS_HOME/pgsql/bin/initdb --pwfile=$agens_passwd_file -A md5 -U $USER -D $DATA_DIR"
fi

# edit postgresql.conf
su - $USER -c "sed -e \"s@\#port = 5432@port = $port@g\" \
                         -e \"s@\#port = 5456@port = $port@g\" \
                        $DATA_DIR/postgresql.conf > $DATA_DIR/postgresql.conf.$$"
su - $USER -c "mv $DATA_DIR/postgresql.conf.$$ $DATA_DIR/postgresql.conf"
chmod 600 $DATA_DIR/postgresql.conf


# operate server
su - $USER -c "$AGENS_HOME/pgsql/bin/pg_ctl -D $DATA_DIR -l $DATA_DIR/server_log.txt start"

# wait for booting postmaster process
sleep 3

# createdb
if [ -z $password ]; then
	su - $USER -c "$AGENS_HOME/pgsql/bin/createdb -p $port -U $USER $DATABASE"
else
	su - $USER -c "$AGENS_HOME/pgsql/bin/createdb -p $port -U $USER $DATABASE < $agens_passwd_file"
fi

# remove password file
rm -f $agens_passwd_file

exit 0

# run psql
# $AGENS_HOME/pgsql/bin/psql -p $port -U $USER $DATABASE



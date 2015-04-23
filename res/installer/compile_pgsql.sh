#!/bin/bash
if [ $(id -u) != "0" ]; then
	echo "This script requires root privileges."
	exit 1
fi

# set env_path
if [ -f "/etc/bash.bashrc" ]; then # Ubuntu
	echo "export PATH=$PATH:$INSTALL_PATH/pgsql/bin" >> /etc/bash.bashrc
	echo "export LD_LIBRARY_PATH=$INSTALL_PATH/pgsql/lib:$LD_LIBRARY_PATH" >> /etc/bash.bashrc
	source /etc/bash.bashrc
elif [ -f "/etc/bashrc" ]; then # Centos
	echo "export PATH=$PATH:$INSTALL_PATH/pgsql/bin" >> /etc/bashrc
	echo "export LD_LIBRARY_PATH=$INSTALL_PATH/pgsql/lib:$LD_LIBRARY_PATH" >> /etc/bashrc
	source /etc/bashrc
else				# Solairs
        echo "export PATH=$PATH:$INSTALL_PATH/pgsql/bin" >> /etc/profile
        echo "export LD_LIBRARY_PATH=$INSTALL_PATH/pgsql/lib:$LD_LIBRARY_PATH" >> /etc/profile
        source /etc/profile
fi

# adduser postgres
username="postgres"
password="$postgres.password"
egrep "^$username" /etc/passwd >/dev/null
if [ $? -eq 0 ]; then
	echo "$username exists!"
else
	pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
	useradd -m -p $pass $username
	[ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
fi

# bin
chmod a+x -R $INSTALL_PATH/pgsql/bin
rm $INSTALL_PATH/pgsql/bin/postmaster
ln -s postgres $INSTALL_PATH/pgsql/bin/postmaster

# data
chown -R postgres:postgres $INSTALL_PATH/pgsql/data
chown postgres:root $INSTALL_PATH/pgsql/data
chmod -R 600 $INSTALL_PATH/pgsql/data
find $INSTALL_PATH/pgsql/data -type d -exec chmod 700 {} \;

# run postgres
su - postgres -c "sh $INSTALL_PATH/installer/res/run_server.sh"



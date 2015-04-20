#!/bin/bash

# check root privileges
if [ $(id -u) != "0" ]; then
	echo "This script requires root privileges."
	exit 1
fi

# bin
chmod a+x -R $INSTALL_PATH/pgpool/bin

# lib
rm $INSTALL_PATH/pgpool/lib/libpcp.so
rm $INSTALL_PATH/pgpool/lib/libpcp.so.0
chmod 755 $INSTALL_PATH/pgpool/lib/libpcp.la
chmod 755 $INSTALL_PATH/pgpool/lib/libpcp.so.0.0.0
ln -s libpcp.so.0.0.0 $INSTALL_PATH/pgpool/lib/libpcp.so
ln -s libpcp.so.0.0.0 $INSTALL_PATH/pgpool/lib/libpcp.so.0




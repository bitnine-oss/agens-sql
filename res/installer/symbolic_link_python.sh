#!/bin/bash
# Symbolic Linking Python Version
PYTHON_VERSION="$(python --version 2>&1)"
eval VERSION_STRING=($PYTHON_VERSION)
if [ ${VERSION_STRING[1]} != "2.6.*" ]; then
	if [ -f /usr/lib/libpython2.7.so.1.0 ]; then
		ln -s /usr/lib/libpython2.7.so.1.0 $INSTALL_PATH/pgsql/lib/libpython2.6.so.1.0
	elif [ -f /usr/lib64/libpython2.7.so.1.0 ]; then
		ln -s /usr/lib64/libpython2.7.so.1.0 $INSTALL_PATH/pgsql/lib/libpython2.6.so.1.0
	elif [ -f /usr/lib/x86_64-linux-gnu/libpython2.7.so.1.0 ]; then
		ln -s /usr/lib/x86_64-linux-gnu/libpython2.7.so.1.0 $INSTALL_PATH/pgsql/lib/libpython2.6.so.1.0
	else
		continue
	fi
		
fi

#!/bin/bash
#Create symbolic link
if [ ! -f $INSTALL_PATH/pgsql/lib/libevent-2.0.so.5 ]; then 
    if [ -f $INSTALL_PATH/pgsql/lib/libevent-2.0.so.5.1.9 ]; then
        ln -s $INSTALL_PATH/pgsql/lib/libevent-2.0.so.5.1.9 $INSTALL_PATH/pgsql/lib/libevent-2.0.so.5
    elif [ -f $INSTALL_PATH/pgsql/lib/libevent-2.0.so.5.1.10 ]; then
        ln -s $INSTALL_PATH/pgsql/lib/libevent-2.0.so.5.1.10 $INSTALL_PATH/pgsql/lib/libevent-2.0.so.5
    fi

# Library
if [ -d "$INSTALL_PATH/skytools/lib64/" ]; then # centos-64bit
        if [ -d "$INSTALL_PATH/skytools/lib64/python2.7" ]; then
                chmod 755 $INSTALL_PATH/skytools/lib64/python2.7/site-packages/skytools/_chashtext.so
                chmod 755 $INSTALL_PATH/skytools/lib64/python2.7/site-packages/skytools/_cquoting.so
        else # Centos6.6-64bit
                chmod 755 $INSTALL_PATH/skytools/lib64/python2.6/site-packages/skytools/_cquoting.so
                chmod 755 $INSTALL_PATH/skytools/lib64/python2.6/site-packages/skytools/_chashtext.so
fi
else
        if [ -d "$INSTALL_PATH/skytools/lib/python2.6" ]; then # centos-32bit
                chmod 755 $INSTALL_PATH/skytools/lib/python2.6/site-packages/skytools/_chashtext.so
                chmod 755 $INSTALL_PATH/skytools/lib/python2.6/site-packages/skytools/_cquoting.so
        else # ubuntu-32,64bit
                chmod 755 $INSTALL_PATH/skytools/lib/python2.7/site-packages/skytools/_chashtext.so
                chmod 755 $INSTALL_PATH/skytools/lib/python2.7/site-packages/skytools/_cquoting.so
        fi
fi


#!/bin/bash
#make symlink
ln -s -f $INSTALL_PATH/pgsql/lib/libgdal.so.1.18.2 $INSTALL_PATH/pgsql/lib/libgdal.so
ln -s -f $INSTALL_PATH/pgsql/lib/libgdal.so.1.18.2 $INSTALL_PATH/pgsql/lib/libgdal.so.1
ln -s -f $INSTALL_PATH/pgsql/lib/libgeos_c.so.1.8.2 $INSTALL_PATH/pgsql/lib/libgeos_c.so
ln -s -f $INSTALL_PATH/pgsql/lib/libgeos_c.so.1.8.2 $INSTALL_PATH/pgsql/lib/libgeos_c.so.1
ln -s -f $INSTALL_PATH/pgsql/lib/libproj.so.9.0.0 $INSTALL_PATH/pgsql/lib/libproj.so
ln -s -f $INSTALL_PATH/pgsql/lib/libproj.so.9.0.0 $INSTALL_PATH/pgsql/lib/libproj.so.9
ln -s -f $INSTALL_PATH/pgsql/lib/libgeos-3.4.2.so $INSTALL_PATH/pgsql/lib/libgeos.so

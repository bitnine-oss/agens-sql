#!/bin/bash
#make symlink
if [ ! -f $INSTALL_PATH/pgsql/lib/libgdal.so ]; then ln -s $INSTALL_PATH/pgsql/lib/libgdal.so.1.18.2 $INSTALL_PATH/pgsql/lib/libgdal.so; fi
if [ ! -f $INSTALL_PATH/pgsql/lib/libgdal.so.1 ]; then ln -s $INSTALL_PATH/pgsql/lib/libgdal.so.1.18.2 $INSTALL_PATH/pgsql/lib/libgdal.so.1; fi
if [ ! -f $INSTALL_PATH/pgsql/lib/libgeos_c.so ]; then ln -s $INSTALL_PATH/pgsql/lib/libgeos_c.so.1.8.2 $INSTALL_PATH/pgsql/lib/libgeos_c.so; fi
if [ ! -f $INSTALL_PATH/pgsql/lib/libgeos_c.so.1 ]; then ln -s $INSTALL_PATH/pgsql/lib/libgeos_c.so.1.8.2 $INSTALL_PATH/pgsql/lib/libgeos_c.so.1; fi
if [ ! -f $INSTALL_PATH/pgsql/lib/libproj.so ]; then ln -s $INSTALL_PATH/pgsql/lib/libproj.so.9.0.0 $INSTALL_PATH/pgsql/lib/libproj.so; fi
if [ ! -f $INSTALL_PATH/pgsql/lib/libproj.so.9 ]; then ln -s $INSTALL_PATH/pgsql/lib/libproj.so.9.0.0 $INSTALL_PATH/pgsql/lib/libproj.so.9; fi
if [ ! -f $INSTALL_PATH/pgsql/lib/libgeos.so ]; then ln -s $INSTALL_PATH/pgsql/lib/libgeos-3.4.2.so $INSTALL_PATH/pgsql/lib/libgeos.so; fi
if [ ! -f $INSTALL_PATH/pgsql/lib/libjson-c.so ]; then ln -s $INSTALL_PATH/pgsql/lib/libjson-c.so.2.0.1 $INSTALL_PATH/pgsql/lib/libjson-c.so; fi
if [ ! -f $INSTALL_PATH/pgsql/lib/libjson-c.so.2 ]; then ln -s $INSTALL_PATH/pgsql/lib/libjson-c.so.2.0.1 $INSTALL_PATH/pgsql/lib/libjson-c.so.2; fi

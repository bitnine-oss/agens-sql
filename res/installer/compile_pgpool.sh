#!/bin/bash
#make symlink
if [ ! -f $INSTALL_PATH/pgpool/lib/libpcp.so ]; then ln -s $INSTALL_PATH/pgpool/lib/libpcp.so.0.0.0 $INSTALL_PATH/pgpool/lib/libpcp.so; fi
if [ ! -f $INSTALL_PATH/pgpool/lib/libpcp.so.0 ]; then ln -s $INSTALL_PATH/pgpool/lib/libpcp.so.0.0.0 $INSTALL_PATH/pgpool/lib/libpcp.so.0; fi
if [ ! -f $INSTALL_PATH/pgsql/lib/libpcp.so.0 ]; then ln -s $INSTALL_PATH/pgpool/lib/libpcp.so.0.0.0 $INSTALL_PATH/pgsql/lib/libpcp.so.0; fi

#!/bin/bash
if [ ! -f $INSTALL_PATH/pgsql/lib/libevent-2.0.so.5 ]; then ln -s $INSTALL_PATH/pgsql/lib/libevent-2.0.so.5.1.10 $INSTALL_PATH/pgsql/lib/libevent-2.0.so.5; fi

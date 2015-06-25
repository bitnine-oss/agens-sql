#!/bin/bash
# terminate server
$INSTALL_PATH/pgsql/bin/pg_ctl -w -D $INSTALL_PATH/pgsql/data -l $INSTALL_PATH/pgsql/data/server_log.txt stop -m immediate


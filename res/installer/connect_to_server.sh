#!/bin/bash
# connect to server
LD_LIBRARY_PATH=$INSTALL_PATH/pgsql/lib:$LD_LIBRARY_PATH $INSTALL_PATH/pgsql/bin/psql -p $agens_sql.port -U agens agens



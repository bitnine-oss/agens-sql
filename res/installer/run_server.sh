#!/bin/bash
if [ $(whoami) = "postgres" ]; then
	$INSTALL_PATH/pgsql/bin/postgres -D $INSTALL_PATH/pgsql/data >$INSTALL_PATH/pgsql/data/logfile 2>&1 &
else
	su - postgres -c "sh $INSTALL_PATH/installer/res/run_server.sh"
fi

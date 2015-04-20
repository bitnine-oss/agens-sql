#!/bin/bash
# check root privileges
if [ $(id -u) != "0" ]; then
        echo "This script requires root privileges."
        exit 1
fi


/usr/bin/install -c -m 644 $INSTALL_PATH/pg_hint_plan/pg_hint_plan.control '$INSTALL_PATH/pgsql/share/extension/'
/usr/bin/install -c -m 644 $INSTALL_PATH/pg_hint_plan/pg_hint_plan--1.1.3.sql $INSTALL_PATH/pg_hint_plan/pg_hint_plan--1.1.2--1.1.3.sql '$INSTALL_PATH/pgsql/share/extension/'
/usr/bin/install -c -m 755 $INSTALL_PATH/pg_hint_plan/pg_hint_plan.so '$INSTALL_PATH/pgsql/lib/'


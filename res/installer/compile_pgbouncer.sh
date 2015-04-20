#!/bin/bash

# check root privileges
if [ $(id -u) != "0" ]; then
        echo "This script requires root privileges."
        exit 1
fi

# bin
chmod a+x -R $INSTALL_PATH/pgbouncer/bin


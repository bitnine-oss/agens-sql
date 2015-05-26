#!/bin/bash
# check root privileges
if [ $(id -u) != "0" ]; then
        echo "This script requires root privileges."
        exit 1
fi


#/usr/bin/install -c -m 755 $INSTALL_PATH/plproxy/plproxy.so '$INSTALL_PATH/pgsql/lib/plproxy.so'
#/usr/bin/install -c -m 644 $INSTALL_PATH/plproxy/plproxy.control '$INSTALL_PATH/pgsql/share/extension/'
#/usr/bin/install -c -m 644 $INSTALL_PATH/plproxy/sql/plproxy--2.6.0.sql $INSTALL_PATH/plproxy/sql/plproxy--2.3.0--2.6.0.sql $INSTALL_PATH/plproxy/sql/plproxy--2.4.0--2.6.0.sql $INSTALL_PATH/plproxy/sql/plproxy--2.5.0--2.6.0.sql $INSTALL_PATH/plproxy/sql/plproxy--unpackaged--2.6.0.sql '$INSTALL_PATH/pgsql/share/extension/'

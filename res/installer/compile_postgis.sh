#!/bin/bash
# check root privileges
if [ $(id -u) != "0" ]; then
        echo "This script requires root privileges."
        exit 1
fi

# copy postgis to pgsql
cp $INSTALL_PATH/postgis/extensions/postgis/postgis.control $INSTALL_PATH/pgsql/share/extension
cp $INSTALL_PATH/postgis/extensions/postgis/sql/* $INSTALL_PATH/pgsql/share/extension

# copy postgis_topology to pgsql
cp $INSTALL_PATH/postgis/extensions/postgis_topology/postgis_topology.control $INSTALL_PATH/pgsql/share/extension
cp $INSTALL_PATH/postgis/extensions/postgis_topology/sql/* $INSTALL_PATH/pgsql/share/extension

# copy postgis_tiger_geocoder to pgsql
cp $INSTALL_PATH/postgis/extensions/postgis_tiger_geocoder/postgis_tiger_geocoder.control $INSTALL_PATH/pgsql/share/extension
cp $INSTALL_PATH/postgis/extensions/postgis_tiger_geocoder/sql/* $INSTALL_PATH/pgsql/share/extension

# copy .so files
/usr/bin/install -c -m 755 $INSTALL_PATH/postgis/postgis/postgis-2.1.so '$INSTALL_PATH/pgsql/lib/postgis-2.1.so'
/usr/bin/install -c -m 755 $INSTALL_PATH/postgis/raster/rt_pg/rtpostgis-2.1.so '$INSTALL_PATH/pgsql/lib/rtpostgis-2.1.so'

/usr/bin/install -c -m 755 $INSTALL_PATH/postgis/postgis/libgeos_c.so.1.8.2 '$INSTALL_PATH/pgsql/lib/libgeos_c.so.1.8.2'
/usr/bin/install -c -m 755 $INSTALL_PATH/postgis/postgis/libproj.so.9.0.0 '$INSTALL_PATH/pgsql/lib/libproj.so.9.0.0'
/usr/bin/install -c -m 755 $INSTALL_PATH/postgis/postgis/libgdal.so.1.18.2 '$INSTALL_PATH/pgsql/lib/libgdal.so.1.18.2'
/usr/bin/install -c -m 755 $INSTALL_PATH/postgis/postgis/libgeos-3.4.2.so '$INSTALL_PATH/pgsql/lib/libgeos-3.4.2.so'


ln -s $INSTALL_PATH/pgsql/lib/libgdal.so.1.18.2 $INSTALL_PATH/pgsql/lib/libgdal.so
ln -s $INSTALL_PATH/pgsql/lib/libgdal.so.1.18.2 $INSTALL_PATH/pgsql/lib/libgdal.so.1
ln -s $INSTALL_PATH/pgsql/lib/libgeos_c.so.1.8.2 $INSTALL_PATH/pgsql/lib/libgeos_c.so
ln -s $INSTALL_PATH/pgsql/lib/libgeos_c.so.1.8.2 $INSTALL_PATH/pgsql/lib/libgeos_c.so.1
ln -s $INSTALL_PATH/pgsql/lib/libproj.so.9.0.0 $INSTALL_PATH/pgsql/lib/libproj.so
ln -s $INSTALL_PATH/pgsql/lib/libproj.so.9.0.0 $INSTALL_PATH/pgsql/lib/libproj.so.9
ln -s $INSTALL_PATH/pgsql/lib/libgeos-3.4.2.so $INSTALL_PATH/pgsql/lib/libgeos.so


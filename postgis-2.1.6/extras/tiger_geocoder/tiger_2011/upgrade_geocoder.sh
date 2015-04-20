#!/bin/bash
# $Id: upgrade_geocoder.sh 11969 2013-09-23 04:36:25Z robe $
export PGPORT=5432
export PGHOST=localhost
export PGUSER=postgres
export PGPASSWORD=yourpasswordhere
THEDB=geocoder
PSQL_CMD=/usr/bin/psql
PGCONTRIB=/usr/share/postgresql/contrib
${PSQL_CMD} -d "${THEDB}" -f "upgrade_geocode.sql"

#unremark the loader line to update your loader scripts
#note this wipes out your custom settings in loader_* tables
#${PSQL_CMD} -d "${THEDB}" -f "tiger_loader_2013.sql"
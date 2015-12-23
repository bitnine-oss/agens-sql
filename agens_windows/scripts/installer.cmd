@echo off
REM Agens SQL, Copyright (c) 2015, Bitnine Co., Ltd. All rights reserved.
REM Agens SQL script for Windows

rem set variable from install.xml
set AGENS_HOME=$INSTALL_PATH
set PORT=$PORT
set DATA_DIR=$DATA_PATH

rem create 'data dir'
mkdir "$DATA_PATH"

rem change mod 'data dir' -> similar chmod of Linux
icacls "$DATA_PATH" /grant %USERNAME%:(OI)(CI)F /t /c /q

rem execute initdb
"$INSTALL_PATH\pgsql\bin\initdb.exe" -U agens -D "$DATA_PATH"

rem postgresql.conf file modify
call "$INSTALL_PATH\pgsql\change_port.cmd"

rem start server
"$INSTALL_PATH\pgsql\bin\pg_ctl.exe" -D "$DATA_PATH" -l "$DATA_PATH\server_log.txt" -w start

rem createdb
"$INSTALL_PATH\pgsql\bin\psql.exe" -U agens -d postgres -p $PORT -c "CREATE DATABASE agens"

rem stop server
"$INSTALL_PATH\pgsql\bin\pg_ctl.exe" -D "$DATA_PATH" -l "$DATA_PATH\server_log.txt" -w stop

rem win service register
"$INSTALL_PATH\pgsql\bin\pg_ctl.exe" register -N agens_ctl -D "$INSTALL_PATH\pgsql\data" -S auto

del "$INSTALL_PATH\pgsql\change_port.cmd"
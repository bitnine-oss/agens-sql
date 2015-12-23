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
"$INSTALL_PATH\pgsql\bin\initdb.exe" -U postgres -D "$DATA_PATH"

rem postgresql.conf file modify
call "$INSTALL_PATH\pgsql\pg_change_port.cmd"

rem win service register
"$INSTALL_PATH\pgsql\bin\pg_ctl.exe" register -N pg_ctl -D "$INSTALL_PATH\pgsql\data" -S auto

del "$INSTALL_PATH\pgsql\pg_change_port.cmd"
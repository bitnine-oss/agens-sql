@echo off
REM Agens SQL, Copyright (c) 2015, Bitnine Co., Ltd. All rights reserved.
REM Agens SQL psql runner script for Windows

SET server=localhost
SET /P server="Server [%server%]: "

SET database=postgres
SET /P database="Database [%database%]: "

SET port=$PORT
SET /P port="Port [%port%]: "

SET username=postgres
SET /P username="Username [%username%]: "

REM Run psql
"$INSTALL_PATH\pgsql\bin\psql.exe" -h %server% -U %username% -d %database% -p %port%

pause
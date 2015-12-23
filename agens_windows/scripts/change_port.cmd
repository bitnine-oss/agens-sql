@echo off
REM Agens SQL, Copyright (c) 2015, Bitnine Co., Ltd. All rights reserved.
REM Agens SQL script for Windows
setlocal enabledelayedexpansion

set INTEXTFILE="$DATA_PATH\postgresql.conf"
set OUTTEXTFILE="$DATA_PATH\TMP1.conf"
set OUTTEXTFILE2="$DATA_PATH\TMP2.conf"

set SEARCHTEXT=#port
set REPLACETEXT=port
for /f "tokens=1,* delims=" %%A in ('type %INTEXTFILE%') do (
	SET string=%%A
	SET modified=!string:%SEARCHTEXT%=%REPLACETEXT%!

	echo !modified! >> %OUTTEXTFILE%
)

set SEARCHTEXT=6179
set REPLACETEXT=$PORT
for /f "tokens=1,* delims=" %%A in ('type %OUTTEXTFILE%') do (
	SET string=%%A
	SET modified=!string:%SEARCHTEXT%=%REPLACETEXT%!

	echo !modified! >> %OUTTEXTFILE2%
)

del %INTEXTFILE%
ren %OUTTEXTFILE2% postgresql.conf
del %OUTTEXTFILE%
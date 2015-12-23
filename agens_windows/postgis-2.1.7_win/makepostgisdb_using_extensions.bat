REM this is an example of how to create a new db and spatially enable it using CREATE EXTENSION
set PGPORT=5432
set PGHOST=localhost
set PGUSER=postgres
set PGPASSWORD=yourpasswordhere
set THEDB=example_postgis21
set PGINSTALL=C:\Program Files\PostgreSQL\9.1
REM set PGINSTALL=C:\Program Files (x86)\PostgreSQL\9.1
set PGADMIN=%PGINSTALL%\pgAdmin III
set PGBIN=%PGINSTALL%\bin\
set PGLIB=%PGINSTALL%\lib\
set POSTGISVER=2.1
xcopy bin\*.* "%PGBIN%"
xcopy /I /S bin\postgisgui\* "%PGBIN%\postgisgui"
xcopy /I plugins.d\* "%PGADMIN%\plugins.d"
xcopy lib\*.* "%PGLIB%"
xcopy share\extension\*.* "%PGINSTALL%\share\extension"
xcopy /I /S share\contrib\*.* "%PGINSTALL%\share\contrib"
xcopy /I gdal-data "%PGINSTALL%\gdal-data"
"%PGBIN%\psql"  -c "CREATE DATABASE %THEDB%"
"%PGBIN%\psql"  -d "%THEDB%" -c "CREATE EXTENSION postgis;"
"%PGBIN%\psql"  -d "%THEDB%" -c "CREATE EXTENSION postgis_topology;"

REM Uncomment the below line if this is a template database
REM "%PGBIN%\psql" -d "%THEDB%" -c "UPDATE pg_database SET datistemplate = true WHERE datname = '%THEDB%';GRANT ALL ON geometry_columns TO PUBLIC; GRANT ALL ON spatial_ref_sys TO PUBLIC"


pause
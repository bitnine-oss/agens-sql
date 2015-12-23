set PGPORT=5432
set PGHOST=localhost
set PGUSER=postgres
set PGPASSWORD=yourpasswordhere
set THEDB=template_postgis21
set PGINSTALL=C:\Program Files\PostgreSQL\9.1
REM set PGINSTALL=C:\Program Files (x86)\PostgreSQL\9.1
set PGADMIN=%PGINSTALL%\pgAdmin III
set PGBIN=%PGINSTALL%\bin\
set PGLIB=%PGINSTALL%\lib\
set POSTGISVER=2.1
xcopy bin\*.* "%PGBIN%"
xcopy /I /S bin\postgisgui\* "%PGBIN%\postgisgui"
xcopy /I /S share\contrib\postgis-%POSTGISVER% "%PGINSTALL%\share\contrib\postgis-%POSTGISVER%"
xcopy /I plugins.d\* "%PGADMIN%\plugins.d"
xcopy lib\*.* "%PGLIB%"
xcopy /I gdal-data "%PGINSTALL%\gdal-data"
"%PGBIN%\psql"  -c "CREATE DATABASE %THEDB%"
"%PGBIN%\psql"  -d "%THEDB%" -c "CREATE LANGUAGE plpgsql"
"%PGBIN%\psql"  -d "%THEDB%" -f "share\contrib\postgis-%POSTGISVER%\postgis.sql"
"%PGBIN%\psql"  -d "%THEDB%" -f "share\contrib\postgis-%POSTGISVER%\spatial_ref_sys.sql"
"%PGBIN%\psql"  -d "%THEDB%" -f "share\contrib\postgis-%POSTGISVER%\postgis_comments.sql"

REM installs raster support
"%PGBIN%\psql"  -d "%THEDB%" -f "share\contrib\postgis-%POSTGISVER%\rtpostgis.sql"
"%PGBIN%\psql"  -d "%THEDB%" -f "share\contrib\postgis-%POSTGISVER%\raster_comments.sql"

REM installs topology support
"%PGBIN%\psql"  -d "%THEDB%" -f "share\contrib\postgis-%POSTGISVER%\topology.sql"
"%PGBIN%\psql"  -d "%THEDB%" -f "share\contrib\postgis-%POSTGISVER%\topology_comments.sql"

REM Uncomment the below line if this is a template database
REM "%PGBIN%\psql" -d "%THEDB%" -c "UPDATE pg_database SET datistemplate = true WHERE datname = '%THEDB%';GRANT ALL ON geometry_columns TO PUBLIC; GRANT ALL ON spatial_ref_sys TO PUBLIC"


pause
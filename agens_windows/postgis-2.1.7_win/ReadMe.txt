## INTRODUCTION
pgRouting is a network routing extension for PostgreSQL that works with PostGIS
This package is for PostGIS 2.0,2.1
More details can be found at: http://pgrouting.org/

pgRouting extends the PostGIS/PostgreSQL geospatial database to provide geospatial routing and other network analysis functionality.

This 2.0 library contains following features:

    All Pairs Shortest Path, Johnson Algorithm (new 2.0)
    All Pairs Shortest Path, Floyd-Warshall Algorithm (new 2.0)
    Shortest Path A*
    Bi-directional Dijkstra Shortest Path (new 2.0)
    Bi-directional A* Shortest Path (new 2.0)
    Shortest Path Dijkstra
    Driving Distance
    K-Shortest Path, Multiple Alternative Paths (new 2.0)
    K-Dijkstra, One to Many Shortest Path (new 2.0)
    Traveling Sales Person (enhanced 2.0)
    Turn Restriction Shortest Path (TRSP) (new 2.0)

## INSTALL
To install first create a postgresql database using createdb, psql, or pgAdmin
Copy the files from this zip file to same named folders in your PostgreSQL install.

Install PostGIS 2.0 or 2.1 using:
CREATE EXTENSION postgis;

If you have multiple versions of PostGIS and want to force a particular version do:
--For latest stable
CREATE EXTENSION postgis VERSION "2.0.4";

--For latest dev
CREATE EXTENSION postgis VERSION "2.1.0";

Then install pgRouting:

CREATE EXTENSION pgrouting;


## FOR THOSE WHO WANT TO COMPILE THEMSELVES 
These were built using
* These binaries are compiled from source
   at git@github.com:pgRouting/pgrouting.git
git clone https://github.com/pgRouting/pgrouting.git
git checkout develop

If building for 32-bit download http://www.bostongis.com/postgisstuff/ming32.zip
If building for 64-bit download http://www.bostongis.com/postgisstuff/ming64.zip
Download cmake windows binaries from http://cmake.org/cmake/resources/software.html, extract the zip and copy to
 c:\ming32\projects\cmake-2.8.10.2-win32-x86 (or ming64 folder)
 
To rebuild, you can modify the packaged scripts in tools/
makedependanciesw64.sh  - how to build the dependencies
makepgroutingw32.sh          - how to build under ming32
makepgroutingw64.sh          - how to build under ming64

Once built to get rid of all the debug weight: 
cd build/lib
strip *.dll
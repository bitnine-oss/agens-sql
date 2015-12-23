-- pgRouting version '2.0.0' extension for postgresql
-- built WITH_DD = ON
-- Complain if script is sourced in pgsql, rather than CREATE EXTENSION

--  pgRouting 2.0 types


CREATE TYPE pgr_costResult AS
(
    seq integer,
    id1 integer,
    id2 integer,
    cost float8
);

CREATE TYPE pgr_costResult3 AS
(
    seq integer,
    id1 integer,
    id2 integer,
    id3 integer,
    cost float8
);

CREATE TYPE pgr_geomResult AS
(
    seq integer,
    id1 integer,
    id2 integer,
    geom geometry
);

CREATE OR REPLACE FUNCTION pgr_version()
RETURNS TABLE(
		"version" varchar, 
		tag varchar,
		build varchar,
		hash varchar,
		branch varchar,
		boost varchar
	) AS
$BODY$
/*
.. function:: pgr_version()

   Author: Stephen Woodbridge <woodbri@imaptools.com>

   Returns the version of pgrouting,Git build,Git hash, Git branch and boost
*/

DECLARE

BEGIN
    RETURN QUERY SELECT '2.0.0'::varchar AS version, 
    					'pgrouting-2.0.0'::varchar AS tag, 
                        '0'::varchar AS build, 
                        'f26831f'::varchar AS hash, 
                        'master'::varchar AS branch, 
                        '1.53.0'::varchar AS boost;
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE;

-- -------------------------------------------------------------------
-- pgrouting_utilities.sql
-- AuthorL Stephen Woodbridge <woodbri@imaptools.com>
-- Copyright 2013 Stephen Woodbridge
-- This file is release unde an MIT-X license.
-- -------------------------------------------------------------------


/*
.. function:: pgr_getTableName(tab)
   
   Examples:  
	* 	 select * from  pgr_getTableName('tab');
        *        naming record;
		 excecute 'select * from  pgr_getTableName('||quote_literal(tab)||')' INTO naming;
	         schema=naming.sname; table=naming.tname
		   

   Returns (schema,name) of table "tab" considers Caps and when not found considers lowercases
           (schema,NULL) when table was not found 
           (NULL,NULL) when schema was not found. 

   Author: Vicky Vergara <vicky_vergara@hotmail.com>>

  HISTORY
     Created: 2013/08/19  for handling schemas

*/
CREATE OR REPLACE FUNCTION pgr_getTableName(IN tab text,OUT sname text,OUT tname text)
  RETURNS RECORD AS
$BODY$ 
DECLARE
	naming record;
	i integer;
	query text;
        sn text;
        tn text;
BEGIN

    execute 'select strpos('||quote_literal(tab)||','||quote_literal('.')||')' into i;
    if (i!=0) then 
	execute 'select substr('||quote_literal(tab)||',1,strpos('||quote_literal(tab)||','||quote_literal('.')||')-1)' into sn;
	execute 'select substr('||quote_literal(tab)||',strpos('||quote_literal(tab)||','||quote_literal('.')||')+1),length('||quote_literal(tab)||')' into tn;
    else 
        execute 'select current_schema' into sn;
        tn =tab;
    end if;
    
    
    EXECUTE 'SELECT schema_name FROM information_schema.schemata WHERE schema_name = '||quote_literal(sn) into naming;
    sname=naming.schema_name;
    
    if sname is NOT NULL THEN -- found schema (as is)
    	EXECUTE 'select table_name from information_schema.tables where 
		table_type='||quote_literal('BASE TABLE')||' and 
		table_schema='||quote_literal(sname)||' and 
		table_name='||quote_literal(tn) INTO  naming;
	tname=naming.table_name;	
	IF tname is NULL THEN
	   EXECUTE 'select table_name from information_schema.tables where 
		table_type='||quote_literal('BASE TABLE')||' and 
		table_schema='||quote_literal(sname)||' and 
		table_name='||quote_literal(lower(tn))||'order by table_name' INTO naming;
	   tname=naming.table_name;		
	END IF;
    END IF;	 
    IF sname is NULL or tname is NULL THEN 	--schema not found or table in schema was not found        	
	EXECUTE 'SELECT schema_name FROM information_schema.schemata WHERE schema_name = '||quote_literal(lower(sn)) into naming;
	sname=naming.schema_name;
	if sname is NOT NULL THEN -- found schema (with lower caps)	
	   EXECUTE 'select table_name from information_schema.tables where 
		table_type='||quote_literal('BASE TABLE')||' and 
		table_schema='||quote_literal(sname)||' and 
		table_name='||quote_literal(tn) INTO  naming;
	   tname=naming.table_name;	
	   IF tname is NULL THEN
		EXECUTE 'select table_name from information_schema.tables where 
			table_type='||quote_literal('BASE TABLE')||' and 
			table_schema='||quote_literal(sname)||' and 
			table_name='||quote_literal(lower(tn))||'order by table_name' INTO naming;
		tname=naming.table_name;		
	   END IF;
	END IF;
    END IF;	   
	        	
END;
$BODY$
LANGUAGE plpgsql VOLATILE STRICT;
COMMENT ON FUNCTION pgr_getTableName(text) IS 'args: tab  -gets the schema (sname) and the table (tname) form the table tab';


/*
.. function:: pgr_getColumnName(tab,col)
   
   Examples:  
	* 	 select  pgr_getColumnName('tab','col');
        *        column text;
		 excecute 'select pgr_getColumnName('||quote_literal('tab')||','||quote_literal('col')||')' INTO column;


   Returns cname of column "col" in table "tab" considers Caps and when not found considers lowercases
           NULL when "tab" is not found or when "col" is not in table "tab"

   Author: Vicky Vergara <vicky_vergara@hotmail.com>>

  HISTORY
     Created: 2013/08/19  for handling schemas
*/
CREATE OR REPLACE FUNCTION pgr_getColumnName(tab text, col text)
RETURNS text AS
$BODY$
DECLARE
    sname text;
    tname text;
    cname text;
    naming record;
BEGIN
    select * into naming from pgr_getTableName(tab) ;
    sname=naming.sname;
    tname=naming.tname;
   
    IF sname IS NULL or tname IS NULL THEN
        RETURN NULL;
    ELSE 
        SELECT column_name INTO cname
          FROM information_schema.columns 
          WHERE table_name=tname and table_schema=sname and column_name=col;

        IF FOUND THEN
          RETURN cname;
        ELSE
            SELECT column_name INTO cname
		FROM information_schema.columns 
		WHERE table_name=tname and table_schema=sname and column_name=lower(col);
            IF FOUND THEN
		RETURN cname;
	    ELSE
		RETURN NULL;
	    END IF;
        END IF;
    END IF;
END;
$BODY$
LANGUAGE plpgsql VOLATILE STRICT;
COMMENT ON FUNCTION pgr_getColumnName(text,text) IS 'args: tab,col  -gets the registered column name of "col" in table "tab"';





/*
.. function:: pgr_isColumnInTable(tab, col)

   Examples:  
	* 	 select  pgr_isColumnName('tab','col');
        *        flag boolean;
		 excecute 'select pgr_getColumnName('||quote_literal('tab')||','||quote_literal('col')||')' INTO flag;

   Returns true  if column "col" exists in table "tab"
           false when "tab" doesn't exist or when "col" is not in table "tab"

   Author: Stephen Woodbridge <woodbri@imaptools.com>

   Modified by: Vicky Vergara <vicky_vergara@hotmail.com>>

  HISTORY
     Modified: 2013/08/19  for handling schemas
*/
CREATE OR REPLACE FUNCTION pgr_isColumnInTable(tab text, col text)
RETURNS boolean AS
$BODY$
DECLARE
    cname text;
BEGIN
    select * from pgr_getColumnName(tab,col) into cname;
  
    IF cname IS NULL THEN
        RETURN false;
    ELSE
        RETURN true;
    END IF;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE STRICT;
COMMENT ON FUNCTION pgr_isColumnInTable(text,text) IS 'args: tab,col  -returns true when the column "col" is in table "tab"';


/*
.. function:: pgr_isColumnIndexed(tab, col)

   Examples:  
	* 	 select  pgr_isColumnIndexed('tab','col');
        *        flag boolean;
		 excecute 'select pgr_getColumnIndexed('||quote_literal('tab')||','||quote_literal('col')||')' INTO flag;

   Author: Stephen Woodbridge <woodbri@imaptools.com>

   Modified by: Vicky Vergara <vicky_vergara@hotmail.com>>

   Returns true  when column "col" in table "tab" is indexed.
           false when table "tab"  is not found or 
                 when column "col" is nor found in table "tab" or
	  	 when column "col" is not indexed

*/
CREATE OR REPLACE FUNCTION public.pgr_isColumnIndexed(tab text, col text)
RETURNS boolean AS
$BODY$
DECLARE
    naming record;
    rec record;
    sname text;
    tname text;
    cname text;
    pkey text;
BEGIN
    SELECT * into naming FROM pgr_getTableName(tab);
    sname=naming.sname;
    tname=naming.tname;
    IF sname IS NULL OR tname IS NULL THEN
	RETURN FALSE;
    END IF;
    SELECT pgr_getColumnName(tab,col) INTO cname;
    IF cname IS NULL THEN
	RETURN FALSE;
    END IF;
    SELECT               
          pg_attribute.attname into pkey
         --  format_type(pg_attribute.atttypid, pg_attribute.atttypmod) 
          FROM pg_index, pg_class, pg_attribute 
          WHERE 
                  pg_class.oid = pgr_quote_ident(sname||'.'||tname)::regclass AND
                  indrelid = pg_class.oid AND
                  pg_attribute.attrelid = pg_class.oid AND 
                  pg_attribute.attnum = any(pg_index.indkey)
                  AND indisprimary;
        
    IF pkey=cname then
          RETURN TRUE; 
    END IF;
                      

   
    SELECT a.index_name, 
           b.attname,
           b.attnum,
           a.indisunique,
           a.indisprimary
      INTO rec
      FROM ( SELECT a.indrelid,
                    a.indisunique,
                    a.indisprimary, 
                    c.relname index_name, 
                    unnest(a.indkey) index_num 
               FROM pg_index a,
                    pg_class b, 
                    pg_class c,
                    pg_namespace d  
              WHERE b.relname=tname
                AND b.relnamespace=d.oid
                AND d.nspname=sname 
                AND b.oid=a.indrelid 
                AND a.indexrelid=c.oid 
           ) a, 
           pg_attribute b 
     WHERE a.indrelid = b.attrelid 
       AND a.index_num = b.attnum 
       AND b.attname = cname
  ORDER BY a.index_name, 
           a.index_num;

    IF FOUND THEN
        RETURN true;
    ELSE
        RETURN false;
    END IF;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE STRICT;
COMMENT ON FUNCTION pgr_isColumnIndexed(text,text) IS 'args: tab,col  -returns true if column "col" in table "tab" is indexed';





create or replace function pgr_quote_ident(idname text)
    returns text as
$body$
/*
.. function:: pgr_quote_ident(text)

   Author: Stephen Woodbridge <woodbri@imaptools.com>

   Function to split a string on '.' characters and then quote the 
   components as postgres identifiers and then join them back together
   with '.' characters. multile '.' will get collapsed into a single
   '.' so 'schema...table' till get returned as 'schema."table"' and 
   'Schema.table' becomes '"Schema'.'table"'

*/

declare
    t text[];
    pgver text;

begin
    pgver := regexp_replace(version(), E'^PostgreSQL ([^ ]+)[ ,].*$', E'\\1');

/*
    RAISE NOTICE 'pgr_quote_ident(%), pgver: %, version: %, versionless %',
        tab, pgver, version(), pgr_versionless(pgver, '9.2');
*/

    if pgr_versionless(pgver, '9.2') then
        select into t array_agg(quote_ident(term)) from
            (select nullif(unnest, '') as term
               from unnest(string_to_array(idname, '.'))) as foo;
    else
        select into t array_agg(quote_ident(term)) from
            (select unnest(string_to_array(idname, '.', '')) as term) as foo;
    end if;
    return array_to_string(t, '.');
end;
$body$
language plpgsql immutable;
COMMENT ON function pgr_quote_ident(text) IS 'args: idname  -  quote_ident to all parts of the identifier "idname"';


CREATE OR REPLACE FUNCTION pgr_versionless(v1 text, v2 text)
  RETURNS boolean AS
$BODY$
/*
 * function for comparing version strings.
 * Ex: select pgr_version_less(postgis_lib_version(), '2.1');

   Author: Stephen Woodbridge <woodbri@imaptools.com>
 *
 * needed because postgis 2.1 deprecates some function names and
 * we need to detect the version at runtime
*/

declare
    v1a text[];
    v2a text[];
    nv1 integer;
    nv2 integer;
    ne1 integer;
    ne2 integer;
    
begin
    -- separate components into an array, like:
    -- '2.1.0-beta3dev'  =>  {2,1,0,beta3dev}
    v1a := regexp_matches(v1, E'^(\\d+)(?:[\\.](\\d+))?(?:[\\.](\\d+))?[-+\\.]?(.*)$');
    v2a := regexp_matches(v2, E'^(\\d+)(?:[\\.](\\d+))?(?:[\\.](\\d+))?[-+\\.]?(.*)$');

    -- convert modifiers to numbers for comparison
    -- we do not delineate between alpha1, alpha2, alpha3, etc
    ne1 := case when v1a[4] is null or v1a[4]='' then 5
                when v1a[4] ilike 'rc%' then 4
                when v1a[4] ilike 'beta%' then 3
                when v1a[4] ilike 'alpha%' then 2
                when v1a[4] ilike 'dev%' then 1
                else 0 end;

    ne2 := case when v2a[4] is null or v2a[4]='' then 5
                when v2a[4] ilike 'rc%' then 4
                when v2a[4] ilike 'beta%' then 3
                when v2a[4] ilike 'alpha%' then 2
                when v2a[4] ilike 'dev%' then 1
                else 0 end;

    nv1 := v1a[1]::integer * 10000 +
           coalesce(v1a[2], '0')::integer * 1000 +
           coalesce(v1a[3], '0')::integer *  100 + ne1;
    nv2 := v2a[1]::integer * 10000 + 
           coalesce(v2a[2], '0')::integer * 1000 + 
           coalesce(v2a[3], '0')::integer *  100 + ne2;

    --raise notice 'nv1: %, nv2: %, ne1: %, ne2: %', nv1, nv2, ne1, ne2;

    return nv1 < nv2;
end;
$BODY$
  LANGUAGE plpgsql IMMUTABLE STRICT
  COST 1;
COMMENT ON function pgr_versionless(text,text) IS 'args: v1,v2  - returns true when v1 < v2';


create or replace function pgr_startPoint(g geometry)
    returns geometry as
$body$
declare

begin
    if geometrytype(g) ~ '^MULTI' then
        return st_startpoint(st_geometryn(g,1));
    else
        return st_startpoint(g);
    end if;
end;
$body$
language plpgsql IMMUTABLE;
COMMENT ON function pgr_startPoint(geometry) IS 'args: g  - returns start point of the geometry "g" even if its multi';



create or replace function pgr_endPoint(g geometry)
    returns geometry as
$body$
declare

begin
    if geometrytype(g) ~ '^MULTI' then
        return st_endpoint(st_geometryn(g,1));
    else
        return st_endpoint(g);
    end if;
end;
$body$
language plpgsql IMMUTABLE;
COMMENT ON function pgr_endPoint(geometry) IS 'args: g  - returns end point of the geometry "g" even if its multi';


/*
.. function:: pgr_pointToId(point geometry, tolerance double precision,vname text,srid integer)

  This function should not be used directly. Use assign_vertex_id instead
 
  Inserts a point into the vertices tablei "vname" with the srid "srid", and return an id
  of a new point or an existing point. Tolerance is the minimal distance
  between existing points and the new point to create a new point.

 Last changes: 2013-03-22
 Author: Christian Gonzalez
 Author: Stephen Woodbridge <woodbri@imaptools.com>
 Modified by: Vicky Vergara <vicky_vergara@hotmail,com>

 HISTORY
    Last changes: 2013-03-22
    2013-08-19:  handling schemas
*/

CREATE OR REPLACE FUNCTION pgr_pointToId(point geometry, tolerance double precision,vertname text,srid integer)
  RETURNS bigint AS
$BODY$ 
DECLARE
    rec record; 
    pid bigint; 

BEGIN
    execute 'SELECT ST_Distance(the_geom,ST_GeomFromText(st_astext('||quote_literal(point::text)||'),'||srid||')) AS d, id, the_geom
        FROM '||pgr_quote_ident(vertname)||'
        WHERE ST_DWithin(the_geom, ST_GeomFromText(st_astext('||quote_literal(point::text)||'),'||srid||'),'|| tolerance||')
        ORDER BY d
        LIMIT 1' INTO rec ;
    IF rec.id is not null THEN
        pid := rec.id;
    ELSE
        execute 'INSERT INTO '||pgr_quote_ident(vertname)||' (the_geom) VALUES ('||quote_literal(point::text)||')';
        pid := lastval();
    END IF;

    RETURN pid;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE STRICT;
COMMENT ON FUNCTION pgr_pointToId(geometry,double precision, text,integer) IS 'args: point geometry,tolerance,verticesTable,srid - inserts the point into the vertices table using tolerance to determine if its an existing point and returns the id assigned to it' ;


/*
.. function:: pgr_createtopology(edge_table, tolerance,the_geom,id,source,target,rows_where)

  Fill the source and target column for all lines. All line ends
  with a distance less than tolerance, are assigned the same id

  Author: Christian Gonzalez <christian.gonzalez@sigis.com.ve>
  Author: Stephen Woodbridge <woodbri@imaptools.com>
  Modified by: Vicky Vergara <vicky_vergara@hotmail,com>

 HISTORY
    Last changes: 2013-03-22
    2013-08-19:  handling schemas
*/

CREATE OR REPLACE FUNCTION pgr_createtopology(edge_table text, tolerance double precision, 
			   the_geom text default 'the_geom', id text default 'id',
			   source text default 'source', target text default 'target',rows_where text default 'true')
  RETURNS VARCHAR AS
$BODY$

DECLARE
    points record;
    sridinfo record;
    source_id bigint;
    target_id bigint;
    totcount bigint;
    rowcount bigint;
    srid integer;
    sql text;
    sname text;
    tname text;
    tabname text;
    vname text;
    vertname text;
    gname text;
    idname text;
    sourcename text;
    targetname text;
    notincluded integer;
    i integer;
    naming record;
    flag boolean;
    query text;
    sourcetype  text;
    targettype text;
    debuglevel text;

BEGIN
  raise notice 'PROCESSING:'; 
  raise notice 'pgr_createTopology(''%'',%,''%'',''%'',''%'',''%'',''%'')',edge_table,tolerance,the_geom,id,source,target,rows_where;
  raise notice 'Performing checks, pelase wait .....';
  execute 'show client_min_messages' into debuglevel;


  BEGIN
    RAISE DEBUG 'Cheking % exists',edge_table;
    execute 'select * from pgr_getTableName('||quote_literal(edge_table)||')' into naming;
    sname=naming.sname;
    tname=naming.tname;
    IF sname IS NULL OR tname IS NULL THEN
	RAISE NOTICE '-------> % not found',edge_table;
        RETURN 'FAIL';
    ELSE
	RAISE DEBUG '  -----> OK';
    END IF;
  
    tabname=sname||'.'||tname;
    vname=tname||'_vertices_pgr';
    vertname= sname||'.'||vname;
    rows_where = ' AND ('||rows_where||')'; 
  END;

  BEGIN 
       raise DEBUG 'Checking id column "%" columns in  % ',id,tabname;
       EXECUTE 'select pgr_getColumnName('||quote_literal(tabname)||','||quote_literal(the_geom)||')' INTO gname;
       EXECUTE 'select pgr_getColumnName('||quote_literal(tabname)||','||quote_literal(id)||')' INTO idname;
       IF idname is NULL then
          raise notice  'ERROR: id column "%"  not found in %',id,tabname;
          RETURN 'FAIL';
       END IF;
       raise DEBUG 'Checking geometry column "%" column  in  % ',the_geom,tabname;
       IF gname is not NULL then
    	  BEGIN
        	raise DEBUG 'Checking the SRID of the geometry "%"', gname;
        	query= 'SELECT ST_SRID(' || quote_ident(gname) || ') as srid '
           		|| ' FROM ' || pgr_quote_ident(tabname)
           		|| ' WHERE ' || quote_ident(gname)
           		|| ' IS NOT NULL LIMIT 1';
                EXECUTE QUERY
           		INTO sridinfo;

        	IF sridinfo IS NULL OR sridinfo.srid IS NULL THEN
            		RAISE NOTICE 'ERROR: Can not determine the srid of the geometry "%" in table %', the_geom,tabname;
            		RETURN 'FAIL';
        	END IF;
        	srid := sridinfo.srid;
        	raise DEBUG '  -----> SRID found %',srid;
        	EXCEPTION WHEN OTHERS THEN
            		RAISE NOTICE 'ERROR: Can not determine the srid of the geometry "%" in table %', the_geom,tabname;
            		RETURN 'FAIL';
    	  END;
        ELSE 
                raise notice  'ERROR: Geometry column "%"  not found in %',the_geom,tabname;
                RETURN 'FAIL';
        END IF;
  END;

  BEGIN 
       raise DEBUG 'Checking source column "%" and target column "%"  in  % ',source,target,tabname;
       EXECUTE 'select  pgr_getColumnName('||quote_literal(tabname)||','||quote_literal(source)||')' INTO sourcename;
       EXECUTE 'select  pgr_getColumnName('||quote_literal(tabname)||','||quote_literal(target)||')' INTO targetname;
       IF sourcename is not NULL and targetname is not NULL then
                --check that the are integer
                EXECUTE 'select data_type  from information_schema.columns where table_name = '||quote_literal(tname)||
                        ' and table_schema='||quote_literal(sname)||' and column_name='||quote_literal(sourcename) into sourcetype;
                EXECUTE 'select data_type  from information_schema.columns where table_name = '||quote_literal(tname)||
                        ' and table_schema='||quote_literal(sname)||' and column_name='||quote_literal(targetname) into targettype;
                IF sourcetype not in('integer','smallint','bigint')  THEN
          	    raise notice  'ERROR: source column "%" is not of integer type',sourcename;
          	    RETURN 'FAIL';
                END IF;
                IF targettype not in('integer','smallint','bigint')  THEN
          	    raise notice  'ERROR: target column "%" is not of integer type',targetname;
          	    RETURN 'FAIL';
                END IF;
                raise DEBUG  '  ------>OK '; 
       END IF;
       IF sourcename is NULL THEN
          	raise notice  'ERROR: source column "%"  not found in %',source,tabname;
          	RETURN 'FAIL';
       END IF;
       IF targetname is NULL THEN
          	raise notice  'ERROR: target column "%"  not found in %',target,tabname;
          	RETURN 'FAIL';
       END IF;
  END;

    
       IF sourcename=targetname THEN
		raise notice  'ERROR: source and target columns have the same name "%" in %',target,tabname;
                RETURN 'FAIL';
       END IF;
       IF sourcename=idname THEN
		raise notice  'ERROR: source and id columns have the same name "%" in %',target,tabname;
                RETURN 'FAIL';
       END IF;
       IF targetname=idname THEN
		raise notice  'ERROR: target and id columns have the same name "%" in %',target,tabname;
                RETURN 'FAIL';
       END IF;


    BEGIN
      RAISE DEBUG 'Cheking "%" column in % is indexed',idname,tabname;
      if (pgr_isColumnIndexed(tabname,idname)) then 
	RAISE DEBUG '  ------>OK';
      else 
        RAISE DEBUG ' ------> Adding  index "%_%_idx".',tabname,idname;
        set client_min_messages  to warning;
        execute 'create  index '||pgr_quote_ident(tname||'_'||idname||'_idx')||' 
                         on '||pgr_quote_ident(tabname)||' using btree('||quote_ident(idname)||')';
        execute 'set client_min_messages  to '|| debuglevel;
      END IF;
    END;

    BEGIN
      RAISE DEBUG 'Cheking "%" column in % is indexed',sourcename,tabname;
      if (pgr_isColumnIndexed(tabname,sourcename)) then 
	RAISE DEBUG '  ------>OK';
      else 
        RAISE DEBUG ' ------> Adding  index "%_%_idx".',tabname,sourcename;
        set client_min_messages  to warning;
        execute 'create  index '||pgr_quote_ident(tname||'_'||sourcename||'_idx')||' 
                         on '||pgr_quote_ident(tabname)||' using btree('||quote_ident(sourcename)||')';
        execute 'set client_min_messages  to '|| debuglevel;
      END IF;
    END;

    BEGIN
      RAISE DEBUG 'Cheking "%" column in % is indexed',targetname,tabname;
      if (pgr_isColumnIndexed(tabname,targetname)) then 
	RAISE DEBUG '  ------>OK';
      else 
        RAISE DEBUG ' ------> Adding  index "%_%_idx".',tabname,targetname;
        set client_min_messages  to warning;
        execute 'create  index '||pgr_quote_ident(tname||'_'||targetname||'_idx')||' 
                         on '||pgr_quote_ident(tabname)||' using btree('||quote_ident(targetname)||')';
        execute 'set client_min_messages  to ' ||debuglevel;
      END IF;
    END;

    BEGIN
      RAISE DEBUG 'Cheking "%" column in % is indexed',gname,tabname;
      if (pgr_iscolumnindexed(tabname,gname)) then 
	RAISE DEBUG '  ------>OK';
      else 
        RAISE DEBUG ' ------> Adding unique index "%_%_gidx".',tabname,gname;
        set client_min_messages  to warning;
        execute 'CREATE INDEX '
            || quote_ident(tname || '_' || gname || '_gidx' )
            || ' ON ' || pgr_quote_ident(tabname)
            || ' USING gist (' || quote_ident(gname) || ')';
        execute 'set client_min_messages  to '|| debuglevel;
      END IF;
    END;
       gname=quote_ident(gname);
       idname=quote_ident(idname);
       sourcename=quote_ident(sourcename);
       targetname=quote_ident(targetname);


    
    BEGIN
       raise DEBUG 'initializing %',vertname;
       execute 'select * from pgr_getTableName('||quote_literal(vertname)||')' into naming;
       IF sname=naming.sname  AND vname=naming.tname  THEN
           execute 'TRUNCATE TABLE '||pgr_quote_ident(vertname)||' RESTART IDENTITY';
           execute 'SELECT DROPGEOMETRYCOLUMN('||quote_literal(sname)||','||quote_literal(vname)||','||quote_literal('the_geom')||')';
       ELSE
           set client_min_messages  to warning;
       	   execute 'CREATE TABLE '||pgr_quote_ident(vertname)||' (id bigserial PRIMARY KEY,cnt integer,chk integer,ein integer,eout integer)';
       END IF;
       execute 'select addGeometryColumn('||quote_literal(sname)||','||quote_literal(vname)||','||
                quote_literal('the_geom')||','|| srid||', '||quote_literal('POINT')||', 2)';
       execute 'CREATE INDEX '||quote_ident(vname||'_the_geom_idx')||' ON '||pgr_quote_ident(vertname)||'  USING GIST (the_geom)';
       execute 'set client_min_messages  to '|| debuglevel;
       raise DEBUG  '  ------>OK'; 
    END;       

  
  BEGIN 
    sql = 'select * from '||pgr_quote_ident(tabname)||' WHERE true'||rows_where ||' limit 1';
    EXECUTE sql into i;
    sql = 'select count(*) from '||pgr_quote_ident(tabname)||' WHERE (' || gname || ' IS NOT NULL AND '||
		idname||' IS NOT NULL)=false '||rows_where;
    EXECUTE SQL  into notincluded;
    EXCEPTION WHEN OTHERS THEN  BEGIN
         RAISE NOTICE 'ERROR: Condition is not correct, please execute the following query to test your condition'; 
         RAISE NOTICE '%',sql;
         RETURN 'FAIL'; 
    END;
  END;    


    BEGIN
    raise notice 'Creating Topology, Please wait...';
    execute 'UPDATE ' || pgr_quote_ident(tabname) ||
            ' SET '||sourcename||' = NULL,'||targetname||' = NULL'; 
    rowcount := 0;
    FOR points IN EXECUTE 'SELECT ' || idname || '::bigint AS id,'
        || ' PGR_StartPoint(' || gname || ') AS source,'
        || ' PGR_EndPoint('   || gname || ') AS target'
        || ' FROM '  || pgr_quote_ident(tabname)
        || ' WHERE ' || gname || ' IS NOT NULL AND ' || idname||' IS NOT NULL '||rows_where
    LOOP

        rowcount := rowcount + 1;
        IF rowcount % 1000 = 0 THEN
            RAISE NOTICE '% edges processed', rowcount;
        END IF;


        source_id := pgr_pointToId(points.source, tolerance,vertname,srid);
        target_id := pgr_pointToId(points.target, tolerance,vertname,srid);
        BEGIN                         
        sql := 'UPDATE ' || pgr_quote_ident(tabname) || 
            ' SET '||sourcename||' = '|| source_id::text || ','||targetname||' = ' || target_id::text || 
            ' WHERE ' || idname || ' =  ' || points.id::text;

        IF sql IS NULL THEN
            RAISE NOTICE 'WARNING: UPDATE % SET source = %, target = % WHERE % = % ', tabname, source_id::text, target_id::text, idname,  points.id::text;
        ELSE
            EXECUTE sql;
        END IF;
        EXCEPTION WHEN OTHERS THEN 
            RAISE NOTICE '%', SQLERRM;
            RAISE NOTICE '%',sql;
            RETURN 'FAIL'; 
        end;
    END LOOP;
    raise notice '-------------> TOPOLOGY CREATED FOR  % edges', rowcount;
    RAISE NOTICE 'Rows with NULL geometry or NULL id: %',notincluded;
    Raise notice 'Vertices table for table % is: %',pgr_quote_ident(tabname),pgr_quote_ident(vertname);
    raise notice '----------------------------------------------';
    END;
    RETURN 'OK';

END;


$BODY$
LANGUAGE plpgsql VOLATILE STRICT;
COMMENT ON FUNCTION pgr_createTopology(text, double precision,text,text,text,text,text) 
IS 'args: edge_table,tolerance, the_geom:=''the_geom'',source:=''source'', target:=''target'',rows_where:=''true'' - fills columns source and target in the geometry table and creates a vertices table for selected rows';




/*------------------------------------------------*/


/*
.. function:: pgr_createVerticesTable(edge_table text, the_geom text, source text default 'source', target text default 'target')

  Based on "source" and "target" columns creates the vetrices_pgr table for edge_table
  Ignores rows where "source" or "target" have NULL values 

  Author: Vicky Vergara <vicky_vergara@hotmail,com>

 HISTORY
    Created 2013-08-19
*/

CREATE OR REPLACE FUNCTION pgr_createverticestable(edge_table text, the_geom text DEFAULT 'the_geom'::text, source text DEFAULT 'source'::text, target text DEFAULT 'target'::text, rows_where text DEFAULT 'true'::text)
  RETURNS text AS
$BODY$
DECLARE
    naming record;
    sridinfo record;
    sname text;
    tname text;
    tabname text;
    vname text;
    vertname text;
    gname text;
    sourcename text;
    targetname text;
    query text;
    ecnt integer; 
    srid integer;
    sourcetype text;
    targettype text;
    sql text;
    totcount integer;
    i integer;
    notincluded integer;
    included integer;
    debuglevel text;

BEGIN 
  raise notice 'PROCESSING:'; 
  raise notice 'pgr_createVerticesTable(''%'',''%'',''%'',''%'',''%'')',edge_table,the_geom,source,target,rows_where;
  raise notice 'Performing checks, pelase wait .....';
  execute 'show client_min_messages' into debuglevel;

  BEGIN
    RAISE DEBUG 'Cheking % exists',edge_table;
    execute 'select * from pgr_getTableName('||quote_literal(edge_table)||')' into naming;
    sname=naming.sname;
    tname=naming.tname;
    IF sname IS NULL OR tname IS NULL THEN
	RAISE NOTICE '-------> % not found',edge_table;
        RETURN 'FAIL';
    ELSE
	RAISE DEBUG '  -----> OK';
    END IF;
  
    tabname=sname||'.'||tname;
    vname=tname||'_vertices_pgr';
    vertname= sname||'.'||vname;
    rows_where = ' AND ('||rows_where||')'; 
  END;


  BEGIN 
       EXECUTE 'select pgr_getColumnName('||quote_literal(tabname)||','||quote_literal(the_geom)||')' INTO gname;
       raise DEBUG 'Checking geometry column "%" column  in  % ',the_geom,tabname;
       IF gname is not NULL then
    	  BEGIN
        	raise DEBUG 'Checking the SRID of the geometry "%"', gname;
        	EXECUTE 'SELECT ST_SRID(' || quote_ident(gname) || ') as srid '
           		|| ' FROM ' || pgr_quote_ident(tabname)
           		|| ' WHERE ' || quote_ident(gname)
           		|| ' IS NOT NULL LIMIT 1'
           		INTO sridinfo;

        	IF sridinfo IS NULL OR sridinfo.srid IS NULL THEN
            		RAISE NOTICE 'ERROR: Can not determine the srid of the geometry "%" in table %', the_geom,tabname;
            		RETURN 'FAIL';
        	END IF;
        	srid := sridinfo.srid;
        	raise DEBUG '  -----> SRID found %',srid;
        	EXCEPTION WHEN OTHERS THEN
            		RAISE NOTICE 'ERROR: Can not determine the srid of the geometry "%" in table %', the_geom,tabname;
            		RETURN 'FAIL';
    	  END;
        ELSE 
                raise notice  'ERROR: Geometry column "%"  not found in %',the_geom,tabname;
                RETURN 'FAIL';
        END IF;
  END;

  BEGIN 
       raise DEBUG 'Checking source column "%" and target column "%"  in  % ',source,target,tabname;
       IF source=target THEN
		raise notice  'ERROR: source and target columns have the same name "%" in %',target,tabname;
                RETURN 'FAIL';
       END IF;
       EXECUTE 'select  pgr_getColumnName('||quote_literal(tabname)||','||quote_literal(source)||')' INTO sourcename;
       EXECUTE 'select  pgr_getColumnName('||quote_literal(tabname)||','||quote_literal(target)||')' INTO targetname;
       IF sourcename is not NULL and targetname is not NULL then
                --check that the are integer
                EXECUTE 'select data_type  from information_schema.columns where table_name = '||quote_literal(tname)||
                        ' and table_schema='||quote_literal(sname)||' and column_name='||quote_literal(sourcename) into sourcetype;
                EXECUTE 'select data_type  from information_schema.columns where table_name = '||quote_literal(tname)||
                        ' and table_schema='||quote_literal(sname)||' and column_name='||quote_literal(targetname) into targettype;
                IF sourcetype not in('integer','smallint','bigint')  THEN
          	    raise notice  'ERROR: source column "%" is not of integer type',sourcename;
          	    RETURN 'FAIL';
                END IF;
                IF targettype not in('integer','smallint','bigint')  THEN
          	    raise notice  'ERROR: target column "%" is not of integer type',targetname;
          	    RETURN 'FAIL';
                END IF;
                raise DEBUG  '  ------>OK '; 
       END IF;
       IF sourcename is NULL THEN
          	raise notice  'ERROR: source column "%"  not found in %',source,tabname;
          	RETURN 'FAIL';
       END IF;
       IF targetname is NULL THEN
          	raise notice  'ERROR: target column "%"  not found in %',target,tabname;
          	RETURN 'FAIL';
       END IF;
  END;

    BEGIN
      RAISE DEBUG 'Cheking "%" column in % is indexed',sourcename,tabname;
      if (pgr_isColumnIndexed(tabname,sourcename)) then
        RAISE DEBUG '  ------>OK';
      else
        RAISE DEBUG ' ------> Adding  index "%_%_idx".',tabname,sourcename;
        set client_min_messages  to warning;
        execute 'create  index '||pgr_quote_ident(tname||'_'||sourcename||'_idx')||' 
                         on '||pgr_quote_ident(tabname)||' using btree('||quote_ident(sourcename)||')';
        execute 'set client_min_messages  to '|| debuglevel;
      END IF;
    END;

    BEGIN
      RAISE DEBUG 'Cheking "%" column in % is indexed',targetname,tabname;
      if (pgr_isColumnIndexed(tabname,targetname)) then
        RAISE DEBUG '  ------>OK';
      else
        RAISE DEBUG ' ------> Adding  index "%_%_idx".',tabname,targetname;
        set client_min_messages  to warning;
        execute 'create  index '||pgr_quote_ident(tname||'_'||targetname||'_idx')||' 
                         on '||pgr_quote_ident(tabname)||' using btree('||quote_ident(targetname)||')';
        execute 'set client_min_messages  to '|| debuglevel;
      END IF;
    END;

    BEGIN
      RAISE DEBUG 'Cheking "%" column in % is indexed',gname,tabname;
      if (pgr_iscolumnindexed(tabname,gname)) then
        RAISE DEBUG '  ------>OK';
      else
        RAISE DEBUG ' ------> Adding unique index "%_%_gidx".',tabname,gname;
        set client_min_messages  to warning;
        execute 'CREATE INDEX '
            || quote_ident(tname || '_' || gname || '_gidx' )
            || ' ON ' || pgr_quote_ident(tabname)
            || ' USING gist (' || quote_ident(gname) || ')';
        execute 'set client_min_messages  to '|| debuglevel;
      END IF;
    END;
       gname=quote_ident(gname);
       sourcename=quote_ident(sourcename);
       targetname=quote_ident(targetname);



    
    BEGIN
       raise DEBUG 'initializing %',vertname;
       execute 'select * from pgr_getTableName('||quote_literal(vertname)||')' into naming;
       IF sname=naming.sname  AND vname=naming.tname  THEN
           execute 'TRUNCATE TABLE '||pgr_quote_ident(vertname)||' RESTART IDENTITY';
           execute 'SELECT DROPGEOMETRYCOLUMN('||quote_literal(sname)||','||quote_literal(vname)||','||quote_literal('the_geom')||')';
       ELSE
           set client_min_messages  to warning;
       	   execute 'CREATE TABLE '||pgr_quote_ident(vertname)||' (id bigserial PRIMARY KEY,cnt integer,chk integer,ein integer,eout integer)';
       END IF;
       execute 'select addGeometryColumn('||quote_literal(sname)||','||quote_literal(vname)||','||
                quote_literal('the_geom')||','|| srid||', '||quote_literal('POINT')||', 2)';
       execute 'CREATE INDEX '||quote_ident(vname||'_the_geom_idx')||' ON '||pgr_quote_ident(vertname)||'  USING GIST (the_geom)';
       execute 'set client_min_messages  to '|| debuglevel;
       raise DEBUG  '  ------>OK'; 
    END;       

  BEGIN
    sql = 'select * from '||pgr_quote_ident(tabname)||' WHERE true'||rows_where||' limit 1';
    EXECUTE sql into i;
    sql = 'select count(*) from '||pgr_quote_ident(tabname)||' WHERE (' || gname || ' IS NULL or '||
		sourcename||' is null or '||targetname||' is null)=true '||rows_where;
    raise debug '%',sql;
    EXECUTE SQL  into notincluded;
    EXCEPTION WHEN OTHERS THEN  BEGIN
         RAISE NOTICE 'ERROR: Condition is not correct, please execute the following query to test your condition';
         RAISE NOTICE '%',sql;
         RETURN 'FAIL';
    END;
  END;


    BEGIN
       raise notice 'Populating %, please wait...',vertname;
       sql= 'with
		lines as ((select distinct '||sourcename||' as id, pgr_startpoint(st_linemerge('||gname||')) as the_geom from '||pgr_quote_ident(tabname)||
		                  ' where ('|| gname || ' IS NULL 
                                    or '||sourcename||' is null 
                                    or '||targetname||' is null)=false 
                                     '||rows_where||')
			union (select distinct '||targetname||' as id,pgr_endpoint(st_linemerge('||gname||')) as the_geom from '||pgr_quote_ident(tabname)||
			          ' where ('|| gname || ' IS NULL 
                                    or '||sourcename||' is null 
                                    or '||targetname||' is null)=false
                                     '||rows_where||'))
		,numberedLines as (select row_number() OVER (ORDER BY id) AS i,* from lines )
		,maxid as (select id,max(i) as maxi from numberedLines group by id)
		insert into '||pgr_quote_ident(vertname)||'(id,the_geom)  (select id,the_geom  from numberedLines join maxid using(id) where i=maxi order by id)';
       RAISE debug '%',sql;
       execute sql;
       GET DIAGNOSTICS totcount = ROW_COUNT;

       sql = 'select count(*) from '||pgr_quote_ident(tabname)||' a, '||pgr_quote_ident(vertname)||' b 
            where '||sourcename||'=b.id and '|| targetname||' in (select id from '||pgr_quote_ident(vertname)||')';
       RAISE debug '%',sql;
       execute sql into included;



       execute 'select max(id) from '||pgr_quote_ident(vertname) into ecnt;
       execute 'SELECT setval('||quote_literal(vertname||'_id_seq')||','||coalesce(ecnt,1)||' , false)';
       raise notice '  ----->   VERTICES TABLE CREATED WITH  % VERTICES', totcount;
       raise notice '                                       FOR   %  EDGES', included+notincluded;
       RAISE NOTICE '  Edges with NULL geometry,source or target: %',notincluded;
       RAISE NOTICE '                            Edges processed: %',included;
       Raise notice 'Vertices table for table % is: %',pgr_quote_ident(tabname),pgr_quote_ident(vertname);
       raise notice '----------------------------------------------';
    END;
    
    RETURN 'OK';
END;
$BODY$
  LANGUAGE plpgsql VOLATILE STRICT;

COMMENT ON FUNCTION pgr_createVerticesTable(text,text,text,text,text) 
IS 'args: edge_table, the_geom:=''the_geom'',source:=''source'', target:=''target'' rows_where:=''true'' - creates a vertices table based on the source and target identifiers for selected rows';
/*
=========================
pgRouting Graph Analytics
=========================
:Author: Stephen Woodbridge <woodbri@swoodbridge.com>
:Date: $Date: 2013-03-22 20:14:00 -5000 (Fri, 22 Mar 2013) $
:Revision: $Revision: 0000 $
:Description: This is a collection of tools for analyzing graphs.
It has been contributed to pgRouting by iMaptools.com.
:Copyright: Stephen Woodbridge. This is released under the MIT-X license.

*/


/*
.. function:: pgr_analyzeGraph(edge_tab, tolerance,the_geom, source,target)

   Analyzes the "edge_tab" and "edge_tab_vertices_pgr" tables and flags if
   nodes are deadends, ie vertices_tmp.cnt=1 and identifies nodes
   that might be disconnected because of gaps < tolerance or because of
   zlevel errors in the data. For example:

.. code-block:: sql

       select pgr_analyzeGraph('mytab', 0.000002);

   After the analyzing the graph, deadends are indentified by *cnt=1*
   in the "vertices_tmp" table and potential problems are identified
   with *chk=1*.  (Using 'source' and 'target' columns for analysis)

.. code-block:: sql

       select * from vertices_tmp where chk = 1;

HISOTRY
:Author: Stephen Woodbridge <woodbri@swoodbridge.com>
:Modified: 2013/08/20 by Vicky Vergara <vicky_vergara@hotmail.com>

Makes more checks:
   checks table edge_tab exists in the schema 
   checks source and target columns exist in edge_tab
   checks that source and target are completely populated i.e. do not have NULL values
   checks table edge_tabVertices exist in the appropiate schema
       if not, it creates it and populates it
   checks 'cnt','chk' columns exist in  edge_tabVertices 
       if not, it creates them
   checks if 'id' column of edge_tabVertices is indexed 
       if not, it creates the index
   checks if 'source','target',the_geom columns of edge_tab are indexed 
       if not, it creates their index     
   populates cnt in edge_tabVertices  <--- changed the way it was processed, because on large tables took to long.
					   For sure I am wrong doing this, but it gave me the same result as the original.
   populates chk                      <--- added a notice for big tables, because it takes time
           (edge_tab text, the_geom text, tolerance double precision)
*/

CREATE OR REPLACE FUNCTION pgr_analyzegraph(edge_table text,tolerance double precision,the_geom text default 'the_geom',id text default 'id',source text default 'source',target text default 'target',rows_where text default 'true')
RETURNS character varying AS
$BODY$

DECLARE
    points record;
    seg record;
    naming record;
    sridinfo record;
    srid integer;
    ecnt integer;
    vertname text;
    sname text;
    tname text;
    vname text;
    idname text;
    sourcename text;
    targetname text;
    sourcetype text;
    targettype text;
    geotype text;
    gname text;
    cntname text;
    chkname text;
    tabName text;
    flag boolean ;
    query text;
    selectionquery text;
    i integer;
    tot integer;
    NumIsolated integer;
    numdeadends integer;
    numgaps integer;
    NumCrossing integer;
    numRings integer;
    debuglevel text;




BEGIN
  raise notice 'PROCESSING:'; 
  raise notice 'pgr_analyzeGraph(''%'',%,''%'',''%'',''%'',''%'',''%'')',edge_table,tolerance,the_geom,id,source,target,rows_where;
  raise NOTICE  'Performing checks, pelase wait...';
  execute 'show client_min_messages' into debuglevel;


  BEGIN
    RAISE DEBUG 'Cheking % exists',edge_table;
    execute 'select * from pgr_getTableName('||quote_literal(edge_table)||')' into naming;
    sname=naming.sname;
    tname=naming.tname;
    IF sname IS NULL OR tname IS NULL THEN
        RAISE NOTICE '-------> % not found',edge_table;
        RETURN 'FAIL';
    ELSE
        RAISE DEBUG '  -----> OK';
    END IF;
  
    tabname=sname||'.'||tname;
    vname=tname||'_vertices_pgr';
    vertname= sname||'.'||vname;
    rows_where = ' AND ('||rows_where||')'; 
  END;

  BEGIN 
       raise DEBUG 'Checking id column "%" columns in  % ',id,tabname;
       EXECUTE 'select pgr_getColumnName('||quote_literal(tabname)||','||quote_literal(the_geom)||')' INTO gname;
       EXECUTE 'select pgr_getColumnName('||quote_literal(tabname)||','||quote_literal(id)||')' INTO idname;
       IF idname is NULL then
          raise notice  'ERROR: id column "%"  not found in %',id,tabname;
          RETURN 'FAIL';
       END IF;
       raise DEBUG 'Checking geometry column "%" column  in  % ',the_geom,tabname;
       IF gname is not NULL then
          BEGIN
                raise DEBUG 'Checking the SRID of the geometry "%"', gname;
                EXECUTE 'SELECT ST_SRID(' || quote_ident(gname) || ') as srid '
                        || ' FROM ' || pgr_quote_ident(tabname)
                        || ' WHERE ' || quote_ident(gname)
                        || ' IS NOT NULL LIMIT 1'
                        INTO sridinfo;

                IF sridinfo IS NULL OR sridinfo.srid IS NULL THEN
                        RAISE NOTICE 'ERROR: Can not determine the srid of the geometry "%" in table %', the_geom,tabname;
                        RETURN 'FAIL';
                END IF;
                srid := sridinfo.srid;
                raise DEBUG '  -----> SRID found %',srid;
                EXCEPTION WHEN OTHERS THEN
                        RAISE NOTICE 'ERROR: Can not determine the srid of the geometry "%" in table %', the_geom,tabname;
                        RETURN 'FAIL';
          END;
        ELSE 
                raise notice  'ERROR: Geometry column "%"  not found in %',the_geom,tabname;
                RETURN 'FAIL';
        END IF;
  END;


  BEGIN 
       raise DEBUG 'Checking source column "%" and target column "%"  in  % ',source,target,tabname;
       EXECUTE 'select  pgr_getColumnName('||quote_literal(tabname)||','||quote_literal(source)||')' INTO sourcename;
       EXECUTE 'select  pgr_getColumnName('||quote_literal(tabname)||','||quote_literal(target)||')' INTO targetname;
       IF sourcename is not NULL and targetname is not NULL then
                --check that the are integer
                EXECUTE 'select data_type  from information_schema.columns where table_name = '||quote_literal(tname)||
                        ' and table_schema='||quote_literal(sname)||' and column_name='||quote_literal(sourcename) into sourcetype;
                EXECUTE 'select data_type  from information_schema.columns where table_name = '||quote_literal(tname)||
                        ' and table_schema='||quote_literal(sname)||' and column_name='||quote_literal(targetname) into targettype;
                IF sourcetype not in('integer','smallint','bigint')  THEN
                    raise notice  'ERROR: source column "%" is not of integer type',sourcename;
                    RETURN 'FAIL';
                END IF;
                IF targettype not in('integer','smallint','bigint')  THEN
                    raise notice  'ERROR: target column "%" is not of integer type',targetname;
                    RETURN 'FAIL';
                END IF;
                raise DEBUG  '  ------>OK '; 
       END IF;
       IF sourcename is NULL THEN
                raise notice  'ERROR: source column "%"  not found in %',source,tabname;
                RETURN 'FAIL';
       END IF;
       IF targetname is NULL THEN
                raise notice  'ERROR: target column "%"  not found in %',target,tabname;
                RETURN 'FAIL';
       END IF;   
       IF sourcename=targetname THEN
                raise notice  'ERROR: source and target columns have the same name "%" in %',target,tabname;
                RETURN 'FAIL';
       END IF;
       IF sourcename=idname THEN
                raise notice  'ERROR: source and id columns have the same name "%" in %',target,tabname;
                RETURN 'FAIL';
       END IF;
       IF targetname=idname THEN
                raise notice  'ERROR: target and id columns have the same name "%" in %',target,tabname;
                RETURN 'FAIL';
       END IF;
  
  END;


    BEGIN
      RAISE DEBUG 'Cheking "%" column in % is indexed',sourcename,tabname;
      if (pgr_isColumnIndexed(tabname,sourcename)) then 
	RAISE DEBUG '  ------>OK';
      else 
        RAISE DEBUG ' ------> Adding  index "%_%_idx".',tabname,sourcename;
        execute 'create  index '||tname||'_'||sourcename||'_idx on '||tabname||' using btree('||quote_ident(sourcename)||')';
      END IF;
    END;

    BEGIN
      RAISE DEBUG 'Cheking "%" column in % is indexed',targetname,tabname;
      if (pgr_isColumnIndexed(tabname,targetname)) then 
	RAISE DEBUG '  ------>OK';
      else 
        RAISE DEBUG ' ------> Adding  index "%_%_idx".',tabname,targetname;
        execute 'create  index '||tname||'_'||targetname||'_idx on '||tabname||' using btree('||quote_ident(targetname)||')';
      END IF;
    END;

    BEGIN
      RAISE DEBUG 'Cheking "%" column in % is indexed',gname,tabname;
      if (pgr_iscolumnindexed(tabname,gname)) then 
	RAISE DEBUG '  ------>OK';
      else 
        RAISE DEBUG ' ------> Adding unique index "%_%_gidx".',tabname,gname;
        execute 'CREATE INDEX '
            || quote_ident(tname || '_' || gname || '_gidx' )
            || ' ON ' || tabname
            || ' USING gist (' || quote_ident(gname) || ')';
      END IF;
    END;

  
       gname=quote_ident(gname);
       sourcename=quote_ident(sourcename);
       targetname=quote_ident(targetname);
       idname=quote_ident(idname);

    BEGIN
       raise DEBUG 'Checking table %.% exists ',sname ,vname;
       execute 'select * from pgr_getTableName('||quote_literal(vertname)||')' into naming;
       IF sname=naming.sname  AND vname=naming.tname  THEN
	   raise DEBUG  '  ------>OK';
       ELSE
           raise notice '   --->Table %.% does not exists',sname ,vname; 
           raise notice '   --->Please create %.% using pgr_createTopology() or pgr_createVerticesTable()',sname ,vname;
           return 'FAIL';
       END IF;
    END;       


    BEGIN
        RAISE DEBUG 'Cheking for "cnt" and "chk" column in %',vertname;
        execute 'select pgr_getcolumnName('||quote_literal(vertname)||','||quote_literal('cnt')||')' into cntname;
        execute 'select pgr_getcolumnName('||quote_literal(vertname)||','||quote_literal('chk')||')' into chkname;
        if cntname is not null and chkname is not null then
		cntname=quote_ident(cntname);
		RAISE DEBUG '  ------>OK';
	else if cntname is not null	then
		RAISE NOTICE '  ------>Adding "cnt" column in %',vertname;
        set client_min_messages  to warning;
		execute 'ALTER TABLE '||pgr_quote_ident(vertname)||' ADD COLUMN cnt integer';
        execute 'set client_min_messages  to '|| debuglevel;
		cntname=quote_ident('cnt');
             end if;
             if chkname is not null then
		RAISE DEBUG '  ------>Adding "chk" column in %',vertname;
        set client_min_messages  to warning;
		execute 'ALTER TABLE '||pgr_quote_ident(vertname)||' ADD COLUMN chk integer';
        execute 'set client_min_messages  to '|| debuglevel;
		cntname=quote_ident('chk');
             end if;
	END IF;
	execute 'UPDATE '||pgr_quote_ident(vertname)||' SET '||cntname||'=0 ,'||chkname||'=0';		
    END;


    BEGIN
      RAISE DEBUG 'Cheking "id" column in % is indexed',vertname;
      if (pgr_iscolumnindexed(vertname,'id')) then 
	RAISE DEBUG '  ------>OK';
      else 
        RAISE DEBUG ' ------> Adding unique index "%_vertices_id_idx".',vname;
        set client_min_messages  to warning;
        execute 'create unique index '||vname||'_id_idx on '||pgr_quote_ident(vertname)||' using btree(id)';
        execute 'set client_min_messages  to '|| debuglevel;
      END IF;
    END;
    
    BEGIN
        query='select count(*) from '||pgr_quote_ident(tabname)||' where true  '||rows_where;
        EXECUTE query into ecnt;
         EXCEPTION WHEN OTHERS THEN 
         BEGIN 
            RAISE NOTICE 'ERROR: Condition is not correct. Please execute the following query to test your condition'; 
            RAISE NOTICE '%',query;
            RETURN 'FAIL'; 
        END;
    END;    

    selectionquery ='with 
           selectedRows as( (select '||sourcename||' as id from '||pgr_quote_ident(tabname)||' where true '||rows_where||')
                           union
                           (select '||targetname||' as id from '||pgr_quote_ident(tabname)||' where true '||rows_where||'))';
    


    

   BEGIN
       RAISE NOTICE 'Analyzing for dead ends. Please wait...';
       query= 'with countingsource as (select a.'||sourcename||' as id,count(*) as cnts 
               from (select * from '||pgr_quote_ident(tabname)||' where true '||rows_where||' ) a  group by a.'||sourcename||') 
                     ,countingtarget as (select a.'||targetname||' as id,count(*) as cntt 
                    from (select * from '||pgr_quote_ident(tabname)||' where true '||rows_where||' ) a  group by a.'||targetname||') 
                   ,totalcount as (select id,case when cnts is null and cntt is null then 0
                                                   when cnts is null then cntt 
                                                   when cntt is null then cnts
                                                   else cnts+cntt end as totcnt 
                                   from ('||pgr_quote_ident(vertname)||' as a left 
                                   join countingsource as t using(id) ) left join countingtarget using(id))
               update '||pgr_quote_ident(vertname)||' as a set cnt=totcnt from totalcount as b where a.id=b.id';
        raise debug '%',query;
        execute query;
        query=selectionquery||'
              SELECT count(*)  FROM '||pgr_quote_ident(vertname)||' WHERE cnt=1 and id in (select id from selectedRows)';
        raise debug '%',query;
        execute query  INTO numdeadends;
   END;



    BEGIN
          RAISE NOTICE 'Analyzing for gaps. Please wait...';
          query = 'with 
                   buffer as (select id,st_buffer(the_geom,'||tolerance||') as buff from '||pgr_quote_ident(vertname)||' where cnt=1)
                   ,veryclose as (select b.id,st_crosses(a.'||gname||',b.buff) as flag 
                   from  (select * from '||pgr_quote_ident(tabname)||' where true '||rows_where||' ) as a 
                   join buffer as b on (a.'||gname||'&&b.buff)  
                   where '||sourcename||'!=b.id and '||targetname||'!=b.id )
                   update '||pgr_quote_ident(vertname)||' set chk=1 where id in (select distinct id from veryclose where flag=true)'; 
          raise debug '%' ,query; 
          execute query; 
          GET DIAGNOSTICS  numgaps= ROW_COUNT; 
    END; 
    
    BEGIN
        RAISE NOTICE 'Analyzing for isolated edges. Please wait...'; 
        query=selectionquery|| ' SELECT count(*) FROM (select * from '||pgr_quote_ident(tabname)||' where true '||rows_where||' )  as a,
                                                 '||pgr_quote_ident(vertname)||' as b,
                                                 '||pgr_quote_ident(vertname)||' as c 
                            WHERE b.id in (select id from selectedRows) and a.'||sourcename||' =b.id 
                            AND b.cnt=1 AND a.'||targetname||' =c.id 
                            AND c.cnt=1';
        raise debug '%' ,query; 
        execute query  INTO NumIsolated; 
    END;

    BEGIN
        RAISE NOTICE 'Analyzing for ring geometries. Please wait...'; 
        execute 'SELECT geometrytype('||gname||')  FROM '||pgr_quote_ident(tabname) limit 1 into geotype; 
        IF (geotype='MULTILINESTRING') THEN 
            query ='SELECT count(*)  FROM '||pgr_quote_ident(tabname)||' 
                                 WHERE true  '||rows_where||' and st_isRing(st_linemerge('||gname||'))'; 
            raise debug '%' ,query; 
            execute query  INTO numRings; 
        ELSE query ='SELECT count(*)  FROM '||pgr_quote_ident(tabname)||' 
                                  WHERE true  '||rows_where||' and st_isRing('||gname||')'; 
            raise debug '%' ,query; 
            execute query  INTO numRings; 
        END IF; 
    END;

    BEGIN
        RAISE NOTICE 'Analyzing for intersections. Please wait...'; 
        query = 'select count(*) from (select distinct case when a.'||idname||' < b.'||idname||' then a.'||idname||' 
                                                        else b.'||idname||' end, 
                                                   case when a.'||idname||' < b.'||idname||' then b.'||idname||' 
                                                        else a.'||idname||' end 
                                    FROM (select * from '||pgr_quote_ident(tabname)||' where true '||rows_where||') as a 
                                    JOIN (select * from '||pgr_quote_ident(tabname)||' where true '||rows_where||') as b 
                                    ON (a.'|| gname||' && b.'||gname||') 
                                    WHERE a.'||idname||' != b.'||idname|| ' 
                                        and (a.'||sourcename||' in (b.'||sourcename||',b.'||targetname||') 
                                              or a.'||targetname||' in (b.'||sourcename||',b.'||targetname||')) = false 
                                        and st_intersects(a.'||gname||', b.'||gname||')=true) as d '; 
        raise debug '%' ,query;
        execute query  INTO numCrossing;
    END;




    RAISE NOTICE '            ANALYSIS RESULTS FOR SELECTED EDGES:';
    RAISE NOTICE '                  Isolated segments: %', NumIsolated;
    RAISE NOTICE '                          Dead ends: %', numdeadends;
    RAISE NOTICE 'Potential gaps found near dead ends: %', numgaps;
    RAISE NOTICE '             Intersections detected: %',numCrossing;
    RAISE NOTICE '                    Ring geometries: %',numRings;


    RETURN 'OK';
END;
$BODY$
  LANGUAGE plpgsql VOLATILE STRICT;
COMMENT ON FUNCTION pgr_analyzeGraph(text,double precision,text,text,text,text,text) IS 'args: edge_table, tolerance,the_geom:=''the_geom'',id:=''id'',source column:=''source'', target column:=''target'' rows_where:=''true'' - creates a vertices table based on the geometry for selected rows';





/*
.. function:: pgr_analyzeOneway(tab, col, s_in_rules, s_out_rules, t_in_rules, t_out_rules)

   This function analyzes oneway streets in a graph and identifies any
   flipped segments. Basically if you count the edges coming into a node
   and the edges exiting a node the number has to be greater than one.

   * tab              - edge table name (TEXT)
   * col              - oneway column name (TEXT)
   * s_in_rules       - source node in rules
   * s_out_rules      - source node out rules
   * t_in_tules       - target node in rules
   * t_out_rules      - target node out rules
   * two_way_if_null  - flag to treat oneway nNULL values as by directional

   After running this on a graph you can identify nodes with potential
   problems with the following query.

.. code-block:: sql

       select * from vertices_tmp where in=0 or out=0;

   The rules are defined as an array of text strings that if match the "col"
   value would be counted as true for the source or target in or out condition.

   Example
   =======

   Lets assume we have a table "st" of edges and a column "one_way" that
   might have values like:

   * 'FT'    - oneway from the source to the target node.
   * 'TF'    - oneway from the target to the source node.
   * 'B'     - two way street.
   * ''      - empty field, assume teoway.
   * <NULL>  - NULL field, use two_way_if_null flag.

   Then we could form the following query to analyze the oneway streets for
   errors.

.. code-block:: sql

   select pgr_analyzeOneway('st', 'one_way',
        ARRAY['', 'B', 'TF'],
        ARRAY['', 'B', 'FT'],
        ARRAY['', 'B', 'FT'],
        ARRAY['', 'B', 'TF'],
        true);

   -- now we can see the problem nodes
   select * from vertices_tmp where ein=0 or eout=0;

   -- and the problem edges connected to those nodes
   select gid

     from st a, vertices_tmp b
    where a.source=b.id and ein=0 or eout=0
   union
   select gid
     from st a, vertices_tmp b
    where a.target=b.id and ein=0 or eout=0;

Typically these problems are generated by a break in the network, the
oneway direction set wrong, maybe an error releted to zlevels or
a network that is not properly noded.

*/

CREATE OR REPLACE FUNCTION pgr_analyzeOneway(
   edge_table text, 
   s_in_rules TEXT[], 
   s_out_rules TEXT[], 
   t_in_rules TEXT[], 
   t_out_rules TEXT[], 
   two_way_if_null boolean default true, 
   oneway text default 'oneway',
   source text default 'source',
   target text default 'target')
  RETURNS text AS
$BODY$


DECLARE
    rule text;
    ecnt integer;
    instr text;
    naming record;
    sname text;
    tname text;
    tabname text;
    vname text;
    owname text;
    sourcename text;
    targetname text;
    sourcetype text;
    targettype text;
    vertname text;
    einname text;
    eoutname text;
    debuglevel text;


BEGIN
  raise notice 'PROCESSING:'; 
  raise notice 'pgr_analyzeOneway(''%'',''%'',''%'',''%'',''%'',''%'',''%'',''%'',%)',
		edge_table, s_in_rules , s_out_rules, t_in_rules, t_out_rules, oneway, source ,target,two_way_if_null ;
  execute 'show client_min_messages' into debuglevel;

  BEGIN
    RAISE DEBUG 'Cheking % exists',edge_table;
    execute 'select * from pgr_getTableName('||quote_literal(edge_table)||')' into naming;
    sname=naming.sname;
    tname=naming.tname;
    IF sname IS NULL OR tname IS NULL THEN
        RAISE NOTICE '-------> % not found',edge_table;
        RETURN 'FAIL';
    ELSE
        RAISE DEBUG '  -----> OK';
    END IF;
  
    tabname=sname||'.'||tname;
    vname=tname||'_vertices_pgr';
    vertname= sname||'.'||vname;
  END;


  BEGIN 
       raise DEBUG 'Checking oneway, source column "%" and target column "%"  in  % ',source,target,tabname;
       EXECUTE 'select  pgr_getColumnName('||quote_literal(tabname)||','||quote_literal(source)||')' INTO sourcename;
       EXECUTE 'select  pgr_getColumnName('||quote_literal(tabname)||','||quote_literal(oneway)||')' INTO owname;
       EXECUTE 'select  pgr_getColumnName('||quote_literal(tabname)||','||quote_literal(target)||')' INTO targetname;
       IF sourcename is not NULL and targetname is not NULL then
                --check that the are integer
                EXECUTE 'select data_type  from information_schema.columns where table_name = '||quote_literal(tname)||
                        ' and table_schema='||quote_literal(sname)||' and column_name='||quote_literal(sourcename) into sourcetype;
                EXECUTE 'select data_type  from information_schema.columns where table_name = '||quote_literal(tname)||
                        ' and table_schema='||quote_literal(sname)||' and column_name='||quote_literal(targetname) into targettype;
                IF sourcetype not in('integer','smallint','bigint')  THEN
                    raise notice  'ERROR: source column "%" is not of integer type',sourcename;
                    RETURN 'FAIL';
                END IF;
                IF targettype not in('integer','smallint','bigint')  THEN
                    raise notice  'ERROR: target column "%" is not of integer type',targetname;
                    RETURN 'FAIL';
                END IF;
                raise DEBUG  '  ------>OK '; 
       END IF;
       IF owname is NULL THEN
                raise notice  'ERROR: oneway column "%"  not found in %',oneway,tabname;
                RETURN 'FAIL';
       END IF;
       IF sourcename is NULL THEN
                raise notice  'ERROR: source column "%"  not found in %',source,tabname;
                RETURN 'FAIL';
       END IF;
       IF targetname is NULL THEN
                raise notice  'ERROR: target column "%"  not found in %',target,tabname;
                RETURN 'FAIL';
       END IF;   
       IF sourcename=targetname THEN
                raise notice  'ERROR: source and target columns have the same name "%" in %',target,tabname;
                RETURN 'FAIL';
       END IF;
       IF sourcename=owname THEN
                raise notice  'ERROR: source and owname columns have the same name "%" in %',source,tabname;
                RETURN 'FAIL';
       END IF;
       IF targetname=owname THEN
                raise notice  'ERROR: target and owname columns have the same name "%" in %',target,tabname;
                RETURN 'FAIL';
       END IF;
       sourcename=quote_ident(sourcename);
       targetname=quote_ident(targetname);
       owname=quote_ident(owname);
  
  END;


    BEGIN
       raise DEBUG 'Checking table %.% exists ',sname ,vname;
       execute 'select * from pgr_getTableName('||quote_literal(sname||'.'||vname)||')' into naming;
      vname=naming.tname;
      vertname=sname||'.'||vname;
       IF naming.sname is not NULL and  naming.tname IS NOT NULL then
           raise DEBUG  '  ------>OK';
       ELSE
           raise notice '   --->Table %.% does not exists',sname ,vname;
           raise exception '   --->Please create %.% using pgr_createTopology() or pgr_makeVerticesTable()',sname ,vname;
       END IF;
    END;


    BEGIN
        RAISE DEBUG 'Cheking for "ein" column in %',vertname;
        execute 'select pgr_getcolumnName('||quote_literal(vertname)||','||quote_literal('ein')||')' into einname;
        if einname is not null then
                einname=quote_ident(einname);
                RAISE DEBUG '  ------>OK';
        else
                RAISE DEBUG '  ------>Adding "ein" column in %',vertname;
                set client_min_messages  to warning;
                execute 'ALTER TABLE '||pgr_quote_ident(vertname)||' ADD COLUMN ein integer';
                execute 'set client_min_messages  to '|| debuglevel;
                einname=quote_ident('ein');
        END IF;
    END;


    BEGIN
        RAISE DEBUG 'Cheking for "eout" column in %',vertname;
        execute 'select pgr_getcolumnName('||quote_literal(vertname)||','||quote_literal('eout')||')' into eoutname;
        if eoutname is not null then
                eoutname=quote_ident(eoutname);
                RAISE DEBUG '  ------>OK';
        else
                RAISE DEBUG '  ------>Adding "eout" column in %',verticesTable;
                set client_min_messages  to warning;
                execute 'ALTER TABLE '||pgr_quote_ident(vertname)||' ADD COLUMN eout integer';
                execute 'set client_min_messages  to '|| debuglevel;
                eoutname=quote_ident('eout');
        END IF;
    END;

    BEGIN
      RAISE DEBUG 'Zeroing columns "ein" and "eout" on "%".', vertname;
      execute 'UPDATE '||pgr_quote_ident(vertname)||' SET '||einname||'=0, '||eoutname||'=0';
    END;


    RAISE NOTICE 'Analyzing graph for one way street errors.';

    rule := CASE WHEN two_way_if_null
            THEN owname || ' IS NULL OR '
            ELSE '' END;

    instr := '''' || array_to_string(s_in_rules, ''',''') || '''';
       EXECUTE 'update '||pgr_quote_ident(vertname)||' a set '||einname||'=coalesce('||einname||',0)+b.cnt
      from (
         select '|| sourcename ||', count(*) as cnt 
           from '|| tabname ||' 
          where '|| rule || owname ||' in ('|| instr ||')
          group by '|| sourcename ||' ) b
     where a.id=b.'|| sourcename;

    RAISE NOTICE 'Analysis 25%% complete ...';

    instr := '''' || array_to_string(t_in_rules, ''',''') || '''';
    EXECUTE 'update '||pgr_quote_ident(vertname)||' a set '||einname||'=coalesce('||einname||',0)+b.cnt
        from (
         select '|| targetname ||', count(*) as cnt 
           from '|| tabname ||' 
          where '|| rule || owname ||' in ('|| instr ||')
          group by '|| targetname ||' ) b
        where a.id=b.'|| targetname;
     
    RAISE NOTICE 'Analysis 50%% complete ...';

    instr := '''' || array_to_string(s_out_rules, ''',''') || '''';
    EXECUTE 'update '||pgr_quote_ident(vertname)||' a set '||eoutname||'=coalesce('||eoutname||',0)+b.cnt
        from (
         select '|| sourcename ||', count(*) as cnt 
           from '|| tabname ||' 
          where '|| rule || owname ||' in ('|| instr ||')
          group by '|| sourcename ||' ) b
        where a.id=b.'|| sourcename;
    RAISE NOTICE 'Analysis 75%% complete ...';

    instr := '''' || array_to_string(t_out_rules, ''',''') || '''';
    EXECUTE 'update '||pgr_quote_ident(vertname)||' a set '||eoutname||'=coalesce('||eoutname||',0)+b.cnt
        from (
         select '|| targetname ||', count(*) as cnt 
           from '|| tabname ||' 
          where '|| rule || owname ||' in ('|| instr ||')
          group by '|| targetname ||' ) b
        where a.id=b.'|| targetname;

    RAISE NOTICE 'Analysis 100%% complete ...';

    EXECUTE 'SELECT count(*)  FROM '||pgr_quote_ident(vertname)||' WHERE ein=0 or eout=0' INTO ecnt;

    RAISE NOTICE 'Found % potential problems in directionality' ,ecnt;

    RETURN 'OK';
    
END;
$BODY$
  LANGUAGE plpgsql VOLATILE STRICT;

COMMENT ON FUNCTION pgr_analyzeOneway(text,TEXT[],TEXT[], TEXT[],TEXT[],boolean,text,text,text)
IS 'args:edge_table , s_in_rules , s_out_rules, t_in_rules , t_out_rules, two_way_if_null:= true, oneway:=''oneway'',source:= ''source'',target:=''target'' - Analizes the directionality of the edges based on the rules';

/*
	Alternative to pgrouting_analytics.sql

	Example:
	SELECT * FROM data.PGR_analyze_graph('SELECT source, target, geom_way 
		AS geom FROM data.dhaka_2po_4pgr', 0.000001) WHERE checkit;
CREATE OR REPLACE FUNCTION PGR_analyzeGraph(sql text, tolerance float)
  RETURNS TABLE(
	vertex bigint, 
	source integer,
	target integer,
	checkit boolean,
	geom geometry
) AS
$BODY$
DECLARE 
	rec	record;
	pnt	record;
	seg	record;
BEGIN
	-- Create temporary vertex table
	CREATE TEMPORARY TABLE vertices_temp (
		vertex bigint  PRIMARY KEY,
		source integer DEFAULT 0,
		target integer DEFAULT 0,
		checkit boolean DEFAULT false,
		geom geometry
	) ON COMMIT DROP;

	-- Count occurance of vertex as source/target
	RAISE NOTICE 'Count occurance of vertex as source/target';
	FOR rec IN EXECUTE sql
	LOOP
		-- Source
		BEGIN
			EXECUTE 'INSERT INTO vertices_temp (vertex,geom,source) VALUES ($1,$2,1)' 
				USING rec.source, PGR_Startpoint(rec.geom);
				-- This assumes that source equals start point of geometry
		EXCEPTION WHEN unique_violation THEN
			EXECUTE 'UPDATE vertices_temp SET source = source + 1 WHERE vertex = $1' 
				USING rec.source;
		END;

		-- Target
		BEGIN
			EXECUTE 'INSERT INTO vertices_temp (vertex,geom,target) VALUES ($1,$2,1)' 
				USING rec.target, PGR_Endpoint(rec.geom);
				-- This assumes that target equals end point of geometry
		EXCEPTION WHEN unique_violation THEN
			EXECUTE 'UPDATE vertices_temp SET target = target + 1 WHERE vertex = $1' 
				USING rec.target;
		END;
	END LOOP;

	-- Create indices
	RAISE NOTICE 'Create indices';
	CREATE INDEX vertices_temp_source_idx ON vertices_temp USING btree (source);
	CREATE INDEX vertices_temp_target_idx ON vertices_temp USING btree (target);
	CREATE INDEX vertices_temp_geom_idx ON vertices_temp USING gist (geom);
	CREATE INDEX vertices_temp_checkit_idx ON vertices_temp USING btree (checkit);

	-- Analyze graph for gaps and zlev errors
	RAISE NOTICE 'Analyze graph for gaps and zlev errors';
	FOR pnt IN EXECUTE 'SELECT * FROM vertices_temp 
				WHERE (source + target) = 1 ORDER BY vertex'
	LOOP
		-- TODO: Better to filter with tolerance BBOX?
		FOR seg IN EXECUTE 'SELECT * FROM (' || sql || ') a WHERE ST_DWithin(a.geom,$1,$2)'
				USING pnt.geom, tolerance
		LOOP
			IF pnt.vertex NOT IN (seg.source, seg.target) THEN
				EXECUTE 'UPDATE vertices_temp SET checkit = TRUE WHERE vertex = $1'
					USING pnt.vertex;
			END IF;
		END LOOP;
	END LOOP;

	RETURN QUERY SELECT * FROM vertices_temp;
EXCEPTION
	-- Not sure this is a good idea or not. It prevents to show "ugly" console output 
	WHEN others THEN
	RAISE EXCEPTION '%', SQLERRM;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE STRICT
  COST 100;
 */

/*****************************************************************************
* Author: Nicolas Ribot, 2013
******************************************************************************/


CREATE OR REPLACE FUNCTION pgr_nodeNetwork(edge_table text, tolerance double precision, 
			id text default 'id', the_geom text default 'the_geom', table_ending text default 'noded') RETURNS text AS
$BODY$
DECLARE
	/*
	 * Author: Nicolas Ribot, 2013
	*/
	p_num int := 0;
	p_ret text := '';
    pgis_ver_old boolean := pgr_versionless(postgis_lib_version(), '2.1.0.0');
    vst_line_substring text;
    vst_line_locate_point text;
    intab text;
    outtab text;
    n_pkey text;
    n_geom text;
    naming record;
    sname text;
    tname text;
    outname text;
    srid integer;
    sridinfo record;
    splits bigint;
    touched bigint;
    untouched bigint;
    geomtype text;
    debuglevel text;
   

BEGIN
  raise notice 'PROCESSING:'; 
  raise notice 'pgr_nodeNetwork(''%'',%,''%'',''%'',''%'')',edge_table,tolerance,the_geom,id,table_ending;
  raise notice 'Performing checks, pelase wait .....';
  execute 'show client_min_messages' into debuglevel;

  BEGIN
    RAISE DEBUG 'Cheking % exists',edge_table;
    execute 'select * from pgr_getTableName('||quote_literal(edge_table)||')' into naming;
    sname=naming.sname;
    tname=naming.tname;
    IF sname IS NULL OR tname IS NULL THEN
	RAISE NOTICE '-------> % not found',edge_table;
        RETURN 'FAIL';
    ELSE
	RAISE DEBUG '  -----> OK';
    END IF;
  
    intab=sname||'.'||tname;
    outname=tname||'_'||table_ending;
    outtab= sname||'.'||outname;
    --rows_where = ' AND ('||rows_where||')'; 
  END;

  BEGIN 
       raise DEBUG 'Checking id column "%" columns in  % ',id,intab;
       EXECUTE 'select pgr_getColumnName('||quote_literal(intab)||','||quote_literal(id)||')' INTO n_pkey;
       IF n_pkey is NULL then
          raise notice  'ERROR: id column "%"  not found in %',id,intab;
          RETURN 'FAIL';
       END IF;
  END; 


  BEGIN 
       raise DEBUG 'Checking id column "%" columns in  % ',the_geom,intab;
       EXECUTE 'select pgr_getColumnName('||quote_literal(intab)||','||quote_literal(the_geom)||')' INTO n_geom;
       IF n_geom is NULL then
          raise notice  'ERROR: the_geom  column "%"  not found in %',the_geom,intab;
          RETURN 'FAIL';
       END IF;
  END;

  IF n_pkey=n_geom THEN
	raise notice  'ERROR: id and the_geom columns have the same name "%" in %',n_pkey,intab;
        RETURN 'FAIL';
  END IF;
 
  BEGIN 
       	raise DEBUG 'Checking the SRID of the geometry "%"', n_geom;
       	EXECUTE 'SELECT ST_SRID(' || quote_ident(n_geom) || ') as srid '
          		|| ' FROM ' || pgr_quote_ident(intab)
          		|| ' WHERE ' || quote_ident(n_geom)
          		|| ' IS NOT NULL LIMIT 1' INTO sridinfo;
       	IF sridinfo IS NULL OR sridinfo.srid IS NULL THEN
        	RAISE NOTICE 'ERROR: Can not determine the srid of the geometry "%" in table %', n_geom,intab;
           	RETURN 'FAIL';
       	END IF;
       	srid := sridinfo.srid;
       	raise DEBUG '  -----> SRID found %',srid;
       	EXCEPTION WHEN OTHERS THEN
           		RAISE NOTICE 'ERROR: Can not determine the srid of the geometry "%" in table %', n_geom,intab;
           		RETURN 'FAIL';
  END;

    BEGIN
      RAISE DEBUG 'Cheking "%" column in % is indexed',n_pkey,intab;
      if (pgr_isColumnIndexed(intab,n_pkey)) then 
	RAISE DEBUG '  ------>OK';
      else 
        RAISE DEBUG ' ------> Adding  index "%_%_idx".',n_pkey,intab;

	set client_min_messages  to warning;
        execute 'create  index '||tname||'_'||n_pkey||'_idx on '||pgr_quote_ident(intab)||' using btree('||quote_ident(n_pkey)||')';
	execute 'set client_min_messages  to '|| debuglevel;
      END IF;
    END;

    BEGIN
      RAISE DEBUG 'Cheking "%" column in % is indexed',n_geom,intab;
      if (pgr_iscolumnindexed(intab,n_geom)) then 
	RAISE DEBUG '  ------>OK';
      else 
        RAISE DEBUG ' ------> Adding unique index "%_%_gidx".',intab,n_geom;
	set client_min_messages  to warning;
        execute 'CREATE INDEX '
            || quote_ident(tname || '_' || n_geom || '_gidx' )
            || ' ON ' || pgr_quote_ident(intab)
            || ' USING gist (' || quote_ident(n_geom) || ')';
	execute 'set client_min_messages  to '|| debuglevel;
      END IF;
    END;
---------------
    BEGIN
       raise DEBUG 'initializing %',outtab;
       execute 'select * from pgr_getTableName('||quote_literal(outtab)||')' into naming;
       IF sname=naming.sname  AND outname=naming.tname  THEN
           execute 'TRUNCATE TABLE '||pgr_quote_ident(outtab)||' RESTART IDENTITY';
           execute 'SELECT DROPGEOMETRYCOLUMN('||quote_literal(sname)||','||quote_literal(outname)||','||quote_literal(n_geom)||')';
       ELSE
	   set client_min_messages  to warning;
       	   execute 'CREATE TABLE '||pgr_quote_ident(outtab)||' (id bigserial PRIMARY KEY,old_id integer,sub_id integer,
								source bigint,target bigint)';
       END IF;
       execute 'select geometrytype('||quote_ident(n_geom)||') from  '||pgr_quote_ident(intab)||' limit 1' into geomtype;
       execute 'select addGeometryColumn('||quote_literal(sname)||','||quote_literal(outname)||','||
                quote_literal(n_geom)||','|| srid||', '||quote_literal(geomtype)||', 2)';
       execute 'CREATE INDEX '||quote_ident(outname||'_'||n_geom||'_idx')||' ON '||pgr_quote_ident(outtab)||'  USING GIST ('||quote_ident(n_geom)||')';
	execute 'set client_min_messages  to '|| debuglevel;
       raise DEBUG  '  ------>OK'; 
    END;  
----------------


  raise notice 'Processing, pelase wait .....';


    if pgis_ver_old then
        vst_line_substring    := 'st_line_substring';
        vst_line_locate_point := 'st_line_locate_point';
    else
        vst_line_substring    := 'st_linesubstring';
        vst_line_locate_point := 'st_linelocatepoint';
    end if;

--    -- First creates temp table with intersection points
    p_ret = 'create temp table intergeom on commit drop as (
        select l1.' || quote_ident(n_pkey) || ' as l1id, 
               l2.' || quote_ident(n_pkey) || ' as l2id, 
	       l1.' || quote_ident(n_geom) || ' as line,
	       pgr_startpoint(l2.' || quote_ident(n_geom) || ') as source,
	       pgr_endpoint(l2.' || quote_ident(n_geom) || ') as target,
               st_intersection(l1.' || quote_ident(n_geom) || ', l2.' || quote_ident(n_geom) || ') as geom 
        from ' || pgr_quote_ident(intab) || ' l1 
             join ' || pgr_quote_ident(intab) || ' l2 
             on (st_dwithin(l1.' || quote_ident(n_geom) || ', l2.' || quote_ident(n_geom) || ', ' || tolerance || '))'||
        'where l1.' || quote_ident(n_pkey) || ' <> l2.' || quote_ident(n_pkey)||' and 
	st_equals(Pgr_startpoint(l1.' || quote_ident(n_geom) || '),pgr_startpoint(l2.' || quote_ident(n_geom) || '))=false and 
	st_equals(Pgr_startpoint(l1.' || quote_ident(n_geom) || '),pgr_endpoint(l2.' || quote_ident(n_geom) || '))=false and 
	st_equals(Pgr_endpoint(l1.' || quote_ident(n_geom) || '),pgr_startpoint(l2.' || quote_ident(n_geom) || '))=false and 
	st_equals(Pgr_endpoint(l1.' || quote_ident(n_geom) || '),pgr_endpoint(l2.' || quote_ident(n_geom) || '))=false  )';
    raise debug '%',p_ret;	
    EXECUTE p_ret;	

    -- second temp table with locus (index of intersection point on the line)
    -- to avoid updating the previous table
    -- we keep only intersection points occuring onto the line, not at one of its ends
--    drop table if exists inter_loc;

--HAD TO CHANGE THIS QUERY
    p_ret= 'create temp table inter_loc on commit drop as ( select * from (
        (select l1id, l2id, ' || vst_line_locate_point || '(line,source) as locus from intergeom)
         union
        (select l1id, l2id, ' || vst_line_locate_point || '(line,target) as locus from intergeom)) as foo
        where locus<>0 and locus<>1)';
    raise debug  '%',p_ret;	
    EXECUTE p_ret;	

    -- index on l1id
    create index inter_loc_id_idx on inter_loc(l1id);

    -- Then computes the intersection on the lines subset, which is much smaller than full set 
    -- as there are very few intersection points

--- outab needs to be formally created with id, old_id, subid,the_geom, source,target
---  so it can be inmediatly be used with createTopology

--   EXECUTE 'drop table if exists ' || pgr_quote_ident(outtab);
--   EXECUTE 'create table ' || pgr_quote_ident(outtab) || ' as 
     P_RET = 'insert into '||pgr_quote_ident(outtab)||' (old_id,sub_id,'||quote_ident(n_geom)||') (  with cut_locations as (
           select l1id as lid, locus 
           from inter_loc
           -- then generates start and end locus for each line that have to be cut buy a location point
           UNION ALL
           select i.l1id  as lid, 0 as locus
           from inter_loc i left join ' || pgr_quote_ident(intab) || ' b on (i.l1id = b.' || quote_ident(n_pkey) || ')
           UNION ALL
           select i.l1id  as lid, 1 as locus
           from inter_loc i left join ' || pgr_quote_ident(intab) || ' b on (i.l1id = b.' || quote_ident(n_pkey) || ')
           order by lid, locus
       ), 
       -- we generate a row_number index column for each input line 
       -- to be able to self-join the table to cut a line between two consecutive locations 
       loc_with_idx as (
           select lid, locus, row_number() over (partition by lid order by locus) as idx
           from cut_locations
       ) 
       -- finally, each original line is cut with consecutive locations using linear referencing functions
       select l.' || quote_ident(n_pkey) || ', loc1.idx as sub_id, ' || vst_line_substring || '(l.' || quote_ident(n_geom) || ', loc1.locus, loc2.locus) as ' || quote_ident(n_geom) || ' 
       from loc_with_idx loc1 join loc_with_idx loc2 using (lid) join ' || pgr_quote_ident(intab) || ' l on (l.' || quote_ident(n_pkey) || ' = loc1.lid)
       where loc2.idx = loc1.idx+1
           -- keeps only linestring geometries
           and geometryType(' || vst_line_substring || '(l.' || quote_ident(n_geom) || ', loc1.locus, loc2.locus)) = ''LINESTRING'') ';
    raise debug  '%',p_ret;	
    EXECUTE p_ret;	
	GET DIAGNOSTICS splits = ROW_COUNT;
        execute 'with diff as (select distinct old_id from '||pgr_quote_ident(outtab)||' )
                 select count(*) from diff' into touched; 
	-- here, it misses all original line that did not need to be cut by intersection points: these lines
	-- are already clean
	-- inserts them in the final result: all lines which gid is not in the res table.
	EXECUTE 'insert into ' || pgr_quote_ident(outtab) || ' (old_id , sub_id, ' || quote_ident(n_geom) || ')
                ( with used as (select distinct old_id from '|| pgr_quote_ident(outtab)||')
		select ' ||  quote_ident(n_pkey) || ', 1 as sub_id, ' ||  quote_ident(n_geom) ||
		' from '|| pgr_quote_ident(intab) ||' where  '||quote_ident(n_pkey)||' not in (select * from used))';
	GET DIAGNOSTICS untouched = ROW_COUNT;

	raise NOTICE '  Splitted Edges: %', touched;
	raise NOTICE ' Untouched Edges: %', untouched;
	raise NOTICE '     Total original Edges: %', touched+untouched;
        RAISE NOTICE ' Edges generated: %', splits;
	raise NOTICE ' Untouched Edges: %',untouched;
	raise NOTICE '       Total New segments: %', splits+untouched;
        RAISE NOTICE ' New Table: %', outtab;
        RAISE NOTICE '----------------------------------';

    drop table  if exists intergeom;
    drop table if exists inter_loc;
    RETURN 'OK';
END;
$BODY$
    LANGUAGE 'plpgsql' VOLATILE STRICT COST 100;


COMMENT ON FUNCTION pgr_nodeNetwork(text,tolerance double precision, 
                        text,  text ,  text )
 IS  'edge_table, tolerance, id:=''id'', the_geom:=''the_geom'', table_ending:=''noded'' ';

--
-- Copyright (c) 2005 Sylvain Pasche,
--               2006-2007 Anton A. Patrushev, Orkney, Inc.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
--


-----------------------------------------------------------------------
-- Core function for shortest_path_astar computation
-- Simillar to shortest_path in usage but uses the A* algorithm
-- instead of Dijkstra's.
-----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION pgr_astar(sql text, source_id integer, target_id integer, directed boolean, has_reverse_cost boolean)
    RETURNS SETOF pgr_costResult
    AS '$libdir/librouting', 'shortest_path_astar'
    LANGUAGE c IMMUTABLE STRICT; 
-----------------------------------------------------------------------
-- Core function for bi_directional_astar_shortest_path computation
-- See README for description
-----------------------------------------------------------------------
--
--

CREATE OR REPLACE FUNCTION pgr_bdAstar(
		sql text, 
		source_vid integer, 
        target_vid integer, 
        directed boolean, 
        has_reverse_cost boolean)
        RETURNS SETOF pgr_costResult
        AS '$libdir/librouting_bd', 'bidir_astar_shortest_path'
        LANGUAGE 'c' IMMUTABLE STRICT;

--
-- Copyright (c) 2005 Sylvain Pasche,
--               2006-2007 Anton A. Patrushev, Orkney, Inc.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
--


-----------------------------------------------------------------------
-- Core function for Dijkstra shortest_path computation
-----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION pgr_dijkstra(sql text, source_id integer, 
        target_id integer, directed boolean, has_reverse_cost boolean)
        RETURNS SETOF pgr_costResult
        AS '$libdir/librouting', 'shortest_path'
        LANGUAGE c IMMUTABLE STRICT;

-----------------------------------------------------------------------
-- Core function for one_to_many_dijkstra_shortest_path computation
-----------------------------------------------------------------------
--
--

/*CREATE TYPE dist_result AS (vertex_id_source integer, edge_id_source integer, vertex_id_target integer, edge_id_target integer, cost float8);
CREATE TYPE concatpath_result AS (vertex_id_source integer, edge_id_source integer, vertex_id_target integer, edge_id_target integer, cost float8, the_way text);

CREATE OR REPLACE FUNCTION KDijkstra_dist_sp(
	    sql text,
		source_vid integer, 
        target_vid integer array, 
        directed boolean, 
        has_reverse_cost boolean)
        RETURNS SETOF dist_result
        AS '$libdir/librouting', 'onetomany_dijkstra_dist'
        LANGUAGE C IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION KDijkstra_ways_sp(
	    sql text,
		source_vid integer, 
        target_vid integer array, 
        directed boolean, 
        has_reverse_cost boolean)
        RETURNS SETOF concatpath_result
        AS '$libdir/librouting', 'onetomany_dijkstra_path'
        LANGUAGE C IMMUTABLE STRICT;
*/

CREATE OR REPLACE FUNCTION pgr_kdijkstracost(
    sql text,
    source_vid integer,
    target_vid integer array,
    directed boolean,
    has_reverse_cost boolean)
    RETURNS SETOF pgr_costResult
    AS '$libdir/librouting', 'onetomany_dijkstra_dist'
    LANGUAGE C IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION pgr_kdijkstrapath(
    sql text,
    source_vid integer,
    target_vid integer array,
    directed boolean,
    has_reverse_cost boolean)
    RETURNS SETOF pgr_costResult3
    AS '$libdir/librouting', 'onetomany_dijkstra_path'
    LANGUAGE C IMMUTABLE STRICT;


-----------------------------------------------------------------------
-- Core function for bi_directional_dijkstra_shortest_path computation
-- See README for description
-----------------------------------------------------------------------
--
--

CREATE OR REPLACE FUNCTION pgr_bdDijkstra(
		sql text, 
		source_vid integer, 
        target_vid integer, 
        directed boolean, 
        has_reverse_cost boolean)
        RETURNS SETOF pgr_costResult
        AS '$libdir/librouting_bd', 'bidir_dijkstra_shortest_path'
        LANGUAGE c IMMUTABLE STRICT;


CREATE OR REPLACE FUNCTION pgr_apspJohnson(sql text)
    RETURNS SETOF pgr_costResult
    AS '$libdir/librouting', 'apsp_johnson'
LANGUAGE C IMMUTABLE STRICT;


CREATE OR REPLACE FUNCTION pgr_apspWarshall(sql text, directed boolean, has_reverse_cost boolean)
    RETURNS SETOF pgr_costResult
    AS '$libdir/librouting', 'apsp_warshall'
    LANGUAGE 'c' IMMUTABLE STRICT;
-----------------------------------------------------------------------
-- Core function for time_dependent_shortest_path computation
-- See README for description
-----------------------------------------------------------------------
--TODO - Do we need to add another sql text for the query on time-dependent-weights table?
--     - For now just checking with static data, so the query is similar to shortest_paths.

CREATE OR REPLACE FUNCTION pgr_trsp(
		sql text, 
		source_vid integer, 
        target_vid integer, 
        directed boolean, 
        has_reverse_cost boolean, 
        turn_restrict_sql text DEFAULT null)
        RETURNS SETOF pgr_costResult
        AS '$libdir/librouting', 'turn_restrict_shortest_path_vertex'
        LANGUAGE 'c' IMMUTABLE;

CREATE OR REPLACE FUNCTION pgr_trsp(
		sql text, 
		source_eid integer, 
        source_pos float8,
        target_eid integer,
        target_pos float8,
        directed boolean, 
        has_reverse_cost boolean, 
        turn_restrict_sql text DEFAULT null)
        RETURNS SETOF pgr_costResult
        AS '$libdir/librouting', 'turn_restrict_shortest_path_edge'
        LANGUAGE 'c' IMMUTABLE;

--
-- Copyright (c) 2013 Stephen Woodbridge
--
-- This files is released under an MIT-X license.
--


-----------------------------------------------------------------------
-- Core function for TSP
-----------------------------------------------------------------------
/*
 * select seq, id from pgr_tsp(matrix float8[][], start int,
 *                             OUT seq int, OUT id int);
*/
-- endpt does not work, and is ignored in the code at the moment
-- we hope to support it in the future but the tsp algorithm needs to
-- change or be replaced to support this functionality.
CREATE OR REPLACE FUNCTION pgr_tsp(matrix float8[][], startpt integer, endpt integer DEFAULT -1, OUT seq integer, OUT id integer)

--CREATE OR REPLACE FUNCTION pgr_tsp(matrix float8[][], startpt integer, OUT seq integer, OUT id integer)
    RETURNS SETOF record
    AS '$libdir/librouting_tsp', 'tsp_matrix'
    LANGUAGE c IMMUTABLE STRICT;
--
-- Copyright (c) 2013 Stephen Woodbridge
--
-- This files is released under an MIT-X license.
--



create or replace function pgr_makeDistanceMatrix(sqlin text, OUT dmatrix double precision[], OUT ids integer[])
  as
$body$
declare
    sql text;
    r record;
    
begin
    dmatrix := array[]::double precision[];
    ids := array[]::integer[];

    sql := 'with nodes as (' || sqlin || ')
        select i, array_agg(dist) as arow from (
            select a.id as i, b.id as j, st_distance(st_makepoint(a.x, a.y), st_makepoint(b.x, b.y)) as dist
              from nodes a, nodes b
             order by a.id, b.id
           ) as foo group by i order by i';

    for r in execute sql loop
        dmatrix := array_cat(dmatrix, array[r.arow]);
        ids := ids || array[r.i];
    end loop;

end;
$body$
language plpgsql stable cost 10;



create or replace function pgr_tsp(sql text, start_id integer, end_id integer default (-1))
    returns setof pgr_costResult as
$body$
declare
    sid integer;
    eid integer;
    
begin

    return query with dm  as (
        select * from pgr_makeDistanceMatrix( sql )
    ),
    ids as (
        select (row_number() over (order by id asc))-1 as rnum, id
          from (
                select unnest(ids) as id
                  from dm
                ) foo
    ), 
    t as (
        select a.seq, b.rnum, b.id
          from pgr_tsp(
                   (select dmatrix from dm),
                   (select rnum from ids where id=start_id)::integer,
                   (case when end_id = -1 then -1 else (select rnum from ids where id=end_id) end)::integer
               ) a,
               ids b
         where a.id=b.rnum
    ),
    r as (
        select array_agg(t.rnum) as rnum from t 
    )
    select t.seq::integer, 
           t.rnum::integer as id1, 
           t.id::integer as id2, 
           dm.dmatrix[r.rnum[t.seq+1]+1][r.rnum[(t.seq+1)%array_length(r.rnum, 1)+1]+1]::float8 as cost
      from t, dm, r;
end;
$body$
language plpgsql volatile cost 50 rows 50;


-----------------------------------------------------------------------
-- Function for k shortest_path computation
-- See README for description
-----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION pgr_ksp(sql text, source_id integer, target_id integer, no_paths integer, has_reverse_cost boolean)
    RETURNS SETOF pgr_costResult3
    AS '$libdir/librouting_ksp', 'kshortest_path'
    LANGUAGE c IMMUTABLE STRICT;

--
-- Copyright (c) 2005 Sylvain Pasche,
--               2006-2007 Anton A. Patrushev, Orkney, Inc.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
--

-----------------------------------------------------------------------
-- Core function for driving distance.
-- The sql should return edge and vertex ids.
-----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION pgr_drivingDistance(sql text, source_id integer, distance float8, directed boolean, has_reverse_cost boolean)
    RETURNS SETOF pgr_costResult
    AS '$libdir/librouting_dd', 'driving_distance'
    LANGUAGE c IMMUTABLE STRICT;
                        
-----------------------------------------------------------------------
-- Core function for alpha shape computation.
-- The sql should return vertex ids and x,y values. Return ordered
-- vertex ids. 
-----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION pgr_alphashape(sql text, OUT x float8, OUT y float8)
    RETURNS SETOF record
    AS '$libdir/librouting_dd', 'alphashape'
    LANGUAGE c IMMUTABLE STRICT;

----------------------------------------------------------
-- Draws an alpha shape around given set of points.
-- ** This should be rewritten as an aggregate. **
----------------------------------------------------------
CREATE OR REPLACE FUNCTION pgr_pointsAsPolygon(query varchar)
	RETURNS geometry AS
	$$
	DECLARE
		r record;
		path_result record;					     
		i int;							     
		q text;
		x float8[];
		y float8[];

	BEGIN	
		i := 1;								     
		q := 'SELECT ST_GeometryFromText(''POLYGON((';

		FOR path_result IN EXECUTE 'SELECT x, y FROM pgr_alphashape('''|| query || ''')' 
		LOOP
			x[i] = path_result.x;
			y[i] = path_result.y;
			i := i+1;
		END LOOP;

		q := q || x[1] || ' ' || y[1];
		i := 2;

		WHILE x[i] IS NOT NULL 
		LOOP
			q := q || ', ' || x[i] || ' ' || y[i];
			i := i + 1;
		END LOOP;

		q := q || ', ' || x[1] || ' ' || y[1] || '))'',0) AS geom';

		EXECUTE q INTO r;
		RETURN r.geom;
	END;
	$$
	LANGUAGE 'plpgsql' VOLATILE STRICT;


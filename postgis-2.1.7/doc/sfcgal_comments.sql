
COMMENT ON FUNCTION postgis_sfcgal_version() IS 'Returns the version of SFCGAL in use';
			
COMMENT ON FUNCTION ST_Extrude(geometry, float, float, float) IS 'args: geom, x, y, z - Extrude a surface to a related volume';
			
COMMENT ON FUNCTION ST_StraightSkeleton(geometry) IS 'args: geom - Compute a straight skeleton from a geometry';
			
COMMENT ON FUNCTION ST_Orientation(geometry) IS 'args: geom - Determine surface orientation';
			
COMMENT ON FUNCTION ST_ForceLHR(geometry) IS 'args: geom - Force LHR orientation';
			
COMMENT ON FUNCTION ST_MinkowskiSum(geometry, geometry) IS 'args: geom1, geom2 - Performs Minkowski sum';
			
COMMENT ON FUNCTION ST_3DIntersection(geometry, geometry) IS 'args: geom1, geom2 - Perform 3D intersection';
			
COMMENT ON FUNCTION ST_3DArea(geometry) IS 'args: geom1 - Computes area of 3D geometries';
			
COMMENT ON FUNCTION ST_Tesselate(geometry) IS 'args: geom - Perform surface Tesselation';
			
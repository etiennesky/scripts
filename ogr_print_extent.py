#!/usr/bin/env python


from osgeo import gdal
from osgeo import ogr
from osgeo import osr
from osgeo.gdalconst import *
from osgeo.gdal_array import *
import sys, time
import numpy as np
import os

import ogr

ds = ogr.Open( "wrs2_descending_SA_PRODES.shp" )
if ds is None:
    print "Open failed.\n"
    sys.exit( 1 )

lyr = ds.GetLayer( 0 )

lyr.ResetReading()

        #check polygon layer extent
extent = lyr.GetExtent(True)

#print '========Polygon Bounding Box========'
#print 'UL: ', extent[0], extent[3]
#print 'LR: ', extent[1], extent[2]

feat_defn = lyr.GetLayerDefn()
field_i = feat_defn.GetFieldIndex("PR_PRODES")

for feat in lyr:

    
#    XUL = extent[0]
#    YUL = extent[3]
#    XLR = extent[1]
#    YLR = extent[2]

#    for i in range(feat_defn.GetFieldCount()):
#        field_defn = feat_defn.GetFieldDefn(i)

#        # Tests below can be simplified with just :
#        # print feat.GetField(i)
#        if field_defn.GetType() == ogr.OFTInteger:
#            print "%d" % feat.GetFieldAsInteger(i)
#        elif field_defn.GetType() == ogr.OFTReal:
#            print "%.3f" % feat.GetFieldAsDouble(i)
#        elif field_defn.GetType() == ogr.OFTString:
#            print "%s" % feat.GetFieldAsString(i)
#        else:
#            print "%s" % feat.GetFieldAsString(i)

    geom = feat.GetGeometryRef()
    if geom is not None and geom.GetGeometryType() == ogr.wkbPoint:
        print "%.3f, %.3f" % ( geom.GetX(), geom.GetY() )
    else:
 #       print "no point geometry\n"
        extent = geom.GetEnvelope()
#        print '========Polygon Bounding Box========'
        #UL:  -74.2351 -3.45891
        #LR:  -72.2613 -5.22013
#        print 'UL: ', extent[0], extent[3]
#        print 'LR: ', extent[1], extent[2]
        fld_name=feat.GetFieldAsString(field_i)
        nc_file="out/trmm_%s.nc" % (fld_name)
        cmd="cdo -s yearmean -fldmean -sellonlatbox,%f,%f,%f,%f trmm_sam_2000_2010.nc %s" % (extent[0],extent[1],extent[3],extent[2],nc_file)
#        print(cmd)
        out_str = os.popen(cmd).read()
#        print(out_str)
        cmd='cdo -s output,"%8.4g",12 '+nc_file
#        print(cmd)
        out_str = os.popen(cmd).read()
#        print(out_str)
        tmp_vals=out_str.lstrip().rstrip().replace('\n', ',').replace(' ', '')
        print(fld_name+','+tmp_vals)


ds = None




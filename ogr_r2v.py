#!/usr/bin/env python
#/******************************************************************************
# * $Id$
# *
# * Project:  OpenGIS Simple Features Reference Implementation
# * Purpose:  Python port of a simple client for translating between formats.
# * Author:   Even Rouault, <even dot rouault at mines dash paris dot org>
# *
# * Port from ogr2ogr.cpp whose author is Frank Warmerdam
# *
# ******************************************************************************
# * Copyright (c) 2010, Even Rouault
# * Copyright (c) 1999, Frank Warmerdam
# *
# * Permission is hereby granted, free of charge, to any person obtaining a
# * copy of this software and associated documentation files (the "Software"),
# * to deal in the Software without restriction, including without limitation
# * the rights to use, copy, modify, merge, publish, distribute, sublicense,
# * and/or sell copies of the Software, and to permit persons to whom the
# * Software is furnished to do so, subject to the following conditions:
# *
# * The above copyright notice and this permission notice shall be included
# * in all copies or substantial portions of the Software.
# *
# * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# * DEALINGS IN THE SOFTWARE.
# ****************************************************************************/

# Note : this is the most direct port of ogr2ogr.cpp possible
# It could be made much more Python'ish !

import sys
import os
import stat

try:
    from osgeo import gdal
    from osgeo import ogr
    from osgeo import osr
    from osgeo.gdalconst import *
except:
    import gdal
    import ogr
    import osr
    from gdalconst import *

###############################################################################

class ScaledProgressObject:
    def __init__(self, min, max, cbk, cbk_data = None):
        self.min = min
        self.max = max
        self.cbk = cbk
        self.cbk_data = cbk_data

###############################################################################

def ScaledProgressFunc(pct, msg, data):
    if data.cbk is None:
        return True
    return data.cbk(data.min + pct * (data.max - data.min), msg, data.cbk_data)

###############################################################################

def EQUAL(a, b):
    return a.lower() == b.lower()

###############################################################################
# Redefinition of GDALTermProgress, so that autotest/pyscripts/test_ogr2ogr_py.py
# can check that the progress bar is displayed

nLastTick = -1

def TermProgress( dfComplete, pszMessage, pProgressArg ):

    global nLastTick;
    nThisTick = (int) (dfComplete * 40.0);

    if nThisTick < 0:
        nThisTick = 0
    if nThisTick > 40:
        nThisTick = 40

    # Have we started a new progress run?  
    if nThisTick < nLastTick and nLastTick >= 39:
        nLastTick = -1;

    if nThisTick <= nLastTick:
        return True

    while nThisTick > nLastTick:
        nLastTick = nLastTick + 1
        if (nLastTick % 4) == 0:
            sys.stdout.write('%d' % ((nLastTick / 4) * 10))
        else:
            sys.stdout.write('.')

    if nThisTick == 40:
        print(" - done." )
    else:
        sys.stdout.flush()

    return True


#/************************************************************************/
#/*                                main()                                */
#/************************************************************************/

bSkipFailures = False
nGroupTransactions = 200
bPreserveFID = False
nFIDToFetch = ogr.NullFID

class Enum(set):
    def __getattr__(self, name):
        if name in self:
            return name
        raise AttributeError

GeomOperation = Enum(["NONE", "SEGMENTIZE", "SIMPLIFY_PRESERVE_TOPOLOGY"])

def main(args = None, progress_func = TermProgress, progress_data = None):
    
    global bSkipFailures
    global nGroupTransactions
    global bPreserveFID
    global nFIDToFetch
    
    pszFormat = "ESRI Shapefile"
    pszDataSource = None
    pszDestDataSource = None
    papszLayers = []
    papszDSCO = []
    papszLCO = []
    bTransform = False
    bAppend = False
    bUpdate = False
    bOverwrite = False
    pszOutputSRSDef = None
    pszSourceSRSDef = None
    poOutputSRS = None
    poSourceSRS = None
    pszNewLayerName = None
    pszWHERE = None
    poSpatialFilter = None
    pszSelect = None
    papszSelFields = None
    pszSQLStatement = None
    eGType = -2
    eGeomOp = GeomOperation.NONE
    dfGeomOpParam = 0
    papszFieldTypesToString = []
    bDisplayProgress = False
    pfnProgress = None
    pProgressData = None
    bClipSrc = False
    poClipSrc = None
    pszClipSrcDS = None
    pszClipSrcSQL = None
    pszClipSrcLayer = None
    pszClipSrcWhere = None
    poClipDst = None
    pszClipDstDS = None
    pszClipDstSQL = None
    pszClipDstLayer = None
    pszClipDstWhere = None
    pszSrcEncoding = None
    pszDstEncoding = None
    bExplodeCollections = False
    pszZField = None

    if args is None:
        args = sys.argv

    args = ogr.GeneralCmdLineProcessor( args )

#/* -------------------------------------------------------------------- */
#/*      Processing command line arguments.                              */
#/* -------------------------------------------------------------------- */
    if args is None:
        return False

    nArgc = len(args)

    iArg = 1
    while iArg < nArgc:
        if EQUAL(args[iArg],"-f") and iArg < nArgc-1:
            iArg = iArg + 1
            pszFormat = args[iArg]

        elif EQUAL(args[iArg],"-dsco") and iArg < nArgc-1:
            iArg = iArg + 1
            papszDSCO.append(args[iArg] )

        elif EQUAL(args[iArg],"-lco") and iArg < nArgc-1:
            iArg = iArg + 1
            papszLCO.append(args[iArg] )

        elif EQUAL(args[iArg],"-preserve_fid"):
            bPreserveFID = True

        elif len(args[iArg]) >= 5 and EQUAL(args[iArg][0:5], "-skip"):
            bSkipFailures = True
            nGroupTransactions = 1 # /* #2409 */

        elif EQUAL(args[iArg],"-append"):
            bAppend = True
            bUpdate = True

        elif EQUAL(args[iArg],"-overwrite"):
            bOverwrite = True
            bUpdate = True

        elif EQUAL(args[iArg],"-update"):
            bUpdate = True

        elif EQUAL(args[iArg],"-fid") and iArg < nArgc-1:
            iArg = iArg + 1
            nFIDToFetch = int(args[iArg])

        elif EQUAL(args[iArg],"-sql") and iArg < nArgc-1:
            iArg = iArg + 1
            pszSQLStatement = args[iArg]

        elif EQUAL(args[iArg],"-nln") and iArg < nArgc-1:
            iArg = iArg + 1
            pszNewLayerName = args[iArg]

        elif EQUAL(args[iArg],"-nlt") and iArg < nArgc-1:

            if EQUAL(args[iArg+1],"NONE"):
                eGType = ogr.wkbNone
            elif EQUAL(args[iArg+1],"GEOMETRY"):
                eGType = ogr.wkbUnknown
            elif EQUAL(args[iArg+1],"POINT"):
                eGType = ogr.wkbPoint
            elif EQUAL(args[iArg+1],"LINESTRING"):
                eGType = ogr.wkbLineString
            elif EQUAL(args[iArg+1],"POLYGON"):
                eGType = ogr.wkbPolygon
            elif EQUAL(args[iArg+1],"GEOMETRYCOLLECTION"):
                eGType = ogr.wkbGeometryCollection
            elif EQUAL(args[iArg+1],"MULTIPOINT"):
                eGType = ogr.wkbMultiPoint
            elif EQUAL(args[iArg+1],"MULTILINESTRING"):
                eGType = ogr.wkbMultiLineString
            elif EQUAL(args[iArg+1],"MULTIPOLYGON"):
                eGType = ogr.wkbMultiPolygon
            elif EQUAL(args[iArg+1],"GEOMETRY25D"):
                eGType = ogr.wkbUnknown | ogr.wkb25DBit
            elif EQUAL(args[iArg+1],"POINT25D"):
                eGType = ogr.wkbPoint25D
            elif EQUAL(args[iArg+1],"LINESTRING25D"):
                eGType = ogr.wkbLineString25D
            elif EQUAL(args[iArg+1],"POLYGON25D"):
                eGType = ogr.wkbPolygon25D
            elif EQUAL(args[iArg+1],"GEOMETRYCOLLECTION25D"):
                eGType = ogr.wkbGeometryCollection25D
            elif EQUAL(args[iArg+1],"MULTIPOINT25D"):
                eGType = ogr.wkbMultiPoint25D
            elif EQUAL(args[iArg+1],"MULTILINESTRING25D"):
                eGType = ogr.wkbMultiLineString25D
            elif EQUAL(args[iArg+1],"MULTIPOLYGON25D"):
                eGType = ogr.wkbMultiPolygon25D
            else:
                print("-nlt %s: type not recognised." % args[iArg+1])
                return False

            iArg = iArg + 1

        elif (EQUAL(args[iArg],"-tg") or \
                EQUAL(args[iArg],"-gt")) and iArg < nArgc-1:
            iArg = iArg + 1
            nGroupTransactions = int(args[iArg])

        elif EQUAL(args[iArg],"-s_srs") and iArg < nArgc-1:
            iArg = iArg + 1
            pszSourceSRSDef = args[iArg]

        elif EQUAL(args[iArg],"-a_srs") and iArg < nArgc-1:
            iArg = iArg + 1
            pszOutputSRSDef = args[iArg]

        elif EQUAL(args[iArg],"-t_srs") and iArg < nArgc-1:
            iArg = iArg + 1
            pszOutputSRSDef = args[iArg]
            bTransform = True

        elif EQUAL(args[iArg],"-spat") and iArg + 4 < nArgc:
            oRing = ogr.Geometry(ogr.wkbLinearRing)

            oRing.AddPoint_2D( float(args[iArg+1]), float(args[iArg+2]) )
            oRing.AddPoint_2D( float(args[iArg+1]), float(args[iArg+4]) )
            oRing.AddPoint_2D( float(args[iArg+3]), float(args[iArg+4]) )
            oRing.AddPoint_2D( float(args[iArg+3]), float(args[iArg+2]) )
            oRing.AddPoint_2D( float(args[iArg+1]), float(args[iArg+2]) )

            poSpatialFilter = ogr.Geometry(ogr.wkbPolygon)
            poSpatialFilter.AddGeometry(oRing)
            iArg = iArg + 4

        elif EQUAL(args[iArg],"-where") and iArg < nArgc-1:
            iArg = iArg + 1
            pszWHERE = args[++iArg]

        elif EQUAL(args[iArg],"-select") and iArg < nArgc-1:
            iArg = iArg + 1
            pszSelect = args[iArg]
            if pszSelect.find(',') != -1:
                papszSelFields = pszSelect.split(',')
            else:
                papszSelFields = pszSelect.split(' ')
            if papszSelFields[0] == '':
                papszSelFields = []

        elif EQUAL(args[iArg],"-simplify") and iArg < nArgc-1:
            iArg = iArg + 1
            eGeomOp = GeomOperation.SIMPLIFY_PRESERVE_TOPOLOGY
            dfGeomOpParam = float(args[iArg])

        elif EQUAL(args[iArg],"-segmentize") and iArg < nArgc-1:
            iArg = iArg + 1
            eGeomOp = GeomOperation.SEGMENTIZE
            dfGeomOpParam = float(args[iArg])

        elif EQUAL(args[iArg],"-fieldTypeToString") and iArg < nArgc-1:
            iArg = iArg + 1
            pszFieldTypeToString = args[iArg]
            if pszFieldTypeToString.find(',') != -1:
                tokens = pszFieldTypeToString.split(',')
            else:
                tokens = pszFieldTypeToString.split(' ')

            for token in tokens:
                if EQUAL(token,"Integer") or \
                    EQUAL(token,"Real") or \
                    EQUAL(token,"String") or \
                    EQUAL(token,"Date") or \
                    EQUAL(token,"Time") or \
                    EQUAL(token,"DateTime") or \
                    EQUAL(token,"Binary") or \
                    EQUAL(token,"IntegerList") or \
                    EQUAL(token,"RealList") or \
                    EQUAL(token,"StringList"):

                    papszFieldTypesToString.append(token)

                elif EQUAL(token,"All"):
                    papszFieldTypesToString = [ 'All' ]
                    break

                else:
                    print("Unhandled type for fieldtypeasstring option : %s " % token)
                    return Usage()

        elif EQUAL(args[iArg],"-progress"):
            bDisplayProgress = True

        #/*elif EQUAL(args[iArg],"-wrapdateline") )
        #{
        #    bWrapDateline = True;
        #}
        #*/
        elif EQUAL(args[iArg],"-clipsrc") and iArg < nArgc-1:

            bClipSrc = True
            if IsNumber(args[iArg+1]) and iArg < nArgc - 4:
                oRing = ogr.Geometry(ogr.wkbLinearRing)

                oRing.AddPoint_2D( float(args[iArg+1]), float(args[iArg+2]) )
                oRing.AddPoint_2D( float(args[iArg+1]), float(args[iArg+4]) )
                oRing.AddPoint_2D( float(args[iArg+3]), float(args[iArg+4]) )
                oRing.AddPoint_2D( float(args[iArg+3]), float(args[iArg+2]) )
                oRing.AddPoint_2D( float(args[iArg+1]), float(args[iArg+2]) )

                poClipSrc = ogr.Geometry(ogr.wkbPolygon)
                poClipSrc.AddGeometry(oRing)
                iArg = iArg + 4

            elif (len(args[iArg+1]) >= 7 and EQUAL(args[iArg+1][0:7],"POLYGON") ) or \
                  (len(args[iArg+1]) >= 12 and EQUAL(args[iArg+1][0:12],"MULTIPOLYGON") ) :
                poClipSrc = ogr.CreateGeometryFromWkt(args[iArg+1])
                if poClipSrc is None:
                    print("FAILURE: Invalid geometry. Must be a valid POLYGON or MULTIPOLYGON WKT\n")
                    return Usage()

                iArg = iArg + 1

            elif EQUAL(args[iArg+1],"spat_extent"):
                iArg = iArg + 1

            else:
                pszClipSrcDS = args[iArg+1]
                iArg = iArg + 1

        elif EQUAL(args[iArg],"-clipsrcsql") and iArg < nArgc-1:
            pszClipSrcSQL = args[iArg+1]
            iArg = iArg + 1

        elif EQUAL(args[iArg],"-clipsrclayer") and iArg < nArgc-1:
            pszClipSrcLayer = args[iArg+1]
            iArg = iArg + 1

        elif EQUAL(args[iArg],"-clipsrcwhere") and iArg < nArgc-1:
            pszClipSrcWhere = args[iArg+1]
            iArg = iArg + 1

        elif EQUAL(args[iArg],"-clipdst") and iArg < nArgc-1:

            if IsNumber(args[iArg+1]) and iArg < nArgc - 4:
                oRing = ogr.Geometry(ogr.wkbLinearRing)

                oRing.AddPoint_2D( float(args[iArg+1]), float(args[iArg+2]) )
                oRing.AddPoint_2D( float(args[iArg+1]), float(args[iArg+4]) )
                oRing.AddPoint_2D( float(args[iArg+3]), float(args[iArg+4]) )
                oRing.AddPoint_2D( float(args[iArg+3]), float(args[iArg+2]) )
                oRing.AddPoint_2D( float(args[iArg+1]), float(args[iArg+2]) )

                poClipDst = ogr.Geometry(ogr.wkbPolygon)
                poClipDst.AddGeometry(oRing)
                iArg = iArg + 4

            elif (len(args[iArg+1]) >= 7 and EQUAL(args[iArg+1][0:7],"POLYGON") ) or \
                  (len(args[iArg+1]) >= 12 and EQUAL(args[iArg+1][0:12],"MULTIPOLYGON") ) :
                poClipDst = ogr.CreateGeometryFromWkt(args[iArg+1])
                if poClipDst is None:
                    print("FAILURE: Invalid geometry. Must be a valid POLYGON or MULTIPOLYGON WKT\n")
                    return Usage()

                iArg = iArg + 1

            elif EQUAL(args[iArg+1],"spat_extent"):
                iArg = iArg + 1

            else:
                pszClipDstDS = args[iArg+1]
                iArg = iArg + 1

        elif EQUAL(args[iArg],"-clipdstsql") and iArg < nArgc-1:
            pszClipDstSQL = args[iArg+1]
            iArg = iArg + 1

        elif EQUAL(args[iArg],"-clipdstlayer") and iArg < nArgc-1:
            pszClipDstLayer = args[iArg+1]
            iArg = iArg + 1

        elif EQUAL(args[iArg],"-clipdstwhere") and iArg < nArgc-1:
            pszClipDstWhere = args[iArg+1]
            iArg = iArg + 1

        elif EQUAL(args[iArg],"-explodecollections"):
            bExplodeCollections = True

        elif EQUAL(args[iArg],"-zfield") and iArg < nArgc-1:
            pszZField = args[iArg+1]
            iArg = iArg + 1

        elif args[iArg][0] == '-':
            return Usage()

        elif pszDestDataSource is None:
            pszDestDataSource = args[iArg]
        elif pszDataSource is None:
            pszDataSource = args[iArg]
        else:
            papszLayers.append (args[iArg] )

        iArg = iArg + 1

    if pszDataSource is None:
        return Usage()

    if pszDestDataSource is None:
        return Usage()

    inds = gdal.Open( pszDataSource, GA_ReadOnly )
    if inds is None:
        print "Open of input file failed.\n"
        sys.exit( 1 )

    drv = ogr.GetDriverByName( pszFormat )
    if drv is None:
        print "%s driver not available.\n" % pszFormat
        sys.exit( 1 )


    outds = drv.CreateDataSource( pszDestDataSource )
    if outds is None:
        print "Creation of output file failed.\n"
        sys.exit( 1 )

    lyr = outds.CreateLayer( "layer", None, ogr.wkbPoint )
    if lyr is None:
        print "Layer creation failed.\n"
        sys.exit( 1 )
        
    field_defn = ogr.FieldDefn( "Value", ogr.OFTString )
    field_defn.SetWidth( 32 )

    if lyr.CreateField ( field_defn ) != 0:
        print "Creating Name field failed.\n"
        sys.exit( 1 )

    gt = inds.GetGeoTransform()
#    if gt is not None and gt != (0.0, 1.0, 0.0, 0.0, 0.0, 1.0):
#    outdataset.SetGeoTransform(gt)

    prj = inds.GetProjectionRef()
    print 'prj: '+str(prj)
    if prj is not None and len(prj) > 0:
        outds.SetProjection(prj)


#/* -------------------------------------------------------------------- */
#/*      Close down.                                                     */
#/* -------------------------------------------------------------------- */
    #/* We must explicetely destroy the output dataset in order the file */
    #/* to be properly closed ! */
    outds.Destroy()
    #inds.Destroy()
    inds = None

    return True

#/************************************************************************/
#/*                               Usage()                                */
#/************************************************************************/

def Usage():

    print( "Usage: ogr2ogr [--help-general] [-skipfailures] [-append] [-update] [-gt n]\n" + \
            "               [-select field_list] [-where restricted_where] \n" + \
            "               [-progress] [-sql <sql statement>] \n" + \
            "               [-spat xmin ymin xmax ymax] [-preserve_fid] [-fid FID]\n" + \
            "               [-a_srs srs_def] [-t_srs srs_def] [-s_srs srs_def]\n" + \
            "               [-f format_name] [-overwrite] [[-dsco NAME=VALUE] ...]\n" + \
            "               [-simplify tolerance]\n" + \
            #// "               [-segmentize max_dist] [-fieldTypeToString All|(type1[,type2]*)]\n" + \
            "               [-fieldTypeToString All|(type1[,type2]*)] [-explodecollections] \n" + \
            "               dst_datasource_name src_datasource_name\n" + \
            "               [-lco NAME=VALUE] [-nln name] [-nlt type] [layer [layer ...]]\n" + \
            "\n" + \
            " -f format_name: output file format name, possible values are:")

    for iDriver in range(ogr.GetDriverCount()):
        poDriver = ogr.GetDriver(iDriver)

        if poDriver.TestCapability( ogr.ODrCCreateDataSource ):
            print( "     -f \"" + poDriver.GetName() + "\"" )

    print( " -append: Append to existing layer instead of creating new if it exists\n" + \
            " -overwrite: delete the output layer and recreate it empty\n" + \
            " -update: Open existing output datasource in update mode\n" + \
            " -progress: Display progress on terminal. Only works if input layers have the \"fast feature count\" capability\n" + \
            " -select field_list: Comma-delimited list of fields from input layer to\n" + \
            "                     copy to the new layer (defaults to all)\n" + \
            " -where restricted_where: Attribute query (like SQL WHERE)\n" + \
            " -sql statement: Execute given SQL statement and save result.\n" + \
            " -skipfailures: skip features or layers that fail to convert\n" + \
            " -gt n: group n features per transaction (default 200)\n" + \
            " -spat xmin ymin xmax ymax: spatial query extents\n" + \
            " -simplify tolerance: distance tolerance for simplification.\n" + \
            #//" -segmentize max_dist: maximum distance between 2 nodes.\n" + \
            #//"                       Used to create intermediate points\n" + \
            " -dsco NAME=VALUE: Dataset creation option (format specific)\n" + \
            " -lco  NAME=VALUE: Layer creation option (format specific)\n" + \
            " -nln name: Assign an alternate name to the new layer\n" + \
            " -nlt type: Force a geometry type for new layer.  One of NONE, GEOMETRY,\n" + \
            "      POINT, LINESTRING, POLYGON, GEOMETRYCOLLECTION, MULTIPOINT,\n" + \
            "      MULTIPOLYGON, or MULTILINESTRING.  Add \"25D\" for 3D layers.\n" + \
            "      Default is type of source layer.\n" + \
            " -fieldTypeToString type1,...: Converts fields of specified types to\n" + \
            "      fields of type string in the new layer. Valid types are : \n" + \
            "      Integer, Real, String, Date, Time, DateTime, Binary, IntegerList, RealList,\n" + \
            "      StringList. Special value All can be used to convert all fields to strings.")

    print(" -a_srs srs_def: Assign an output SRS\n" + \
        " -t_srs srs_def: Reproject/transform to this SRS on output\n" + \
        " -s_srs srs_def: Override source SRS\n" + \
        "\n" + \
        " Srs_def can be a full WKT definition (hard to escape properly),\n" + \
        " or a well known definition (ie. EPSG:4326) or a file with a WKT\n" + \
        " definition." )

    return False

def CSLFindString(v, mystr):
    i = 0
    for strIter in v:
        if EQUAL(strIter, mystr):
            return i
        i = i + 1
    return -1

def IsNumber( pszStr):
    try:
        (float)(pszStr)
        return True
    except:
        return False

if __name__ == '__main__':
    version_num = int(gdal.VersionInfo('VERSION_NUM'))
    if version_num < 1800: # because of ogr.GetFieldTypeName
        print('ERROR: Python bindings of GDAL 1.8.0 or later required')
        sys.exit(1)

    if not main(sys.argv):
        sys.exit(1)
    else:
        sys.exit(0)


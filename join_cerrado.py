#!/usr/bin/env python
###############################################################################
# $Id$
#
# Project:  GDAL Python samples
# Purpose:  Script to replace specified values from the input raster file
#           with the new ones. May be useful in cases when you don't like
#           value, used for NoData indication and want replace it with other
#           value. Input file remains unchanged, results stored in other file.
# Author:   Andrey Kiselev, dron@remotesensing.org
#
###############################################################################
# Copyright (c) 2003, Andrey Kiselev <dron@remotesensing.org>
# 
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
###############################################################################


try:
    from osgeo import gdal
    from osgeo.gdalconst import *
    gdal.TermProgress = gdal.TermProgress_nocb
except ImportError:
    import gdal
    from gdalconst import *

try:
    import numpy
except ImportError:
    import Numeric as numpy

import sys, os
import inspect 
import string

# =============================================================================
def Usage():
    print('Usage: join_cerrado.py [-of out_format] [-ot out_type] [-co create_options]')
    print('                       infile1 infile2 outfile')
    print('')
    sys.exit( 1 )

# =============================================================================

# =============================================================================
def ParseType(type):
    gdal_dt = gdal.GetDataTypeByName(type)
    if gdal_dt is GDT_Unknown:
        gdal_dt = GDT_Byte
    return gdal_dt

# =============================================================================


infile1 = None
infile2 = None
outfile = None
format = 'GTiff'
type = GDT_Byte
#type = GDT_Int16
create_options = []
a_nodata = None#254

limit_anthrop = 18   #first index of anthropic vegtypes, only change values below this
deforest_year = 108  #which deforestation years to consider 2008=>108
deforest_value = 19  #default set deforested area to "agricultural", could be "deforested"
ref_year = 2008

# Parse command line arguments.
i = 1
while i < len(sys.argv):
    arg = sys.argv[i]

    if arg == '-of':
        i = i + 1
        format = sys.argv[i]

    elif arg == '-ot':
        i = i + 1
        type = ParseType(sys.argv[i])

    elif arg == '-a_nodata':
        i = i + 1
        a_nodata = float(sys.argv[i])

    elif arg == '-co':
        i = i + 1
        create_options.append( sys.argv[i] )

    elif infile1 is None:
        infile1 = arg
    elif infile2 is None:
        infile2 = arg

    elif outfile is None:
        outfile = arg

    else:
        Usage()

    i = i + 1


if infile1 is None:
    Usage()
if infile2 is None:
    Usage()
if outfile is None:
    Usage()

print infile1, infile2, outfile


#open datasets
indataset = gdal.Open( infile1, GA_ReadOnly )
if indataset is None:
    print('Unable to open %s' % infile1)
    sys.exit(1)
indataset2 = gdal.Open( infile2, GA_ReadOnly )
if indataset2 is None:
    print('Unable to open %s' % infile2)
    sys.exit(1)

#make sure input datasets are comparable
if indataset.GetGeoTransform() != indataset2.GetGeoTransform():
    print('Mismatch in input GT')
    sys.exit()
if indataset.GetProjectionRef() != indataset2.GetProjectionRef():
    print('Mismatch in input projection')
    sys.exit()
if indataset.RasterXSize != indataset2.RasterXSize:
    print('Mismatch in X Size')
    sys.exit()
if indataset.RasterYSize != indataset2.RasterYSize:
    print('Mismatch in Y Size')
    sys.exit()

#create out dataset from ifile1
out_driver = gdal.GetDriverByName(format)
if os.path.exists( outfile ):
    os.remove( outfile )
outdataset = out_driver.Create(outfile, indataset.RasterXSize, indataset.RasterYSize, 
                               indataset.RasterCount, type, create_options)
if outdataset is None:
    print('Unable to open %s' % outfile)
    sys.exit(1)

gt = indataset.GetGeoTransform()
if gt is not None and gt != (0.0, 1.0, 0.0, 0.0, 0.0, 1.0):
    outdataset.SetGeoTransform(gt)

prj = indataset.GetProjectionRef()
if prj is not None and len(prj) > 0:
    outdataset.SetProjection(prj)


for iBand in range(1, indataset.RasterCount + 1):
    inband = indataset.GetRasterBand(iBand)
    inband2 = indataset2.GetRasterBand(iBand)
    outband = outdataset.GetRasterBand(iBand)
    if a_nodata is not None:  outband.SetNoDataValue(a_nodata)
    else: outband.SetNoDataValue(inband.GetNoDataValue())
    print('nodata '+str(inband.GetNoDataValue())+' - '+str(outband.GetNoDataValue()) )
    for i in range(inband.YSize - 1, -1, -1):

        j=inband.YSize-i
        if j % 1000 == 0 :
            print(str(j)+' / ',str(inband.YSize))

        scanline = inband.ReadAsArray(0, i, inband.XSize, 1, inband.XSize, 1)
        scanline2 = inband2.ReadAsArray(0, i, inband.XSize, 1, inband.XSize, 1)
        to_modify = numpy.logical_and( numpy.less_equal(scanline2,deforest_year), numpy.less(scanline,limit_anthrop) )
        scanline = numpy.choose( to_modify, (scanline,deforest_value) )

        outband.WriteArray(scanline, 0, i)
        #outband.WriteArray(to_modify, 0, i)


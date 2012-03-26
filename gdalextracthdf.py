#!/usr/bin/env python
#******************************************************************************
#  $Id$
# 
#  Name:     gdalcopyproj.py
#  Project:  GDAL Python Interface
#  Purpose:  Duplicate the geotransform and projection metadata from
#	     one raster dataset to another, which can be useful after
#	     performing image manipulations with other software that
#	     ignores or discards georeferencing metadata.
#  Author:   Schuyler Erle, schuyler@nocat.net
# 
#******************************************************************************
#  Copyright (c) 2005, Frank Warmerdam
# 
#  Permission is hereby granted, free of charge, to any person obtaining a
#  copy of this software and associated documentation files (the "Software"),
#  to deal in the Software without restriction, including without limitation
#  the rights to use, copy, modify, merge, publish, distribute, sublicense,
#  and/or sell copies of the Software, and to permit persons to whom the
#  Software is furnished to do so, subject to the following conditions:
# 
#  The above copyright notice and this permission notice shall be included
#  in all copies or substantial portions of the Software.
# 
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
#  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
#  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
#  DEALINGS IN THE SOFTWARE.
#******************************************************************************

try:
    from osgeo import gdal
except ImportError:
    import gdal

import sys
import os.path


if len(sys.argv) < 2:
    print("Usage: gdalextracthdf.py source_file")
    sys.exit(1)

input = sys.argv[1]
input_base = os.path.splitext(input)[0]
#input_base = os.path.splitext(input_base)[0]

format = "GTiff"
driver_opts = [ 'COMPRESS=LZW' ]
driver = gdal.GetDriverByName( format )
dataset = gdal.Open( input )
if dataset is None:
    print('Unable to open', input, 'for reading')
    sys.exit(1)

projection   = dataset.GetProjection()
geotransform = dataset.GetGeoTransform()

sds_md = dataset.GetMetadata('SUBDATASETS')

print type(sds_md)
print sds_md

#sds_md =  sortedDictValues1(sds_md)
#sds_md.sort()
#print sds_md

#for key in sds_md :
#    print key

for key,value in sds_md.items() :
    is_name = key.find("_NAME") is not -1
    if is_name:
        last_i = value.rfind(":")
        if last_i is -1:
            print('Unable to extract info from subdataset ', key, value)
            sys.exit(1)
        ifile = value
        ofile = input_base + "." + value[last_i+1:] + ".tif"

#        print key, value, is_name, last_i, ofile
        print ofile, key, value

        ids = gdal.Open( ifile )
        if ids is None:
            print('Unable to open', ifile, 'for reading')
            sys.exit(1)     
        ods = driver.CreateCopy( ofile, ids, 0, driver_opts )
        if ods is None:
            print('Unable to create', ofile)
            sys.exit(1)     
        ids = None
        ods = None

#now:
#   sds_name = sds_md[key]

#   x = gdalnumeric.LoadFile(sds_name)

sys.exit(0)


output = sys.argv[2]
dataset2 = gdal.Open( output, gdal.GA_Update )

if dataset2 is None:
    print('Unable to open', output, 'for writing')
    sys.exit(1)

if geotransform is not None:
    dataset2.SetGeoTransform( geotransform )

if projection is not None:
    dataset2.SetProjection( projection )


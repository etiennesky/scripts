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
import subprocess
import math
from collections import OrderedDict


ifile = sys.argv[1]
ifile_base = os.path.splitext(ifile)[0]
#input_base = os.path.splitext(input_base)[0]
ofile = ifile_base + '.vrt'

format = 'VRT'
driver_opts = [ '' ]
driver = gdal.GetDriverByName( format )
idataset = gdal.Open( ifile )
if idataset is None:
    print('Unable to open', ifile, 'for reading')
    sys.exit(1)

projection   = idataset.GetProjection()
geotransform = idataset.GetGeoTransform()

sds_md = idataset.GetMetadata('SUBDATASETS')
sds_md_str = ''
#print(type(sds_md))
#sds_md = sortedDictValues1(sds_md)
#sds_md.sort()
#
#print type(sds_md)
#print sds_md


#get MD with keys renamed like SUBDATASET_004_NAME
#if len( sds_md ) >= 20:
if False:
    sds_md2 = dict()
    width = int(math.ceil(len( sds_md ) / 2 / 10))+1
    for key in sorted(sds_md.iterkeys()):
        value = sds_md[key]
        elems = key.split('_')
        key2 = elems[0] + '_' + elems[1].zfill(width) + '_' + elems[2]
        sds_md2[key2] = value
    sds_md = dict()
    for key in sorted(sds_md2.iterkeys()):
        sds_md[key] = sds_md2[key]

#print(str(sds_md2))
sds_md_str = ''
ifiles=''
sds_md3 = idataset.GetSubDatasets()
#print(str(sds_md3))
#for key,value in sds_md.items() :
#for key in sorted(sds_md.iterkeys()):
#    value = sds_md[key]
#    sds_md_str = sds_md_str + ' \n\r' + key + '=' + value 
#    is_name = key.find("_NAME") is not -1
#    if is_name:
#        last_i = value.rfind(":")
#        if last_i is -1:
#            print('Unable to extract info from subdataset ', key, value)
#            sys.exit(1)
#        ifiles = ifiles + ' \'' + value + '\''
#        #print key, value

for index, item in enumerate(sds_md3):
#    value = sds_md[key]
    ifiles = ifiles + ' \'' + item[0] + '\''
        #print key, value

#make vrt
cmd = 'gdalbuildvrt -overwrite -separate ' + ofile + ' ' + ifiles
#print ifiles
print cmd
#print sds_md_str
if ifiles != '':
    subprocess.call(cmd, stderr=subprocess.STDOUT, shell=True)

#add metadata list to vrt
odataset = gdal.Open( ofile, gdal.GA_Update )
odataset.SetMetadata( sds_md )
#odataset.SetMetadataItem( 'SUBDATASETS', '{\n'+sds_md_str+'\n}' )
#odataset.SetMetadataItem( 'SUBDATASETS', '{\n'+sds_md_str+'\n}' )

idataset = None
odataset = None

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

import sys
import csv
import inspect 

# =============================================================================
def Usage():
    print('Usage: val_repl_csv.py -csv_file file.csv -in_id in_id -out_id out_id]')
    print('                       [-of out_format] [-ot out_type] [-co create_options]')
    print('                       infile outfile')
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

# =============================================================================
#def UnicodeDictReader(utf8_data, **kwargs):
#    csv_reader = csv.DictReader(utf8_data, **kwargs)
#    for row in csv_reader:
#        yield dict([(key, unicode(value, 'utf-8')) for key, value in row.iteritems()])
#def UnicodeDictReader(str_data, encoding, **kwargs):
#    csv_reader = csv.DictReader(str_data, **kwargs)
#    # Decode the keys once
#    keymap = dict((k, k.decode(encoding)) for k in csv_reader.fieldnames)
#    for row in csv_reader:
#        yield dict((keymap[k], v.decode(encoding)) for k, v in row.iteritems())
def UnicodeDictReader(utf8_data, **kwargs):
    csv_reader = csv.DictReader(utf8_data, **kwargs)
    for row in csv_reader:
        yield dict([(key, unicode(value, 'utf-8')) for key, value in row.iteritems()])
# =============================================================================


infile = None
outfile = None
format = 'GTiff'
type = GDT_Byte
#type = GDT_Int16
create_options = []
a_nodata = 0#None

csv_file = None
in_id = None
out_id = None
replace_table = None
csv_reader = None

tmp_key = None
tmp_val = None


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

    elif arg == '-csv_file':
        i = i + 1
        csv_file = sys.argv[i]

    elif arg == '-in_id':
        i = i + 1
        in_id = sys.argv[i]

    elif arg == '-out_id':
        i = i + 1
        out_id = sys.argv[i]

    elif arg == '-co':
        i = i + 1
        create_options.append( sys.argv[i] )

    elif infile is None:
        infile = arg

    elif outfile is None:
        outfile = arg

    else:
        Usage()

    i = i + 1

print infile, outfile, csv_file, in_id, out_id

if infile is None:
    Usage()
if  outfile is None:
    Usage()
if csv_file is None:
    Usage()
if in_id is None:
    Usage()
if out_id is None:
    Usage()


#read csv file
csv_reader = csv.DictReader(open(csv_file), delimiter=',', quotechar='\"')
#csv_reader = UnicodeDictReader(open(csv_file), delimiter=',', quotechar='\"')

if csv_reader is None:
    print('Unable to process csv file %s' % csv_file)
    sys.exit(1)
replace_table = dict()
for row in csv_reader:
    print row
#    print row[in_id], '-', row[out_id] 
    if row[in_id] is not '':
#        print row[in_id], '-', row[out_id] 
        if(type is GDT_Byte):
            tmp_key = int(row[in_id])
            tmp_val = int(row[out_id])
        else:
            tmp_key = float(row[in_id])
            tmp_val = float(row[out_id])
#        replace_table[row[in_id]] = row[out_id] 
        replace_table[tmp_key] = tmp_val 

print replace_table

#open datasets
indataset = gdal.Open( infile, GA_ReadOnly )
if indataset is None:
    print('Unable to open %s' % infile)
    sys.exit(1)
out_driver = gdal.GetDriverByName(format)
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
    outband = outdataset.GetRasterBand(iBand)
    if a_nodata != None:  outband.SetNoDataValue(a_nodata)
    else: outband.SetNoDataValue(inband.GetNoDataValue())

    print inband.YSize,inband.XSize 
    for i in range(inband.YSize - 1, -1, -1):
        scanline = inband.ReadAsArray(0, i, inband.XSize, 1, inband.XSize, 1)
        modified=numpy.empty(scanline.shape)
        modified.fill( False )
        j=inband.YSize-i
        if j % 1000 == 0 :
            print(str(j)+' / ',str(inband.YSize))
#        print(str(scanline.shape))

#this could be more efficient with numpy function...
#        for value in scanline.flat:
#            tmp_val = replace_table.get(value)
#            if tmp_val is not None:
#                value = tmp_val
#        for value in scanline.flat:
#            if value in replace_table:
#                value = replace_table[value]
        for key,value in replace_table.items():
            #print("k: %d v: %d\n" % (key,value) )
#            scanline=numpy.choose( numpy.equal( scanline, key ), (scanline, value) )
#            scanline= numpy.choose( numpy.logical_and( modified,numpy.equal( scanline, key )) ,
#                                       (scanline, value) )

#            to_modify = numpy.equal( scanline, key )
#            scanline = numpy.choose( numpy.logical_and( numpy.logical_not(modified), to_modify),
#                       (scanline, value) )
#            modified =numpy.logical_and( modified, to_modify )

            to_modify = numpy.logical_and( numpy.logical_not(modified), numpy.equal( scanline, key ))
            modified = numpy.logical_or( modified, to_modify )
            scanline = numpy.choose( to_modify, (scanline, value) )

        outband.WriteArray(scanline, 0, i)


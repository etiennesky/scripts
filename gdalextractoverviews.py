#!/usr/bin/env python
#******************************************************************************
#  $Id$
# 
#  Name:     gdalcopymeta.py
#  Project:  GDAL Python Interface
#  Purpose:  
#  Author:   Etienne Tourigny, etiennesky@yahoo.com
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

if len(sys.argv) < 3:
    print("Usage: gdalcopymeta.py source_file dest_prefix")
    sys.exit(1)

#input file

input = sys.argv[1]
dest_prefix = sys.argv[2]

print input, dest_prefix

myOutDrv = gdal.GetDriverByName("GTiff")
create_options = []
create_options.append("COMPRESS=LZW")

dataset = gdal.Open( input )
if dataset is None:
    print('Unable to open', input, 'for reading')
    sys.exit(1)


if dataset.RasterCount is not 1:
    print('Can only use on a single-band dataset for now')
    sys.exit(1)

# global metadata
metad = dataset.GetMetadata()
proj = dataset.GetProjection()
geo = dataset.GetGeoTransform()

for iBand in range(1, dataset.RasterCount + 1):
#        dest_pre
    iBand = dataset.GetRasterBand(iBand)
    print iBand.GetOverviewCount()
    for iOverview in range(0, iBand.GetOverviewCount()):
        print iOverview
    for iOverview in range(0, iBand.GetOverviewCount()):
        ofile = dest_prefix+"-over-"+str(iOverview)+".tif"
        print iOverview,  ofile
        if os.path.exists(ofile):
            os.remove(ofile)
        if os.path.exists(ofile+".aux.xml"):
            os.remove(ofile+".aux.xml")
        iOverviewBand = iBand.GetOverview(iOverview)
        print iOverview,ofile,iOverviewBand.XSize,iOverviewBand.YSize
        oDataset = myOutDrv.Create(ofile,iOverviewBand.XSize,iOverviewBand.YSize,
                                   1,iOverviewBand.DataType,create_options)
        oDataset.SetGeoTransform(geo)
        oDataset.SetProjection(proj)
        oBand = oDataset.GetRasterBand(1)
        oBand.SetNoDataValue(iOverviewBand.GetNoDataValue())
        for line in range(iOverviewBand.YSize):
            data_src = iOverviewBand.ReadAsArray( 0, line, iOverviewBand.XSize, 1, iOverviewBand.XSize, 1 )
            oBand.WriteArray( data_src, 0, line )           
#    outband = dataset2.GetRasterBand(iBand)
#    if inband is not None and outband is not None:
#        metad = inband.GetMetadata()
#        if metad is not None:
#            print("copying band metadata")
#            outband.SetMetadata( metad )

sys.exit(0)


#output file
output = sys.argv[2]
dataset2 = gdal.Open( output, gdal.GA_Update )
if dataset2 is None:
    print('Unable to open', output, 'for writing')
    sys.exit(1)

if metad is not None:
    print("copying global metadata")
    dataset2.SetMetadata( metad )

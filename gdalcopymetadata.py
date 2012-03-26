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
    print("Usage: gdalcopymeta.py source_file dest_file")
    sys.exit(1)

#input file

input = sys.argv[1]
dataset = gdal.Open( input )
if dataset is None:
    print('Unable to open', input, 'for reading')
    sys.exit(1)

#output file
output = sys.argv[2]
dataset2 = gdal.Open( output, gdal.GA_Update )
if dataset2 is None:
    print('Unable to open', output, 'for writing')
    sys.exit(1)

# global metadata
metad = dataset.GetMetadata()

if metad is not None:
    print("copying global metadata")
    dataset2.SetMetadata( metad )

for iBand in range(1, dataset.RasterCount + 1):
    inband = dataset.GetRasterBand(iBand)
    outband = dataset2.GetRasterBand(iBand)
    if inband is not None and outband is not None:
        metad = inband.GetMetadata()
        if metad is not None:
            print("copying band metadata")
            outband.SetMetadata( metad )

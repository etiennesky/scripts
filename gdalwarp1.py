#!/usr/bin/env python
###############################################################################
# $Id$
#
# Project:  
# Purpose:  
# Author:   Etienne Tourigny, etourigny.dev@gmail.com
#
###############################################################################
# Copyright (c) 2013 Etienne Tourigny
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
except ImportError:
    import gdal
    from gdalconst import *

import sys, os, subprocess
from glob import glob

# =============================================================================

def get_projection( src_file ):

    dataset = gdal.Open( src_file )
    if dataset is None:
        print('Unable to open subdataset', src_file, ' for reading')
        sys.exit(1)
    prj = dataset.GetProjectionRef()

    dataset = None

    return prj


#reproj_nc_data(Dir_In, File_Pattern, Dir_Out, s_srs, t_srs, xres, yres, resample, nc_format)
#"""
#  Dir_In : repertoire contenant les donnnees a traiter 
#  File_Pattern : PREVIMER_F1-MARS3D-MANGA4000_????????.nc
#
#  Dir_Out : repertoire de sorti
#  t_srs : target spatial reference set
#  xres, yres : set output file resolution (in target georeferenced units)
#
#Parametres optionnels :
#
#  s_srs :  systeme de proj contenu dans les fichiers input s'il existe, sinon on force a la valeur en argument
#           si argument manquant et le fichier n'a pas de srs, on force EPSG:4326 
#
#  resample : resampling method (defaut None)
#  zlib : defaut True
#  zlevel : defaut 2
#  fmt : 'NETCDF4', 'NETCDF4_CLASSIC', 'NETCDF3_CLASSIC', 'NETCDF3_64BIT'
#  nodata : destination nodata value
#  cutline : full path of shapefile containing cutline mask
#"""

def reproj_nc_data( Dir_In, File_Pattern, Dir_Out, t_srs, xres, yres, s_srs=None, resample=None, zlib=True, zlevel=2, fmt='NETCDF3_CLASSIC', dstnodata=-9999, cutline='' ):

    # basic path validation
    if not os.path.isdir( Dir_Out ):
        print('ERROR! Dir_Out '+Dir_Out+' does not exist!')
        return

    if Dir_In == Dir_Out:
        print('ERROR! Dir_In (%s) and Dir_Out (%s) are the same!' % (Dir_In, Dir_Out))
        return

    pattern=Dir_In +'/' + File_Pattern
    ifiles=glob( pattern ) 

    for ifile in ifiles:
        reproj_nc_file( ifile, Dir_Out + '/' + os.path.basename( ifile ), t_srs, xres, yres, s_srs=s_srs, resample=resample, zlib=zlib, zlevel=zlevel, fmt=fmt, dstnodata=dstnodata, cutline=cutline )


def reproj_nc_file( src_file, dst_file, t_srs, xres, yres, s_srs=None, resample=None, zlib=True, zlevel=2, fmt='NETCDF3_CLASSIC', dstnodata=-9999, cutline='' ):
    
    # process arguments

    if s_srs is not None and s_srs != '':
        args_s_srs='-s_srs '+s_srs
    else:
        # test that datasets contains projection ref, if not force to EPSG:4326
        dataset = gdal.Open( src_file )
        if dataset is None:
            print('Unable to open ', src_file, ' for reading')
            sys.exit(1)
        sds = dataset.GetSubDatasets()
        args_s_srs=''
        for ds in sds:
            sds_file = ds[0]
            prj = get_projection( sds_file )
            if prj is None or prj=='':
                s_srs='EPSG:4326'
                args_s_srs='-s_srs '+s_srs
                print('NOTICE: no srs in %s forcing to %s' % (sds_file,s_srs))
                break

    if t_srs is not None and t_srs != '':
        args_t_srs='-t_srs '+t_srs
    else:
        args_t_srs=''

    if xres is not None and xres != '' and yres is not None and yres != '':
        args_tr='-tr %d %d' % ( xres, yres )
    else:
        args_tr=''

    if resample is not None and resample != '':
        args_resample='-r '+resample
    else:
        args_resample=''

    # only use compression with fix to gdal bug #5082 (applied in trunk and 1.10-svn), 
    # if not set ncks arguments accordingly in gdalwarp_sds.sh
    # if using compression, use NC4C which is better for metadata with \n
    # a compression level of 2 is recommended in most cases for speed/size tradeoffs
    if zlib:
        if fmt != 'NETCDF4' and fmt != 'NETCDF4_CLASSIC':
            print('NOTICE: as zlib is requested using format NETCDF4_CLASSIC/NC4C')
            fmt = 'NETCDF4_CLASSIC'
        args_co = '-co WRITE_BOTTOMUP=NO -co COMPRESS=DEFLATE -co ZLEVEL=%d' % zlevel
    else:
        args_co = '-co WRITE_BOTTOMUP=NO'

    # fmt arg from netcdf4-python to gdal
    fmt2 = 'NC'
    if fmt == 'NETCDF4':
        fmt2 = 'NC4'
    elif fmt == 'NETCDF4_CLASSIC':
        fmt2 = 'NC4C'
    elif fmt == 'NETCDF3_CLASSIC':
        fmt2 = 'NC'
    elif fmt == 'NETCDF3_64BIT':
        fmt2 = 'NC2'
    else:
        print('ERROR: unsupported format %s - using default NETCDF3_CLASSIC/NC' % fmt )
    args_co = '%s -co FORMAT=%s' % ( args_co, fmt2 )

    # dstnodata is needed unless fix in gdal bug #5087 is applied (only in gdal trunk)
    if dstnodata is not None:
        args_nodata = '-dstnodata %d' % dstnodata
    else:
        args_nodata = ''
    if cutline != '' and cutline is not None:
        args_cutline = '-cutline %s' % cutline
    else:
        args_cutline = ''

    args_format = '-of netcdf'
    args_extra = ''#'-quiet'

    # setum multithreading
    numthreads = '1'#'halfprocs'
    os.putenv( 'GDALWARP_SDS_NUM_THREADS', numthreads )

    if os.path.isfile( dst_file ):
        os.unlink( dst_file )

    command = 'nice gdalwarp_sds.sh %s %s %s %s %s %s %s %s %s %s %s' %\
        ( args_format, args_s_srs, args_t_srs, args_tr, args_resample, \
              args_nodata, args_cutline, args_co, args_extra, src_file, dst_file )
    print('$ '+command)
    subprocess.call(command, shell=True)




# =============================================================================
# test script for using reproj_nc_data()

def Usage():
    print( 'Usage: gdalwarp1.py Dir_In, File_Pattern, Dir_Out' )
    sys.exit( 1 )


# Parse command line arguments.

argc = len(sys.argv)

if argc < 3:
    Usage()

argv = sys.argv

Dir_In = argv[1]
File_Pattern = argv[2]
Dir_Out = argv[3]

print('%s / %s / %s' % (Dir_In,File_Pattern,Dir_Out))

s_srs=''#'EPSG:4326'
# spherical mercator is EPSG:3857 or 
# +proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +no_defs
t_srs='EPSG:3857'
#args_t_srs=''
#args_tr=''#'-tr 10000 10000'
xres=None
yres=None
resample=None
zlib=True
zlevel=2
fmt='NETCDF3_CLASSIC'
dstnodata=-9999
cutline=''#'ne_10m_ocean.shp'

reproj_nc_data( Dir_In, File_Pattern, Dir_Out, t_srs, xres, yres, s_srs=s_srs, resample=resample, zlib=zlib, zlevel=zlevel,fmt=fmt,dstnodata=dstnodata,cutline=cutline )

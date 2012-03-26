#!/usr/bin/env python
#******************************************************************************
# 
#  Project:  GDAL
#  Purpose:  
#  Author:   
# 
#******************************************************************************
#  Copyright (c) 2010, Chris Yesson <chris.yesson@ioz.ac.uk>
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

################################################################
################################################################

try:
    from osgeo import gdal, gdalconst, osr
    from osgeo.gdalnumeric import *
except ImportError:
    import gdal, gdalconst, osr
    from gdalnumeric import *

#from optparse import OptionParser
import sys
import os
import subprocess, shlex


################################################################
def doit(argv):

#    nobs = int( ( len(sys.argv) - 2 ) / 2 )
    nobs = int( ( len(sys.argv) - 2 ) )
    inNoData = -32768
    ofile = argv[1]
#    ofile_tmp = ofile+'.tmp'
    ofile_tmp = ofile
    ifile_ba = argv[2]
    ifile_ba_base = os.path.basename(ifile_ba)
    print ofile, ifile_ba, nobs

    if ifile_ba_base[:12] == "MCD45monthly":
        print "monthly"
    else:
        print "ERROR, only supports MCD45monthly files!"
        print "file was",ifile_ba
        return

    # constants
    daysn = [ "001", "032", "060", "091", "121", "152", "182", "213", "244", "274", "305", "335"]
    daysb = [ "001", "032", "061", "092", "122", "153", "183", "214", "245", "275", "306", "336"]
    
    #read first input file
    src_ba_ds = gdal.Open(ifile_ba, gdal.GA_ReadOnly)
#    print 'Driver: ', src_ba_ds.GetDriver().ShortName,'/', \
#          src_ba_ds.GetDriver().LongName
    xsize = src_ba_ds.RasterXSize
    ysize = src_ba_ds.RasterYSize
#    print 'Size is ',src_ba_ds.RasterXSize,'x',src_ba_ds.RasterYSize, \
#          'x',src_ba_ds.RasterCount
#    print 'Projection is ',src_ba_ds.GetProjection()
    geotransform = src_ba_ds.GetGeoTransform()
#    if not geotransform is None:
#        print 'Origin = (',geotransform[0], ',',geotransform[3],')'
#        print 'Pixel Size = (',geotransform[1], ',',geotransform[5],')'

    #create output file
#        print ofile, ofile_tmp
    if os.path.isfile( ofile ):
        os.unlink( ofile )
    if os.path.isfile( ofile+'.aux.xml' ):
        os.unlink( ofile+'.aux.xml' )
    if os.path.isfile( ofile_tmp ):
        os.unlink( ofile_tmp )
    driver = gdal.GetDriverByName( "GTiff" )
#    dst_ds = driver.Create( ofile, 
#                            src_ba_ds.RasterXSize, src_ba_ds.RasterYSize, 
#                            1, gdal.GDT_Int16,  [ 'COMPRESS=LZW' ] )
    dst_ds = driver.Create( ofile_tmp, 
                            src_ba_ds.RasterXSize, src_ba_ds.RasterYSize, 
                            1, gdal.GDT_Int16,  [ 'COMPRESS=LZW' ] )
    dst_ds.SetGeoTransform( src_ba_ds.GetGeoTransform() )
#    dst_ds.SetProjection( src_ba_ds.GetProjection() )
    sr = osr.SpatialReference()
    sr.ImportFromEPSG(4326)
    dst_ds.SetProjection( sr.ExportToWkt() )
    dst_band = dst_ds.GetRasterBand(1)
    dst_band.SetNoDataValue(0);

    for j in range(0,nobs):
        ifile_ba = argv[2+j]
        ifile_ba_base = os.path.basename(ifile_ba)
#        ifile_qa = argv[2+nobs+j]
#        print j, ifile_ba, ifile_qa
#        print j, ifile_ba
        year=None
        month=None
        doy=None
        doy_start=0
        doy_end=366

        #MCD45monthly.A2010001.Win05.005.burndate.tif
        if ifile_ba_base[:12] == "MCD45monthly":
            year = ifile_ba_base[14:18]
            doy_start = ifile_ba_base[18:21]
            if year == "2000" or year == "2004" or year == "2008" :
                days = daysb
            else:
                days = daysn
#            print year,days
            month = days.index(doy_start)
            doy_start = int(doy_start)
            if month is 11:
                doy_end = 366
            else:
                doy_end = int(days[month+1])
#            print "monthly",year,doy_start,doy_end
        else:
            print "ERROR, conly supports MCD45monthly files!"
            return

        if j != 0:
            src_ba_ds = gdal.Open(ifile_ba, gdal.GA_ReadOnly)
#        src_qa_ds = gdal.Open(ifile_qa, gdal.GA_ReadOnly)        
        src_ba_band = src_ba_ds.GetRasterBand(1)
#        src_qa_band = src_qa_ds.GetRasterBand(1)
        xsize = src_ba_band.XSize
        ysize = src_ba_band.YSize

#        print xsize,ysize

        for i in range(ysize - 1, -1, -1):
            src_line_ba = src_ba_band.ReadAsArray(0, i, xsize, 1, xsize, 1)
#            src_line_qa = src_qa_band.ReadAsArray(0, i, xsize, 1, xsize, 1)
            dst_line = dst_band.ReadAsArray(0, i, xsize, 1, xsize, 1)
            #filter
#            src_burned = numpy.logical_and(numpy.greater( src_line_ba, 0),numpy.less( src_line_ba, 366))
            src_burned = numpy.logical_and(numpy.greater( src_line_ba, doy_start),numpy.less( src_line_ba, doy_end))
#            qa_ok =  numpy.greater( src_line_qa, 0)
            dst_line = numpy.choose( src_burned, (dst_line,src_line_ba) )
            dst_band.WriteArray(dst_line, 0, i)
      
#        print "clean up"
        src_ba_ds is None
#        src_qa_ds is None

    
    dst_ds is None

#make a compressed copy, ugly hack!!
#    src_ba_ds = gdal.Open(ofile_tmp, gdal.GA_ReadOnly)
#    dst_ds = driver.CreateCopy( ofile, src_ba_ds, 0, [ 'COMPRESS=LZW' ] )
##    dst_ds.GetRasterBand(1).SetNoDataValue(0);
#    dst_ds is None
#    command='gdal_translate -co "COMPRESS=LZW" '+ofile_tmp+' '+ofile
#    print command
#    command=shlex.split(command)
#    subprocess.call( command )
    
#    if os.path.exists( ofile_tmp ):
#        os.unlink( ofile_tmp )

    return

################################################################
def main():

    usage = """
process_mcd45a1.py ofile ifiles-burndate ifiles-qa
    """

#    nobs = ( len(sys.argv) - 2 ) / 2.0

#    print len(sys.argv)
#    print nobs
#    print sys.argv


    if len(sys.argv) < 3:
       print(usage)
#    if nobs < 1 or nobs != floor(nobs):
#        print(usage)
    else:
        nobs = len(sys.argv)
        doit(sys.argv)

if __name__ == "__main__":
    main()

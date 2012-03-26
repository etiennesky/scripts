#!/usr/bin/env python
#******************************************************************************
#  Purpose:  This script will append OGR_DATUM_NAME and TOWGS84 parameters
#            to the GDAL/OGR datum file and create another file with a reduced 
#            set of parameters and geocentric datums only.  The intended use
#            is a reference for the datum names in the CF standard.
#
#  Requirements:  GDAL/OGR python bindings and data files, csv_tools.py
#
#  Author:   Etienne Tourigny, etourigny.dev-a-gmail.com
# 
#******************************************************************************
#  Copyright (c) 2012, Etienne Tourigny <etourigny.dev-a-gmail.com>
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
# 

###############################################################################
# This script is based loosely on  add_esri_column.py by Frank Warmerdam
#
# The rules to translate EPSG datum names to OGC standard (used by OGR/CadCorp)
# are taken from GDAL/OGR source code and
# http://home.gdal.org/projects/opengis/wktproblems.htlm
#
# convert all non alphanumeric characters to underscores (including +), 
# then to strip any leading, trailing or repeating underscores.
#
# notable exceptions / equivalences are:
#
# EPSG code  EPSG name                                   OGR name                                  Equivalent
# 6312       Militar-Geographische Institut              Militar_Geographische_Institute           Militar_Geographische_Institut
# 6322       World Geodetic System 1972                  WGS_1972                                  World_Geodetic_System_1972
# 6324       WGS 72 Transit Broadcast Ephemeris          WGS_1972_Transit_Broadcast_Ephemeris      WGS_72_Transit_Broadcast_Ephemeris
# 6326       World Geodetic System 1984                  WGS_1984                                  World_Geodetic_System_1984
# 6258       European Terrestrial Reference System 1989  European_Terrestrial_Reference_System_89  European_Reference_System_1989
###############################################################################

from osgeo import ogr, osr
import csv
import sys
import os
import csv_tools
import re


# =============================================================================
# Parse command line arguments.

if len(sys.argv) < 2:
    print('Usage: make_cf_datum.py csv_dir (should be the GDAL/OGR data directory)')
    print('')
    sys.exit( 1 )

csv_dir = sys.argv[1]


# =============================================================================
# define variables

ogr_gcs_names = {}
ogr_datum_names = {}
towgs84_params = {}

towgs84_names = ['DX','DY','DZ','RX','RY','RZ','DS']
new_field_names = ['OGC_DATUM_NAME','DX','DY','DZ','RX','RY','RZ','DS']
horiz_datum_field_names = ['DATUM_CODE','DATUM_NAME','ELLIPSOID_CODE',\
                               'PRIME_MERIDIAN_CODE','ESRI_DATUM_NAME',\
                               'OGC_DATUM_NAME',\
                               'DX','DY','DZ','RX','RY','RZ','DS']
datum_code_equiv = [6312,6322,6324,6326,6258]

#csv_dir = '/home/softdev/share/gdal'
gcs_file = csv_dir+'/gcs.csv'
#gcs_file = csv_dir+'/gcs-tmp.csv'
vertcs_file = csv_dir+'/vertcs.csv'
datum_file = csv_dir+'/gdal_datum.csv'
#datum_file = csv_dir+'/gdal_datum-tmp.csv'

out_dir = '.'
outfile1 = out_dir+'/ogc_datum.csv'
outfile2 = out_dir+'/cf_datum_horiz.csv'

if not os.path.isfile(gcs_file) or not os.path.isfile(vertcs_file) or not os.path.isfile(datum_file):
    print('csv file(s) not found in '+csv_dir)
    sys.exit( 1 )

print('using csv files in '+csv_dir+' and producing csv files '+outfile1+' '+outfile2)


# =============================================================================
# get values

def get_vals( csv_file, get_datum_info=1, field_name='GEOGCS', field_datum='DATUM'  ):
    
    # load table(s)
    gcs_table = csv_tools.CSVTable()
    gcs_table.read_from_csv( csv_file )

    # loop for all elements
    for gcs_code in gcs_table.data.keys():
        gcs_code = int(gcs_code)

        # get the ogr datum name from GDAL/OGR using epsg code
        srs = osr.SpatialReference()
        srs.ImportFromEPSG( gcs_code )
        gcs_name = srs.GetAttrValue( field_name )
        datum_name = srs.GetAttrValue( field_datum )

        # get datum code
        try:
            gcs_rec = gcs_table.get_record( gcs_code )
            datum_code = int(gcs_rec['DATUM_CODE'])
            #print(str(gcs_rec))       
            #print str(gcs_code)+'='+gcs_name+' / '+str(datum_code)+'='+datum_name
        except:
            datum_code = None
            print 'Failed to get gcs record, or datum info for '+str(gcs_code)

        # store datum name and towgs84 parameters
        if not datum_code is None:
            ogr_datum_names[datum_code] = datum_name

            if get_datum_info == 1:
                if gcs_rec['DX'] != '':
                    towgs84_params[datum_code] = [ gcs_rec['DX'],gcs_rec['DY'],\
                                                       gcs_rec['DZ'],gcs_rec['RX'],\
                                                       gcs_rec['RY'],gcs_rec['RZ'],\
                                                       gcs_rec['DS'] ] 
             

get_vals( gcs_file, )
get_vals( vertcs_file, 0, 'VERT_CS','VERT_DATUM' )


# =============================================================================
# create tables for output files

datum_table = csv_tools.CSVTable()
datum_table.read_from_csv( datum_file )

# add missing field names

for tmp_name in new_field_names:
    if tmp_name not in datum_table.fields:
        datum_table.add_field( tmp_name )
    
# Loop over all datums, adding new values where needed

for datum_code in datum_table.data.keys():
    datum_rec = datum_table.get_record( datum_code )
    datum_type = datum_rec['DATUM_TYPE']
    epsg_datum_name = datum_rec['DATUM_NAME']
    tmp_datum_name = epsg_datum_name
    #for some reason OGR does not transform vertical datum names
    if datum_type == 'geodetic':
        tmp_datum_name = re.sub('[^a-zA-Z0-9\+]','_',tmp_datum_name)
        tmp_datum_name = re.sub('\_{2,}','_',tmp_datum_name)
        tmp_datum_name = re.sub('^\_|\_$','',tmp_datum_name)
    
    if ogr_datum_names.has_key(datum_code):
        print 'match for '+str(datum_code)+' ('+datum_type+')'
        #datum_rec['OGC_DATUM_NAME'] = ogr_datum_names[datum_code]
        ogr_datum_name = ogr_datum_names[datum_code]
        if tmp_datum_name != ogr_datum_name:
            if not datum_code in datum_code_equiv: 
                print 'ERROR with # '+str(datum_code)+\
                    ' EPSG name ['+epsg_datum_name+\
                    ']: OGR name is ['+ogr_datum_name+\
                    '] but we computed ['+tmp_datum_name+']'

    else:
        #datum_rec['OGC_DATUM_NAME'] = ''
        ogr_datum_name = epsg_datum_name
        ogr_datum_name = tmp_datum_name
        print 'no match for '+str(datum_code)+' / '+datum_type+' / ['\
            +epsg_datum_name+'], replaced with ['+ogr_datum_name+']'
    datum_rec['OGC_DATUM_NAME'] = ogr_datum_name
    #print str(datum_code)+'-'+epsg_datum_name+'-'+ogr_datum_name
#    if ogr_datum_name = '' or ogr_datum_name != epsg_datum_name

    if towgs84_params.has_key(datum_code):
        tmp_towgs84 = towgs84_params[datum_code]
        #print(str(tmp_towgs84))
        for i in range(0,len(towgs84_names)):
            datum_rec[towgs84_names[i]] = tmp_towgs84[i]

    #print(str(datum_rec))
    datum_table.set_record( datum_code, datum_rec )

# create table with only horizontal(geodetic) datums and variabels of interest for CF

horiz_datum_table = csv_tools.CSVTable()
for tmp_name in horiz_datum_field_names:
    if tmp_name not in horiz_datum_table.fields:
        horiz_datum_table.add_field( tmp_name )

for datum_code in datum_table.data.keys():
    datum_rec = datum_table.get_record( datum_code )
    if datum_rec['DATUM_TYPE']=='geodetic':
        horiz_datum_rec = {}
        for tmp_name in horiz_datum_field_names:
            horiz_datum_rec[tmp_name] = datum_rec[tmp_name]
            horiz_datum_table.set_record( datum_code, horiz_datum_rec )


# =============================================================================
# write csv files

datum_table.write_to_csv( outfile1 )
horiz_datum_table.write_to_csv( outfile2 )


#!/usr/bin/env python
###############################################################################

###############################################################################
# The rules to translate EPSG datum names to OGR/CadCorp is taken from
# http://home.gdal.org/projects/opengis/wktproblems.html and OGR source
# convert all non alphanumeric characters to underscores (including +), 
# then to strip any leading, trailing or repeating underscores
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
    print('Usage: make_cf_datum.py csv_dir')
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
gcs_override_file = csv_dir+'/gcs.override.csv'
#gcs_file = csv_dir+'/gcs-tmp.csv'
vertcs_file = csv_dir+'/vertcs.csv'
vertcs_override_file = csv_dir+'/vertcs.override.csv'
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

def get_vals( csv_file, csv_override_file='', get_datum_info=1, field_name='GEOGCS', field_datum='DATUM'  ):
    
    # load table(s)
    gcs_table = csv_tools.CSVTable()
    gcs_table.read_from_csv( csv_file )
    if csv_override_file != '':
        override_table = csv_tools.CSVTable()
        override_table.read_from_csv( csv_override_file )   

    # loop for all elements
    for gcs_code in gcs_table.data.keys():
        gcs_code = int(gcs_code)

        # get the ogr datum name from epsg code
        srs = osr.SpatialReference()
        srs.ImportFromEPSG( gcs_code )
        gcs_name = srs.GetAttrValue( field_name )
        datum_name = srs.GetAttrValue( field_datum )

        # get datum code
        try:
            gcs_rec = gcs_table.get_record( gcs_code )
            # look for value in override table
            override_rec = None
            if csv_override_file != '':
                try:                  
                    override_rec = override_table.get_record( gcs_code )
                except:
                    override_rec = None
                    pass
            if not override_rec is None:
                print('code '+str(gcs_code)+' was overriden from '+csv_override_file)
                #print(str(override_rec))
                gcs_rec = override_rec

            datum_code = int(gcs_rec['DATUM_CODE'])
            #print(str(gcs_rec))       
            #print str(gcs_code)+'='+gcs_name+' / '+str(datum_code)+'='+datum_name
        except:
            print 'Failed to get gcs record, or datum info for '+str(gcs_code)
            datum_code = None

        # store datum name
        ogr_datum_names[datum_code] = datum_name

        # store towgs84 parameters
        if get_datum_info == 1:
            if gcs_rec['DX'] != '':
                towgs84_params[datum_code] = [ gcs_rec['DX'],gcs_rec['DY'],\
                                                   gcs_rec['DZ'],gcs_rec['RX'],\
                                                   gcs_rec['RY'],gcs_rec['RZ'],\
                                                   gcs_rec['DS'] ] 

                

get_vals( gcs_file, gcs_override_file )
get_vals( vertcs_file, vertcs_override_file, 0, 'VERT_CS','VERT_DATUM' )

#print(str(ogr_datum_names))
#print(str(towgs84_params))

# =============================================================================
# create tables for output files

datum_table = csv_tools.CSVTable()
datum_table.read_from_csv( datum_file )
horiz_datum_table = csv_tools.CSVTable()

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


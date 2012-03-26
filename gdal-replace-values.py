#!/usr/bin/env python

from osgeo import ogr
import csv
import sys
import os

if (len(sys.argv) > 2):
    shp_file=sys.argv[1]
    csv_file=sys.argv[2]
else:
    print('usage: ',sys.argv[0],' amazonia.shp probio_vegtypes_detail.csv')
    sys.exit(1);    

if not os.path.exists( shp_file ):
    print('shp_file '+shp_file+' does not exist')
    sys.exit(1);    

if not os.path.exists( csv_file ):
    print('csv_file '+csv_file+' does not exist')
    sys.exit(1);    

#shp_file='cerrado_small.shp'
#shp_file='cerrado.shp'
#shp_file='amazonia.shp'
new_field_name1='ID_IBIS'
new_field_name2='ID_FORMACA'
old_field_name1='SG_FORMACA'
old_field_name2='SG_REGIAO'
#csv_file='probio-vegtypes2.csv'
#csv_file='probio_vegtypes_detail.csv'

# Open a Shapefile, and get field names
#source = ogr.Open('test.shp', 1)
source = ogr.Open(shp_file, 1)

#print "open"
layer = source.GetLayer()
layer_defn = layer.GetLayerDefn()
field_names = [layer_defn.GetFieldDefn(i).GetName() for i in range(layer_defn.GetFieldCount())]

#print field_names
#print len(field_names), old_field_name1 in field_names, new_field_name1 in field_names, new_field_name2 in field_names

#print len(field_names), 'MYFLD' in field_names

#exit if old is not there
if not old_field_name1 in field_names:
    print old_field_name1, "not existent, exiting"
    exit

## Add a new field if needed
if new_field_name1 in field_names:
    print new_field_name1, " already there"
else:
    print new_field_name1, " not existent, creating it"
    new_field1 = ogr.FieldDefn(new_field_name1, ogr.OFTInteger)
    layer.CreateField(new_field1)

if new_field_name2 in field_names:
    print new_field_name2, " already there"
else:
    print new_field_name2, " not existent, creating it"
    new_field2 = ogr.FieldDefn(new_field_name2, ogr.OFTInteger)
    layer.CreateField(new_field2)

print "reading csv file"

probioLUT = dict()
probioReader = csv.reader(open(csv_file, 'rb'), delimiter=',', quotechar='\"')

first_line = True
for row in probioReader:
    if not first_line:
        probioLUT[ row[old_field_id] ] = (int(row[new_field_id1]),(int(row[new_field_id2])))
        line_count = 0
    else:
        new_field_id1=row.index(new_field_name1)
        new_field_id2=row.index(new_field_name2)
        old_field_id=row.index(old_field_name1)
        first_line = False

print(str(probioLUT))

print "looping over features"

feat_count=layer.GetFeatureCount()
print('feat_count: ',str(feat_count))

feat_i=0
err_count=0
feat = layer.GetNextFeature()
while feat is not None:
    feat_i = feat_i + 1
    c_name_field1 = feat.GetFieldIndex( old_field_name1 )
    c_name_field2 = feat.GetFieldIndex( old_field_name2 )
    c_id_field1 = feat.GetFieldIndex( new_field_name1 )
    old_id1 = feat.GetField( c_id_field1 )
    c_id_field2 = feat.GetFieldIndex( new_field_name2 )
    old_id2 = feat.GetField( c_id_field2 )
    c_name1 = feat.GetField( c_name_field1 )
    c_name2 = feat.GetField( c_name_field2 )

    #default NC (Unclassified) code
    if c_name1 is None and c_name2 is None:
        c_name1='NC'
    tup = probioLUT.get( c_name1 )
    if tup is None:
        tup = probioLUT.get( c_name2 )
        if tup is None:
            err_count = err_count +1
            print 'error getting value ',c_name1,c_name2,c_name_field1, c_name_field2, " - ",feat_i," / ",feat_count
            feat = layer.GetNextFeature()
            continue

#    ( new_id1, new_id2 ) = probioLUT.get( c_name )
    ( new_id1, new_id2 ) = tup

    if old_id1 is not new_id1 :
        print "setting old value1 ", old_id1, " to ",new_id1, " - ",feat_i," / ",feat_count
        feat.SetField( c_id_field1, new_id1 )
        layer.SetFeature( feat )

    if old_id2 is not new_id2 :
        print "setting old value2 ", old_id2, " to ",new_id2, " - ",feat_i," / ",feat_count
        feat.SetField( c_id_field2, new_id2 )
        layer.SetFeature( feat )

    line_count = line_count + 1

    feat = layer.GetNextFeature()

print 'got ',str(err_count),' errors'

# Close the Shapefile
source = None

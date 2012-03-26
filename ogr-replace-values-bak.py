#!/usr/bin/env python

from osgeo import ogr
import csv

# Open a Shapefile, and get field names
#source = ogr.Open('test.shp', 1)
source = ogr.Open('vegetacao.shp', 1)

print "open"
layer = source.GetLayer()
layer_defn = layer.GetLayerDefn()
field_names = [layer_defn.GetFieldDefn(i).GetName() for i in range(layer_defn.GetFieldCount())]
new_field_name="CLASSE_ID"
old_field_name="CLASSE"

print field_names
print len(field_names), old_field_name in field_names, new_field_name in field_names

#print len(field_names), 'MYFLD' in field_names

#exit if old is not there
if not old_field_name in field_names:
    print old_field_name, "not exixtent, exiting"
    exit

## Add a new field if needed
if new_field_name in field_names:
    print new_field_name, " already there"
else:
    print new_field_name, " not existent, creating it"
    new_field = ogr.FieldDefn('CLASSE_ID', ogr.OFTInteger)
    layer.CreateField(new_field)

print "reading file"

probioLUT = dict()
probioReader = csv.reader(open('probio-vegtypes.csv', 'rb'), delimiter=',', quotechar='\"')
#probioReader = csv.reader(open('probio-vegtypes.csv', 'rb'), delimiter=',')
first_line = True
for row in probioReader:
    if not first_line:
        print ', '.join(row)
        print row[0], " - ", row[1]
        probioLUT[ row[0] ] = int(row[1])
#read the features
#line_layer = source.GetLayer( )
        line_count = 0
    else:
        first_line = False

print probioLUT
print "Sas" in probioLUT
print "Sas2" in probioLUT
print probioLUT.get('Sas')
print probioLUT.get('Sd')


feat = layer.GetNextFeature()
c_name_field = feat.GetFieldIndex( 'CLASSE' )
c_id_field = feat.GetFieldIndex( 'CLASSE_ID' )
while feat is not None:
    c_name = feat.GetField( c_name_field )
    old_id = feat.GetField( c_id_field )
    new_id = probioLUT.get( c_name,-1 )

    print c_name, old_id, new_id

    if old_id is not new_id :
        print "setting old value ", old_id, " to ",new_id
        feat.SetField( c_id_field, new_id )
        layer.SetFeature( feat )

#    c_name = feat.GetField( c_name_field )
#    c_id = feat.GetField( c_id_field )
#    new_id = probioLUT.get( c_name,-1 )

#    try:
#        module = modules_hash[tile_ref]
#    except:
#        module = Module()
#        modules_hash[tile_ref] = module

#    module.lines[geom_id] = feat.GetGeometryRef().Clone()
    line_count = line_count + 1

#    feat.Destroy()

    feat = layer.GetNextFeature()


# Close the Shapefile
source = None

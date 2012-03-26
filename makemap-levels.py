#!/usr/bin/env python

try:
    from osgeo import gdal
    from osgeo.gdalconst import *
    gdal.TermProgress = gdal.TermProgress_nocb
except ImportError:
    import gdal
    from gdalconst import *

try:
    import numpy as np
except ImportError:
    import Numeric as np

import sys
import os
import subprocess
import pprint

###############################################################################
# functions

####################
def myexec(command):
    print('myexec: '+command)
    return subprocess.call(command, stderr=subprocess.STDOUT, shell=True)

####################
def myunlink(file):
    if os.path.exists(file):
        os.unlink(file)
        if os.path.exists(file+'.aux.xml'):
            os.unlink(file+'.aux.xml')

####################
#coe from attachpct.py
def attach_pct( ctfile, ofile ):
# =============================================================================
# Get the PCT.
# =============================================================================
    ds = gdal.Open( ctfile )
    ct = ds.GetRasterBand(1).GetRasterColorTable()  
    if ct is None:
        print('No color table on file ', ctfile)
        return
    ct = ct.Clone()
    ds = None

# =============================================================================
# Open file in update and copy CT
# =============================================================================
    out_ds = gdal.Open( ofile, gdal.GA_Update )
    if out_ds is None:
        print('Unable to open', ofile, 'for writing')
        return
#    for iBand in range(0, out_ds.RasterCount):    
#        out_ds.GetRasterBand(iBand+1).SetRasterColorTable( ct )
#        out_ds.GetRasterBand(iBand+1).SetRasterColorInterpretation( gdal.GCI_PaletteIndex )
    out_ds.GetRasterBand(1).SetRasterColorTable( ct )
    out_ds.GetRasterBand(1).SetRasterColorInterpretation( gdal.GCI_PaletteIndex )

# =============================================================================
# Close datasets
# =============================================================================
    out_ds = None
    src_ds = None



####################
def copyBand(inband,outband):
    for i in range(0, inband.YSize):
        scanline = inband.ReadAsArray(0, i, inband.XSize, 1, inband.XSize, 1)
        outband.WriteArray(scanline, 0, i)

####################
def make_map_levels(ifile,ofile):

    indataset = gdal.Open( ifile, GA_ReadOnly )
    if indataset.RasterCount != 1:
        print('ifile must have 1 band')
        #exit()
        return 0

    out_driver = gdal.GetDriverByName(format)
    myunlink(ofile)
    outdataset = out_driver.Create(ofile, indataset.RasterXSize, indataset.RasterYSize,len(vegtype_ids), GDT_Float32, create_options)

    gt = indataset.GetGeoTransform()
    if gt is not None and gt != (0.0, 1.0, 0.0, 0.0, 0.0, 1.0):
        outdataset.SetGeoTransform(gt)

    prj = indataset.GetProjectionRef()
    if prj is not None and len(prj) > 0:
        outdataset.SetProjection(prj)

    inband = indataset.GetRasterBand(1)

    print(str(vegtype_ids))
    print(str(vegtype_names))

    #set outband metadata
    for iBand in range(outdataset.RasterCount):
        outband = outdataset.GetRasterBand(iBand+1)    
        metadata = outband.GetMetadata()
        vegtype_id=vegtype_ids[iBand]
        vegtype_name=vegtype_names[vegtype_id]
        print iBand,'-',vegtype_id,'-',vegtype_name
        metadata['vegtype_id']=str(vegtype_id)
        metadata['vegtype_name']=str(vegtype_name)
        print(str(metadata))
        outband.SetMetadata(metadata)
        
    #loop all inbands
    for i in range(inband.YSize - 1, -1, -1):
        i2=inband.YSize-i
        if ( float(i2)%1000==0 ):
            print(i2,'/',inband.YSize)
            
        scanline = inband.ReadAsArray(0, i, inband.XSize, 1, inband.XSize, 1)
    #outline = numpy.zeros((1,inband.XSize))
#    print scanline.shape
#    print outline.shape

        # loop all outbands and calculate proportion
        for iBand in range(outdataset.RasterCount):
            vegtype_id=vegtype_ids[iBand]
            vegtype_name=vegtype_names[vegtype_id]
            outline = np.choose( np.equal( scanline, vegtype_id),
                                (0.0, 100.0) )
        #print iBand,'-',vegtype_id,'-',vegtype_name
        #print str(scanline)
        #print str(outline)
        #print (str(numpy.equal( scanline, vegtype_id)))
            
            outband = outdataset.GetRasterBand(iBand+1)
            outband.WriteArray(outline, 0, i)
            outband=None
                      
    inband=None
    indataset=None
    outdataset=None
    
    return 1


####################
def join_maps(ifile_mosaic,ifile_domin,ofile_ids,ofile_vals,num_join_cats):
    print('join_maps ',ifile_mosaic,ifile_domin,ofile_ids,ofile_vals,num_join_cats)
    indataset = gdal.Open( ifile_mosaic, GA_ReadOnly )
    if indataset.RasterCount < len(vegtype_ids):
        print(ifile_mosaic+' has only '+str(indataset.RasterCount)+' bands, needs '+str(len(vegtype_ids)))
        #exit()
        return 0
    indataset1 = gdal.Open( ifile_domin, GA_ReadOnly )
    if indataset1.RasterCount != 1:
        print('ifile_domin must have 1 band, has '+indataset1.RasterCount)
        #exit()
        return 0

    out_driver = gdal.GetDriverByName(format)
#print(str(numvegtypes))
#print(str(create_options))
    myunlink(ofile_ids)
    myunlink(ofile_vals)
    outdataset_ids = out_driver.Create(ofile_ids, indataset.RasterXSize, indataset.RasterYSize,num_join_cats, GDT_Byte, create_options)
    outdataset_vals = out_driver.Create(ofile_vals, indataset.RasterXSize, indataset.RasterYSize,num_join_cats+1, GDT_Float32, create_options)

    gt = indataset.GetGeoTransform()
    if gt is not None and gt != (0.0, 1.0, 0.0, 0.0, 0.0, 1.0):
        outdataset_ids.SetGeoTransform(gt)
        outdataset_vals.SetGeoTransform(gt)

    prj = indataset.GetProjectionRef()
    if prj is not None and len(prj) > 0:
        outdataset_ids.SetProjection(prj)
        outdataset_vals.SetProjection(prj)


    #set outband metadata
#    tmpmeta=['dominant', 'water']
    tmpmeta=[]
    for i in range(0,len(tmpmeta)):
        outband = outdataset_ids.GetRasterBand(i+1)    
        metadata = outband.GetMetadata()
        metadata['category'] = tmpmeta[i]+'_id'
        #print(str(metadata))
        outband.SetMetadata(metadata)

        outband = outdataset_vals.GetRasterBand(i+1)    
        metadata = outband.GetMetadata()
        metadata['category'] = tmpmeta[i]+'_prop'
        #print(str(metadata))
        outband.SetMetadata(metadata)

    for i in range(0,num_join_cats):
#        print(str(i),str(i*2),str(i*2+1),str(i+1))
        outband = outdataset_ids.GetRasterBand(i+1)    
        outmetadata = outband.GetMetadata()
        outmetadata['category'] = 'cat'+str(i+1)+'_prop'
        #print(str(outmetadata))
        outband.SetMetadata(outmetadata)
        outband.SetNoDataValue( nodata_id )

        outband = outdataset_vals.GetRasterBand(i+1)    
        outmetadata = outband.GetMetadata()
        outmetadata['category'] = 'cat'+str(i+1)+'_id'
#        tmpmeta.append('cat'+str(i+2)+'_id')
        #print(str(outmetadata))
        outband.SetMetadata(outmetadata)

    outband = outdataset_vals.GetRasterBand(num_join_cats+1)    
    outmetadata = outband.GetMetadata()
    outmetadata['category'] = 'total'
#        tmpmeta.append('cat'+str(i+2)+'_id')
        #print(str(outmetadata))
    outband.SetMetadata(outmetadata)

    #set outband data

        #TODO add dominant_vals and water_ids
    #dominant
    inband = indataset1.GetRasterBand(1)
    outband = outdataset_ids.GetRasterBand(1)
    copyBand( inband, outband )

    #water
#    for i in range(0,indataset.RasterCount):
#        inband = indataset.GetRasterBand(i+1)  
#        inmetadata = inband.GetMetadata()
##        print(str(i)+'-'+str(inmetadata))
#        if int(inmetadata['vegtype_id']) == water_id:
##            print('water')
#            outband = outdataset_vals.GetRasterBand(2)
#            copyBand( inband, outband )

    #others - loop over all pixels and compute num_join_cats props.

    scanlines = np.empty([indataset.RasterCount,indataset.RasterXSize ], dtype=np_type)#change this if float data
    scanline = np.empty([1,indataset.RasterXSize], dtype=np_type)#change this if float data
    cat_ids = np.empty([num_join_cats,indataset.RasterXSize ], dtype=np_type)#change this if float data
    cat_vals = np.empty([num_join_cats,indataset.RasterXSize ], dtype=np_type)#change this if float data
    total_vals = np.empty([1,indataset.RasterXSize ], dtype=np_type)#change this if float data
    for i in range(0, indataset.RasterYSize):
        for iCats in range(0, num_join_cats):
            cat_ids[iCats:] = np.zeros( indataset.RasterXSize )
            cat_vals[iCats:] = np.zeros( indataset.RasterXSize )
            total_vals[iCats:] = np.zeros( indataset.RasterXSize )
        for iBand in range(0, indataset.RasterCount):
            scanlines[iBand,:] = indataset.GetRasterBand(iBand+1).ReadAsArray(0, i, inband.XSize, 1, inband.XSize, 1)
#            if i==0:
            if False:
                print('scanlines['+str(iBand)+',:)')
                pp.pprint(scanlines[iBand,:])
        for j in range(0, indataset.RasterXSize):
            tmpval=dict(enumerate(scanlines[:,j]))
            tmpval2=sorted(tmpval,key=tmpval.get,reverse=True)
            for iCats in range(0, num_join_cats):
                cat_ids[iCats,j] = vegtype_ids[tmpval2[iCats]]
                cat_vals[iCats,j] = tmpval[tmpval2[iCats]]
            if False:
#                if i==0 and j==6:
                    print('ids:')
                    pp.pprint(vegtype_ids[tmpval2[iCats]])
                    print('vals:')
                    pp.pprint(tmpval[tmpval2[iCats]])
#                cat_ids[tmpval[[tmpval2[iCats]]]==0.0,j] = vegtype_nd
#            tmpval3=list(sorted(tmpval, key=tmpval.__getitem__))
#            if i==0 and j==6:
            if False:
                print('scanlines[:,'+str(j)+')')
                pp.pprint(scanlines[:,j])
                pp.pprint(tmpval)
                pp.pprint(tmpval.keys())
                pp.pprint(tmpval2)
                print(str(cat_ids[:,j]))
                print(str(cat_vals[:,j]))
#                pp.pprint(tmpval3)
        #pp.pprint(scanlines)
#        for j in range(0, indataset.RasterXSize):
#            print(str(i)+' '+str(j))
        # remove ids which val==0
        cat_ids[cat_vals==0.0] = nodata_id
        for iCats in range(0, num_join_cats):
#            scanline = np.zeros([indataset.RasterXSize]) 
#            scanline[0,:] = iCats+1
#            pp.pprint(scanline)
            outband = outdataset_ids.GetRasterBand(iCats+1)
            scanline[0,] = cat_ids[iCats,]
            #pp.pprint(scanline)
            outband.WriteArray(scanline, 0, i)
            outband = outdataset_vals.GetRasterBand(iCats+1)
            scanline[0,] = cat_vals[iCats,]
            #pp.pprint(scanline)
            total_vals[0] += cat_vals[iCats,] 
            #pp.pprint(total_vals)
            outband.WriteArray(scanline, 0, i)

        outband = outdataset_vals.GetRasterBand(num_join_cats+1)
        scanline[0,] = total_vals[0]
        #pp.pprint(total_vals)
        outband.WriteArray(scanline, 0, i)
            
#        scanline = inband.ReadAsArray(0, i, indataset.RasterXSize, 1, indataset.XSize, 1)
#        outband.WriteArray(scanline, 0, i)

                        
    inband=None
    indataset=None
    outdataset_ids=None
    outdataset_vals=None
    
    attach_pct( file_pct, ofile_ids)

    return 1


###############################################################################
# args

#if mtype is None or ifile is None or ofile is None:
if len(sys.argv) < 3:
    print('usage: ',sys.argv[0],' mtype ifile.tif')
    print('mtype must be one of <IGBP,IBIS>')
    exit()

# Parse command line arguments.
mtype=sys.argv[1]
ifile=sys.argv[2]

###############################################################################
# defs

pp = pprint.PrettyPrinter(indent=4, depth=100)

mosaic_levs="2 4 8 16 30 32 64 120 128 256"
mosaic_outsize="-outsize 94 138"
mosaic_outsize2="-outsize 188 276" #1/32
options_gtiff="-co COMPRESS=DEFLATE" 
#join_cats=4

inNoData = None
inNoData2 = None
outNoData = None
infile = None
outfile = None
format = 'GTiff'
#otype = GDT_Byte
#np_type = np.uint8
np_type = np.float32
#otype = GDT_Float32
compare = 'eq'
compare_buffer = None
compare_buffer2 = None
a_nodata = None
create_options = ['COMPRESS=DEFLATE']

#ofile_wgs_mode=$product.$var.$region.$year.wgs84.dominant_05.tif
#ofile_wgs_mosaic=$product.$var.$region.$year.wgs84.mosaic.tif
#ofile_wgs_mosaic2=$product.$var.$region.$year.wgs84.mosaic_05.tif
ofile_base=os.path.splitext(os.path.basename(ifile))[0]
ofile_domin_0p5=ofile_base+'.domin_0p5.tif'
ofile_domin_0p125=ofile_base+'.domin_0p125.tif'
ofile_mosaic_all=ofile_base+'.mosaic_all.tif'
ofile_mosaic_0p5=ofile_base+'.mosaic_0p5.tif'
ofile_mosaic_0p125=ofile_base+'.mosaic_0p125.tif'
#ofile_join_0p5=ofile_base+'.join_0p5.tif'
#ofile_ids_0p5=ofile_base+'.ids_0p5.tif'
#ofile_vals_0p5=ofile_base+'.vals_0p5.tif'

#myvegtypes = ['1','2','8','9','10','11','14','20','21','22','23']
#vegtype_ids = [1,2,8,9,10,11,14,20,21,22,23]
#numvegtypes = len(myvegtypes)
#print(str(numvegtypes))

if mtype=='IGBP':
    vegtype_ids=range(0,16+1)
    nodata_id=255
    vegtype_ids.append(254)
    vegtype_ids.append(255)
    water_id=0
    file_pct='/data/research/data/map/colors/igbp.pct'

    vegtype_names={
        0:'Water',
        1:'Evergreen Needleleaf forest',
        2:'Evergreen Broadleaf forest',
        3:'Deciduous Needleleaf forest',
        4:'Deciduous Broadleaf forest',
        5:'Mixed forest',
        6:'Closed shrublands',
        7:'Open shrublands',
        8:'Woody savannas',
        9:'Savannas',
        10:'Grasslands',
        11:'Permanent wetlands',
        12:'Croplands',
        13:'Urban and built-up',
        14:'Cropland/Natural vegetation mosaic',
        15:'Snow and ice',
        16:'Barren or sparsely vegetated',
        254:'Unclassified',
        255:'Fill Value' 
        }

elif mtype=='IBIS':
    vegtype_ids=range(1,15+1)
    vegtype_ids.append(99)
    vegtype_ids.append(100)
    nodata_id=100
    water_id=99
    file_pct='/data/research/data/map/colors/ibis.pct'

    vegtype_names = dict()
    vegtype_names[1]="tropical_evergreen"
    vegtype_names[2]="tropical_deciduous"
    vegtype_names[3]="temperate_evergreen_broadleaf"
    vegtype_names[4]="temperate_evergreen_conifer"
    vegtype_names[5]="temperate_deciduous"
    vegtype_names[6]="boreal_evergreen"
    vegtype_names[7]="boreal_deciduous"
    vegtype_names[8]="mixed_forest"
    vegtype_names[9]="cerrado_savanna"
    vegtype_names[10]="grassland_steppe"
    vegtype_names[11]="caatinga_dense_schrubland"
    vegtype_names[12]="open_shrubland"
    vegtype_names[13]="tundra"
    vegtype_names[14]="desert"
    vegtype_names[15]="polar_desert_rock_ice"
    vegtype_names[99]="water"
    vegtype_names[100]="unclassified"
#vegtype_names[20]="water"
#vegtype_names[21]="agro_pecuary"
#vegtype_names[22]="urban"
#vegtype_names[23]="secondary_forest"

elif mtype=='INLAND':
    vegtype_ids=range(1,22+1)
    vegtype_ids.append(100)
    nodata_id=100
    water_id=16
    file_pct='/data/research/data/map/colors/inland.pct'

    vegtype_names = dict()
    vegtype_names[1]="tropical_evergreen"
    vegtype_names[2]="tropical_deciduous"
    vegtype_names[3]="temperate_evergreen_broadleaf"
    vegtype_names[4]="temperate_evergreen_conifer"
    vegtype_names[5]="temperate_deciduous"
    vegtype_names[6]="boreal_evergreen"
    vegtype_names[7]="boreal_deciduous"
    vegtype_names[8]="mixed_forest"
    vegtype_names[9]="cerrado_savanna"
    vegtype_names[10]="grassland_steppe"
    vegtype_names[11]="caatinga_dense_schrubland"
    vegtype_names[12]="open_shrubland"
    vegtype_names[13]="tundra"
    vegtype_names[14]="desert"
    vegtype_names[15]="polar_desert_rock_ice"
    vegtype_names[16]="water"
    vegtype_names[17]="urban"
    vegtype_names[18]="wetlands"
    vegtype_names[19]="agricultural"
    vegtype_names[20]="cropland"
    vegtype_names[21]="pasture"
    vegtype_names[22]="secondary/reforestation"
    vegtype_names[100]="unclassified"


else:
    print('mtype must be one of <IGBP,IBIS,INLAND>')
    exit()

print(ifile,ofile_base)
print(str(vegtype_ids))
print(str(vegtype_names))


###############################################################################
# output files
# input.tif                 input                     MCD12Q1.IGBP.SA.2002.wgs84.tif 
# input.tif.ovr             dominant at all res.      MCD12Q1.IGBP.SA.2002.wgs84.tif.ovr
# input.domin_<res>.tif     dominant at <res>         MCD12Q1.IGBP.SA.2002.wgs84.domin_0p5.tif
# input.mosaic_all.tif      mosaic at base res.       MCD12Q1.IGBP.SA.2002.wgs84.mosaic_all.tif
# input.mosaic_all.tif.ovr  props. at all res.        MCD12Q1.IGBP.SA.2002.wgs84.mosaic_all.tif.ovr
# input.mosaic_<res>.tif    mosaic at <res>           MCD12Q1.IGBP.SA.2002.wgs84.mosaic_0p5.tif
# input.join_<res>.tif      dominant+mosaic at <res>  MCD12Q1.IGBP.SA.2002.wgs84.join_0p5.tif



###############################################################################
# exec

#make dominant maps
if True:
#if not os.path.exists(ofile_domin_0p5):
    myexec('gdaladdo -ro -clean -r mode --config COMPRESS_OVERVIEW DEFLATE '+ifile+' '+mosaic_levs)
    myexec('gdal_translate '+options_gtiff+' '+mosaic_outsize+' '+ifile+' '+ofile_domin_0p5) 
    attach_pct( file_pct, ofile_domin_0p5)
    myexec('gdal_translate '+options_gtiff+' '+mosaic_outsize2+' '+ifile+' '+ofile_domin_0p125) 
    attach_pct( file_pct, ofile_domin_0p125)

#make map levels and compute mosaic levels

if not os.path.exists(ofile_mosaic_all):
    print(ofile_mosaic_all+' does not exist, calling make_map_levels')
    make_map_levels(ifile,ofile_mosaic_all)
    myexec('time gdaladdo -ro -clean -r average --config COMPRESS_OVERVIEW DEFLATE '+ofile_mosaic_all+' '+mosaic_levs)

#extract mosaic levels
if not os.path.exists(ofile_mosaic_0p5):
    myexec('gdal_translate '+options_gtiff+' '+mosaic_outsize+' '+ofile_mosaic_all+' '+ofile_mosaic_0p5) 
if not os.path.exists(ofile_mosaic_0p125):
    myexec('gdal_translate '+options_gtiff+' '+mosaic_outsize2+' '+ofile_mosaic_all+' '+ofile_mosaic_0p125) 

#join dominant and mosaics
for res in ['0p5','0p125']:
    for numcats in ['02','04','08','16']:
        join_maps( ofile_base+'.mosaic_'+res+'.tif', ofile_base+'.domin_'+res+'.tif', ofile_base+'.'+numcats+'ids_'+res+'.tif', ofile_base+'.'+numcats+'vals_'+res+'.tif',int(numcats) )


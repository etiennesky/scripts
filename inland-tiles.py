#!/usr/bin/env python

# /data/docs/research/scripts/inland-tiles.py  inland-2000 inland-tiles-2000.nc inland-yearly-2000-t??.nc
# inland-tiles.py bla5 ../inland-tiles-2000.nc 1 tiles-tmp00000?.nc
# 

import sys, os, shutil

import numpy

from netCDF4 import Dataset, num2date
#from scipy.io import netcdf 
#from netcdftime import num2date #get this from netCDF4-python

# =============================================================================
# Functions

def Usage():
    print('Usage: inland-tiles oprefix tilefile istile={0,1} ifile(s)')
    print('')
    sys.exit( 1 )

# =============================================================================
# Arguments

if len(sys.argv) < 3:
    Usage()
      
oprefix=sys.argv[1]
tfile=sys.argv[2]
istile=sys.argv[3]
ifiles=sys.argv[4:]

if not os.path.exists(tfile):
    print('tfile '+tfile+' not found')
    Usage()
for ifile in ifiles:
    if not os.path.exists(ifile):
        print('ifile '+ifile+' not found')
        Usage()

ntiles = len(ifiles)
nvegtypes=20

ofiles = []
for i in range(1,nvegtypes+1):
    ofiles.append( "%s-v%s.nc" % (oprefix, str(i).zfill(2)) )
ofiletot = "%s-vxx.nc" % (oprefix)

print ('tfile: '+str(tfile))
print ('ifiles: '+str(ifiles))
print ('ofiles: '+str(ofiles))


# create output files by copying and clearing non-dim vars

def nodataval(var):
    if "missing_value" in var.ncattrs():
        nodata = var.getncattr("missing_value") 
    elif "_FillValue" in var.ncattrs():
        nodata = var.getncattr("_FillValue") 
    else:
        nodata = None
    return nodata
    
ofile = ofiles[0]
shutil.copyfile( ifiles[0], ofile )
ods = Dataset(ofile, 'r+')

for varname in ods.variables:
    if varname in ods.dimensions or varname == "date":
        continue
    var = ods.variables[varname]
    nodata = nodataval(var)
    var[:] = nodata

ods.close()
ods = None

for ofile in ofiles[1:]:
    shutil.copyfile( ofiles[0], ofile )


tds = Dataset(tfile, 'r')

# process each input file

for j in range(1,nvegtypes+1):
    ofile = ofiles[j-1]
    print("ofile: "+ofile)
    ods = Dataset(ofile, 'r+')

    for varname in ods.variables:
    #for varname in ["npptot"]:
        if varname in ods.dimensions or varname == "date":
            continue
        
        #print(varname)
        ovar = ods.variables[varname]
        nodata = nodataval(ovar)
        if istile == "1":
            nodata = 0
        data = ovar[:]

        for i in range(0,len(ifiles)):
            ifile = ifiles[i]
            ids = Dataset(ifiles[i])
            ivar = ids.variables[varname]
            idata = ivar[:]

            if i == 0:
                data[:] = nodata
                if istile == "1": 
                    data2 = 0
            #print(tds.variables['vegtype'])
            vals = tds.variables['vegtype'][:,i]
            mask = numpy.equal( vals, j )
            #else:
            #    data = numpy.choose( mask, (data,idata) )
            if varname == "tileprop":
            #if varname == "vegtype":
                print("ifile: "+ifile+" j: "+str(j))
                print(idata)
                print(vals)
                print(mask)
            
            if istile == "1": 
                data2 = data2 + numpy.choose( mask, (0,idata) )
            else:
                data = numpy.choose( mask, (data,idata) )


            ids.close()

        if istile == "1": 
            ovar[:] = data2
        else:
            ovar[:] = data
        #print(data)

    ods.close()


# make multi-level file

ods = Dataset(ofiletot, 'w')
print('ofiletot: '+ofiletot)
ids = Dataset(ofiles[0], 'r')

#sys.exit( 1 )

# create dimensions
#print( 'dimensions:' )
dimnames=[]
for dimname in ids.dimensions: 
    dim = ids.dimensions[dimname]
    #print( dimname )
    d = ods.createDimension( dimname, len(dim) )
    if dimname in ids.variables:
        var = ids.variables[dimname]
        v = ods.createVariable( dimname, var.dtype, var.dimensions )
        for a in var.ncattrs():
            v.setncattr( a, var.getncattr(a) )
        v[:] = var[:]

#copy attributes
#print( 'global attr:' )
for a in ids.ncattrs():
    #print( a )
    ods.setncattr( a, getattr(ids,a) )

# create new vegtype dim+var
dimvegtype = ods.createDimension( "vegtype", nvegtypes )
varvegtype = ods.createVariable( "vegtype", "b", ("vegtype",) )
varvegtype[:] = range(1,nvegtypes+1)

# create variables - could first define and then write for more efficiency
#print( 'variables:' )
for varname in ids.variables:
    if varname in ods.dimensions or varname == "date":
        continue
    #print( varname )
    var = ids.variables[varname]
    dim2=list(var.dimensions)
    #dim2.insert(0,"vegtype")
    dim2.insert(1,"vegtype")
    #dim2.insert(len(var.dimensions)-3,"vegtype")
    dim2=tuple(dim2)
    #v = ods.createVariable( varname, var.dtype, var.dimensions )
    v = ods.createVariable( varname, var.dtype, dim2 )
    for a in var.ncattrs():
        v.setncattr( a, getattr(var,a) )
    nodata = nodataval(var)
    v[:] = nodata #var[:]

ids.close()

# copy data from vegtype files to this one

print( 'copying final' )

for varname in ods.variables:
#for varname in ["npptot"]:
    if varname in ods.dimensions or varname == "date":
        continue

    #print(str(varname))
    data = ods.variables[varname][:]

    for j in range(1,nvegtypes+1):
        ifile = ofiles[j-1]
        ids = Dataset(ifile, 'r')

        ivar = ids.variables[varname]
        #data[j-1,] = ivar[:]
        data[0][j-1,] = ivar[:]

    ods.variables[varname][:] = data

    ids.close()

ods.close()

#!/usr/bin/env python

import sys, os, shutil

import numpy

from netCDF4 import Dataset, num2date
#from scipy.io import netcdf 
#from netcdftime import num2date #get this from netCDF4-python

# =============================================================================
# Functions

def Usage():
    print('Usage: inland-tiles oprefix ifile(s)')
    print('')
    sys.exit( 1 )

# =============================================================================
# Arguments

if len(sys.argv) < 3:
    Usage()
      
oprefix=sys.argv[1]
tfile=sys.argv[2]
ifiles=sys.argv[3:]

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

ofile = ofiles[0]
shutil.copyfile( ifiles[0], ofile )
ods = Dataset(ofile, 'r+')

for varname in ods.variables:
    if varname in ods.dimensions or varname == "date":
        continue
    var = ods.variables[varname]
    if "missing_value" in var.ncattrs():
        nodata = var.getncattr("missing_value") 
    else:
        nodata = None
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
        
        ovar = ods.variables[varname]
        if "missing_value" in ovar.ncattrs():
            nodata = ovar.getncattr("missing_value") 
        else:
            nodata = None
        nodata = None #TMP
        data = ovar[:]

        for i in range(0,len(ifiles)):
            ifile = ifiles[i]
            ids = Dataset(ifiles[i])
            ivar = ids.variables[varname]

            if i == 0:
                data[:] = nodata
            vals = tds.variables['vegtype'][:,i]
            mask = numpy.equal( vals, j )
            
            data = numpy.choose( mask, (data,ivar) )

            ids.close()

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
    dim2.insert(0,"vegtype")
    dim2=tuple(dim2)
    #v = ods.createVariable( varname, var.dtype, var.dimensions )
    v = ods.createVariable( varname, var.dtype, dim2 )
    for a in var.ncattrs():
        v.setncattr( a, getattr(var,a) )
    if "missing_value" in var.ncattrs():
        nodata = var.getncattr("missing_value") 
    else:
        nodata = None
    nodata = None #TMP
    v[:] = nodata #var[:]

ids.close()

# copy data from vegtype files to this one

print( 'copying final' )

for varname in ods.variables:
#for varname in ["npptot"]:
    if varname in ods.dimensions or varname == "date":
        continue
    data = ods.variables[varname][:]
    #print(str(data[:]))

    for j in range(1,nvegtypes+1):
        ifile = ofiles[j-1]
        ids = Dataset(ifile, 'r')

        ivar = ids.variables[varname]
        data[j-1,] = ivar[:]

    #print(str(data[:]))
    ods.variables[varname][:] = data
    #print(str(ods.variables[varname][:]))

    ids.close()

ods.close()

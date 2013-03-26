#!/usr/bin/env python

# =============================================================================
# inland-hrmap.py
# this script generates a high-res map for all variables in input file
# it works for small files, but not for large ones, must write in F90...

# =============================================================================
# imports

import sys, os
import numpy

#from guppy import hpy
#import resource
#print 'resources:'
#print resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
#print h.heap()


# import netcdf package, either netCDF4 (recommended, support netcdf-4 files) or scipy.io.netcdf
# actually... scipy.io.netcdf is not supported yet...
try:
    from netCDF4 import Dataset, num2date
    use_netcdf4 = True
except ImportError:
    print('please install netcdf4-python from http://netcdf4-python.googlecode.com')
    sys.exit( 1 )
    #use_netcdf4 = False
    #try:
    #    from scipy.io import netcdf 
    #except ImportError:
    #    print('please install netCDF4 or scipy.io.netcdf')
    #    sys.exit( 1 )
    #try:
    #    from netcdftime import num2date #get this from netCDF4-python if using scipy
    #except ImportError:
    #    print('please install num2date.py from netCDF4')
    #    sys.exit( 1 )

# =============================================================================
# Functions

def Usage():
    print('Usage: inland-hrmap.py ifile hrfile tfile ofile')
    print('')
    sys.exit( 1 )

# get nodata value for a given variable
def nodataval(var):
    if "missing_value" in var.ncattrs():
        nodata = var.getncattr("missing_value") 
    elif "_FillValue" in var.ncattrs():
        nodata = var.getncattr("_FillValue") 
    else:
        nodata = None
    return nodata


# returns [npoi1,tile] tuple for a given index (which can range from 1:npoi)
#def npoi1_tile(index):

# =============================================================================
# Arguments

if len(sys.argv) < 5:
    Usage()
      
ifile=sys.argv[1]
hrfile=sys.argv[2]
tfile=sys.argv[3]
ofile=sys.argv[4]

if not os.path.exists(ifile):
    print('ifile '+ifile+' not found')
    Usage()
if not os.path.exists(hrfile):
    print('hrfile '+hrfile+' not found')
    Usage()
if not os.path.exists(tfile):
    print('tfile '+tfile+' not found')
    Usage()

print ('ifile: '+str(ifile))
print ('hrfile: '+str(hrfile))
print ('tfile: '+str(tfile))
print ('ofile: '+str(ofile))

vars_ignore = ['date', 'tile']


# ==============================================================================
# create output file by copying input file dims, global attributes and vars

print("opening datasets")

# if using netcdf4, define file as netcdf4-classic and use zlib compression in vars 
ids = Dataset(ifile, 'r')
hrds = Dataset(hrfile, 'r')
tds = Dataset(tfile, 'r')
ods = Dataset(ofile, 'w', format='NETCDF4_CLASSIC')

# create dimensions - could first define and then write for more efficiency
print("creating dims")
dimnames=[]
for dimname in ids.dimensions: 
    #print( dimname )

    # skip tile - we don't need it in hrmap
    if dimname == "tile":
        continue

    dim = ids.dimensions[dimname]

    #resize lon and lat to hrmap
    dlen = len(dim)
    if dimname=="lon" or dimname=="longitude" or dimname=="lat" or dimname=="latitude":
        dlen = len(hrds.dimensions[dimname])

    d = ods.createDimension( dimname, dlen )
    if dimname in ids.variables:
        var = ids.variables[dimname]
        dims = var.dimensions
        if dimname=="lon" or dimname=="longitude" or dimname=="lat" or dimname=="latitude":
            dvar = hrds.variables[dimname][:]            
        else:
            dvar = var[:]            
        v = ods.createVariable( dimname, var.dtype, dims )
        for a in var.ncattrs():
            v.setncattr( a, var.getncattr(a) )       
        v[:] = dvar
    d = None

#copy global attributes
for a in ids.ncattrs():
    ods.setncattr( a, getattr(ids,a) )

# close datasets, so memory doesn't explode when writing vars
ods.close()

# create variables
print("creating vars")
for varname in ids.variables:

    if (varname in ids.dimensions) or (varname in vars_ignore):
        continue
    var = ids.variables[varname]

    # skip tile dimension
    #dim2 = var.dimensions
    dim2 = []
    for d in list(var.dimensions):
        if d != "tile":
            dim2.append(d)
    dim2=tuple(dim2)

    ods = Dataset(ofile, 'r+')

    # if using netcdf4, define file as netcdf4-classic and use zlib compression in vars 
    v = ods.createVariable( varname, var.dtype, dim2, zlib=True, complevel=2 )
    #v = ods.createVariable( varname, var.dtype, dim2 )

    #add attrs
    for a in var.ncattrs():
        v.setncattr( a, getattr(var,a) )

    v = None

    # close datasets, so memory doesn't explode when writing vars
    ods.close()


# ==============================================================================
# populate output file

print("getting tile map")

# get tile map
ihrtileparent_data = hrds.variables['ihrtileparent']
itilechild_data = tds.variables['itilechild']

# store parent tile indices in a map, key is child index, value is [tile,lat,lon] indices
tile_map = dict() #dict()
nd = len(itilechild_data.dimensions)
for k in range(itilechild_data.shape[nd-3]) :
    for j in range(itilechild_data.shape[nd-2]) :
        for i in range(itilechild_data.shape[nd-1]) :
            #if itilechild_data[:,k,j,i][0] in ihrtileparent_data[0]:
            tile_map[ itilechild_data[:,k,j,i][0] ] = numpy.array([k,j,i])
#ihrtileparent_unique = numpy.unique(ihrtileparent_data[0])[0:-1]
ihrtileparent_unique = tile_map.keys()


# process each var, except dims and any other special vars

vars = ods.variables
dimvars = ods.dimensions

print("filling vars")

for varname in vars:
#for varname in ["npptot", "biomass"]:
#for varname in ["exist","plai","biomass","npp"]:

    if (varname in dimvars) or (varname in vars_ignore):
        continue
    
    ivar = ids.variables[varname]
    numdims = len(ivar.shape)

    sys.stdout.write("==== "+varname+" "+str(numdims)+" ")
    sys.stdout.flush()

    ods = Dataset(ofile, 'r+')
    ovar = ods.variables[varname]
    # fill with nodata
    nodata = nodataval(ovar)
    ovar[:] = nodata
    ovar1 = ovar[:]
        
    # loop over tiles
    # it might be more efficient to NOT loop over ihrtileparent_unique, find a pythonic way 
    for t in ihrtileparent_unique:

        if not numpy.isscalar(t):
            continue

        m = tile_map[t]

        # if var has 5 dims (pft), we need to loop over pfts
        # might be more efficient outside tile loop...
        if numdims == 5:
            continue
            #sys.stdout.write(str(i)+" ")
            #sys.stdout.flush()
            for j in range(ovar.shape[1]):
                ovar1[ 0,j,numpy.equal( ihrtileparent_data[0], t ) ] = ivar[ 0,m[0],j,m[1],m[2] ]
        else:
            ovar1[ 0,numpy.equal( ihrtileparent_data[0], t ) ] = ivar[ 0,m[0],m[1],m[2] ]

    # set data
    ovar[:] = ovar1

    # close datasets, so memory doesn't explode when writing vars
    ids.close()
    ods.close()

    print("")

# ==============================================================================
# close files

#ids.close()
#hrds.close()
tds.close()
#ods.close()



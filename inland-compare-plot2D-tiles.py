#!/usr/bin/env python

import sys, os, subprocess

import pylab as pl
import numpy as np
import matplotlib as mpl
from mpl_toolkits.basemap import Basemap

#use_scipy=True
use_scipy=False
if use_scipy:
    from scipy.io import netcdf 
    from netcdftime import num2date #get this from netCDF4-python
else:
    from netCDF4 import Dataset, num2date, date2num

# =============================================================================
# Functions

def Usage():
    print('Usage: plot-2D.py ifile <odir> [plot_2d=1] [plot_norm=0]')
    print('')
    sys.exit( 1 )

def plot_var(varname,ofile,title,units,data,fill_value,lon,lat):
    print('plot_var '+varname+' '+ofile)
    pl.clf()
    if plot_norm:
        title = title + ' / norm. diff ( % ) '
        units = '%'
    elif units == 'none' or units == 'None' or units == None or units == '':
            units = 'none'        
#    else:
#        title = title + ' ( ' + units + ' )'
#        units = '\n'+units
    pl.suptitle(title)
    # fix stupid scipy.io.netcdf _FillValue bug
    if use_scipy:
        data2 = np.copy( data )
        data2[data2==fill_value] = None
    else:
        data2 = data

    lon2=[ lon[0], lon[len(lon)-1] ]
    lat2=[ lat[0], lat[len(lat)-1] ] 
    lonstep=10
    latstep=10
    labelstyle=None
    fontsize=12
    if lon2 == [-179.75, 179.75] and lat2 == [89.75, -89.75]:
        lat2 = [85,-60]
        lonstep=30
        latstep=20
        #labelstyle="+/-"
        fontsize=9

    map = Basemap(llcrnrlon=min(lon2),llcrnrlat=min(lat2),urcrnrlon=max(lon2),urcrnrlat=max(lat2),projection='mill')
    map.drawcoastlines(linewidth=1.25)
    map.drawparallels(np.arange(round(min(lat2)),max(lat2),latstep),labels=[1,0,0,0],labelstyle=labelstyle,fontsize=fontsize)
    map.drawmeridians(np.arange(round(min(lon2)),max(lon2),lonstep),labels=[0,0,0,1],labelstyle=labelstyle,fontsize=fontsize)
    data3 = map.transform_scalar(np.flipud(data2), lon, np.flipud(lat), len(lon), len(lat))

    # show data
    #cs = pl.contourf(data)
    #cs = map.imshow(data3,interpolation='nearest')
    if varname in limits:
        limit = limits[varname]
        norm = None
        cmap = pl.cm.jet
        #if varname in cbar_discrete:
        if data.dtype == np.int8 or data.dtype == np.int16  or data.dtype == np.int32:
            #http://stackoverflow.com/questions/14777066/matplotlib-discrete-colorbar
            bounds = range(limit[0],limit[1]+1)
            bounds2 = [bounds[0]]
            for i in bounds[1:]:
                bounds2.append(i-0.01)
            norm = mpl.colors.BoundaryNorm(bounds2, cmap.N)
            cs = map.imshow(data3,interpolation='nearest',vmin=limit[0], vmax=limit[1], cmap=cmap, norm=norm)
            cbar = map.colorbar(cs, cmap=cmap, norm=norm, spacing='proportional', ticks=bounds[0:-1], boundaries=bounds, format='%1i')
        else:
            cs = map.imshow(data3,interpolation='nearest',vmin=limit[0], vmax=limit[1])
            cbar = map.colorbar(cs)
    else:
        cs = map.imshow(data3,interpolation='nearest')
        cbar = map.colorbar(cs)
    if units != 'none':
        cbar.ax.set_xlabel(units,ha='left')   

    pl.savefig(ofile)


# =============================================================================
# Arguments

if len(sys.argv) < 2:
    print('got '+str(len(sys.argv)))
    Usage()

#print(len(sys.argv))
ifile=sys.argv[1]  
(odir,ifile_base) = os.path.split(ifile)
#if len(sys.argv)>=3:
#    odir=odir+'/'+sys.argv[2]
if len(sys.argv)>=3:
    odir=sys.argv[2]

plot_2d = True
if len(sys.argv)>=4:
    if (sys.argv[3]=='0'):
        plot_2d = False
plot_norm = False
if len(sys.argv)>=5:
    if (sys.argv[4]=='1'):
        plot_norm = True


plot_4d = False
#exclude_vars=[ 'time_weights', 'longitude', 'latitude' ]
exclude_vars=[ 'time_weights', 'longitude', 'latitude', 'itilechild', 'itileparent', 'vegtype0' ]

limits = dict()
limits['aet'] = [0,2000]
limits['anpptot'] = [-1,2]
limits['awc'] = [0,15]
limits['caccount'] = [-0.5,1]
limits['co2root'] = [0,0.1]
limits['co2soi'] = [0,0.5]
limits['drainage'] = [0,50]
limits['fl'] = [0,1]
limits['fu'] = [0,1]
limits['neetot'] = [-1,5]
limits['npptot'] = [-1,5]
limits['srunoff'] = [0,50000]
limits['trunoff'] = [0,50000]
limits['totbiol'] = [0,0.5]
limits['totbiou'] = [0,10]
limits['totlail'] = [0,10]
limits['totlaiu'] = [0,10]
limits['vegtype0'] = [1,19]
limits['vegtype'] = [1,19]
limits['wsoi'] = [0,1]
limits['tilefrac'] = [0,1]
limits['landusetype'] = [1,17]

cbar_discrete = ['vegtype','vegtype0','landusetype']
#cbar_discrete = []

mapping = dict()
mapping["vegtype"] = [1,9,17,18,19]

print('plot-2D.py '+ifile+' '+ifile_base+' '+odir)

if not os.path.exists(ifile):
    print('ifile '+ifile+' not found')
    Usage()

if not os.path.exists(odir):
    print('odir '+odir+' not found')
    Usage()

# =============================================================================
# Main

# open file
if use_scipy:
    ncfile = netcdf.netcdf_file(ifile, 'r')
else:
    ncfile = Dataset(ifile)
print('ifile: '+ifile)
#print('variables: '+str(ncfile.variables))
#print('time: '+str(ncfile.variables['time']))
times = ncfile.variables['time']
#dates = num2date(times[:],units=times.units,calendar=times.calendar)
dates = num2date(times[:],units=times.units)
#print('dates: '+str(dates))


firstvar=True

for var_name in sorted(ncfile.variables.iterkeys()): 
#    print(var_name)
    print var_name,
    sys.stdout.flush()
    var = ncfile.variables[var_name]
    ndims = len(var.shape)
    ofile_base = os.path.splitext(ifile_base)[0]+'_'+var_name
    if ndims < 3:
        print " skipped"
        continue    
    if var_name in exclude_vars:
        print " skipped"
        continue

    id_time = var.dimensions.index('time')
    ntime = var.shape[id_time]
    # TODO test this with n>5
    step = 1
    if ntime > 50:
        step = 20
    steps = range(0,ntime,step)
    #print('steps: '+str(steps))
    if not ntime-1 in steps:
        steps.append(ntime-1)
    
    if firstvar:
        firstvar=False
        if len(steps) > 0:
            print('steps: ',len(steps),str(steps))

    for j in steps:
        #print str(j), #not ok w/ python 3!
        #print('step :'+str(j))
        if ( len(steps) > 1 ):
            tmp1 = str(dates[j])[0:4] # this only works for yearly files
            tmp2 = '_' + tmp1
            tmp3 = ' - ' + tmp1
        else:
            tmp1 = ''
            tmp2 = ''
            tmp3 = ''
        if use_scipy:
            londata = ncfile.variables['longitude'].data
            latdata = ncfile.variables['latitude'].data
            nodata = var._FillValue
        else:
            londata = ncfile.variables['longitude'][:]
            latdata = ncfile.variables['latitude'][:]
            if "missing_value" in var.ncattrs():
                nodata = var.getncattr("missing_value") 
            else:
                nodata = None
        if ndims == 3:
            ofile_name = odir + '/' + ofile_base + tmp2 + '.png'
            ofile_title = var_name + tmp3
            #print(var)
            plot_var(var_name,ofile_name,ofile_title,var.units,var[j],nodata,londata,latdata)
        elif ndims == 4 and plot_2d:
            odir2 = odir + '/' + var.dimensions[1]
            if not os.path.exists(odir2):
                os.mkdir(odir2)
            if var.dimensions[1] in mapping:
                r = mapping[ var.dimensions[1] ]
            else:
                r = range(1,var.shape[1]+1)
            #for i in range(0,var.shape[1]): # TODO test
            ofiles=[]
            titles=[]
            for i in r: # TODO test
                ofile_name = odir2 + '/' + ofile_base + '_' + tmp1 + '_' + str(i).zfill(2) + '.png'
                ofiles.append(ofile_name)
                ofile_title = var_name + ' / ' + var.dimensions[1] + ' = ' + str(i) 
                if tmp1 != '':
                    ofile_tile = ofile_title + ' / ' + tmp1
                plot_var(var_name,ofile_name,ofile_title,var.units,var[j][i-1],nodata,londata,latdata)

            #montage -geometry +1+20 -tile 2x2 -pointsize 20  -label $basedir_ref $1/plot2d/$f_base -label diff $3/plot2d/$f_base  -label $basedir_comp $2/plot2d/$f_base  $3/montage2d/$f_base'
            ofiles=' '.join(ofiles)
            if not os.path.exists(odir2 + '/montage/'):
                os.mkdir(odir2 + '/montage/')
            command='montage -trim -geometry +20+20 -pointsize 20 '+ofiles+' ' + odir2 + '/montage/' + ofile_base + '.png'
            print(command) 
            subprocess.call(command, shell=True)


print('')

            
ncfile.close()
ncfile = None

print('done')


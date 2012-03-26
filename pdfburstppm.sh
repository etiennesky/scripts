#!/bin/sh

#set -x 

if [ $# -lt 1 ]
then
  echo "Usage: `basename $0` ifile"
  exit 1
fi

ifile=$1
res=300

if [ $# -eq 2 ]; then res=$2; fi

echo "resolution: $res" 

rm -rf pg_*.pdf*
pdftk $1 burst
for f in pg*.pdf ; do echo $f ; pdftoppm -r $res $f > $f.ppm ; done

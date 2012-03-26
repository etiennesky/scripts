#!/bin/bash

#set -x 

if [ $# -lt 1 ]
then
  echo "Usage: `basename $0` img_files"
  exit 1
fi

#note: use "$var" to account for file names with spaces
#http://g-scripts.sourceforge.net/faq.php
#http://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-bash-script

 function namename()
 {
   local name=${1##*/}
   local name0="${name%.*}"
   echo "${name0:-$name}"
 }
 function namename2()
 {
   local name=${1}
   local name0="${name%.*}"
   echo "${name0:-$name}"
 }
 function ext()
 {
   local name=${1##*/}
   local name0="${name%.*}"
   local ext=${name0:+${name#$name0}}
   echo "${ext:-.}"
 }
 function ext2()
 {
   echo ${1##*.}   
 }

for arg
do
    ifile=$arg
    echo "--- "$ifile
    if [ -d "$ifile" ]; then echo "<"$ifile"> is a directory, stopping now"; continue; fi
    if [ ! -f "$ifile" ]; then echo "<"$ifile"> does not exist, stopping now"; continue; fi
    ifileext=`ext2 "$ifile" | tr '[A-Z]' '[a-z]'`
#    if [[ "$ifileext" == "pdf" || "$ifileext" == "zip" || "$ifileext" == "jpg" || "$ifileext" == "jpeg" ]]; then echo "<"$ifile"> has file extension $ifileext, stopping now"; continue; fi
    if [[ "$ifileext" != "png" && "$ifileext" != "tiff" && "$ifileext" != "tif" && "$ifileext" != "gif" ]]; then echo "<"$ifile"> has file extension $ifileext, stopping now"; continue; fi
    ofile=`namename2 "$ifile"`
    ofile=$ofile".jpg"
    if [ "$ifile" == "$ofile" ]; then echo "<"$ifile"> is already a jpg, stopping now"; continue; fi
    nice convert -quality 85 "$ifile" "$ofile" 
done 
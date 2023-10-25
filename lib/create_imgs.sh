#!/bin/sh

set -x

cont_files=$(find staging -print|wc -l)           # files under staging
   cont_mb=$((1+$(du -sk staging|cut -f1)/1024))  # staging in MB

   headroom_fs=8   # room in ffsimg
headroom_media=30  # room in media.img

   roomminus_fs=4  # lesser offset ffsimg
roomminus_media=1  # lesser offset media

# create img files
#
ffsimg=fuguita-$(uname -r)-$(uname -m).ffsimg 
./lib/setup_fsimg.sh $ffsimg $((cont_mb+headroom_fs+roomminus_fs)) $cont_files
./lib/setup_fsimg.sh media.img $((cont_mb+headroom_fs+headroom_media+roomminus_media)) 20

# make a filler for media.img
#
make open-media
pv $ffsimg | dd of=media/$ffsimg bs=16m
rm -f fill
dd if=/dev/zero of=media/fill bs=1m
cat media/fill >> media/fill
cp media/fill .
make close-all

# make empty ffsimg again
#
rm media.img
./setup_fsimg.sh media.img $((cont_mb+16+30)) 20

# first, locate filler in media
#
make open-media
pv fill > media/fill

# next, put ffsimg
# (media perfectly filled)
#
pv $ffsimg | dd of=media/$ffsimg bs=16m

# remove filler to reserve boot loader and kernel
#
df -h
rm media/fill
make close-media

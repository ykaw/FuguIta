#!/bin/sh

# mkusbfi.sh --- make USB FuguIta
#
# usage: mkusbfi.sh [imgfilesize-mb]
#
# default image file size is 1024MB.

# environment
#
set -x # verbose
set -e # exit on error

# parameters
#
imgfile=FuguIta-`cat /usr/fuguita/version`.img
imgsize=${1:-1024}
vnode=vnd0

# make img file
#
dd if=/dev/zero of=$imgfile bs=1m count=$imgsize
ls -lh

# set device and build
#
vnconfig $vnode $imgfile
vnconfig -l
usbfadm <<EOT
newdrive

$vnode
y
*
y
bye
EOT

# cleanups
#
vnconfig -u $vnode
vnconfig -l
file $imgfile

# compress
#
gzip -v -9 $imgfile

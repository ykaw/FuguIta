#!/bin/sh

#----------------------------------------
# setup_fsimg.sh - setup file system image with specified size
# Yoshihiro Kawamata, kaw@on.rim.or.jp
# $Id: setup_fsimg.sh,v 1.1 2021/05/09 11:53:59 kaw Exp $
#----------------------------------------

errmsg () {
    echo "$0: $@" >&2
}

usage () {
    echo "usage: $0 img_file fs_img_mb [max_files_in_fs]" >&2
}

err_exit () {
    if [ -n "$1" ]; then
        errmsg "$@"
        echo
    fi
    usage;
    exit 1
}

# main from here
#
   fsimg="$1"
 imgsize="$2"
maxfiles="$3"

if [ -z "$imgsize" ]; then
   err_exit "more argument required"
fi

# normalize as an integer
imgsize=$((imgsize + 0))

# find unused vnode device
vndev=$(vnconfig -l | grep 'not in use' | head -n 1 | cut -d: -f1)
if [ -z "$vndev" ]; then
    err_exit "no vn device available"
fi

# create an image file
dd if=/dev/zero bs=1m count="$imgsize" | pv -s "$imgsize"M > "$fsimg"
vnconfig "$vndev" "$fsimg"

# setup fdisk and disklabel partition
echo "e 3\nA6\nn\n64\n*\nw\nq" | fdisk -e "$vndev"
echo "a a\n64\n*\n4.2BSD\nw\nq" | disklabel -E "$vndev"

# calculate appropriate inode density
if [ -n "$maxfiles" ]; then
    idense="-i $((1024*1024*imgsize/maxfiles))"
fi

# format file system
newfs -O 1 -o space -m 0 $idense "/dev/r${vndev}a"

# display result
disklabel -pm "$vndev"
if mount "/dev/${vndev}a" /mnt; then
    df -ki
    echo
    df -k | awk '$1 == "/dev/'${vndev}'a" {print "diff: '$imgsize'MB - " int($2/1024) "MB = " '$((1024*imgsize))'-$2 "KB"}'
    umount /mnt
fi

# clean ups
vnconfig -u "$vndev"

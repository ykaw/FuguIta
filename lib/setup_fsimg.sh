#!/bin/sh

#----------------------------------------
# setup_fsimg.sh - setup file system image with specified size
# Yoshihiro Kawamata, kaw@on.rim.or.jp
# $Id: setup_fsimg.sh,v 1.4 2023/10/25 03:31:19 kaw Exp $
#----------------------------------------

# Copyright (c) 2006--2023
# Yoshihiro Kawamata
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#   * Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#
#   * Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in
#     the documentation and/or other materials provided with the
#     distribution.
#
#   * Neither the name of Yoshihiro Kawamata nor the names of its
#     contributors may be used to endorse or promote products derived
#     from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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
    echo
    df -ki
    echo
    echo "Summary:"
    echo "  max files: ${maxfiles:-not given}"
    idense=${idense#-i }
    echo "   newfs -i: ${idense:-auto}"
    df -k | awk '$1 == "/dev/'${vndev}'a" {printf("  specified: %.1fMB\n  allocated: %.1fMB\n   shrinked: %dKB\n", '$imgsize', $2/1024, '$((1024*imgsize))'-$2)}'
    umount /mnt
fi

# clean ups
vnconfig -u "$vndev"

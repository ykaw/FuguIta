#!/bin/ksh

#----------------------------------------
# setup_fsimg.sh - setup file system image with specified size
# Yoshihiro Kawamata, kaw@on.rim.or.jp
# $Id: setup_fsimg.sh,v 1.13 2025/01/01 00:58:54 kaw Exp $
#----------------------------------------

# Copyright (c) 2021--2025
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

set -e
#set -x

errmsg () {
    echo "$0: $@" >&2
}

usage () {
    echo "usage: $0 img_file du_in_fs[KMG] [max_files_in_fs] ['fs_options']" >&2
}

err_exit () {
    if [ -n "$1" ]; then
        errmsg "$@"
    fi
    usage
    exit 1
}

# notice for progress
#
banner () {
    cat<<EOT

========================================
= $@
========================================
EOT
}

# normalize size value with factor suffix
#
defactor () {
    local valstr=$(echo "$1"|tr kmg KMG)  # capitalize factor

    # check argument format
    #
    if ! $(expr "$valstr" : '[1-9][0-9]*[KMG]\{0,1\}$' >/dev/null); then
        err_exit illegal str: "'$valstr'"
    fi

    local val=${valstr%%[KMG]}   # pick up value part
    local fac=${valstr##*[0-9]}  # pick up factor part

    # calculate bytes
    #
    case "$fac" in
        "") echo "$val";;
        K) echo "$((1024*val))";;
        M) echo "$((1024*1024*val))";;
        G) echo "$((1024*1024*1024*val))";;
        *) err_exit "can't be happen:" val="'$val'" fac="'$fac'"
    esac
}

# main from here
#
if [ -z "$2" ]; then
   err_exit "more argument required"
fi

   fsimg="$1"              # name of image file
 imgsize=$(defactor "$2")  # size of image file
maxfiles="$3"              # files to be contained
 fs_opts="$4"              # newfs options
tgt_part='a'               # target partition

# find unused vnode device
vndev=$(vnconfig -l | grep 'not in use' | head -n 1 | cut -d: -f1)
if [ -z "$vndev" ]; then
    err_exit "no vnode devices available"
fi

# create an image file
# Properly utilize buffering to write faster
  size_m=$(( imgsize / (1024*1024) ))  # image size in MB
size_rem=$(( imgsize % (1024*1024) ))  # remainder divided by 1MB
  size_k=$(( size_rem / 1024 ))        # remainder in KB

# write to file: note that less than 1KB will be truncated
banner "creating zero-filled file"
(dd if=/dev/zero bs=1m count="$size_m" status=none
 dd if=/dev/zero bs=1k count="$size_k" status=none) \
| pv -N "$fsimg" -s "$((imgsize/1024))"K > "$fsimg"

vnconfig "$vndev" "$fsimg"

# setup fdisk and disklabel partition
banner "setup fdisk/disklabel partition"
echo "e 3\nA6\nn\n64\n*\nw\nq" | fdisk -e "$vndev" >/dev/null
fdisk "$vndev"
echo "a ${tgt_part}\n64\n*\n4.2BSD\nw\nq" | disklabel -E "$vndev" >/dev/null
disklabel -pm "$vndev"

# calculate appropriate inode density
if [ -n "$maxfiles" ]; then
    idense="-i $((imgsize/maxfiles))"
fi

# format file system
banner "formatting partiton"
newfs -O 1 -o space -m 0 $fs_opts $idense "/dev/r${vndev}${tgt_part}"

# display result
banner "resulted filesystem"
if mount "/dev/${vndev}${tgt_part}" /mnt; then
    echo
    df -ki | egrep "^(Filesystem|/dev/${vndev}${tgt_part})"
    echo
    echo "Summary:"
    echo "  max files: ${maxfiles:-not given}"
    idense=${idense#-i }
    echo "   newfs -i: ${idense:-auto}"
    df -k \
    | awk '$1 == "/dev/'${vndev}${tgt_part}'"\
           {printf("  specified: %.1fM\n  allocated: %.1fM\n   shrinked: %dK\n",
                   '$((imgsize/1024/1024))',
                   $2/1024,
                   '$((imgsize/1024))'-$2)}'
    umount /mnt
fi

# clean ups
vnconfig -u "$vndev"

banner "done."

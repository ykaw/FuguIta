#!/bin/sh

#----------------------------------------
# remaster_dvd.sh - Remastering FuguIta's LiveDVD
# Yoshihiro Kawamata, kaw@on.rim.or.jp
# $Id: remaster_dvd.sh,v 1.6 2022/12/27 03:59:04 kaw Exp $
#----------------------------------------

# Copyright (c) 2006--2022
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

# check command-line arguments
#
while getopts m: name
do
    case $name in
        m) memfs=$OPTARG ;;
        ?) echo "Usage: ${0##*/} [-m mfs|tmpfs]"; exit 1 ;;
    esac
done
shift $(($OPTIND - 1))

case $memfs in
    mfs)   altfs=tmpfs;;
    tmpfs) altfs=mfs;;
    ?*) echo "Usage: ${0##*/} [-m mfs|tmpfs]"; exit 1;;
esac

# parameters
#
projname=FuguIta
 version=$(uname -r)
    arch=$(uname -m)
    date=$(date +%Y%m%d)
     rev=1
 imgfile=$(echo ${projname} | tr A-Z a-z)-${version}-${arch}.ffsimg

# files to be remastered
#
files="./boot
./bsd-fi
./bsd-fi.mp
./cdboot
./cdbr
./etc/boot.conf
./$imgfile"

# check contents
#
for f in $files; do
    if [ ! -r $f ]; then
        nofiles="$nofiles $f"
    fi
done
if [[ -n "$nofiles" ]]; then
    echo "$0: missing files needed:$nofiles" >&2
    exit 1
fi

# change mem-based FS if -m specified
#
if [[ -n "memfs" ]]; then
    vn=$(vnconfig $imgfile)
    if [ -z "$vn" ]; then
        echo 'no available vnode device'
        exit 1
    fi
    if mount /dev/${vn}a /mnt; then
        if grep "memfstype=$memfs" /mnt/etc/fuguita/global.conf; then
            echo "File system of /ram is already ${memfs}. Not changed."
        else
            # rewrite the value
            echo "Changing file system of /ram: from $altfs to $memfs"
            sed -i -e '1,$s/memfstype='$altfs'/memfstype='$memfs'/' /mnt/etc/fuguita/global.conf
        fi
        umount /mnt
    fi
    vnconfig -u $vn
fi

# do remastering
#
mkhybrid -a -R -L -l -d -D -N \
                -o ../${projname}-${version}-${arch}-${date}${rev}.iso \
                -v -v \
                -A "FuguIta - OpenBSD Live System" \
                -P "Copyright (c) `date +%Y` Yoshihiro Kawamata" \
                -p "Yoshihiro Kawamata, https://fuguita.org/" \
                -V "${projname}-${version}-${arch}-${date}${rev}" \
                -b cdbr \
                -c boot.catalog \
                .

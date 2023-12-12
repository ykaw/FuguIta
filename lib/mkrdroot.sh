#!/bin/sh

#----------------------------------------
# mkrdroot.sh - create rdroot.ffsimg
# Yoshihiro Kawamata, kaw@on.rim.or.jp
# $Id: mkrdroot.sh,v 1.3 2023/12/12 17:00:29 kaw Exp $
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

set -e
set -x

# make crunched binary bootbin
#
(cd lib
 (cd special
      for prog in init mount_* newfs swapctl sysctl vnconfig; do
         (cd $prog &&
          ln -sf /usr/src/sbin/$prog/*.[ch] .)
      done
  make obj
  make)

 mkdir -p bootbin
 (cd bootbin
  sh ../doit_bootbin))

# create rdroot.ffsimg
#
./lib/setup_fsimg.sh rdroot.ffsimg 1900K 1500 '-b 4096 -f 512'
            # parameters for minimum resources ^^^^^^^^^^^^^^
vnconfig vnd0 rdroot.ffsimg
mount /dev/vnd0a /mnt
(cd rdroot && pax -rwvpe . /mnt/.)

# setup inside rdroot.ffsimg
#
ln -sf boottmp /mnt/bin
ln -sf boottmp /mnt/etc
ln -sf boottmp /mnt/sbin
mkdir -p /mnt/{dev,fuguita,mnt,ram,sysmedia,sysmedia-iso,tmp}
chmod go-rwx /mnt/sysmedia-iso
chmod 1777 /mnt/tmp
(cd /mnt/dev
 cp -p /usr/src/etc/etc.$(uname -m)/MAKEDEV .
 sh ./MAKEDEV all vnd4 vnd5)
cp -p /usr/src/etc/etc.$(uname -m)/login.conf /mnt/boottmp/.
cp -p lib/bootbin/bootbin /mnt/boottmp
for prog in disklabel halt init ksh ln mount mount_cd9660 mount_ext2fs \
            mount_ffs mount_mfs mount_msdos mount_ntfs mount_vnd newfs \
            reboot sed sh sleep swapctl swapon sysctl umount vnconfig
do
    ln -f /mnt/boottmp/bootbin /mnt/boottmp/$prog
done

umount /mnt
vnconfig -u vnd0

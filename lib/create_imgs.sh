#!/bin/ksh

#----------------------------------------
# create_imgs.sh - create media.img and fuguita-*.ffsimg
# Yoshihiro Kawamata, kaw@on.rim.or.jp
# $Id: create_imgs.sh,v 1.5 2023/11/29 06:02:39 kaw Exp $
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

set -x
set -e

stage_files=$(find staging -print|wc -l)           # files under staging
   stage_mb=$((1+$(du -sk staging|cut -f1)/1024))  # staging in MB

 ffs_headroom=8  # room in ffsimg
ffs_roomminus=4  # lesser offset ffsimg
     ffs_size=$((stage_mb+ffs_headroom+ffs_roomminus))

  media_kernels=$(($(cat sys/arch/$(uname -m)/compile/{RDROOT,RDROOT.MP}/obj/bsd | gzip -9c | wc -c)/1024/1024))
                                     # total of compressed kernels size
 media_headroom=$((media_kernels/2)) # room in media.img
media_roomminus=1                    # lesser offset media
     media_size=$((ffs_size+media_kernels+media_headroom+media_roomminus))

cat <<EOT
stage_files=$stage_files
   stage_mb=$stage_mb

 ffs_headroom=8
ffs_roomminus=4
     ffs_size=$ffs_size

 media_headroom=$media_headroom
  media_kernels=$media_kernels
media_roomminus=$media_roomminus
     media_size=$media_size
EOT

# create media.img
#
./lib/setup_fsimg.sh media.img $media_size 20

# create ffsimg in media.img
#
make open-media
ffsimg=fuguita-$(uname -r)-$(uname -m).ffsimg 
./lib/setup_fsimg.sh media/$ffsimg $ffs_size $stage_files
make close-all

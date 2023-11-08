#!/bin/sh

#----------------------------------------
# create_imgs.sh - create media.img and fuguita-*.ffsimg
# Yoshihiro Kawamata, kaw@on.rim.or.jp
# $Id: create_imgs.sh,v 1.4 2023/11/08 00:46:57 kaw Exp $
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

cont_files=$(find staging -print|wc -l)           # files under staging
   cont_mb=$((1+$(du -sk staging|cut -f1)/1024))  # staging in MB

   headroom_fs=8   # room in ffsimg
headroom_media=30  # room in media.img

   roomminus_fs=4  # lesser offset ffsimg
roomminus_media=1  # lesser offset media

# create media.img
#
./lib/setup_fsimg.sh media.img $((cont_mb+headroom_fs+headroom_media+roomminus_media)) 20

# create ffsimg in media.img
#
make open-media
ffsimg=fuguita-$(uname -r)-$(uname -m).ffsimg 
./lib/setup_fsimg.sh media/$ffsimg $((cont_mb+headroom_fs+roomminus_fs)) $cont_files
make close-all

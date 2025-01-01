#!/bin/ksh

#----------------------------------------
# create_imgs.sh - create sysmedia.img and fuguita-*.ffsimg
# Yoshihiro Kawamata, kaw@on.rim.or.jp
# $Id: create_imgs.sh,v 1.13 2025/01/01 00:58:54 kaw Exp $
#----------------------------------------

# Copyright (c) 2023--2025
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

# Strategy: pass1: measure the offset between planned and actual capacity
#           pass2: create the target image file using the measured offset

# measure total size and number of files under staging/
#
      stage_files=$(find staging -print | wc -l)     #  files under staging
       stage_size=$((1+$(du -sk staging | cut -f1))) #  staging in KB
stage_capa_enough=$((12*stage_size/10))              #  increase capacity 20% for trial

cat <<EOT
Staging status:
      stage_files = $stage_files
       stage_size = ${stage_size}K
stage_capa_enough = ${stage_capa_enough}K
EOT

./lib/setup_fsimg.sh trial_capa.img "${stage_capa_enough}K" $stage_files

# setup vn device and mount point before capacity trial
#
setup_trial () {
    (set +e
     mkdir trial_capa
     vnconfig vnd0 trial_capa.img
     mount -o async,noatime /dev/vnd0a trial_capa)
}

# clean up mount point and vn device after capacity trial
#
cleanup_trial () {
    (set +e
     umount trial_capa
     rmdir trial_capa
     vnconfig -u vnd0
     rm -f trial_capa.img)
    true
}

# try Pass1: inject staging files/dirs into trial ffsimg
#
if setup_trial; then
    if ! (cd staging && pax -rwvpe . ../trial_capa); then
        cleanup_trial
        exit 1
    fi
else
    cleanup_trial
    exit 1
fi

  img_capa_real=$(du -sk trial_capa | cut -f1)  # result capacity
headroom_ffsimg=10240                           # headroom to img size

cleanup_trial

cat <<EOT
Pass1 results:
 planned = ${stage_size}K
  actual = ${img_capa_real}K
headroom = ${headroom_ffsimg}K
EOT

# perform Pass2: create real image files
#

# create sysmedia.img if specified by CREATE_SYSMEDIA_IMG
#
if [ -n "$CREATE_SYSMEDIA_IMG" ]; then
    if [[ -f sys/arch/$(uname -m)/compile/RDROOT/obj/bsd &&
          -f sys/arch/$(uname -m)/compile/RDROOT.MP/obj/bsd ]]; then
        media_kernels=$(($(cat sys/arch/$(uname -m)/compile/{RDROOT,RDROOT.MP}/obj/bsd | gzip -9c | wc -c)/1024))
        # total of compressed kernels size
    else
        echo "${0##*/}: kernel not found"
        exit 1
    fi
    media_headroom=$((media_kernels/2)) # room in sysmedia.img
    media_size=$((img_capa_real + headroom_ffsimg + media_kernels + media_headroom))

    cat <<EOT
sysmedia.img results:
   media_kernels=${media_kernels}K
  media_headroom=${media_headroom}K
      media_size=${media_size}K
EOT

    ./lib/setup_fsimg.sh sysmedia.img "${media_size}K" 20
fi

# create ffsimg in sysmedia.img
#
make open-sysmedia
       ffsimg=fuguita-$(uname -r)-$(uname -m).ffsimg

cat <<EOT
Constants:
size of ffsimg: "${img_capa_real}K + ${headroom_ffsimg}K = $((img_capa_real + headroom_ffsimg))K"
EOT

./lib/setup_fsimg.sh sysmedia/$ffsimg "$((img_capa_real + headroom_ffsimg))K" $stage_files
make close-all

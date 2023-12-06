#!/bin/ksh

# Copyright (c) 2006--2023, Yoshihiro Kawamata
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
#   * Neither the name of the Yoshihiro Kawamata nor the names of its
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

#========================================
#
# 010_extract.sh - Extract OpenBSD's install set to staging directory
# KAWAMATA, Yoshihiro / kaw@on.rim.or.jp
#
# $Id: 010_extract.sh,v 1.8 2023/12/06 18:12:44 kaw Exp $
#
#========================================

set -e
set -x

ver=$(uname -r)
shortver=$(echo $ver|tr -dc 0-9)

if [ -d staging ]; then
    rnd=${RANDOM}_${RANDOM}
    mv staging staging.$rnd
    rm -rf staging.$rnd &
fi

mkdir staging
cd staging
pv ../install_sets/base${shortver}.tgz   | tar xzpf -
pv ../install_sets/comp${shortver}.tgz   | tar xzpf -
pv ../install_sets/game${shortver}.tgz   | tar xzpf -
pv ../install_sets/man${shortver}.tgz    | tar xzpf -
pv ../install_sets/xbase${shortver}.tgz  | tar xzpf -
pv ../install_sets/xfont${shortver}.tgz  | tar xzpf -
pv ../install_sets/xserv${shortver}.tgz  | tar xzpf -
pv ../install_sets/xshare${shortver}.tgz | tar xzpf -
pv ./var/sysmerge/etc.tgz | tar xzpf -
pv ./var/sysmerge/xetc.tgz | tar xzpf -

# install packages needed for FuguIta
#
cp ../install_pkgs/*-*.tgz  ./tmp/.
(cd dev && sh ./MAKEDEV std)

cd .. # back to top of build tools

#
# perform pkg_add in chrooted environment
#
cat <<EOT | chroot ./staging /bin/ksh
set -e
set -x
ldconfig /usr/lib /usr/X11R6/lib /usr/local/lib
pkg_add -D unsigned /tmp/rsync-*.tgz
pkg_add -D unsigned /tmp/rlwrap-*.tgz
pkg_add -D unsigned /tmp/pv-*.tgz
rm /tmp/*
EOT

cd staging

# add user's customization, if any
#
if [ -f ../install_sets/site${shortver}.tgz ]; then
    pv ../install_sets/site${shortver}.tgz | tar xzpf -
    if [ -f install.site ]; then
        cat install.site >> etc/rc.firsttime
        rm install.site
    fi
fi

cd .. # back to top of build tools

# apply all issued patches except in kernel
#
if [[ -d ./install_patches && -n "$(ls -A ./install_patches)" ]]; then
    for patch in ./install_patches/binupdate-$(uname -r)-$(uname -m)-*.tgz; do
        tar -C ./staging -xvzpf $patch
    done
fi

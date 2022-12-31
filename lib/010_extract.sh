#!/bin/sh

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
# $Id: 010_extract.sh,v 1.4 2022/12/31 23:56:13 kaw Exp $
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

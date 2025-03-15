#!/bin/ksh

#========================================
# compress_man.sh - compress and link man pages
#                   for live system authoring
#
# Yoshihiro Kawamata, kaw@on.rim.or.jp
# $Id: compress_man.sh,v 1.1 2025/03/15 18:58:35 kaw Exp $
#========================================

# Copyright (c) 2010--2025
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

find . -type f \( -name '*.[0-9]' -o -name '*.[0-9][a-z]' \) -links 1 -print | xargs gzip -v9

find . -type f \( -name '*.[0-9]' -o -name '*.[0-9][a-z]' \) -links +1 -print |
while read f
do
    if file $f | grep -q 'gzip compressed data'
    then
        mv $f $f.gz
    else
        gzip -cv9 $f > $f.gz.tmp
        mv $f $f.gz
        cat $f.gz.tmp > $f.gz
        rm $f.gz.tmp
    fi
done

find . -type l \( -name '*.[0-9]' -o -name '*.[0-9][a-z]' \) -print |
while read f
do
    ln -s `stat -f '%Y' $f`.gz $f.gz
    rm $f
done

#!/bin/sh

#========================================
#
# guidtab.sh - generate "GUID,Partition Name" table text
# from /usr/src/sbin/fdisk/part.c
#
# KAWAMATA, Yoshihiro / kaw@on.rim.or.jp
#
# $Id: guidtab.sh,v 1.1 2025/03/15 18:58:35 kaw Exp $
#
#========================================

# Copyright (c) 2025
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

awkcode='
BEGIN {
    DEFFS=FS
    COMFS="[ 	]*,[ 	]*"
}

# #define OPENBSD_GUID		"824cc7a0-36a8-11e3-890a-952519ad3f61"
#
/^\#define[ 	]+[A-Z0-9_][A-Z0-9_]*_GUID[ 	]+"[0-9a-f][0-9a-f]*-[0-9a-f][0-9a-f]*-[0-9a-f][0-9a-f]*-[0-9a-f][0-9a-f]*-[0-9a-f][0-9a-f]*"/ {
    FS=DEFFS
    $0=$0  # re-split with new field separator
    gsub("\"", "", $3)
    guid[$2] = $3
#    print "guid["$2"]="$3  # for debug
}

#	{ 0, "Microsoft basic data",		MICROSOFT_BASIC_DATA_GUID },
#
/{[ 	]*0[ 	]*,[ 	]*"[^"][^"]*"[ 	]*,[ 	]*[A-Z0-9_][A-Z0-9_]*_GUID[ 	]*}/ {
    FS=COMFS
    $0=$0  # re-split with new field separator
    gsub("\"", "", $2)
    gsub("[ 	]*}.*", "", $3)
    print guid[$3]","$2
}

#	{ 0xA6,	0xA6,	"OpenBSD",	OPENBSD_GUID },
#
/^[ 	]+{[ 	]*0x[0-9A-F][0-9A-F][ 	]*,[ 	]*0x[0-9A-F][0-9A-F][ 	]*,[ 	]*"[^"]*"[ 	]*,[ 	]*[A-Z0-9_][A-Z0-9_]*[ 	]*}/ {
    FS=COMFS
    $0=$0  # re-split with new field separator
    gsub("\"", "", $3)
    gsub("[ 	]*}.*", "", $4)
    if (guid[$4] != "")
        print guid[$4]","$3
}
'

awk "$awkcode" /usr/src/sbin/fdisk/part.c | sort -t, -k2,2 -k1,1 | uniq

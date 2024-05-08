#!/bin/ksh

#========================================
# gen_makebootarc_arm64
#
# This shell script tries to generate shell command sequence
# to copy apropriate files from RPi FW and u-boot package to 
# to specified directory according to the structure of ESP
# (EFI System Partition)
#
# Yoshihiro Kawamata, kaw@on.rim.or.jp
# $Id: gen_makebootarc_arm64.sh,v 1.3 2024/05/08 06:57:52 kaw Exp $
#========================================

# Copyright (c) 2016--2024
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

# system wide constants
#
readonly ESP=/dev/sd0i
readonly SRC_DIRS='/usr/local/share/raspberrypi-firmware /usr/local/share/u-boot'

# print error message and exit
#
err_exit () {
    echo "${0##*/}: $@" >&2
    exit 1
}

# main: build dir tree and copy files
#
gen_cmds () {
    # list of all package files
    local src_files="$(find $SRC_DIRS -type f -print | sort)"

    [[ -z "$src_files" ]] && err_exit 'no source files'

    # build two lists
    #   directories and files in ESP
    mount -r $ESP /mnt || err_exit 'cannot mount /mnt readonly'
    local cwd=$(pwd)
    cd /mnt || err_exit 'cannot cd to /mnt'
    local dst_dirs="$(find * -type d -print | sort)"
    local dst_files="$(find * -type f -print | sort)"
    cd $cwd
    umount $ESP

    [[ -z "$dst_dirs" ]] && err_exit 'no destination directories set'
    [[ -z "$dst_files" ]] && err_exit 'no destination files set'

    # make directories from the list
    #
    local path
    for path in $dst_dirs; do
        echo mkdir -p $path
    done

    # generate command sequence for copying files
    #
    local base
    local nfound
    for path in $dst_files; do
        base=${path##*/}
        nfound=$(echo "$src_files" | grep "/$base\$" | wc -l)
        if [[ 0 -eq "$nfound" ]]; then
            # boot stuff which missing in package directories (/usr/local/*)
            # maybe this needs to be created by hand
            echo "# $base not found: replace this with a command line to create $path"
        elif [[ 1 -eq "$nfound" ]]; then
            # found only one, generate copy command
            echo cp -p $(echo "$src_files" | grep "/$base\$") $path
        elif [[ 2 -le "$nfound" ]]; then
            # found multiple
            echo "# found $base in multiple paths"
            echo "# please select (uncomment) from following lines"
            for found in $(echo "$src_files" | grep "/$base\$"); do
                echo "# dup: cp -p $found $path"
            done
        fi
    done
}

ARCNAME="bootstuff.$(uname -m)"

cat <<EOT
#!/bin/sh

set -x

mkdir '$ARCNAME' || exit 1
cd '$ARCNAME' || exit 1

EOT

gen_cmds

cat <<EOT

tar cvzf '../${ARCNAME}.tar.gz' .
cd ..
rm -r '$ARCNAME'
EOT

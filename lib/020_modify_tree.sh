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
# 020_extract.sh - modify OpenBSD's file tree for FuguIta
# KAWAMATA, Yoshihiro / kaw@on.rim.or.jp
#
# $Id: 020_modify_tree.sh,v 1.11 2023/11/29 23:26:39 kaw Exp $
#
#========================================

set -e
set -x

# remove KARL files ... not needed for R/O filesystem
#
rm -f  ./staging/usr/share/relink/kernel.tgz
rm -rf ./staging/usr/share/relink/kernel

# disable inappropriate commands
#
mv ./staging/usr/sbin/sysupgrade{,.orig}
mv ./staging/usr/sbin/syspatch{,.orig}
cat <<EOT > ./staging/usr/sbin/sysupgrade
#!/bin/sh
echo Sorry, \${0##*/} does not work correctly on FuguIta.
EOT
cat <<EOT > ./staging/usr/sbin/syspatch
#!/bin/sh
echo Sorry, \${0##*/} does not work correctly on FuguIta.
echo Please use fiupdate utility to apply patch.
EOT
chown root:bin ./staging/usr/sbin/{sysupgrade,syspatch}
chmod 0555 ./staging/usr/sbin/{sysupgrade,syspatch}

# fix dangling symlinks
#
ln -sf /bin/chmod   ./staging/usr/bin/chflags
ln -sf /bin/chgrp   ./staging/usr/sbin/chgrp
ln -sf /sbin/chown  ./staging/usr/sbin/chown
ln -sf /sbin/sysctl ./staging/usr/sbin/sysctl

# for stable shutdown
# replace /sbin/{reboot,halt} with ones on rdroot
#
mv ./staging/sbin/reboot{,.orig}
mv ./staging/sbin/halt{,.orig}
ln -s /boottmp/reboot ./staging/sbin/reboot
ln -s /boottmp/halt ./staging/sbin/halt

# setup FuguIta specific files/directories
#
mkdir -p ./staging/usr/fuguita/bin
ln -sf /boottmp/dtjsetup ./staging/usr/fuguita/bin/dtjsetup

mkdir -p ./staging/usr/fuguita/sbin
for cmd in chnetconf fdadm fiupdate gen_mode0sldir gennetconfs remaster_dvd.sh usbfadm
do
    ln -sf /boottmp/$cmd ./staging/usr/fuguita/sbin
done

# some setups in chrooted environment
#
cat <<EOT | chroot ./staging /bin/ksh
set -e
set -x
makewhatis
for dir in 100dpi 75dpi OTF TTF Type1 cyrillic misc
do
    mkfontdir /usr/X11R6/lib/X11/fonts/\$dir
done
for dir in OTF TTF Type1
do
    mkfontscale /usr/X11R6/lib/X11/fonts/\$dir
done
fc-cache
EOT

# setup FuguIta specific files/directories again
#
mkdir -p ./staging/etc/fuguita
cp -p ./lib/global.conf.$(uname -m) ./staging/etc/fuguita/global.conf
cp -p ./lib/mode0symlinks.cpio.gz.$(uname -m) ./staging/etc/fuguita/mode0symlinks.cpio.gz || true
cp -p ./lib/usbfadm_postproc.sh.$(uname -m) ./staging/etc/fuguita/usbfadm_postproc.sh || true

# cleanups
#
rm -f ./staging/root/.ksh_history

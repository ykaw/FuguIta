#!/bin/sh

set -e
set -x

origwd=$(pwd)
[[ -z "$origwd" ]] && exit 1

rm -f  ./staging/usr/share/relink/kernel.tgz
rm -rf ./staging/usr/share/relink/kernel

ln -sf /bin/chmod   ./staging/usr/bin/chflags
ln -sf /bin/chgrp   ./staging/usr/sbin/chgrp
ln -sf /sbin/chown  ./staging/usr/sbin/chown
ln -sf /sbin/sysctl ./staging/usr/sbin/sysctl

mkdir -p ./staging/usr/fuguita/bin
ln -sf /boottmp/dtjsetup ./staging/usr/fuguita/bin/dtjsetup

mkdir -p ./staging/usr/fuguita/sbin
for cmd in chnetconf compress_man.sh fdadm find1so.sh fiupdate gen_mode0sldir gennetconfs remaster_dvd.sh setup_fsimg.sh usbfadm
do
    ln -sf /boottmp/$cmd ./staging/usr/fuguita/sbin
done

cp ./install_pkgs/rsync-*.tgz  ./staging/tmp/.
cp ./install_pkgs/rlwrap-*.tgz ./staging/tmp/.
cp ./install_pkgs/pv-*.tgz     ./staging/tmp/.

(cd ./staging/dev && sh ./MAKEDEV std)

cat <<EOT | chroot ./staging /bin/ksh
set -x
ldconfig /usr/lib /usr/X11R6/lib /usr/local/lib
pkg_add -D unsigned /tmp/rsync-*.tgz
pkg_add -D unsigned /tmp/rlwrap-*.tgz
pkg_add -D unsigned /tmp/pv-*.tgz
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

rm ./staging/tmp/*
rm -f ./staging/root/.ksh_history

mkdir ./staging/etc/fuguita
cp -p ./lib/usbfadm.conf.$(uname -m) ./staging/etc/fuguita/usbfadm.conf
cp -p ./lib/mode0symlinks.cpio.gz.$(uname -m) ./staging/etc/fuguita/mode0symlinks.cpio.gz

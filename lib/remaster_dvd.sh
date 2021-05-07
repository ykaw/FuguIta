#!/bin/sh

#----------------------------------------
# remaster_dvd.sh - Remastering FuguIta's LiveDVD
# Yoshihiro Kawamata, kaw@on.rim.or.jp
# $Id: remaster_dvd.sh,v 1.2 2021/05/07 10:39:20 kaw Exp $
#----------------------------------------

# parameters
#
projname=FuguIta
 version=$(uname -r)
    arch=$(uname -m)
    date=$(date +%Y%m%d)
     rev=1

# files to be remastered
#
files=$(cat<<EOT
./boot
./boot.catalog
./bsd-fi
./bsd-fi.mp
./cdboot
./cdbr
./etc/boot.conf
./etc/random.seed
./$(echo ${projname} | tr A-Z a-z)-${version}-${arch}.ffsimg
EOT)

# check contents
#
if [ "$files" != "$(find . -type f -print | sort)" ]; then
    echo "$0: it doesn't seem to be ${projname}'s dir:" >&2
    echo '  shouldbe:' $files
    echo '  reallyis:' $(find . -type f -print | sort)
    exit 1
fi

# do remastering
#
mkhybrid -a -R -L -l -d -D -N \
                -o ../${projname}-${version}-${arch}-${date}${rev}.iso \
                -v -v \
                -A "FuguIta - OpenBSD Live System" \
                -P "Copyright (c) `date +%Y` Yoshihiro Kawamata" \
                -p "Yoshihiro Kawamata, http://fuguita.org/" \
                -V "${projname}-${version}-${arch}-${date}${rev}" \
                -b cdbr \
                -c boot.catalog \
                .
